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


import {_STARKCURVE} from "@solidity/include/SCL_mask.h.sol";
import {FIELD_OID} from "@solidity/include/SCL_field.h.sol";
import "forge-std/Test.sol";



contract SCL_configTest is Test {


 function libSCLstark() public returns (bool){
   bool res=true;
  
   return res;
 }

 

 function test_starkcurve() public returns (bool){
  
   console.log("test libSCL_secp256r1:");
   if(FIELD_OID!=_STARKCURVE){//desactivate test if configuration is not set to secp256r1
      console.log("untested");
      return true;
   }
   bool res= libSCLstark();
   assertEq(res,true);

   if(res==true){
     console.log(" %s", "OK");
  }

   return res;
 }

}