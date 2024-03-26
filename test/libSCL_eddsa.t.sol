/********************************************************************************************/
/*
#/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
#/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
#/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
#/*              
#/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
#/* License: This software is licensed under MIT License (and allways will)   
#/* Description: Testing contract for SCL implementation of rip7212                
#/********************************************************************************************/
// SPDX-License-Identifier: MIT


/* import eddsa*/


import "forge-std/Test.sol";
import  "@solidity/lib/libSCL_eddsa.sol"; 


contract Test_eddsa is Test {

 
    function test_SHA512_ed255KG()  public {
        //vector 3 input secret key
        uint256 secret=0xc5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7;
        //uint256 secret=0xf758440b2e3ace854b096f073585d366b1b7dc312f44b7ed7b839f3ff48daac5;

        uint256 res=SCL_EDDSA.HashSecret(secret);
        //expected hashed secret (obtained via sage):0x9ca91e9981a125131bf5c2c54e7f4dba113dc2155ba523908402d95e758b9a90
        //909A8B755ED902849023A55B15C23D11BA4D7F4EC5C2F51B1325A181991EA99C
        //6608C8666B9CDE2325F539D7D83386FE8187C6BE61D8A70C247190D64EDF5F1E
        console.log("res=%x",res);
        uint256[2] memory Kpub=SCL_EDDSA.ExpandSecret(secret);
         console.log("Kpub=%d %d",Kpub[0], Kpub[1]);
        //expected expanded
        //uint256 expanded=41911590414521875233341115108072091496810396974354451206977851026743843592848;
    }
 


}