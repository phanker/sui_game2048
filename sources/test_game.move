#[test_only]
module sui::test_game {
    use sui::clock;
    use sui::tx_context;
    use game::game_2048::{Self,Game2048};
    use std::debug;
    use sui::object;
    use oracle::weather;
    use std::vector;
    use sui::vec_map;

    #[test]
    fun creat_tiles_panel() {
        let ctx = tx_context::dummy();
        let weather_oracle = weather::create_for_testing(&mut ctx);
        weather::add_city_for_testing(&mut weather_oracle,  2988507, 
                                    std::string::utf8(b"France"), 
                                std::string::utf8(b"France"),
                                    133,
                    true, 
                            155, 
                                    true, 
                                    31,
                                    &mut ctx);
        let game = game_2048::create_tiles_panel(&mut ctx,&weather_oracle);
        let tiles = game_2048::get_tiles(&game);
        assert!(vec_map::size(tiles) == 2,1);
        game_2048::destroy_for_testing(game);
        weather::destroy_for_testing(weather_oracle);
    }



     #[test]
    fun moves_tile_test() {
        let ctx = tx_context::dummy();
        let weather_oracle = weather::create_for_testing(&mut ctx);
        weather::add_city_for_testing(&mut weather_oracle,  2988507, 
                                    std::string::utf8(b"France"), 
                                std::string::utf8(b"France"),
                                    133,
                    true, 
                            155, 
                                    true, 
                                    35,
                                    &mut ctx);
        let game = game_2048::create_tiles_panel(&mut ctx,&weather_oracle);
        // 0 -> left
        // 1 -> down
        // 2 -> right
        // 3 -> up 
        game_2048::move_tile(&mut game,&weather_oracle,0);
        game_2048::move_tile(&mut game,&weather_oracle,2);
        game_2048::move_tile(&mut game,&weather_oracle,2);
        game_2048::move_tile(&mut game,&weather_oracle,3);
               game_2048::move_tile(&mut game,&weather_oracle,1);
                      game_2048::move_tile(&mut game,&weather_oracle,2);
                             game_2048::move_tile(&mut game,&weather_oracle,3);
                                    game_2048::move_tile(&mut game,&weather_oracle,2);
                                           game_2048::move_tile(&mut game,&weather_oracle,1);
        game_2048::move_tile(&mut game,&weather_oracle,2);
        game_2048::move_tile(&mut game,&weather_oracle,3);
game_2048::move_tile(&mut game,&weather_oracle,1);
game_2048::move_tile(&mut game,&weather_oracle,2);
game_2048::move_tile(&mut game,&weather_oracle,3);
game_2048::move_tile(&mut game,&weather_oracle,0);
game_2048::move_tile(&mut game,&weather_oracle,3);
game_2048::move_tile(&mut game,&weather_oracle,1);
game_2048::move_tile(&mut game,&weather_oracle,2);
game_2048::move_tile(&mut game,&weather_oracle,0);
game_2048::move_tile(&mut game,&weather_oracle,1);
game_2048::move_tile(&mut game,&weather_oracle,2);
game_2048::move_tile(&mut game,&weather_oracle,3);
game_2048::move_tile(&mut game,&weather_oracle,2);
game_2048::move_tile(&mut game,&weather_oracle,3);
game_2048::move_tile(&mut game,&weather_oracle,1);
        // debug::print();
        let tiles = game_2048::get_tiles(&game);
        // debug::print(tiles);
        assert!(vec_map::size(tiles) == 3,1);
        game_2048::destroy_for_testing(game);
        weather::destroy_for_testing(weather_oracle);
    }


    // #[test]
    // fun creating_a_clock_and_incrementing_it() {
    //     let ctx = tx_context::dummy();
    //     let clock = clock::create_for_testing(&mut ctx);
      
    //     // game_2048::
    //     // clock::increment_for_testing(&mut clock, 42);
    //     // assert!(clock::timestamp_ms(&clock) == 42, 1);

    //     // clock::set_for_testing(&mut clock, 50);
    //     // assert!(clock::timestamp_ms(&clock) == 50, 1);

    //     // clock::destroy_for_testing(clock);
    // }



}




// 0,0
// 1,0
// 2,1


// 0,3
// 1,3
// 2,3
// 3,0

