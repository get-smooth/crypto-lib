/********************************************************************************************/
/*
#/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
#/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
#/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
#/*              
#/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
#/* License: This software is licensed under MIT License (and allways will)   
#/* Description: This file implements isogeny conversions from Weierstrass to Edwards testing                    
#/********************************************************************************************/
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import  "@solidity/modular/SCL_ModInv.sol"; 
import "@solidity/fields/SCL_wei25519.sol";
import "@solidity/elliptic/SCL_Isogeny.sol";
import "@solidity/elliptic/SCL_mulmuladd_fullgen_b4.sol";

contract SCL_isogenyTest is Test {

 function ecPow128(uint256 X, uint256 Y, uint256 ZZ, uint256 ZZZ) public returns(uint256 x128, uint256 y128){
   assembly{
   function vecDbl(x, y, zz, zzz) -> _x, _y, _zz, _zzz{
            let T1 := mulmod(2, y, p) //U = 2*Y1, y free
                let T2 := mulmod(T1, T1, p) // V=U^2
                let T3 := mulmod(x, T2, p) // S = X1*V
                T1 := mulmod(T1, T2, p) // W=UV
                let T4 := addmod(mulmod(3, mulmod(x,x,p),p),mulmod(a,mulmod(zz,zz,p),p),p)//M=3*X12+aZZ12  
                _zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                _zz := mulmod(T2, zz, p) //zz3=V*ZZ1

                _x := addmod(mulmod(T4, T4, p), mulmod(pMINUS_2, T3, p), p) //X3=M^2-2S
                T2 := mulmod(T4, addmod(_x, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)
                _y := addmod(mulmod(T1, y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd
                _y:= sub(p, _y)
         }
         for {x128:=0} lt(x128, 128) { x128:=add(x128,1) }{
           X, Y, ZZ, ZZZ := vecDbl(X, Y, ZZ, ZZZ)
         }
         }
      ZZ=ModInv(ZZ, p);
      ZZZ=ModInv(ZZZ,p);
      x128=mulmod(X, ZZ, p);
      y128=mulmod(Y, ZZZ, p);
}


 //test involutivity of Edwards/Weierstrass isogenies
 function test_isogeny_generator_wei25519() public {   
 uint256 genX=0x216936D3CD6E53FEC0A4E231FDD6DC5C692CC7609525A7B2C9562D608F25D51A;
 uint256 genY=0x6666666666666666666666666666666666666666666666666666666666666658;  
 uint256 resX;
 uint256 resY;
 (resX, resY)=Edwards2WeierStrass(genX, genY);
 assertEq(resX, gx);
 assertEq(resY, gy);
 
 //console.log(" Weierstrass: %x %x",resX, resY);

 (resX, resY)=WeierStrass2Edwards(resX, resY);
 assertEq(resX, genX);
 assertEq(resY, genY);//todo: correct Y return value
 
//console.log(" Recomputed edwards: %x %x",resX, resY);
 }

 function test_mulwithiso() public pure{
    //input secret key for edd25519
    uint256 expandedsec=31531604425972617034374315527056165422477269154623932846749706281462965132592;
    //expected public key

 }

//vectors extracted from https://asecuritysite.com/curve25519/ed
//https://crypto.stackexchange.com/questions/99798/test-vectors-points-for-ed25519
//Point 1G 5866666666666666666666666666666666666666666666666666666666666666 , LSB first
//Point 2G, x= 0x36ab384c9f5a046c3d043b7d1833e7ac080d8e4515d7a45f83c5a14e2843ce0e
//Point 5G x=0x49fda73eade3587bfcef7cf7d12da5de5c2819f93e1be1a591409cc0322ef233

 function test_wei25519() public {
  
   uint256 resX;
   uint256 resY;
   
   uint256 q2p128_x;
   uint256 q2p128_y;

   //value of 2G over wei25519, computed with SCL_sage
   //0x4b7ded7fc31e9c62841fb71327c01bbf39ea0797c8dfb6070758f1478815734c
   uint256 g2x=34145958685188182721225203372338409610255982577099208428796738225249784787788;
   //0x13b57e011700e8ae050a00945d2ba2f377659eb28d8d391ebcd70465c72df563
   uint256 g2y= 8914613091229147831277935472048643066880067899251840418855181793938505594211;
   
   (q2p128_x, q2p128_y)=ecPow128(gx, gy, 1, 1);
   
   //console.log("x128:%x y128:%x", x128, y128);

   uint256[10] memory Qpa= [gx,gy,q2p128_x, q2p128_y, p,a,gx,gy, gpow2p128_x, gpow2p128_y];//store Qx, Qy, Q'x, Q'y p, a, gx, gy, gx2pow128, gy2pow128 

  //testing doubling
   (resX, resY) =ecGenMulmuladd(Qpa, 2, 0);
   assertEq(resX, g2x);
   assertEq(resY, g2y);

   (resX, resY) =ecGenMulmuladd(Qpa, 0, 2);
   assertEq(resX, g2x);
   assertEq(resY, g2y);

   (resX, resY)=WeierStrass2Edwards(resX, resY);
   assertEq(resX, 0x36ab384c9f5a046c3d043b7d1833e7ac080d8e4515d7a45f83c5a14e2843ce0e);//expected 2G result
   
//******-----TEST SHA(abc), intermediate state from RFC8032, computed using provided python reference.

//expanded secret: 31531604425972617034374315527056165422477269154623932846749706281462965132592
//x,y= 40121575059854498688793601084330139334125048157368472832084429102603245386799 28895729190139806181135174156803260194472099954421499683004293713963394996204
 (resX, resY) =ecGenMulmuladd(Qpa, 0, 31531604425972617034374315527056165422477269154623932846749706281462965132592);
  (resX, resY)=WeierStrass2Edwards(resX, resY);
  console.log(" Recomputed edwards: %d %d",resX, resY);
 assertEq(resX, 40121575059854498688793601084330139334125048157368472832084429102603245386799);
 assertEq(resY, 28895729190139806181135174156803260194472099954421499683004293713963394996204);

//******-----RFC 8032, TEST 3	

//expanded secret: 41911590414521875233341115108072091496810396974354451206977851026743843592848
//x,y= 43933056957747458452560886832567536073542840507013052263144963060608791330050 16962727616734173323702303146057009569815335830970791807500022961899349823996
 (resX, resY) =ecGenMulmuladd(Qpa, 0, 41911590414521875233341115108072091496810396974354451206977851026743843592848);
 (resX, resY)=WeierStrass2Edwards(resX, resY);
 assertEq(resX, 43933056957747458452560886832567536073542840507013052263144963060608791330050);
 assertEq(resY, 16962727616734173323702303146057009569815335830970791807500022961899349823996);


 }



}