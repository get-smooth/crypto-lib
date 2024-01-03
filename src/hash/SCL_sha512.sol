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
/* (am3->a=-3, sw=short weierstrass) */
/* b4=Four dimensional multiexponentiation */
// SPDX-License-Identifier: MIT

//https://emn178.github.io/online-tools/sha512.html

pragma solidity >=0.8.19 <0.9.0;

library SCL_sha512 {
    uint256 constant SHA512_BLOCK_LENGTH8 = 128;
    uint256 constant SHA512_BLOCK_LENGTH64 = SHA512_BLOCK_LENGTH8 >> 3;
    uint256 constant SHA512_SHORT_BLOCK_LENGTH64 = SHA512_BLOCK_LENGTH64 - 4;
    uint256 constant SHA512_DIGEST_LENGTH = 64;

bytes constant K512=hex"428a2f98d728ae227137449123ef65cdb5c0fbcfec4d3b2fe9b5dba58189dbbc3956c25bf348b53859f111f1b605d019923f82a4af194f9bab1c5ed5da6d8118d807aa98a303024212835b0145706fbe243185be4ee4b28c550c7dc3d5ffb4e272be5d74f27b896f80deb1fe3b1696b19bdc06a725c71235c19bf174cf692694e49b69c19ef14ad2efbe4786384f25e30fc19dc68b8cd5b5240ca1cc77ac9c652de92c6f592b02754a7484aa6ea6e4835cb0a9dcbd41fbd476f988da831153b5983e5152ee66dfaba831c66d2db43210b00327c898fb213fbf597fc7beef0ee4c6e00bf33da88fc2d5a79147930aa72506ca6351e003826f142929670a0e6e7027b70a8546d22ffc2e1b21385c26c9264d2c6dfc5ac42aed53380d139d95b3df650a73548baf63de766a0abb3c77b2a881c2c92e47edaee692722c851482353ba2bfe8a14cf10364a81a664bbc423001c24b8b70d0f89791c76c51a30654be30d192e819d6ef5218d69906245565a910f40e35855771202a106aa07032bbd1b819a4c116b8d2d0c81e376c085141ab532748774cdf8eeb9934b0bcb5e19b48a8391c0cb3c5c95a634ed8aa4ae3418acb5b9cca4f7763e373682e6ff3d6b2b8a3748f82ee5defb2fc78a5636f43172f6084c87814a1f0ab728cc702081a6439ec90befffa23631e28a4506cebde82bde9bef9a3f7b2c67915c67178f2e372532bca273eceea26619cd186b8c721c0c207eada7dd6cde0eb1ef57d4f7fee6ed17806f067aa72176fba0a637dc5a2c898a6113f9804bef90dae1b710b35131c471b28db77f523047d8432caab7b40c724933c9ebe0a15c9bebc431d67c49c100d4c4cc5d4becb3e42b6597f299cfc657e2a5fcb6fab3ad6faec6c44198c4a475817";
 
struct SHA512_CTX {
       bytes  K512;
       uint64[8] state;
       uint256 usedspace64;
       uint64[SHA512_BLOCK_LENGTH64] buffer;
      
    }

    function _k512(SHA512_CTX memory context, uint j) internal pure returns (uint64 r){
        uint256 read;
        assembly{
            read:=mload(add(add(context, 160),mul(8,j)))//offset from start of K512 cst is 160
        }
        return uint64((read>>192));

    }


    function Sha_Init() public pure returns (SHA512_CTX memory context){
         context.state[0]=   0x6a09e667f3bcc908;
         context.state[1]=   0xbb67ae8584caa73b;
         context.state[2]=   0x3c6ef372fe94f82b;
         context.state[3]=   0xa54ff53a5f1d36f1;
         context.state[4]=   0x510e527fade682d1;
         context.state[5]=   0x9b05688c2b3e6c1f;
         context.state[6]=   0x1f83d9abfb41bd6b;
         context.state[7]=   0x5be0cd19137e2179;
        
      
       context.usedspace64=0;
       for(uint i=0;i<SHA512_BLOCK_LENGTH64;i++) {
        context.buffer[i]=0;
       }
       context.K512=K512;
    }

       
    function Swap512(uint256[2] memory w) internal pure returns(uint256[2] memory r)
    {
        r[0]=Swap256(w[1]);
        r[1]=Swap256(w[0]);

        return r;
    }

    function Swap256(uint256 w) internal pure returns (uint256 x)
    {
        return uint256(Swap128(uint128(w>>128)))^(uint256(Swap128(uint128(w&0xffffffffffffffffffffffffffffffff)))<<128);
    }

    function Swap128(uint128 w) internal pure returns (uint128 x)
    {
        return uint128(Swap64(uint64(w>>64)))^(uint128(Swap64(uint64(w&0xffffffffffffffff)))<<64);

    }

    function Swap64(uint64 w) internal pure returns (uint64 x){
     uint64 tmp= (w >> 32) | (w << 32);
	 tmp = ((tmp & 0xff00ff00ff00ff00) >> 8) |    ((tmp & 0x00ff00ff00ff00ff) << 8); 
	 x = ((tmp & 0xffff0000ffff0000) >> 16) |   ((tmp & 0x0000ffff0000ffff) << 16); 
    }

    function Sigma1_512(uint64 h) internal pure returns (uint64 x){

        return (((h) >> (14)) | ((h) << (64 - (14)))) ^ (((h) >> (18)) | ((h) << (64 - (18))))^ (((h) >> (41)) | ((h) << (64 - (41))));
    }

    function Sigma0_512(uint64 h) internal pure returns (uint64 x){
        return (((h) >> (28)) | ((h) << (64 - (28)))) ^ (((h) >> (34)) | ((h) << (64 - (34))))^ (((h) >> (39)) | ((h) << (64 - (39))));
    }

    function sigma1_512(uint64 h) internal pure returns (uint64 x){
          return (((h) >> (19)) | ((h) << (64 - (19)))) ^ (((h) >> (61)) | ((h) << (64 - (61))))^ (((h) >> (6)) );

    }

    function sigma0_512(uint64 h) internal pure returns (uint64 x){
          return (((h) >> (1)) | ((h) << (64 - (1)))) ^ (((h) >> (8)) | ((h) << (64 - (8))))^ (((h) >> (7)) );

    }

    function Ch(uint64 x,uint64 y,uint64 z)	internal pure returns(uint64 r){
        return (((x) & (y)) ^ ((~(x)) & (z)));
    }

    function Maj(uint64 x,uint64 y,uint64 z) internal pure  returns(uint64 r ){
	return (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)));
    }


    function SHA512_Transform(SHA512_CTX memory i_context, uint64[SHA512_BLOCK_LENGTH64] memory data) internal view returns(SHA512_CTX memory context)  {
        unchecked {
            
        context=i_context;

        uint64 a = context.state[0];
        uint64 b = context.state[1];
        uint64 c = context.state[2];
        uint64 d = context.state[3];
        uint64 e = context.state[4];
        uint64 f = context.state[5];
        uint64 g = context.state[6];
        uint64 h = context.state[7];
        uint64 j = 0;
    
        do {
            context.buffer[j] = Swap64(data[j]);   
           
            uint64 T1 = h + (((((e) >> (14)) | ((e) << (64 - (14)))) ^ (((e) >> (18)) | ((e) << (64 - (18))))^ (((e) >> (41)) | ((e) << (64 - (41)))))) + Ch(e, f, g) + uint64(k512(j)) + context.buffer[j];           
            uint64 T2 = Sigma0_512(a) + Maj(a, b, c);
            h = g;
            g = f;
            f = e;
            e = d + T1;
            d = c;
            c = b;
            b = a;
            a = T1 + T2;
            j++;
        } while (j < 16);

        do {
           
            /* Part of the message block expansion: */
            uint64 T1 = context.buffer[(j + 1) & 0x0f];
            T1 = sigma0_512(T1);
            uint64 T2 = context.buffer[(j+14)&0x0f];
		    T2 =  sigma1_512(T2);
          
            /* Apply the SHA-512 compression function to update a..h */
            T1 = h + Sigma1_512(e) + Ch(e, f, g) + uint64(k512(j)) +
		     (context.buffer[j&0x0f] += T2 + context.buffer[(j+9)&0x0f] + T1);
		      T2 = Sigma0_512(a) + Maj(a, b, c);

            h = g;
            g = f;
            f = e;
            e = d + T1;
            d = c;
            c = b;
            b = a;
            a = T1 + T2;

            j++;
        } while (j < 80);
        
        /* Compute the current intermediate hash value */
        context.state[0] += a;
        context.state[1] += b;
        context.state[2] += c;
        context.state[3] += d;
        context.state[4] += e;
        context.state[5] += f;
        context.state[6] += g;
        context.state[7] += h;
        }
        return context;
    }


    function k512(uint j) internal view returns (uint64 r)
    {
        uint256[1] memory T;
         assembly{
        extcodecopy(0xcaca, T, mul(j,8), 8)
    }
        r=uint64(T[0]>>192);

        return r;
    }

}