// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import {BaseScript} from "./BaseScript.sol";

import "../src/lib/libSCL_RIP7212.sol";


/// @notice Wrap the FCL_ecdsa library in a contract to be able to deploy it
contract SCL_RIP7212_wrapper {
    function ecdsa_verify(bytes32 message, uint256 r, uint256 s, uint256 x, uint256 y) external view returns (bool) {
        return SCL_RIP7212.verify(message, r,s , x,y);
   
    }
}


contract Script_Deploy_SCL is BaseScript {
    function run() external broadcast returns (address addressOfLibrary) {
        // deploy the library contract and return the address
        addressOfLibrary = address(new SCL_RIP7212_wrapper{salt: 0}());
    }
}