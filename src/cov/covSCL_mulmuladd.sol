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
/* 
/********************************************************************************************/
/* This file implements elliptic curve over short weierstrass form, with coefficient a=-3, with xyzz coordinates */
/* It is a custom 4 dimensional version of Shamir's trick (tis not a window)*/
/* It is a self sufficient implementation which aims to prove that its counterpart efficient implementation
* reach 100% coverage
*/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


library COV_SCLMulmuladd{

   
// prime field modulus of the secp256r1 curve
uint256 constant p = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
// short weierstrass first coefficient
uint256 constant a = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC;
// short weierstrass second coefficient
uint256 constant b = 0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B;
// the affine coordinates of the generating point on the curve
uint256 constant gx = 0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296;
uint256 constant gy = 0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5;
// the order of the curve, i.e., the number of points on the curve
uint256 constant n = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;

/*//////////////////////////////////////////////////////////////
                            CONSTANTS
//////////////////////////////////////////////////////////////*/

// -2 mod(p), used to accelerate inversion and doubling operations by avoiding negation
uint256 constant pMINUS_2 = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFD;
// -2 mod(n), used to speed up inversion operations
uint256 constant nMINUS_2 = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC63254F;

//precomputed 2^128.G
//0x447d739beedb5e67fb982fd588c6766efc35ff7dc297eac357c84fc9d789bd85
uint256 constant gpow2p128_x = 30978927491535595270285342502287618780579786685182435011955893029189825707397;
uint256 constant gpow2p128_y= 20481551163499472379222416201371726725754635744576161296521936142531318405938;
uint256 constant _HIBIT_CURVE=255;

 //P+1 div 4, used for sqrtmod computation
 uint256 constant pp1div4=0x3fffffffc0000000400000000000000000000000400000000000000000000000;

uint256 constant   _MODEXP_PRECOMPILE=0x05;
// the representation of -1 over 255 bits
uint256 constant MINUS_1 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    
//test equality of two projective points    
function ecTestEq(uint256 x,uint256 y,uint256 zz,uint256 zzz,uint256 xp,uint256 yp,uint256 zzp,uint256 zzzp) public
pure returns (bool){
  bool res=true;

  if(mulmod(x,zzp, p)!=mulmod(xp, zz, p)) {
    res=false;
  }

  if(mulmod(y,zzzp, p)!=mulmod(yp, zzz, p)) {
    res=false;
  }
   
  return res;
}

    function ecNormalize(uint256 x, uint256 y, uint256 zz, uint256 zzz) public view
    returns (uint256 x1, uint256 y1 ){

        if(zz==0){
            return (0,0);
        }

        uint256 zzzInv; 
        //1/zzz
         assembly {
            let pointer := mload(0x40)
            // Define length of base, exponent and modulus. 0x20 == 32 bytes
            mstore(pointer, 0x20)
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), 0x20)
            // Define variables base, exponent and modulus
            mstore(add(pointer, 0x60), zzz)
            mstore(add(pointer, 0x80), pMINUS_2)
            mstore(add(pointer, 0xa0), p)

            // Call the precompiled contract 0x05 = ModExp
            if iszero(staticcall(not(0), 0x05, pointer, 0xc0, pointer, 0x20)) { revert(0, 0) }
            zzzInv := mload(pointer)
        }

        y1 = mulmod(y, zzzInv, p); //Y/zzz
        uint256 _b = mulmod(zz, zzzInv, p); //1/z
        zzzInv = mulmod(_b, _b, p); //1/zz
        x1 = mulmod(x, zzzInv, p); //X/zz
   }

   //compute R=-2G,
   function ecDblNeg(uint256 x, uint256 y, uint256 zz, uint256 zzz) public pure
   returns (uint256 P0, uint256 P1, uint256 P2, uint256 P3){
        unchecked {
            assembly {
                P0 := mulmod(2, y, p) //U = 2*Y1
                P2 := mulmod(P0, P0, p) // V=U^2
                P3 := mulmod(x, P2, p) // S = X1*V
                P1 := mulmod(P0, P2, p) // W=UV
                P2 := mulmod(P2, zz, p) //zz3=V*ZZ1
                //zz := mulmod(3, mulmod(addmod(x, sub(p, zz), p), addmod(x, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                zz:=addmod(mulmod(3, mulmod(x,x,p),p),mulmod(a,mulmod(zz,zz,p),p),p)//3*X12+aZZ12  
                P0 := addmod(mulmod(zz, zz, p), mulmod(pMINUS_2, P3, p), p) //X3=M^2-2S
                x := mulmod(zz, addmod(P3, sub(p, P0), p), p) //M(S-X3)
                P3 := mulmod(P1, zzz, p) //zzz3=W*zzz1
                P1 := addmod(x, sub(p, mulmod(P1, y, p)), p) //Y3= M(S-X3)-W*Y1
            }
        }
        return (P0, addmod(p-P1,0,p), P2, P3);
   }

   //compute R=-(G1+G2)
   function ecAddNeg(uint256 x1, uint256 y1, uint256 zz1, uint256 zzz1, uint256 x2, uint256 y2, uint256 zz2, uint256 zzz2) public
    pure
        returns (uint256 x3, uint256 y3, uint256 zz3, uint256 zzz3){
          uint256 u1=mulmod(x1,zz2,p); // U1 = X1*ZZ2
    uint256 u2=mulmod(x2, zz1,p);               //  U2 = X2*ZZ1
    u2=addmod(u2, p-u1, p);//  P = U2-U1
    x1=mulmod(u2, u2, p);//PP
    x2=mulmod(x1, u2, p);//PPP
    
    zz3=mulmod(x1, mulmod(zz1, zz2, p),p);//ZZ3 = ZZ1*ZZ2*PP  
    zzz3=mulmod(zzz1, mulmod(zzz2, x2, p),p);//ZZZ3 = ZZZ1*ZZZ2*PPP

    zz1=mulmod(y1, zzz2,p);  // S1 = Y1*ZZZ2
    zz2=mulmod(y2, zzz1, p);    // S2 = Y2*ZZZ1 
    zz2=addmod(zz2, p-zz1, p);//R = S2-S1
    zzz1=mulmod(u1, x1,p); //Q = U1*PP
    x3= addmod(addmod(mulmod(zz2, zz2, p), p-x2,p), mulmod(pMINUS_2, zzz1,p),p); //X3 = R2-PPP-2*Q
    y3=addmod( mulmod(zz2, addmod(zzz1, p-x3, p),p), p-mulmod(zz1, x2, p),p);//R*(Q-X3)-S1*PPP

    return (x3, addmod(p-y3,0,p), zz3, zzz3);

        }

   function ecAddn(uint256 x1, uint256 y1, uint256 zz1, uint256 zzz1, uint256 x2, uint256 y2) public
    pure
        returns (uint256 P0, uint256 P1, uint256 P2, uint256 P3)
    {
        unchecked {
            if (y1 == 0) {
                return (x2, y2, 1, 1);
            }

            assembly {
                y1 := sub(p, y1)
                y2 := addmod(mulmod(y2, zzz1, p), y1, p)
                x2 := addmod(mulmod(x2, zz1, p), sub(p, x1), p)
                P0 := mulmod(x2, x2, p) //PP = P^2
                P1 := mulmod(P0, x2, p) //PPP = P*PP
                P2 := mulmod(zz1, P0, p) ////ZZ3 = ZZ1*PP
                P3 := mulmod(zzz1, P1, p) ////ZZZ3 = ZZZ1*PPP
                zz1 := mulmod(x1, P0, p) //Q = X1*PP
                P0 := addmod(addmod(mulmod(y2, y2, p), sub(p, P1), p), mulmod(pMINUS_2, zz1, p), p) //R^2-PPP-2*Q
                P1 := addmod(mulmod(addmod(zz1, sub(p, P0), p), y2, p), mulmod(y1, P1, p), p) //R*(Q-X3)
            }
            //end assembly
        } //end unchecked
        return (P0, P1, P2, P3);
    }

   //store in Preco the value, val1, val2, val3, val4 starting from offset in bytes
   function mstore4(uint256[4][16] memory Preco, uint offset, uint val1, uint val2, uint val3, uint val4) public pure {
      if (offset>1920) {
        revert();}//would overflow 16 cells

      uint cell=offset/128;
      Preco[cell][0]=val1;
      Preco[cell][1]=val2;
      Preco[cell][2]=val3;
      Preco[cell][3]=val4;
   }
   
//this function is for use only after validation of the Q input:
//Q shall belongs to the curve, and different from -P, -P128, -(P+P128), ...
//those 16 values are tested by the ValidateKey function
//due to handling of Neutral element, this function will not work for 16 specific weak keys
//those value are excluded from the 
function ec_mulmuladdX(
       /* uint256 Q0,
        uint256 Q1, //affine rep for input point Q
        uint256 Q2, 
        uint256 Q3, //affine rep for precomputations*/
        uint256 [4] memory Q,
        uint256 scalar_u,
        uint256 scalar_v
    )  public view returns (uint256 X) {
        uint256 mask=1<<127;
       
        /* I. precomputation phase */
        uint256[4][16] memory Preco;
        Preco[0][0]=127;//storing index of main loop here due to low stack

        if(scalar_u==0&&scalar_v==0){
            return 0;
        }
        uint256 Y;
        uint256 ZZZ;
        uint256 ZZ;

          /* I. Precomputations */
          //allocate memory for 15 projective points, first slot is unused
          mstore4(Preco, 128, gx, gy, 1, 1);                      //G the base point
          mstore4(Preco, 256, gpow2p128_x, gpow2p128_y, 1, 1);     //G'=2^128.G
        

          (X,Y,ZZ,ZZZ)=ecAddn( gpow2p128_x,gpow2p128_y,1,1, gx,gy); //G+G'
          mstore4(Preco, 384, X,Y,ZZ,ZZZ)     ;                   //Q, the public key
          mstore4(Preco, 512, Q[0],Q[1],1,1)  ;                       
         
          (X,Y,ZZ,ZZZ)=ecAddn(Q[0],Q[1],1,1, gx,gy);//G+Q
          mstore4(Preco, 640, X,Y,ZZ,ZZZ)   ;
         
         (X,Y,ZZ,ZZZ)=ecAddn(gpow2p128_x,gpow2p128_y,1,1,Q[0],Q[1]);//G'+Q
          mstore4(Preco, 768, X,Y,ZZ,ZZZ)  ; 
        
          (X,Y,ZZ,ZZZ)=ecAddn( X,Y,ZZ,ZZZ, gx, gy);//G'+Q+G
          mstore4(Preco, 896, X,Y,ZZ,ZZZ)  ;
         
          mstore4(Preco, 1024, Q[2],Q[3],1,1) ;  //Q'=2^128.Q

         (X,Y,ZZ,ZZZ)=ecAddn(Q[2],Q[3],1,1, gx,gy);//Q'+G
          mstore4(Preco, 1152, X,Y,ZZ,ZZZ) ; 
        
         (X,Y,ZZ,ZZZ)=ecAddn(Q[2],Q[3],1,1, gpow2p128_x,gpow2p128_y);//Q'+G'
          mstore4(Preco, 1280, X,Y,ZZ,ZZZ) ; 
           
         (X,Y,ZZ,ZZZ)=ecAddn(X, Y, ZZ, ZZZ, gx, gy);//Q'+G'+G
          mstore4(Preco, 1408, X,Y,ZZ,ZZZ)  ;
           
         (X,Y,ZZ,ZZZ)=ecAddn( Q[0],Q[1],1,1,Q[2],Q[3]);//Q+Q'
          mstore4(Preco, 1536, X,Y,ZZ,ZZZ)  ;

         (X,Y,ZZ,ZZZ)=ecAddn( X,Y,ZZ,ZZZ, gx, gy);//Q+Q'+G
          mstore4(Preco, 1664, X,Y,ZZ,ZZZ)  ;

        (X,Y,ZZ,ZZZ)=(Preco[6][0], Preco[6][1],Preco[6][2],Preco[6][3]);//G'+Q
      
        (X,Y,ZZ,ZZZ)=ecAddn( X,Y,ZZ,ZZZ, Q[2],Q[3]);//G'+Q+Q'+
         mstore4(Preco, 1792, X,Y,ZZ,ZZZ)  ;

         (X,Y,ZZ,ZZZ)=ecAddn( X,Y,ZZ,ZZZ,gx,gy);//G'+Q+Q'+G
          //  Prec[15]
          mstore4(Preco, 1920, X,Y,ZZ,ZZZ)  ;
    
    /*II. First MSB bit*/
    uint256 hi_u=scalar_u>>128;
    uint256 hi_v=scalar_v>>128;
    uint256 quadribit=0;
  
         while(quadribit==0){
            /*
            assembly{
                 quadribit:=add(add(sub(1,iszero(and(scalar_u, mask))), shl(1,sub(1,iszero(and(hi_u, mask))))),
                           add(shl(2,sub(1,iszero(and(scalar_v, mask)))), shl(3,sub(1,iszero(and(hi_v, mask))))))
            }*/
            
            quadribit=((scalar_u&mask)>>Preco[0][0])+2*((hi_u&mask)>>Preco[0][0])+4*((scalar_v&mask)>>Preco[0][0])+8*((hi_v&mask)>>Preco[0][0]);
          
            mask>>=1;
           Preco[0][0]--;
        }
       


        X=Preco[quadribit][0];
        Y=Preco[quadribit][1];
        ZZ=Preco[quadribit][2];
        ZZZ=Preco[quadribit][3];
        
   /*III. Main loop */
        while(mask!=0)
        {
            (X,Y,ZZ,ZZZ)=ecDblNeg(X,Y,ZZ,ZZZ);
            
            assembly{
                 quadribit:=add(add(sub(1,iszero(and(scalar_u, mask))), shl(1,sub(1,iszero(and(hi_u, mask))))),
                           add(shl(2,sub(1,iszero(and(scalar_v, mask)))), shl(3,sub(1,iszero(and(hi_v, mask))))))

            }
           mask>>=1;
            if(quadribit!=0){
              //todo: replace by homogeneous function
                //special case ecAdd(P,P)=EcDbl
                //        if iszero(y2) {
                //            if iszero(T2) {

                //            }
                //        }
              
              (X,Y,ZZ,ZZZ)=ecAddNeg(X,Y,ZZ,ZZZ, Preco[quadribit][0], Preco[quadribit][1],Preco[quadribit][2],Preco[quadribit][3]);
            }
            else{
                Y=p-Y;
            }
        }   
        Y=p-Y;
        (X,)=ecNormalize(X,Y,ZZ,ZZZ);
  }
}