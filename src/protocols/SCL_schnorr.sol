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
// Description : a minimal non-standard didactic Schnorr signature as described in https://en.wikipedia.org/wiki/Schnorr_signature
pragma solidity >=0.8.19 <0.9.0;


import { p, gx, gy, n, pMINUS_2, nMINUS_2 } from "@solidity/include/SCL_field.h.sol"; 
import { nModInv } from "@solidity/modular/SCL_modular.sol"; 
import {ec_mulmuladdX, ec_mulmuladd_S8_extcode} from  "@solidity/include/SCL_ecmulmuladd.h.sol"; 
import {ecmulmuladd_oracle} from "@solidity/elliptic/SCL_muloracle.sol";



function Schnorr_verify(bytes32 message, uint256 s, uint256 e, uint256 qx, uint256 qy) view returns (bool) 
{
    uint256 rv=ec_mulmuladdX( qx, qy, s, e) ;
    uint256 ev=uint256(sha256(abi.encodePacked(rv, message )));

    return (ev==e);
}

//version using an ecrecover as oracle for the mul for the verification 
//WIP, do not use
function schnorr_verify_oraclemul(bytes32 message, uint256 s, uint256 e, uint256 qx, uint256 qy, uint256 oracle_r) view returns (bool) 
{
    uint256 h=ecmulmuladd_oracle( qx, qy, s, e) ;
    //todo check that oracle didn't lie
   
    uint256 ev=uint256(sha256(abi.encodePacked(oracle_r, message)));

    return false;//WIP
    return (ev==e);
}

/******************* OFF CHAIN FUNCTIONS (sensitive data)*/
/* Warning : Offchain code is not meant to be used with funds ! It is for demonstration/testing only as private keys shall never
exist on chain*/
function Schnorr_sign(bytes32 message, uint256 kpriv) view returns
(uint256 s, uint256 e)
{
 //randomness is deterministically derived as in eddsa
 uint256 random=uint256(sha256(abi.encodePacked(kpriv, message )));

 uint256 rx=ec_mulmuladdX( 0,0,random, 0) ;
 e=uint256(sha256(abi.encodePacked(rx, message )));

 s=addmod( random, p-e, p);

 return (s,e);
}

