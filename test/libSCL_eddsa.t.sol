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

import "@solidity/modular/SCL_sqrtMod_5mod8.sol";
import  "@solidity/lib/libSCL_eddsa.sol"; 


contract Test_eddsa is Test {

    //fuzzing modular square root
    function testFuzz_ed255sqrtmod(uint256 val) public{
      
        vm.assume(val < p);
        vm.assume(val > 0);
        uint256 val2=mulmod(val,val,p);

        uint256 sqrt = SqrtMod(val2);
    
        assertEq(mulmod(sqrt,sqrt, p), val2);

    }


 function test_ed255sqrtmod2() public {
        uint256 val = mulmod(gx, gx, p);
        uint256 rac = SqrtMod(val);
        console.log("rac=", rac);
        assertEq(mulmod(rac, rac, p), val);
    }


    function test_ed255Decompress() public {
        //compress/decompress base point
        uint256[2] memory Kpub=[edX, edY];
       
        uint256 KpubC=SCL_EDDSA.edCompress(Kpub);
        uint256 recovered=SCL_EDDSA.edDecompressX(KpubC);
    
        assertEq(recovered, edX);

    }
 
    function test_SHA512_ed255KG()  public {
        //vector 3 input secret key, lsb first
        uint256 secret=0xc5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7;
        //uint256 secret=0xf758440b2e3ace854b096f073585d366b1b7dc312f44b7ed7b839f3ff48daac5;

        uint256 res=SCL_EDDSA.HashSecret(secret);
        //expected hashed secret (obtained via sage):0x9ca91e9981a125131bf5c2c54e7f4dba113dc2155ba523908402d95e758b9a90
        //909A8B755ED902849023A55B15C23D11BA4D7F4EC5C2F51B1325A181991EA99C
        //6608C8666B9CDE2325F539D7D83386FE8187C6BE61D8A70C247190D64EDF5F1E
        console.log("res=%x",res);
        uint256[2] memory Kpub=SCL_EDDSA.ExpandSecret(secret);
         console.log("Kpub=%x %x",Kpub[0], Kpub[1]);
        //expected expanded
        //uint256 expanded=41911590414521875233341115108072091496810396974354451206977851026743843592848;
        //uint256 expanded=0x258090481591eb5dac0333ba13ed160858f03002d07ea48da3a118628ecd51fc;
        
        //vector 3 public key, expressed lsb first
        //fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025
        //given, expressed msb first (number), because a number is read from right to left mother of god.
        expected=0x258090481591eb5dac0333ba13ed160858f03002d07ea48da3a118628ecd51fc;
        assertEq( Kpub[1], expected);
    }
 
    function test_Verif_rfc() public {
        //vector 3 input secret key, page 25 of RFC8032, lsb first
        uint256 secret=0xc5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7;
       
    /*
   PUBLIC KEY:
   fc51cd8e6218a1a38da47ed00230f058
   0816ed13ba3303ac5deb911548908025

   MESSAGE (length 2 bytes):
   af82

   SIGNATURE:
   6291d657deec24024827e69c3abe01a3
   0ce548a284743a445e3680d7db5ac3ac
   18ff9b538d16f290ae67f760984dc659
   4a7c15e9716ed28dc027beceea1ec40a*/
   uint256 r=0xacc35adbd780365e443a7484a248e50ca301be3a9ce627480224ecde57d69162;//msb first
   uint256 s=0xac41eeacebe27c08dd26e71e9157c4a59c64d9860f767ae90f2168d539bff18; 
    }


}