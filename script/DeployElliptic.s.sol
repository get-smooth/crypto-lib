// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import {BaseScript} from "./BaseScript.sol";
import  "../src/lib/libSCL_ecdsab4.sol";


/// @notice Wrap the FCL_ecdsa library in a contract to be able to deploy it
contract FCL_ecdsa_wrapper {
    function ecdsa_verify(bytes32 message, uint256 r, uint256 s, uint256[10] memory Qpa, uint256 n) external view returns (bool) {
        return SCL_ECDSAB4.verify(message, r,s , Qpa,n);
   
    }
}


contract Script_Deploy_SCL is BaseScript {
    function run() external broadcast returns (address addressOfLibrary) {
        // deploy the library contract and return the address
        addressOfLibrary = address(new FCL_ecdsa_wrapper{salt: 0}());
    }
}