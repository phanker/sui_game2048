module game::game_2048{
    use std::vector;
    use std::option::{Self,Option};
    use std::string::{Self,String};
    use sui::object::{Self,UID};
    use sui::vec_map::{Self,VecMap};
    use sui::tx_context::{Self,TxContext};
    use sui::math;
    use sui::event;
    use sui::transfer;
    use std::debug;
    use sui::ecvrf::ecvrf_verify;
    use sui::vec_set;
    use sui::hash::blake2b256;
    use oracle::weather::{Self,WeatherOracle};
    
    
    const E_GAME_ALREADY_OVER: u64=1;
  
    struct Tile has store,copy,drop {
        key:u64,
        i: u64,
        j: u64,
        value : u64,
        overlaid:bool,
    }

    struct Game2048 has key ,store{
        id: UID,
        tiles: VecMap<u64, Tile>,
        isgameOver: bool,
        won:bool,
        score:u64,
    }

    struct TopTiles has copy,drop{
        tiles: vector<Option<Tile>>,
        toDelete: vector<u64>,
    }


    //#############Event##############
    struct ScoreEvent has copy,drop{
        addScore:u64,
        totalScore:u64,
    }

    struct UpdateEvent has copy,drop{
        tiles: VecMap<u64, Tile>
    }
    
    //0:fail 1:success
    struct GameOverEvent has copy,drop{
        result: u8,
        msg: String,
    }

    struct MaxMergeEvent has copy,drop{
        maxMerge: u64,
    }

    struct WinEvent has copy,drop{
        gameOverFlag: bool,
    }

    struct StateChanged has copy,drop{
        stateChanged: vector<u64>,
    }

    #[lint_allow(self_transfer)]
    public entry fun new_game(weather_oracle:&WeatherOracle,ctx:&mut TxContext){
        let game = create_tiles_panel(ctx,weather_oracle);
        transfer::public_transfer(game,tx_context::sender(ctx));
    }


    public fun create_tiles_panel(ctx:&mut TxContext,weather_oracle:&WeatherOracle):Game2048{
        let id = object::new(ctx);
        let game = Game2048{
                id,
                tiles:vec_map::empty<u64, Tile>(),
                isgameOver: false,
                won:false,
                score:0,
        };
        generateTile(&mut game,weather_oracle);
        generateTile(&mut game,weather_oracle);
        game
    }

    public fun generateTile(_tiles: &mut Game2048,weather_oracle: &WeatherOracle):bool{
               
    
        let validPos = vec_set::empty<u64>();
        {
            let i = 0;
            while (i < 16) {
                vec_set::insert(&mut validPos,i);
                i = i + 1;
            };
        };
        
        
        let keys = vec_map::keys(&_tiles.tiles);
        {

            let i = 0;
            let len = vector::length(&keys);
   
            while (i < len) {
                let key = vector::borrow(&keys, i);
                let v= vec_map::get(&_tiles.tiles,key);
                if(v.overlaid){
                    i = i + 1;
                    continue;
                };
                let remove_key = v.i * 4 + v.j;
                vec_set::remove(&mut validPos, &remove_key);
                i = i + 1;
              
            };
        };

        let len = vec_set::size(&validPos);
        let random_num = get_random(weather_oracle) % len;
        let pos_keys = vec_set::keys(&validPos);
        let pos = vector::borrow(pos_keys,random_num);
        let i = (*pos / 4 as u64);
        let j = (*pos % 4 as u64);
        let value = {
            let modnum = get_random(weather_oracle) % 6;
            if(modnum > 2){
                4
            }else{
                2
            }
        };

        let keys = vec_map::keys(&_tiles.tiles);
        let keys_length = vector::length(&keys);
        let key = 0;
        if(keys_length > 0){
            key = *vector::borrow(&keys,keys_length - 1) + 1;
        };
        let overlaid = false;
        let new_tile = Tile { i, j ,value,key,overlaid};
        vec_map::insert(&mut _tiles.tiles,key,new_tile);

        if (vec_set::size(&validPos) == 1) {
            return judge(&_tiles.tiles)
        };

        false
    }


    public entry fun move_tile(game:&mut Game2048,weather_oracle: &WeatherOracle,direction:u8){
        assert!(!game.isgameOver,E_GAME_ALREADY_OVER);
        let base = vector::empty<u64>();
        let diff = vector::empty<u64>();
        if(direction == 0){//up
            vector::push_back(&mut base,0);
            vector::push_back(&mut base,4);
            vector::push_back(&mut base,8);
            vector::push_back(&mut base,12);

            vector::push_back(&mut diff,100);
            vector::push_back(&mut diff,101);
            vector::push_back(&mut diff,102);
            vector::push_back(&mut diff,103);
        }else if(direction == 1){//right
            vector::push_back(&mut base,12);
            vector::push_back(&mut base,13);
            vector::push_back(&mut base,14);
            vector::push_back(&mut base,15);

            vector::push_back(&mut diff,100);
            vector::push_back(&mut diff,96);
            vector::push_back(&mut diff,92);
            vector::push_back(&mut diff,88);
        }else if(direction == 2){//Down
            vector::push_back(&mut base,3);
            vector::push_back(&mut base,7);
            vector::push_back(&mut base,11);
            vector::push_back(&mut base,15);

            vector::push_back(&mut diff,100);
            vector::push_back(&mut diff,99);
            vector::push_back(&mut diff,98);
            vector::push_back(&mut diff,97);
        }else if(direction == 3){//Left

            vector::push_back(&mut base,0);
            vector::push_back(&mut base,1);
            vector::push_back(&mut base,2);
            vector::push_back(&mut base,3);

            vector::push_back(&mut diff,100);
            vector::push_back(&mut diff,104);
            vector::push_back(&mut diff,108);
            vector::push_back(&mut diff,112);

        };


        let top_tiles = get_top_tiles(&game.tiles);

        // debug::print(&top_tiles.tiles);

        // debug::print(&string::utf8(b"----------Before Move----------"));
        // debug::print(&game.tiles);
        {

            let i = 0;
            let length = vector::length(&top_tiles.toDelete);
            while(i < length){
                let needed_remove_key = vector::borrow(&top_tiles.toDelete,i);
                vec_map::remove(&mut game.tiles,needed_remove_key);
                i = i + 1;
            }
        };
   
        let movedFlag = false;
        let winFlag = false;
        let scoreAdded = 0;
        let maxTileMerged = 0;

        {
           let i = 0;
           while(i < 4){
                let b = vector::borrow(&base,i);

                let _currentTile = option::none<Tile>();
                let targetPosIndex = 0;
                let j = 0;
                while(j < 4){
                    let d = vector::borrow(&diff,j);
                    let index = *b + *d;
                    let _tile = vector::borrow_mut(&mut top_tiles.tiles,index-100);
                    if(option::is_some(_tile)){
                        let tile = option::borrow_mut(_tile);
                        let o_tile = vec_map::get_mut(&mut game.tiles,&tile.key);
                        if(option::is_some(&_currentTile)){
                            let currentTile = option::borrow_mut(&mut _currentTile);
       
                            if(tile.value == currentTile.value){
                 
                                currentTile.value = o_tile.value * 2;
                                o_tile.overlaid = true;
                            
                                if (currentTile.value == 2048) {
                                    if (!game.won) {
                                        game.won = true;
                                        winFlag = true;
                                    };
                                };
                    
                                o_tile.i = currentTile.i;
                                o_tile.j = currentTile.j;
                                let merge_tile = vec_map::get_mut(&mut game.tiles,&currentTile.key);
                                merge_tile.value = currentTile.value;
                                scoreAdded = scoreAdded + currentTile.value;
                                movedFlag = true;
                                maxTileMerged =  math::max(maxTileMerged,currentTile.value);
                                option::destroy_some(_currentTile);
                            }else{
                        
                                let targetPos = *b + *vector::borrow(&diff,targetPosIndex) - 100;
                                if (tile.i * 4 + tile.j != targetPos) {
                 
                                    tile.i = targetPos / 4; 
                                    tile.j = targetPos % 4;
                                    o_tile.i = tile.i;
                                    o_tile.j = tile.j;
                                    movedFlag = true;
                                };
                                option::swap_or_fill(&mut _currentTile,*tile);
                                targetPosIndex = targetPosIndex + 1;
                            };
                        
                        }else{
              
                           let targetPos = *b + *vector::borrow(&diff,targetPosIndex) - 100;
                           if (tile.i * 4 + tile.j != targetPos) {
             
                             tile.i = targetPos / 4; 
                             tile.j = targetPos % 4;
                             o_tile.i = tile.i;
                             o_tile.j = tile.j;
                             movedFlag = true;
                           };
                           option::swap_or_fill(&mut _currentTile,*tile);
                           targetPosIndex = targetPosIndex + 1;
                        };
                    };
                    j = j + 1;
                };
                i = i + 1;
           }
        };



        let gameOverFlag = false;
        if (movedFlag) {

          gameOverFlag = generateTile(game,weather_oracle);
          let update_event = UpdateEvent{
            tiles:game.tiles
          };
          event::emit(update_event);
        };
        if (scoreAdded > 0) {
            game.score = scoreAdded +  game.score;
            let score_event = ScoreEvent{
                addScore:scoreAdded,
                totalScore:game.score,
            };
            event::emit(score_event);
        };

        if (maxTileMerged>0) {
            let max_merge_event = MaxMergeEvent{
                maxMerge:maxTileMerged,
            };
            event::emit(max_merge_event);
        };
        if (gameOverFlag) {
            game.isgameOver = gameOverFlag;
            let game_over = GameOverEvent{
                  result: 1,
                  msg: string::utf8(b"Game Over!"),
            };
            event::emit(game_over);
        };
        if (winFlag) {
            let winEvent = WinEvent{
                gameOverFlag
            };
            event::emit(winEvent);
        };
        if (movedFlag) {
            let stateChanged = StateChanged{
                stateChanged :get_state(game),
            };
            event::emit(stateChanged);
        };

        // debug::print(&string::utf8(b"----------After Move----------"));
        // debug::print(&game.tiles);
    }


    public fun get_state(game: &Game2048) : vector<u64> {
        if (!game.isgameOver) {

            let result = vector::empty<u64>();

            while (vector::length(&result) < 16) {
                vector::push_back(&mut result, 0);
            };

            let keys = vec_map::keys( &game.tiles);
            let length = vector::length(&keys);

            let i = 0;
            while(i < length){
                let key = vector::borrow(&keys,i);
                let tile = vec_map::get(&game.tiles,key);
                let index = (tile.i * 4) + tile.j;
                vector::push_back(&mut result,log2(tile.value));
                vector::swap_remove(&mut result, index);
                i = i + 1;
            };
           return result
        };

        vector::empty<u64>()
    }

    public fun log2(n: u64): u64 {
        let result: u64 = 0;
        let temp: u64 = n;

        while (temp > 1) {
            temp = temp / 2;
            result = result + 1;
        };
        result
    }


    public fun judge(tiles: &VecMap<u64, Tile>) : bool{
        let top_tiles = get_top_tiles(tiles);
        let flag = true;
        let i = 0;

        while (flag && (i < 4)) {
            let j = 0;
            while (flag && (j < 4)) {
                let current_tile = vector::borrow(&top_tiles.tiles, i * 4 + j);

                if (option::is_none(current_tile)) {
                    flag = false;
                } else if (i % 4 < 3) {
                    let next_tile = vector::borrow(&top_tiles.tiles, (i + 1) * 4 + j);
                    if (option::is_none(next_tile) || option::borrow(current_tile).value == option::borrow(next_tile).value) {
                        flag = false;
                    }
                };

                if (j % 4 < 3 && option::is_some(current_tile)) {
                    let right_tile = vector::borrow(&top_tiles.tiles, i * 4 + j + 1);
                    if (option::is_none(right_tile) || option::borrow(current_tile).value == option::borrow(right_tile).value) {
                        flag = false;
                    }
                };

                j = j + 1;
            };
            i = i + 1;
        };

        flag
    }

    fun get_random(weather_oracle: &WeatherOracle): u64 {
        let geoname_id1 = 2988507; 
        let geoname_id2 = 2290956; 
        let temp1 = weather::city_weather_oracle_temp(weather_oracle, geoname_id1);
        let pre1 = weather::city_weather_oracle_pressure(weather_oracle,geoname_id1);

        let temp2 = weather::city_weather_oracle_temp(weather_oracle, geoname_id2);
        let pre2 = weather::city_weather_oracle_pressure(weather_oracle,geoname_id2);

        let seed = convert_weather_to_seed(temp1+temp1,pre1+pre2);
        generate_random((seed as u64))
    }

    fun convert_weather_to_seed(temperature: u32, wind_speed: u32) : u32 {
        temperature * wind_speed
    }

    fun generate_random(seed:u64) : u64 {
        (seed * 73 + 41) % 100
    }


    public fun get_top_tiles(tiles:&VecMap<u64, Tile>): TopTiles {
        let result = vector::empty<Option<Tile>>();
        {
            let i = 0;
            while(i < 16){
                vector::push_back(&mut result,option::none<Tile>());
                i = i + 1;
            }
        };

        let to_delete_key= vector::empty<u64>();
        {
            let i = 0;
            let keys = vec_map::keys(tiles);
            while (i < vector::length(&keys)) {
                // debug::print(&string::utf8(b"---------------start-------------"));
                // debug::print(tiles);
                let key = vector::borrow(&keys,i);
                // debug::print(key);
                // debug::print(&string::utf8(b"---------------end-------------"));
                let tile = vec_map::get(tiles, key);
                if (!tile.overlaid) {
                    vector::push_back(&mut result, option::some(*tile),);
                    vector::swap_remove(&mut result, tile.i*4 + tile.j);
                } else {
                    vector::push_back(&mut to_delete_key, tile.key);
                };

                i = i + 1;
            };
        };

        TopTiles {
            tiles: result,
            toDelete: to_delete_key
        }
    }


    public fun get_tiles(game:&Game2048):&VecMap<u64, Tile>{
        &game.tiles
    }

    public fun get_score(game:&Game2048):u64{
        game.score
    }


    #[test_only]
    public fun destroy_for_testing(game: Game2048) {
        let Game2048 { 
            id,
            tiles: _,
            isgameOver:_,
            won:_,
            score:_
        }  = game;
        object::delete(id);
    }
    



}