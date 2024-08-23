// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import {BaseScript} from "./BaseScript.sol";

import "../src/lib/libSCL_EIP6565.sol";
import "../src/lib/libSCL_eddsaUtils.sol";

/// @notice Wrap the FCL_ecdsa library in a contract to be able to deploy it
contract SCL_EIP6565_wrapper {
   
    
    function eddsa_setKey(uint256 secret) public view returns (uint256[5] memory extKpub, uint256[2] memory signer){
        return SCL_EIP6565_UTILS.SetKey(secret);
    }

    function eddsa_verify(string memory m, uint256 r, uint256 s, uint256[5] memory extKpub) public view returns(bool flag){

       return  SCL_EIP6565.Verify( m,  r,  s,  extKpub) ;

    } 

   
    function eddsa_sign(uint256 secret_seed, string memory m) public view  returns(uint256 r, uint256 s){
       return  SCL_EIP6565_UTILS.SignSlow( secret_seed, m) ;
    }


}


contract Script_Deploy_SCL is BaseScript {
    function run() external broadcast returns (address addressOfLibrary) {
        // deploy the library contract and return the address
        addressOfLibrary = address(new SCL_EIP6565_wrapper{salt: 0}());
    }
}