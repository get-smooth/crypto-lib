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

import "forge-std/Test.sol";
import  "@solidity/modular/SCL_modular.sol"; 
import  "@solidity/include/SCL_field.h.sol";

contract SCL_ECDSATest is Test {


 function test_FuzzModInv() public returns(bool) {

     uint256 u=2;
     vm.assume(u<p);
     vm.assume(u<n);
     vm.assume(u>0);

    uint256 res=ModInv(u, n);
    uint256 res2=nModInv(u);
    
    assertEq(mulmod(res2,u,n),1); 
    assertEq(mulmod(res,u,n),1); 

    res=ModInv(u, p);
    res2=pModInv(u);


    assertEq(mulmod(res2,u,p),1); 
    assertEq(mulmod(res,u,p),1); 

    return true;
 }



}