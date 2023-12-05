/********************************************************************************************/
/*
/*     ___                _   _       ___               _         _    _ _    
/*    / __|_ __  ___  ___| |_| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__ 
/*    \__ \ '  \/ _ \/ _ \  _| ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
/*   |___/_|_|_\___/\___/\__|_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
/*                                         |__/|_|           
/*              
/* Copyright (C) 2023 - Renaud Dubois - This file is part of SCL (Smooth CryptoLib) project
/* License: This software is licensed under MIT License                                        
/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

//vectors extracted using go_iden3

import "forge-std/Test.sol";

uint256 constant _POSEIDONADD=0xcaca;

contract SCL_ed25519Test is Test {

function test_poseidon5() public{
   string memory deployData = vm.readFile("src/hash/poseidon5.json");
   bytes memory bytecode = abi.decode(vm.parseJson(deployData, ".Bytecode"), (bytes));
   vm.etch(address(uint160(_POSEIDONADD)), bytecode);    
   
    
}


}