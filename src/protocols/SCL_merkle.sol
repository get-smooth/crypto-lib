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
// Description: Using Merkle Trees to compact signers of a UserOp
pragma solidity >=0.8.19 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

uint256 constant _MAX_LEAVES= 32;


library SCL_Merkle{
struct Verifier{
 address SigVerif;
 bytes Kpub;
}

function leftChildIndex(uint index) private pure returns(uint){
  return 2*index+1;
}

function rightChildIndex(uint index) private pure returns(uint){
  return 2*index+2;
}


//TODO: use an include to enable any hash function for Merkle
/**
  * @dev Sorts the pair (a, b) and hashes the result.
  */
function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
       return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
}

function siblingIndex(uint i) private pure returns(uint){
  if(i==0) return 0;
  return 1-2*(i%2); //equivalent to i - (-1) ** (i % 2)
}   

function getProof(bytes memory tree, uint index) private pure returns (bytes memory proof)
{



}


 /**
   * @dev Implementation of keccak256(abi.encode(a, b)) that doesn't allocate or expand memory.
   */
function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

//a OZ compatible Merkle tree, WIP, straight translation from js to solidity
function makeMerkleTree(bytes memory leaves) public pure returns (bytes memory){
  assert(leaves.length>0);
  assert(addmod(leaves.length,0,32)==0);

  uint treelength=2* (leaves.length/32 )- 1;

  //todo: replace by dynamic array
  //bytes32[_MAX_LEAVES*2+1] memory tree;
  bytes memory tree=new bytes(32*treelength);

  //copying leaves
  for(uint index=0;index<treelength; index++){
    uint256 offset=32+index*32;
    bytes32 leaf;
    uint add=32*(treelength-1-index)+32;
    assembly{
        leaf:=mload(add(leaves, offset))
        mstore( tree, leaf)
    }
  } 

  //compute merkle tree from leaves to root
   for(uint i = treelength - 1 - leaves.length; i >= 0; i--) {
    uint256 left=leftChildIndex(i)*32+32;
    uint256 right=rightChildIndex(i)*32+32;
    
    assembly{
      left:=mload(add(tree, left))
      right:=mload(add(tree, right))
 
    }

    bytes32 node = _hashPair( bytes32(left), bytes32(right));
    uint index=32*(treelength-1-i)+32;
    assembly{mstore( add(tree, index), node)}
  
  }
 
  return tree;
}
}

//flexible UserOp enforced by Merkle trees
contract MetamOrp{
   bytes32 private root;
   bytes keyStore;
    
   constructor(SCL_Merkle.Verifier memory, bytes memory SelfCertificate)
   {


   }




}

