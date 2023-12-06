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

address constant _POSEIDONADD=address(0xcaca);


contract Poseidon5{
  
   //a pointer to the bytecode of the contract
   address bytecode;

   constructor(address where){
    bytecode=where;
   }

   function poseidon(uint256[5] memory input) public returns(bool flag, bytes memory res)
    {
      bytes memory payload = abi.encodeWithSignature("poseidon(uint256[5])",input);

     return( address(bytecode).call(payload));
     
    }
}

contract SCL_PoseidonTest is Test {


function test_poseidon5() public{
   string memory deployData = vm.readFile("src/hash/poseidon5.json");
   bytes memory bytecode = abi.decode(vm.parseJson(deployData, ".poseidon5_bytecode"), (bytes));

   console.log("Contract:\n");
   console.logBytes(bytecode);

   vm.etch(_POSEIDONADD, bytecode);    
   
   uint size=bytecode.length;
   console.log("size=",size);

   /* 
   address somewhere;
   console.log("\n code somewhere:");
   assembly{
     somewhere:=create(bytecode, 0, size)
   }
   console.logBytes(somewhere.code); 
   */

   uint256[5] memory hash_in=[uint256(1),2,0,0,0];

   Poseidon5 hash=new Poseidon5(_POSEIDONADD);
   //Poseidon5 hash=new Poseidon5(somewhere);
  

   console.log("Contract wrapper:\n");
   console.logBytes(address(hash).code); 
  
    bytes memory res;

    (,res)=hash.poseidon(hash_in);

    console.log("returned:\n");
    console.logBytes(res);


}


}