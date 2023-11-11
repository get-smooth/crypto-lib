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

//Status:WIP

import { p, gx, gy, n, pMINUS_2, nMINUS_2 } from "@solidity/include/SCL_field.h.sol"; 

/* An adaptator signature scheme as described in 
https://medium.com/crypto-garage/adaptor-signature-on-schnorr-cross-chain-atomic-swaps-3f41c8fb221b*/


/******************* OFF CHAIN PROTOCOL */
/* Warning : This code is not meant to be used with funds ! It is for demonstration only as private keys shall never
exist on chain*/

//assuming that Initiator and Responder already agreed on a (R,P) pair using Musig2 (see SCL_musig2.sol)
function SCL_tweak_initiator(uint256 hash, uint256 privA, uint256 random) view
returns(uint256 SpA, uint256 tweak) 
{
  /* randomness is derived to produce tweak t and nonce rA */  
  tweak = addmod(block.prevrandao, uint256(keccak256(abi.encodePacked(1+random))), p);
  uint256 rA = uint256(keccak256(abi.encodePacked(2+random)));

  return (addmod(addmod(tweak, rA, p), mulmod(privA, hash,p),p), tweak);
}


function SCL_tweak_responder(uint256 hash, uint256 privB, uint256 random)  
pure
returns(uint256 SB) 
{
  uint256 rB = uint256(keccak256(abi.encodePacked(2+random)));

  return addmod(rB, mulmod(privB, hash,p),p);
}

function SCL_unlock_initiator(uint256 SpA, uint256 SB) pure
returns(uint256 S_AB ) 
{
  /* randomness is derived to produce tweak t and nonce rA */  
  S_AB=addmod(SpA, SB, p);
}


function SCL_unlock_responder(uint256 SpA, uint256 SB) pure
returns(uint256 S_AB ) 
{
  /* randomness is derived to produce tweak t and nonce rA */  
  S_AB=addmod(SpA, SB, p);
}

