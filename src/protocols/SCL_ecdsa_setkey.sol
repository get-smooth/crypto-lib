/********************************************************************************************/
/*
/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
/* License: This software is licensed under MIT License (and allways will)                                        
/********************************************************************************************/
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.19 <0.9.0;


import { p, a,b, gx, gy,  gpow2p128_x, gpow2p128_y, n, pMINUS_2, nMINUS_2 } from "@solidity/include/SCL_field.h.sol"; 
import { ec_Normalize} from "@solidity/elliptic/SCL_gensw.sol";

    /// @notice Check the validity of a Public keys
    /// @param qx The x value of the public key Q used for the signature
    /// @param qy The y value of the public key Q used for the signature
    /// @dev Note The public key is assumed to belong to the curve and not neutral, additional weak keys are rejected 

function ecdsa_checkpub(uint256 qx, uint256 qy) 
pure returns (bool)
{
  // check the validity of the range related to prime field characteristic
         if (qx == 0 || qx >= p || qy == 0 || qy >= p) {
            return false;
        }
 // check the curve equation
        uint256 LHS = mulmod(qy, qy, p); // y^2
        uint256 RHS = addmod(mulmod(mulmod(qx, qx, p), qx, p), mulmod(qx, a, p), p); // x^3+ax
        RHS = addmod(RHS, b, p); // x^3 + a*x + b

        return LHS == RHS;
}

    /// @notice Precompute (uint256 q2p128_x, uint256 q2p128_y) =2**128.Q
    /// @param qx The x value of the public key Q used for the signature
    /// @param qy The y value of the public key Q used for the signature
    /// @dev Note It is assumed that the order of Q is not divided by a power of 2 
 
function ecdsa_extendpub(uint256 qx, uint256 qy) 
view returns (uint256 q2p128_x, uint256 q2p128_y)
{
  uint256 cpt=128;
  uint256 qzz=1;
  uint256 qzzz=1;

  assembly{
        
         //non homogeneous doubling for neutral point, but as Q order is not divided by a power of 2, neutral exception cannot be reached
         function ecDbl(x, y, zz, zzz) -> _x, _y, _zz, _zzz{
            let T1 := mulmod(2, y, p) //U = 2*Y1, y free
                let T2 := mulmod(T1, T1, p) // V=U^2
                let T3 := mulmod(x, T2, p) // S = X1*V
                T1 := mulmod(T1, T2, p) // W=UV
                let T4 := addmod(mulmod(3, mulmod(x,x,p),p),mulmod(a,mulmod(zz,zz,p),p),p)//M=3*X12+aZZ12  
                _zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                _zz := mulmod(T2, zz, p) //zz3=V*ZZ1

                _x := addmod(mulmod(T4, T4, p), mulmod(pMINUS_2, T3, p), p) //X3=M^2-2S
                T2 := mulmod(T4, addmod(_x, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)
                _y := addmod(mulmod(T1, y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd
                _y := sub(n, _y)
         }
         for {} iszero(cpt) { cpt:=sub(cpt,1) }{
            qx, qy, qzz, qzzz := ecDbl(qx, qy, qzz, qzzz)
         }
  }
  (q2p128_x, q2p128_y)=ec_Normalize(qx, qy, qzz, qzzz);

}