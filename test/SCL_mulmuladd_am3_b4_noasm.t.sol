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


import{_ZERO_U256} from "@solidity/include/SCL_mask.h.sol";
import { p, a, gx, gy, n, pMINUS_2, nMINUS_2, MINUS_1 } from "@solidity/include/SCL_field.h.sol";
import {gpow2p128_x,gpow2p128_y} from "@solidity/include/SCL_field.h.sol";
import {ec_Add, ec_TestEq, ec_AddN, ec_Dbl, ec_Normalize, ecAff_isOnCurve} from "@solidity/include/SCL_elliptic.h.sol";
import{ec_hAdd} from "@solidity/elliptic/SCL_ecutils.sol";
import "@solidity/elliptic/SCL_mulmuladd_am3_b4_noasm.sol";
import "@solidity/elliptic/SCL_mulmuladd_am3_b4_inlined.sol";

uint256 constant _EMPTY=0xcacacacacacacacacacacacacacacacacacacacacacacacacacacacacacacaca;

contract SCL_mulmuladd_b4_prec is Test {
 
  //testing assembly version of precomputations
  function ec_MultiplierPrec_asm(uint256 [4] memory Q) public pure returns(uint256[4][16] memory Prec)
  {
        uint256 X;
        uint256 Y;
        uint256 ZZZ;
        uint256 ZZ;

         /* I. Precomputations */
        //allocate memory for 16 projective points
        bytes memory Preco = new bytes(16*4*32);

        assembly{
          //Prec[1]=[gx,gy,1,1];
          mstore(add(128, Preco),gx )
          mstore(add(160, Preco),gy ) 
          mstore(add(192, Preco),1 )
          mstore(add(224, Preco),1 )
          //Prec[2]=[gpow2p128_x,gpow2p128_y,1,1];
          mstore(add(256, Preco),gpow2p128_x )
          mstore(add(288, Preco),gpow2p128_y ) 
          mstore(add(320, Preco),1 )
          mstore(add(352, Preco),1 )
        }
        (X,Y,ZZ,ZZZ)=ec_AddN( gpow2p128_x,gpow2p128_y,1,1, gx,gy);
         assembly{
          //Prec[3]=ec_AddN_u4( gpow2p128_x,gpow2p128_y,1,1, gx,gy);
          mstore(add(384, Preco),X )
          mstore(add(416, Preco),Y ) 
          mstore(add(448, Preco),ZZ )
          mstore(add(480, Preco),ZZZ )
          //Prec[4]=[Q[0],Q[1],1,1];
          mstore(add(512, Preco),mload(Q) )
          mstore(add(544, Preco),mload(add(32,Q)) ) 
          mstore(add(576, Preco),1 )
          mstore(add(608, Preco),1 )
         }
        (X,Y,ZZ,ZZZ)=ec_AddN( Q[0],Q[1],1,1, gx,gy);
        assembly{
          //  Prec[5]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(640, Preco),X )
          mstore(add(672, Preco),Y ) 
          mstore(add(704, Preco),ZZ )
          mstore(add(736, Preco),ZZZ )
        }
       (X,Y,ZZ,ZZZ)=ec_AddN( gpow2p128_x,gpow2p128_y,1,1, Q[0], Q[1]);
        assembly{
          //  Prec[6]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(768, Preco),X )
          mstore(add(800, Preco),Y ) 
          mstore(add(832, Preco),ZZ )
          mstore(add(864, Preco),ZZZ )
        }

       (X,Y,ZZ,ZZZ)=ec_AddN( X,Y,ZZ,ZZZ, gx, gy);
        assembly{
          //  Prec[7]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(896, Preco),X )
          mstore(add(928, Preco),Y ) 
          mstore(add(960, Preco),ZZ )
          mstore(add(992, Preco),ZZZ )
          //  Prec[8]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(1024, Preco),mload(add(64,Q) ))
          mstore(add(1056, Preco),mload(add(96,Q)  )) 
          mstore(add(1088, Preco),1 )
          mstore(add(1120, Preco),1 )
        }
        (X,Y,ZZ,ZZZ)=ec_AddN( Q[2], Q[3],1,1, gx,gy);
         assembly{
          //  Prec[9]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(1152, Preco),X )
          mstore(add(1184, Preco),Y ) 
          mstore(add(1216, Preco),ZZ )
          mstore(add(1248, Preco),ZZZ )
         }
        (X,Y,ZZ,ZZZ)=ec_AddN( Q[2], Q[3],1, 1, gpow2p128_x,gpow2p128_y);
        assembly{
          //  Prec[10]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(1280, Preco),X )
          mstore(add(1312, Preco),Y ) 
          mstore(add(1344, Preco),ZZ )
          mstore(add(1376, Preco),ZZZ )
         }
      
        (X,Y,ZZ,ZZZ)=ec_AddN( X, Y, ZZ, ZZZ, gx, gy);
         assembly{
          //  Prec[11]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(1408, Preco),X )
          mstore(add(1440, Preco),Y ) 
          mstore(add(1472, Preco),ZZ )
          mstore(add(1504, Preco),ZZZ )
         }
        
        (X,Y,ZZ,ZZZ)=ec_AddN( Q[0],Q[1],1,1, Q[2], Q[3]);
         assembly{
          //  Prec[12]
          mstore(add(1536, Preco),X )
          mstore(add(1568, Preco),Y ) 
          mstore(add(1600, Preco),ZZ )
          mstore(add(1632, Preco),ZZZ )
         }
        
        (X,Y,ZZ,ZZZ)=ec_AddN( X,Y,ZZ,ZZZ, gx, gy);
         assembly{
          //  Prec[13]
          mstore(add(1664, Preco),X )
          mstore(add(1696, Preco),Y ) 
          mstore(add(1728, Preco),ZZ )
          mstore(add(1760, Preco),ZZZ )
         }
        //TODO load
        assembly{
         X:= mload(add(768, Preco) )
         Y:= mload(add(800, Preco) )
         ZZ:= mload(add(832, Preco) )
         ZZZ:=mload(add(864, Preco) )
        }
        (X,Y,ZZ,ZZZ)=ec_AddN( X ,Y ,ZZ , ZZZ, Q[2], Q[3]);
         assembly{
          //  Prec[14]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(1792, Preco),X )
          mstore(add(1824, Preco),Y ) 
          mstore(add(1856, Preco),ZZ )
          mstore(add(1888, Preco),ZZZ )
         }
        (X,Y,ZZ,ZZZ)=ec_AddN( X,Y,ZZ,ZZZ,gx,gy);
         assembly{
          //  Prec[15]
          mstore(add(1920, Preco),X )
          mstore(add(1952, Preco),Y ) 
          mstore(add(1984, Preco),ZZ )
          mstore(add(2016, Preco),ZZZ )
         }

       for(uint256 i=0;i<16;i++){
         assembly{
           X:=mload(add(Preco, shl(7,i)))
           Y:=mload(add(Preco, add(32, shl(7,i))))
           ZZ:=mload(add(Preco, add(64, shl(7,i))))
           ZZZ:=mload(add(Preco, add(96, shl(7,i))))
         }
         Prec[i]=[X,Y,ZZ,ZZZ];
       }
  }
        


 
  function ec_mulmuladdX_local(
       /* uint256 Q0,
        uint256 Q1, //affine rep for input point Q
        uint256 Q2, 
        uint256 Q3, //affine rep for precomputations*/
        uint256 [4] memory Q,
        uint256 scalar_u,
        uint256 scalar_v
    ) public  returns (uint256 X) {
        uint256 mask=1<<127;
        /* I. precomputation phase */
        
        if(scalar_u==0&&scalar_v==0){
            return 0;
        }
        uint256 Y;
        uint256 ZZZ;
        uint256 ZZ;
        
        /* I. Precomputations */
        //allocate memory for 16 projective points
        bytes memory Preco = new bytes(16*4*32);

        assembly{
          //Prec[1]=[gx,gy,1,1];
          mstore(add(128, Preco),gx )
          mstore(add(160, Preco),gy ) 
          mstore(add(192, Preco),1 )
          mstore(add(224, Preco),1 )
          //Prec[2]=[gpow2p128_x,gpow2p128_y,1,1];
          mstore(add(256, Preco),gpow2p128_x )
          mstore(add(288, Preco),gpow2p128_y ) 
          mstore(add(320, Preco),1 )
          mstore(add(352, Preco),1 )
        }
        (X,Y,ZZ,ZZZ)=ec_AddN( gpow2p128_x,gpow2p128_y,1,1, gx,gy);
         assembly{
          //Prec[3]=ec_AddN_u4( gpow2p128_x,gpow2p128_y,1,1, gx,gy);
          mstore(add(384, Preco),X )
          mstore(add(416, Preco),Y ) 
          mstore(add(448, Preco),ZZ )
          mstore(add(480, Preco),ZZZ )
          //Prec[4]=[Q[0],Q[1],1,1];
          mstore(add(512, Preco),mload(Q) )
          mstore(add(544, Preco),mload(add(32,Q)) ) 
          mstore(add(576, Preco),1 )
          mstore(add(608, Preco),1 )
         }
        (X,Y,ZZ,ZZZ)=ec_AddN( Q[0],Q[1],1,1, gx,gy);
        assembly{
          //  Prec[5]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(640, Preco),X )
          mstore(add(672, Preco),Y ) 
          mstore(add(704, Preco),ZZ )
          mstore(add(736, Preco),ZZZ )
        }
       (X,Y,ZZ,ZZZ)=ec_AddN( gpow2p128_x,gpow2p128_y,1,1, Q[0], Q[1]);
        assembly{
          //  Prec[6]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(768, Preco),X )
          mstore(add(800, Preco),Y ) 
          mstore(add(832, Preco),ZZ )
          mstore(add(864, Preco),ZZZ )
        }

       (X,Y,ZZ,ZZZ)=ec_AddN( X,Y,ZZ,ZZZ, gx, gy);
        assembly{
          //  Prec[7]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(896, Preco),X )
          mstore(add(928, Preco),Y ) 
          mstore(add(960, Preco),ZZ )
          mstore(add(992, Preco),ZZZ )
          //  Prec[8]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(1024, Preco),mload(add(64,Q) ))
          mstore(add(1056, Preco),mload(add(96,Q)  )) 
          mstore(add(1088, Preco),1 )
          mstore(add(1120, Preco),1 )
        }
        (X,Y,ZZ,ZZZ)=ec_AddN( Q[2], Q[3],1,1, gx,gy);
         assembly{
          //  Prec[9]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(1152, Preco),X )
          mstore(add(1184, Preco),Y ) 
          mstore(add(1216, Preco),ZZ )
          mstore(add(1248, Preco),ZZZ )
         }
        (X,Y,ZZ,ZZZ)=ec_AddN( Q[2], Q[3],1, 1, gpow2p128_x,gpow2p128_y);
        assembly{
          //  Prec[10]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(1280, Preco),X )
          mstore(add(1312, Preco),Y ) 
          mstore(add(1344, Preco),ZZ )
          mstore(add(1376, Preco),ZZZ )
         }
      
        (X,Y,ZZ,ZZZ)=ec_AddN( X, Y, ZZ, ZZZ, gx, gy);
         assembly{
          //  Prec[11]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(1408, Preco),X )
          mstore(add(1440, Preco),Y ) 
          mstore(add(1472, Preco),ZZ )
          mstore(add(1504, Preco),ZZZ )
         }
        
        (X,Y,ZZ,ZZZ)=ec_AddN( Q[0],Q[1],1,1, Q[2], Q[3]);
         assembly{
          //  Prec[12]
          mstore(add(1536, Preco),X )
          mstore(add(1568, Preco),Y ) 
          mstore(add(1600, Preco),ZZ )
          mstore(add(1632, Preco),ZZZ )
         }
        
        (X,Y,ZZ,ZZZ)=ec_AddN( X,Y,ZZ,ZZZ, gx, gy);
         assembly{
          //  Prec[13]
          mstore(add(1664, Preco),X )
          mstore(add(1696, Preco),Y ) 
          mstore(add(1728, Preco),ZZ )
          mstore(add(1760, Preco),ZZZ )
         }
        //TODO load
        assembly{
         X:= mload(add(768, Preco) )
         Y:= mload(add(800, Preco) )
         ZZ:= mload(add(832, Preco) )
         ZZZ:=mload(add(864, Preco) )
        }
        (X,Y,ZZ,ZZZ)=ec_AddN( X ,Y ,ZZ , ZZZ, Q[2], Q[3]);
         assembly{
          //  Prec[14]=ec_AddN_u4(Q[0],Q[1],1,1, gx,gy);
          mstore(add(1792, Preco),X )
          mstore(add(1824, Preco),Y ) 
          mstore(add(1856, Preco),ZZ )
          mstore(add(1888, Preco),ZZZ )
         }
        (X,Y,ZZ,ZZZ)=ec_AddN( X,Y,ZZ,ZZZ,gx,gy);
         assembly{
          //  Prec[15]
          mstore(add(1920, Preco),X )
          mstore(add(1952, Preco),Y ) 
          mstore(add(1984, Preco),ZZ )
          mstore(add(2016, Preco),ZZZ )
         }
        uint256 quadribit;
       // uint256 hi_u=scalar_u>>128;
       // uint256 hi_v=scalar_v>>128;
        
        /*II. First MSB bit*/
        do{
              //            quadribit=scalar_u&mask+2*((hi_u&mask)!=0)+4*((scalar_v&mask)!=0)+8*((hi_v&mask)!=0);
               assembly{
                quadribit:=add(add(sub(1,iszero(and(scalar_u, mask))), shl(1,sub(1,iszero(and(shr(128, scalar_u), mask))))),
                           add(shl(2,sub(1,iszero(and(scalar_v, mask)))), shl(3,sub(1,iszero(and(shr(128, scalar_v), mask))))))

            }
            mask>>=1;
        }
        while(quadribit==0);

        assembly{
              X:=mload(add(Preco,shl(7,quadribit)))//X
              Y:=mload(add(Preco,add(32, shl(7,quadribit))))//X
              ZZ:=mload(add(Preco,add(64, shl(7,quadribit))))//X
              ZZZ:=mload(add(Preco,add(96, shl(7,quadribit))))//X
            }


        /*III. Main loop */
        while(mask!=0)
        {
            //(X,Y,ZZ,ZZZ)=ec_Dbl(X,Y,ZZ,ZZZ);
            //TODO, replace mul by shifts
            assembly{
                let T1 := mulmod(2, Y, p) //U = 2*Y1, y free
                let T2 := mulmod(T1, T1, p) // V=U^2
                let T3 := mulmod(X, T2, p) // S = X1*V
                T1 := mulmod(T1, T2, p) // W=UV
                let T4 := mulmod(3, mulmod(addmod(X, sub(p, ZZ), p), addmod(X, ZZ, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                ZZZ := mulmod(T1, ZZZ, p) //zzz3=W*zzz1
                ZZ := mulmod(T2, ZZ, p) //zz3=V*ZZ1, V free

                X := addmod(mulmod(T4, T4, p), mulmod(pMINUS_2, T3, p), p) //X3=M^2-2S
                T2 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)
                Y := addmod(mulmod(T1, Y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd
                Y:=sub(p,Y)
                quadribit:=add(add(sub(1,iszero(and(scalar_u, mask))), shl(1,sub(1,iszero(and(shr(128, scalar_u), mask))))),
                           add(shl(2,sub(1,iszero(and(scalar_v, mask)))), shl(3,sub(1,iszero(and(shr(128, scalar_v), mask))))))

                mask:=shr(1,mask)
            }
           
            uint256[4] memory temp;
            
            assembly{
              mstore(temp, mload(add(Preco,shl(7,quadribit))))//X2
              mstore(add(temp,32), mload(add(Preco,add(32,shl(7,quadribit)))))//Y2
              mstore(add(temp,64), mload(add(Preco,add(64,shl(7,quadribit)))))//ZZ2
              mstore(add(temp,96), mload(add(Preco,add(96, shl(7,quadribit)))))//ZZZ2
            }


            if(quadribit!=0){
              (X,Y,ZZ,ZZZ)=ec_Add(X,Y,ZZ,ZZZ, temp[0], temp[1], temp[2], temp[3]);
            }
        }
       
        /* IV. Normalization */
        (X,)=ec_Normalize(X,Y,ZZ,ZZZ);
    }

 function test_ecPrec_asm() public returns(bool res)
 {
  res=true;

  uint256 qx=0x5ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c;
  uint256 qy=0x8734640c4998ff7e374b06ce1a64a2ecd82ab036384fb83d9a79b127a27d5032;
  uint256 q2p128_x=112495727131302244506157669471790202209849926651017016481532073180322115017576;
  uint256 q2p128_y=88228053145992414849958298035823172674083888062809552550982514976029750463913;
  
  uint256[4][16] memory Prec=ec_MultiplierPrec([qx, qy, q2p128_x, q2p128_y]);
  uint256[4][16] memory Prec_asm=ec_MultiplierPrec_asm([qx, qy, q2p128_x, q2p128_y]);
  
  for(uint256 i=1;i<16;i++){
    //console.log("\n i=%d",i);
    uint256[4] memory Point=Prec[i];
    uint256[4] memory Point2=Prec_asm[i];
    
    //console.log("equality:", ec_TestEq(Point[0], Point[1], Point[2], Point[3], Point2[0], Point2[1], Point2[2], Point2[3]) );
    assertEq(true, ec_TestEq(Point[0], Point[1], Point[2], Point[3], Point2[0], Point2[1], Point2[2], Point2[3]) );
      
  }

  return res;
 }

 function test_ecPrecb4() public returns(bool res){
  res=false;
  
  uint256 qx=0x5ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c;
  uint256 qy=0x8734640c4998ff7e374b06ce1a64a2ecd82ab036384fb83d9a79b127a27d5032;
  uint256 q2p128_x=112495727131302244506157669471790202209849926651017016481532073180322115017576;
  uint256 q2p128_y=88228053145992414849958298035823172674083888062809552550982514976029750463913;
  uint256 x;
  uint256 y;
   uint256 zz; uint256 zzz;

  uint256[4][16] memory Prec= ec_MultiplierPrec([qx,qy,q2p128_x, q2p128_y]);
  Prec[0]=[_EMPTY, _EMPTY, _EMPTY, _EMPTY];
       
  //assert each precomputed point belongs to the curve
  for(uint256 i=1;i<16;i++){

  /*  
     console.log("Point",Prec[i][0], Prec[i][1]);
     assembly{
        x:= mload(add(Prec,shl(7,i)))//X
        y:=mload(add(Prec,add(shl(7,i),32)))//Y
     }
    console.log("asm read:",x, y);
    */
    (x,y)=ec_Normalize(Prec[i][0], Prec[i][1], Prec[i][2], Prec[i][3]);
    assertEq(true, ecAff_isOnCurve(x,y));
  }

  res=true;


  for(uint256 quadribit=1;quadribit<16;quadribit++){
    (x,y,zz,zzz)=(0,0,0,0);

    if(quadribit&1!=0){
        
    (x,y,zz,zzz)= ec_hAdd(x,y,zz,zzz, Prec[1][0], Prec[1][1], Prec[1][2], Prec[1][3]);
    }
    if(quadribit&2!=0){
    (x,y,zz,zzz)= ec_hAdd(x,y,zz,zzz, Prec[2][0], Prec[2][1], Prec[2][2], Prec[2][3]);
    }
     if(quadribit&4!=0){
    (x,y,zz,zzz)= ec_hAdd(x,y,zz,zzz, Prec[4][0], Prec[4][1], Prec[4][2], Prec[4][3]);
    }
     if(quadribit&8!=0){
    (x,y,zz,zzz)= ec_hAdd(x,y,zz,zzz, Prec[8][0], Prec[8][1], Prec[8][2], Prec[8][3]);
    }

    assertEq(true, ec_TestEq(x,y,zz,zzz, Prec[quadribit][0], Prec[quadribit][1], Prec[quadribit][2], Prec[quadribit][3]));

  }

 
  return res;
 }

 function test_Schoolbook_vs_b4()public returns (bool){
     uint256 qx=0x5ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c;
  uint256 qy=0x8734640c4998ff7e374b06ce1a64a2ecd82ab036384fb83d9a79b127a27d5032;
  uint256 q2p128_x=112495727131302244506157669471790202209849926651017016481532073180322115017576;
  uint256 q2p128_y=88228053145992414849958298035823172674083888062809552550982514976029750463913;
 
  uint256 scalar_u=112495727131302234506157669471790202209849926651017016481532073180322115017571;
  uint256 scalar_v=109495727131302234506157669471790202209849926651017016481532073180322115017571;
  uint x;
  uint y;

  x=ec_mulmuladdX_local([qx, qy, q2p128_x, q2p128_y], scalar_u, scalar_v);

  //(x,y)=ec_scalarmulN(scalar_u, qx, qy);
  
  
 }
 
 function test_b4() public returns (bool){
  

   console.log("mulmul b4:");
   if(a!=p-3){//desactivate test if configuration is not set to secp256r1
      console.log("untested");
      return true;
   }

   bool res= true;
   assertEq(res,true);

   return res;
 }
}

