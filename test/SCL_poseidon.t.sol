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
//1,2,0,0,0, ->1018317224307729531995786483840663576608797660851238720571059489595066344487
//1,2,3,4,5 ->6183221330272524995739186171720101788151706631170188140075976616310159254464

import "forge-std/Test.sol";
import "src/hash/SCL_poseidon5.sol";

address constant _POSEIDONADD=address(0xcaca);




contract SCL_PoseidonTest is Test {


function test_poseidon5() public{
   string memory deployData = vm.readFile("src/hash/poseidon5.json");
   bytes memory bytecode = abi.decode(vm.parseJson(deployData, ".poseidon5_bytecode"), (bytes));

   //mocking the deployment
   vm.etch(_POSEIDONADD, bytecode);    
   console.log("Test Poseidon 5 over babyjj field:");

   uint256[5] memory hash_in=[uint256(1),2,3,4,5];

   Poseidon5 hash=new Poseidon5(_POSEIDONADD);
   //Poseidon5 hash=new Poseidon5(somewhere);
   
    bytes memory res;

  (,res)=hash.poseidon(hash_in);
  bytes memory expected = hex"0dab9449e4a1398a15224c0b15a49d598b2174d305a316c918125f8feeb123c0";
//                        
  assertEq(res, expected);
  hash_in=[uint256(1),2,0,0,0];

 (,res)=hash.poseidon(hash_in);
  expected =  hex"024058dd1e168f34bac462b6fffe58fd69982807e9884c1c6148182319cee427";

  assertEq(res, expected);
  
  console.log("                                     OK");

   
}


}