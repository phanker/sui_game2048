# SUI-2048GAME

## Technology Stack & Tools

- [Sui](https://sui.io/) (Block Chain)
- Move (Writing Smart Contracts)

## Setting Up

### 1. Clone/Download the Repository

### 2. Build Project:

`$ sui move client build`

### 3.Deploy contract:

In a separate terminal,go to the project root directory and execute:
`$ sui client publish --gas-budget 100000000`

Get the 'package_id' of contract from the log of deployment:
You'll find the "Transaction Effects" log below,the symbol 'ID' and 'Owner: Immutable' represent 'package_id'.  
On this log,0xcb469efcc88664893e4350b5f3719c01e302a9c1c199a9f96e11eb18381b8f1e is exact package_id.

### 4.Game Introduction

1.2048Game is a full-chain game.All states of game are managed on the blockchain.  
2.We can provide a direction to the move_tiles function to control the movement of tiles on the game panel.  
3.The generation of tiles is base on random numbers ,which are generated by a weather oracle and timestemp from the blockchain