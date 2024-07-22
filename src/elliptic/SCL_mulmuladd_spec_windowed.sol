/********************************************************************************************/
/*
#/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
#/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
#/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
#/*              
#/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/********************************************************************************************/
/* This file implements elliptic curve over short weierstrass form,  with xyzz coordinates */
/* it is generic in the sense that curve coefficients can be any, but defined at compilation time
/* (gen= any curve, sw=short weierstrass) */
/* Window=windowed version */
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


//defined at compilation, while RIP7696 is execution time
import { a,p, gx, gy, n, pMINUS_2, nMINUS_2, MINUS_1} from "../fields/SCL_secp256r1.sol";


//this function is for use only after validation of the Q input:
//Q shall belongs to the curve, and different from P, 2P, 3P, -P, -2P, -3P
//due to handling of Neutral element, this function will not work for 16 specific weak keys
//those value are excluded from the acceptable input
function ecGenMulmuladdW (
        uint256 Qx, 
        uint256 Qy,
        uint256 scalar_u,
        uint256 scalar_v
    )   view returns (uint256 X) {
        uint256 mask=1<<255;
        /* I. precomputation phase */

        if(scalar_u==0&&scalar_v==0){
            return 0;
        }
        uint256 Y;
        uint256 ZZZ;
        uint256 ZZ;
        
        //allocating 16 points of 4 coordinates over a 32 bytes field
        bytes memory Preco = new bytes(16*4*32);

        assembly{
           //store 4 256 bits values starting from addr+offset
          function mstore4(addr, offset, val1, val2, val3, val4){
             mstore(add(offset, addr),val1 )
             offset:=add(32, offset)
             mstore(add(offset, addr),val2 )
             offset:=add(32, offset)
             mstore(add(offset, addr),val3 )
             offset:=add(32, offset)
             mstore(add(offset, addr),val4 )
             offset:=add(32, offset)
          }

         function ecDblNeg(x, y, zz, zzz) -> _x, _y, _zz, _zzz{
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
         }

         function ecDbl(x, y, zz, zzz) -> _x, _y, _zz, _zzz{
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

          /* Utils */
         //normalized addition of two point, must not be neutral input 
         function ecAddn(x1, y1, zz1, zzz1, x2, y2) -> _x, _y, _zz, _zzz {
                y1 := sub(p, y1)
                y2 := addmod(mulmod(y2, zzz1, p), y1, p)
                x2 := addmod(mulmod(x2, zz1, p), sub(p, x1), p)
                _x := mulmod(x2, x2, p) //PP = P^2
                _y := mulmod(_x, x2, p) //PPP = P*PP
                _zz := mulmod(zz1, _x, p) ////ZZ3 = ZZ1*PP
                _zzz := mulmod(zzz1, _y, p) ////ZZZ3 = ZZZ1*PPP
                zz1 := mulmod(x1, _x, p) //Q = X1*PP
                _x := addmod(addmod(mulmod(y2, y2, p), sub(p, _y), p), mulmod(pMINUS_2, zz1, p), p) //R^2-PPP-2*Q
                _y := addmod(mulmod(addmod(zz1, sub(p, _x), p), y2, p), mulmod(y1, _y, p), p) //R*(Q-X3)
           }

            /* Precomputations */
            /* All aP+bQ in [0,3]^2, ordered as p0+2p1+4q0+8q1 value*/
            mstore4(Preco, 128, gx, gy, 1, 1) //G the base point [1]
         
            X, Y, ZZ, ZZZ :=ecDbl(gx, gy, 1, 1)//2G, todo: set as curve constant
            mstore4(Preco, 256, X,Y,ZZ,ZZZ) //[2]
            X, Y, ZZ, ZZZ :=ecAddn(X, Y, ZZ, ZZZ, gx, gy)//2G+G
            mstore4(Preco, 384, X,Y,ZZ,ZZZ) //[3]

            mstore4(Preco, 512, Qx, Qy, 1, 1) //Q the public key [4]
        
            X, Y, ZZ, ZZZ :=ecAddn(gx, gy, 1, 1, Qx, Qy)//Q+G
            mstore4(Preco, 640, X,Y,ZZ,ZZZ) //[5]
           
            X, Y, ZZ, ZZZ :=ecAddn(X,Y,ZZ,ZZZ, gx, gy)//Q+G+G = Q+2G
            mstore4(Preco, 768, X,Y,ZZ,ZZZ) //[6]
           
            X, Y, ZZ, ZZZ :=ecAddn(X,Y,ZZ,ZZZ, gx, gy)//Q+2G+G = Q+3G
            mstore4(Preco, 896, X,Y,ZZ,ZZZ) //[7]
           
            X, Y, ZZ, ZZZ :=ecDbl(Qx, Qy, 1, 1)//2Q
            mstore4(Preco, 1024, X,Y,ZZ,ZZZ) //[8]

            X, Y, ZZ, ZZZ :=ecAddn(X,Y,ZZ,ZZZ, gx, gy)//2Q+G
            mstore4(Preco, 1152, X,Y,ZZ,ZZZ) //[9]

            X, Y, ZZ, ZZZ :=ecAddn(X,Y,ZZ,ZZZ, gx, gy)//2Q+2G
            mstore4(Preco, 1280, X,Y,ZZ,ZZZ) //[10]

            X, Y, ZZ, ZZZ :=ecAddn(X,Y,ZZ,ZZZ, gx, gy)//2Q+3G
            mstore4(Preco, 1408, X,Y,ZZ,ZZZ) //[11]

            //2Q
            X:=mload(add(Preco, 1024))
            Y:=mload(add(Preco, 1056))
            ZZ:=mload(add(Preco, 1088))
            ZZZ:=mload(add(Preco, 1120))

            X, Y, ZZ, ZZZ :=ecAddn(X,Y,ZZ,ZZZ, Qx, Qy)//2Q+Q=3Q
            mstore4(Preco, 1536, X,Y,ZZ,ZZZ) //[12]

            X, Y, ZZ, ZZZ :=ecAddn(X,Y,ZZ,ZZZ, gx,gy)//3Q+G
            mstore4(Preco, 1664, X,Y,ZZ,ZZZ) //[13]
            X, Y, ZZ, ZZZ :=ecAddn(X,Y,ZZ,ZZZ, gx,gy)//3Q+2G
            mstore4(Preco, 1792, X,Y,ZZ,ZZZ) //[14]
            X, Y, ZZ, ZZZ :=ecAddn(X,Y,ZZ,ZZZ, gx,gy)//3Q+3G
            mstore4(Preco, 1920, X,Y,ZZ,ZZZ) //[15]


              /*II. First MSB Window*/
                ZZZ:=0
                for {} iszero(ZZZ) { mask := shr(2, mask) }{
                ZZZ:=add(add(
                  sub(1,iszero(and(scalar_u, shr(1,mask)))),//p0
                  shl(1,sub(1,iszero(and(scalar_u, mask))))),//p1
                  add(shl(2,sub(1,iszero(and(scalar_v, shr(1,mask))))),//q0
                  shl(3,sub(1,iszero(and(scalar_v, mask)))))//q1
                  )

                }
              /* Accumulation is equal to first MSB window*/  
              X:=mload(add(Preco,shl(7,ZZZ)))//X
              Y:=mload(add(Preco,add(32, shl(7,ZZZ))))//Y
              ZZ:=mload(add(Preco,add(64, shl(7,ZZZ))))//ZZ
              ZZZ:=mload(add(Preco,add(96, shl(7,ZZZ))))//ZZZ

        /*III. Main loop */
            //(X,Y,ZZ,ZZZ)=ec_Dbl(X,Y,ZZ,ZZZ);
                for {} gt(mask, 0) { mask := shr(2, mask) } {
               //III.1   standard doubling
               {    
                //X,Y,ZZ,ZZZ:=ecDblNeg(X,Y,ZZ,ZZZ), not having it inplace increase by 12K the cost of the function
                
                let T1 := mulmod(2, Y, p) //U = 2*Y1, y free
                let T2 := mulmod(T1, T1, p) // V=U^2
                let T3 := mulmod(X, T2, p) // S = X1*V
                T1 := mulmod(T1, T2, p) // W=UV
                let T4 := addmod(mulmod(3, mulmod(X,X,p),p),mulmod(a,mulmod(ZZ,ZZ,p),p),p)//M=3*X12+aZZ12  
                ZZZ := mulmod(T1, ZZZ, p) //zzz3=W*zzz1
                ZZ := mulmod(T2, ZZ, p) //zz3=V*ZZ1

                X := addmod(mulmod(T4, T4, p), mulmod(pMINUS_2, T3, p), p) //X3=M^2-2S
                T2 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)
                Y := addmod(mulmod(T1, Y, p), T2, p) //-Y3= W*Y1-M(S-X3)
                Y:=sub(p,Y)
                
                }
                //III.2   standard doubling and negates
                {    
                //X,Y,ZZ,ZZZ:=ecDblNeg(X,Y,ZZ,ZZZ), not having it inplace increase by 12K the cost of the function
                
                let T1 := mulmod(2, Y, p) //U = 2*Y1, y free
                let T2 := mulmod(T1, T1, p) // V=U^2
                let T3 := mulmod(X, T2, p) // S = X1*V
                T1 := mulmod(T1, T2, p) // W=UV
                let T4 := addmod(mulmod(3, mulmod(X,X,p),p),mulmod(a,mulmod(ZZ,ZZ,p),p),p)//M=3*X12+aZZ12  
                ZZZ := mulmod(T1, ZZZ, p) //zzz3=W*zzz1
                ZZ := mulmod(T2, ZZ, p) //zz3=V*ZZ1

                X := addmod(mulmod(T4, T4, p), mulmod(pMINUS_2, T3, p), p) //X3=M^2-2S
                T2 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)
                Y := addmod(mulmod(T1, Y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd
                //Y:=sub(p,Y)*/
                
                }

             //   let T4:=shl(128,mask)  
             // let T1:=add(add(sub(1,iszero(and(scalar_u, mask))), shl(1,sub(1,iszero(and(scalar_u, T4))))),
              //             add(shl(2,sub(1,iszero(and(scalar_v, mask)))), shl(3,sub(1,iszero(and(T4, scalar_v))))))
               
              let T1:=add(
                    add(
                      sub(1,iszero(and(scalar_u, shr(1,mask)))),//p0
                      shl(1,sub(1,iszero(and(scalar_u, mask))))),//p1
                    add(
                      shl(2,sub(1,iszero(and(scalar_v, shr(1,mask))))),//q0
                      shl(3,sub(1,iszero(and(scalar_v, mask)))  )  )//q1
                  )

                            
              if iszero(T1) {
                            Y := sub(p, Y)
                            continue
              }
              

              //inlined ec_Add
               T1:=shl(7, T1)//precomputed value address offset    

              //accumulation is Neutral, so accumulation becomes Window
              //exception raised by wycheproof/ecdsa_secp256r1_sha256_p1363_test.json EcdsaP1363Verify SHA-256 #58
              if iszero(ZZ) {
                            X := mload(add(Preco,T1))//X2
                            Y := mload(add(Preco,add(32,T1)))//Y2
                            ZZ := mload(add(Preco,add(64,T1)))//ZZ2
                            ZZZ := mload(add(Preco,add(96,T1)))//ZZZ2
                            continue
                        }

               let T4:=mload(add(Preco,T1))//X2
               let zzz2:= mload(add(Preco,add(96,T1)))//ZZZ2
                 
                
                 let y2 := addmod(mulmod( mload(add(Preco,add(32,T1))), ZZZ, p), mulmod(Y,zzz2, p), p)//R=S2-S1, sub avoided
                 T1:=mload(add(Preco,add(64,T1)))//zz2
                 let T2 := addmod(mulmod(T4, ZZ, p), sub(p, mulmod(X,T1,p)), p)//P=U2-U1

                        //special case ecAdd(P,P)=EcDbl
                        if iszero(y2) {
                            if iszero(T2) {
                                T1 := mulmod(pMINUS_2, Y, p) //U = 2*Y1, y free
                                T2 := mulmod(T1, T1, p) // V=U^2
                                y2 := mulmod(X, T2, p) // S = X1*V

                                T1 := mulmod(T1, T2, p) // W=UV
                                
                                T4 := addmod(mulmod(3, mulmod(X,X,p),p),mulmod(a,mulmod(ZZ,ZZ,p),p),p)//M=3*X12+aZZ12   //M

                                ZZZ := mulmod(T1, ZZZ, p) //zzz3=W*zzz1
                                ZZ := mulmod(T2, ZZ, p) //zz3=V*ZZ1, V free

                                X := addmod(mulmod(T4, T4, p), mulmod(pMINUS_2, y2, p), p) //X3=M^2-2S
                                T2 := mulmod(T4, addmod(y2, sub(p, X), p), p) //M(S-X3)

                                Y := addmod(T2, mulmod(T1, Y, p), p) //Y3= M(S-X3)-W*Y1

                                continue
                            }
                        }
                  T4 := mulmod(T2, T2, p) //PP
                  T2 := mulmod(T4, T2, p) //PPP
                  ZZ := mulmod(mulmod(ZZ, T4, p), T1 ,p)//zz3=zz1*zz2*PP
                  T1:= mulmod(X,T1, p)
                  ZZZ := mulmod(mulmod(ZZZ, T2, p), zzz2,p) // zzz3=zzz1*zzz2*PPP
                  X := addmod(addmod(mulmod(y2, y2, p), sub(p, T2), p), mulmod( T1 ,mulmod(pMINUS_2, T4, p),p ), p)// R2-PPP-2*U1*PP
                  T4 := mulmod(T1, T4, p)///Q=U1*PP
                  Y := addmod(mulmod(addmod(T4, sub(p, X), p), y2, p), mulmod(mulmod(Y,zzz2, p), T2, p), p)// R*(Q-X3)-S1*PPP

               }//endloop   
                /* IV. Normalization */
                //(X,)=ec_Normalize(X,Y,ZZ,ZZZ);
                 let T := mload(0x40)
                mstore(add(T, 0x60), ZZ)
                //(X,Y)=ecZZ_SetAff(X,Y,zz, zzz);
                //T[0] = inverseModp_Hard(T[0], p); //1/zzz, inline modular inversion using precompile:
                // Define length of base, exponent and modulus. 0x20 == 32 bytes
                mstore(T, 0x20)
                mstore(add(T, 0x20), 0x20)
                mstore(add(T, 0x40), 0x20)
                // Define variables base, exponent and modulus
                //mstore(add(pointer, 0x60), u)
                mstore(add(T, 0x80), pMINUS_2)
                mstore(add(T, 0xa0), p)

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, T, 0xc0, T, 0x20)) { revert(0, 0) }

                //Y:=mulmod(Y,zzz,p)//Y/zzz
                //zz :=mulmod(zz, mload(T),p) //1/z
                //zz:= mulmod(zz,zz,p) //1/zz
                X := mulmod(X, mload(T), p) //X/zz
        
        }//end assembly
    }