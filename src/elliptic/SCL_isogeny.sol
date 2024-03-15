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
//As specified by Rene Struik in
//https://datatracker.ietf.org/doc/draft-ietf-lwig-curve-representations/
//inspired by https://github.com/ncme/c25519
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import { p, a, gx, gy, n, pMINUS_2, nMINUS_2 } from "@solidity/fields/SCL_wei25519.sol";

/*
const uint8_t f25519_delta[F25519_SIZE] = {         // = (255^19 + A) / 3 mod 255^19
	0x51, 0x24, 0xad, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa,
	0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa,
	0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa,
	0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0xaa, 0x2a
};

const uint8_t f25519_c[F25519_SIZE] = {             // = sqrt(-(A + 2)) mod 255^19
	0xe7, 0x81, 0xba, 0x00, 0x55, 0xfb, 0x91, 0x33,
	0x7d, 0xe5, 0x82, 0xb4, 0x2e, 0x2c, 0x5e, 0x3a,
	0x81, 0xb0, 0x03, 0xfc, 0x23, 0xf7, 0x84, 0x2d,
	0x44, 0xf9, 0x5f, 0x9f, 0x0b, 0x12, 0xd9, 0x70
};*/

uint256 constant f25519_delta=0x2aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaad2451;//(p + A) / 3 mod p
uint256 constant     f25519_c=0x70d9120b9f5ff9442d84f723fc03b0813a5e2c2eb482e57d3391fb5500ba81e7;// = sqrt(-(A + 2)) mod 255^19
uint256 constant f25519_A=0x076d06;//486662

 /**
     * /* @dev inversion mod nusing little Fermat theorem via a^(n-2), use of precompiled
     */

    function pModInv(uint256 u) view returns (uint256 result) {
        assembly {
            let pointer := mload(0x40)
            // Define length of base, exponent and modulus. 0x20 == 32 bytes
            mstore(pointer, 0x20)
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), 0x20)
            // Define variables base, exponent and modulus
            mstore(add(pointer, 0x60), u)
            mstore(add(pointer, 0x80), pMINUS_2)
            mstore(add(pointer, 0xa0), p)

            // Call the precompiled contract 0x05 = ModExp
            if iszero(staticcall(not(0), 0x05, pointer, 0xc0, pointer, 0x20)) { revert(0, 0) }
            result := mload(pointer)
        }
    }
/*
	f25519_add(nom, f25519_one, ey);    // nom =   1 + ey
	f25519_sub(den, f25519_one, ey);    // den =              1 - ey
	f25519_inv__distinct(inv, den);     // inv =             (1 - ey)^-1
	f25519_mul__distinct(mul, nom, inv);// mul =  (1 + ey) * (1 - ey)^-1
	f25519_add(wx, mul, f25519_delta);  //  wx = ((1 + ey) * (1 - ey)^-1) + delta
	f25519_normalize(wx);        		//  wx = ((1 + ey) * (1 - ey)^-1) + delta  (mod p)

	f25519_mul__distinct(mul, f25519_c, nom);	// mul =  c * (1 + ey)
	f25519_mul__distinct(inv, den, ex);			// inv =                   (1 - ey) * ex
	f25519_inv__distinct(den, inv);          	// den =                  ((1 - ey) * ex)^-1
	f25519_mul__distinct(wy, mul, den);      	//  wy = (c * (1 + ey)) * ((1 - ey) * ex)^-1
	f25519_normalize(wy);        				//  wy = (c * (1 + ey)) * ((1 - ey) * ex)^-1  (mod p)
    */
function Edwards2WeierStrass(uint256 x,uint256 y)  view returns (uint256 X, uint256 Y){
  //wx = ((1 + ey) * (1 - ey)^-1) + delta
  X=addmod(f25519_delta, mulmod(addmod(1,y,p),pModInv(addmod(1, p-y,p)),p) ,p);
  //  wy = (c * (1 + ey)) * ((1 - ey) * ex)^-1
  
  Y=mulmod(mulmod(f25519_c, addmod(1, y, p),p),        pModInv(mulmod(addmod(1, p-y,p), x,p)),p);
}

// ex  = (c * pa) * (3 * my)^-1 (mod p)

function WeierStrass2Edwards(uint256 X,uint256 Y)  view returns (uint256 x, uint256 y){
     // pa  = 3 * wx - A
     // ex  = (c * pa) * (3 * wy)^-1 (mod p)
    //  ey = (pa - 3) * (pa + 3)^-1 (mod p)
    uint pa=addmod(mulmod(3,X, p), p-a,p);
    uint inv=pModInv(mulmod(3,Y,p));
    x=mulmod(mulmod(f25519_c,pa,p), inv,p);
    inv=pModInv(addmod(pa,3,p));
  
  //  ey = (pa - 3) * (pa + 3)^-1 (mod p)
    y=mulmod(addmod(pa, p-3, p), inv, p);

}

