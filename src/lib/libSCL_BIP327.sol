/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)      
/* Description: This file implements the BIP327/BIP340 verification protocol. The front signing algorithm 
/* is implemented in libMPC                                  
/********************************************************************************************/

import {pp1div4, a,b, p,n, gx, gy,  pMINUS_1} from "../fields/SCL_secp256k1.sol";
import "../modular/SCL_sqrtMod_3mod4.sol";

//compliant with BIP327
function tagged_hashBTC(string memory tag, bytes memory message ) pure returns(uint256 e)
{
 uint256 res=uint256(sha256(bytes(tag)));
 return uint256(sha256(abi.encodePacked(res, res, message)));

}



 /**
     * @notice Extract  coordinates from compressed coordinates (Weierstrass form), assuming y=0
     *
     * @param Px The compressed  point of Edwards form, most significant bit encoding parity
     * @return Py The x-coordinate of the point in affine representation
    */
 function ecDecompress_BTC(uint256 Px)  returns (uint256 Py){
   
  uint256 RHS = addmod(mulmod(mulmod(Px, Px, p), Px, p), mulmod(Px, a, p), p); // x^3+ax
  uint256 y2 = addmod(RHS, b, p); // x^3 + a*x + b
   
  Py=SqrtMod(y2);
  if((Py&1)!=0){
            Py=p-Py;
  }

    return Py;    
  }

//A schnorr verifier compatible with BIP327
//compared to BIP327, which takes only pubkeyX as input, it is assumed that public key has been decompressed using ecDecompress_BTC
//this avoid to perform the same decompression at every verification
  function Schnorr_verify(bytes memory message, uint256 pubkeyX, uint256 pubkeyY, uint256 r, uint256 s)  returns (bool res)
  {
    string memory tag_btc="BIP0340/challenge";
    uint256 e=tagged_hashBTC(tag_btc, abi.encodePacked(r, pubkeyX, message ))%n;
    //let e = int_from_bytes(tagged_hashBTC('BIP0340/challenge', concat)) % secp256k1.CURVE.n;
    bytes32 h = keccak256(abi.encodePacked(bytes32(r), ecDecompress_BTC(r)));
    address expected=address(uint160(uint256(h)));

    s=n-mulmod(s,pubkeyX, n);
    e=n-mulmod(e,pubkeyX, n);

    address R=ecrecover(bytes32(s), 27, bytes32(pubkeyX), bytes32(e));//beware of chainID that might affect the constant 27 value
    return (R==expected);
  }