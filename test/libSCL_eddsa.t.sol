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
        
        uint256[2] memory Kpub;
        uint256[2] memory expSec;

        (Kpub,expSec)=SCL_EDDSA.ExpandSecret(secret);
         console.log("Kpub=%x %x",Kpub[0], Kpub[1]);
            console.log("expSec=%x %x",expSec[0], expSec[1]);
      
        //expected expanded
        //uint256 expanded=41911590414521875233341115108072091496810396974354451206977851026743843592848;
        //uint256 expanded=0x258090481591eb5dac0333ba13ed160858f03002d07ea48da3a118628ecd51fc;
        
        //vector 3 public key, expressed lsb first
        //fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025
        //given, expressed msb first (number), because a number is read from right to left mother of god.
        uint256 expected=0x258090481591eb5dac0333ba13ed160858f03002d07ea48da3a118628ecd51fc;
        assertEq( Kpub[1], expected);
    }
 
  
 //the deterministic extraction of nonce  from message and secret key
 function drng_debug(uint256 Rs,  bytes memory msg) public view returns(uint256 nonce){
  
   uint64[16] memory buffer;
   uint256[2] memory R;

   msg=bytes(string.concat(string(msg), string(bytes(hex"80"))));
   uint256 lengz=msg.length;
   uint256 offset;
   uint256 padding=31+lengz;
  
   if(lengz>56){
    revert();
   }
   buffer[0]=uint64((Rs>>192)&0xffffffffffffffff);
   buffer[1]=uint64((Rs>>128)&0xffffffffffffffff);
   buffer[2]=uint64((Rs>>64)&0xffffffffffffffff);
   buffer[3]=uint64(Rs&0xffffffffffffffff);
   
    assembly{
     
     mstore(add(offset,add(buffer, 128)),shr(192, mload(add(32, msg) )) )
    }
   // 
    buffer[15]=uint64(padding<<3); 
    uint256 i; 
    for(i=0;i<16;i++)
    {
        console.log("%x",buffer[i]);

    }
   console.log("padding=%d",padding);
   (R[0], R[1]) = SCL_sha512.SHA512(buffer);//compute the hash
   console.log("pre reduction=%x %x",R[0], R[1]);
   
   nonce= SCL_EDDSA.Red512Modq(SCL_sha512.Swap512(R)); //swap then reduce mod q

 }
  
 function DebugSign(uint256[2] memory expSecret, uint256 Ap,  bytes memory Msg) public returns(uint256 R, uint256 S)
 {
   uint256 [2] memory ecR; 
   uint64[16] memory tampon;
   uint256 [10] memory Q=[0,0,0,0, p, a, gx, gy, gpow2p128_x, gpow2p128_y ];
   //uint256 r=SCL_sha512.Swap256(expSecret[1]);
   uint256 r=expSecret[1];
   
   console.log("a: %x ", expSecret[0]);
   console.log("prefix: %x ", r);
   uint256 h;

   

   r= drng_debug(r,Msg); //swap then reduce mod q
   console.log("out of drng: %d ", r);
   
   ecR=SCL_RIPB4.ecMulMulAdd_B4(Q, r, 0);
   (ecR[0], ecR[1])=WeierStrass2Edwards(ecR[0], ecR[1]);//back to edwards form
   R=SCL_EDDSA.edCompress(ecR);//returned r part of the signature
   console.log("r part: %x ", R);
   
    console.log("A=",Ap);
   //  h = sha512_modq(Rs + A + msg)
    tampon=SCL_sha512.eddsa_sha512(R,Ap,Msg);
   (ecR[0], ecR[1]) = SCL_sha512.SHA512(tampon);
   h= SCL_EDDSA.Red512Modq(SCL_sha512.Swap512(ecR)); //swap then reduce mod q
   console.log("h=%x",h);
   S=addmod(r, mulmod(h,expSecret[0],n),n );
   console.log("s part: %x ", S);
   
   return (R,S);
   //  s = (r + h * a) % q
 }

   function test_ed255Sign() public{
        uint256 secret=0xc5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7;
        bytes memory Msg=hex"af82";
        //signing requires Kpub knowledge
        uint256[2] memory expSecret;
        uint256[5] memory extKpub;

        (extKpub, expSecret)=SCL_EDDSA.SetKey(secret);

        DebugSign(expSecret, extKpub[4], Msg);

   }


    function test_ed255Verif_rfc() public {
        //vector 3 input secret key, page 25 of RFC8032, lsb first
        uint256 r=0xacc35adbd780365e443a7484a248e50ca301be3a9ce627480224ecde57d69162;//msb first
        uint256 s=0xac41eeacebe27c08dd26e71e9157c4a59c64d9860f767ae90f2168d539bff18;

        uint256 secret=0xc5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7;
        bytes memory msg=hex"af82";
        uint256[5] memory extKpub;
        (extKpub,)=SCL_EDDSA.SetKey(secret);

        bool res=SCL_EDDSA.Verify(msg, r, s, extKpub);
        assertEq(res,true);
    }
}

