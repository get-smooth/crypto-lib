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

struct random_ctx{
 uint256 state;
}

/* A basic DRNG */
function SCL_Random_Init(bytes memory random_initiator) view returns (random_ctx memory RandomCtx) 
{
 RandomCtx.state=uint256(keccak256(random_initiator))^block.prevrandao;
 return RandomCtx;
}


function SCL_Random_Update(bytes memory random_updater, random_ctx memory RandomCtx) view returns (random_ctx memory NewRandomCtx) 
{
 RandomCtx.state=RandomCtx.state ^uint256(keccak256(random_updater))^block.prevrandao;
 return RandomCtx;
}

function SCL_RandomUint256_Generate( random_ctx memory RandomCtx) view returns (random_ctx memory NewRandomCtx, uint256 rand)
{
  rand=uint256(keccak256(abi.encodePacked(RandomCtx.state)))^block.prevrandao;
  NewRandomCtx=SCL_Random_Update(bytes("Update"),RandomCtx);
}

