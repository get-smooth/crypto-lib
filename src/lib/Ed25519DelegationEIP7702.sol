/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)   
/* Description: a Delegation Contract, ready for EIP7702 delegation          
/********************************************************************************************/
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.19 <0.9.0;


// example build adapting commands from https://github.com/paradigmxyz/forge-alphanet
//SCL is required, repo available here: https://github.com/get-smooth/crypto-lib/blob/main/src/lib/libSCL_EIP6565.sol
// assuming 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 to be the EOA private key, 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 its address
// 1. Deploy the libSCL_EIP6565 library : 
//    a.forge create SCL_EIP6565 --gas-limit 300000 --private-key "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" --rpc-url=https://rpc.pectra-devnet-3.ethpandaops.io
//    b. save the SCL_EIP6565_address 
// 2. Create a valid Ed25519 Extended Keypair using SetKey function in libSCL_eddsaUtils  being the result
//    a. (extKpub, signer)=SetKey(secret_seed);
//    b. (Qx' 'Qy' 'Qx128' 'Qy128' 'Qc') = extKpub, hexadecimal
// 3. Deploy this Ed25519 Delegation contract :forge create Ed25519Delegation --private-key "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" --rpc-url "http://127.0.0.1:8545"
    //a. store the deployed Ed25519_address
// 4. To interact with the contract:
//   a. Delegate the EOA : cast send 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 'authorize(SCL_EIP6565_address, uint256,uint256, uint256,uint256, uint256)' ' ' 'Qx' 'Qy' 'Qx128' 'Qy128' 'Qc' --auth "<Ed25519_address>" --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --gas-limit 50000 --rpc-url=https://rpc.pectra-devnet-3.ethpandaops.io
//   message=$(cast abi-encode 'f(uint256,address,bytes,uint256)' $(cast call 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 'nonce()(uint256)') '0x0000000000000000000000000000000000000000' '0x' '1000000000000000000')
//   b. Simulate a signature using eddsaUtils : (r,s)=Sign(uint256 KpubC, uint256[2] memory signer,  string memory message)
//   c. Send from another account (paymaster is controlled by secret key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d)
//   cast send 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 'transact(address to,bytes data,uint256 value,bytes32 r,bytes32 s)' '0x0000000000000000000000000000000000000000' '0x' '1000000000000000000' '<r value>' '<s value>' --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d


abstract contract EdSigner{
     function Verify_LE(string memory m, uint256 r, uint256 s, uint256[5] memory extKpub) public virtual returns(bool flag);
}


/// @notice Contract designed for being delegated to by EOAs to authorize a secp256r1 key to transact on their behalf.
contract Ed25519Delegation {
    /// @notice Address of the SCL deployed library
    address signer;
    /// @notice The x coordinate of the authorized public key
     uint256 authorizedPublicKeyX;
    /// @notice The y coordinate of the authorized public key
    uint256 authorizedPublicKeyY;
     /// @notice The x coordinate of the authorized public key multiplied by 2**128, obtained by SetKey function
     uint256 authorizedPublicKeyX128;
    /// @notice The y coordinate of the authorized public key multiplied by 2**128, obtained by SetKey function
    uint256 authorizedPublicKeyY128;
    /// @notice The edwards form of compressed public key, obtained by SetKey function
    uint256 authorizedPublicKeyCompressed;

    /// @notice Internal nonce used for replay protection, must be tracked and included into prehashed message.
    uint256 public nonce;

    /// @notice Authorizes provided public key to transact on behalf of this account. Only callable by EOA itself.
    function authorize(address DeployedEdSigner, uint256 publicKeyX, uint256 publicKeyY, uint256 publicKeyX128, uint256 publicKeyY128, uint publicKeyCompressed) public {
        require(msg.sender == address(this));

        signer = DeployedEdSigner;
        authorizedPublicKeyX = publicKeyX;
        authorizedPublicKeyY = publicKeyY;
        authorizedPublicKeyX128 = publicKeyX128;
        authorizedPublicKeyY128 = publicKeyY128;
        authorizedPublicKeyCompressed = publicKeyCompressed;
    }

    /// @notice Main entrypoint for authorized transactions. Accepts transaction parameters (to, data, value) and a secp256r1 signature.
    function transact(address to, bytes memory data, uint256 value, bytes32 r, bytes32 s) public {
       EdSigner Ed25519=  EdSigner(signer); 
       require(Ed25519.Verify_LE(string(data), uint256(r), uint256(s), [authorizedPublicKeyX, authorizedPublicKeyY,authorizedPublicKeyX128, authorizedPublicKeyY128, authorizedPublicKeyCompressed ]), "Invalid signature");
       (bool success,) = to.call{value: value}(data);
       
        require(success);
    }
}

