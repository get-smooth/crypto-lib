/********************************************************************************************/
/*
/*     ___                _   _       ___               _         _    _ _    
/*    / __|_ __  ___  ___| |_| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__ 
/*    \__ \ '  \/ _ \/ _ \  _| ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
/*   |___/_|_|_\___/\___/\__|_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
/*                                         |__/|_|           
/*              
/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smooth CryptoLib) project
/* License: This software is licensed under MIT License                                        
/********************************************************************************************/


import {  ed25519 } from '@noble/curves/ed25519';
import{reverse, bytes_xor, int_from_bytes, int_to_bytes, tagged_hashBTC, taghash_rfc8032} from "./common.mjs";

import { secp256k1 } from '@noble/curves/secp256k1';
import { etc, utils, getPublicKey } from '@noble/secp256k1';
import{SCL_ecc} from './SCL_ecc.mjs';
import { randomBytes } from 'crypto'; // Use Node.js's crypto module
import { Field } from "@noble/curves/abstract/modular";



//beware that because horner method is used degree 0 coefficient is last of the list
function Evaluate(coeffs,x, modulus){
    let res=coeffs[0];//a0
    for(let i=1;i<coeffs.length;i++){
        res=((res*x)+(coeffs[i]))%modulus;
    }
    return res;
}

//Lagrangian interpolation in 0= prod(x_i)/prod(xj-xi)
function Interpolate(L, x_i, modulus){
        let num=BigInt(1);
        let deno=BigInt(1);

    for(let j=0;j<L.length;j++)
    {
        let x_j=L[j]
        if( x_j != x_i){
            num=(num*x_j)%modulus;
            deno=deno*(modulus+x_j-x_i)%modulus;

        }
    }
    let F=Field(BigInt(modulus));
    return (num * F.pow(deno, modulus - BigInt(2))) % modulus;
    }


export class SCL_trustedKeyGen
{
    constructor(curve,  sk, n, k) {

        this.curve=new SCL_ecc(curve);
        this.sk=sk;
    
        this.pubkey=this.curve.IndividualPubKey_array(sk);
    
        this.n=n;
        this.degree=k;
        this.min_participants=k+1;
        this.pubshares=[];
        this.secshares=[];
        this.coeffs=[];
       
        this.KeyGen(n, k+1);
        this.ids=this.secshares.map(points =>points[0]);
        
      }

      //in the future, improve it with a PRNG using secret and random generator
      GetRandomElement(){
        return this.curve.Get_Random_privateKey();
      }

      KeyGen(n, min_participants){

        if(min_participants<1) return false;

        this.n=n;//maximum number of participants
        this.degree=min_participants-1;//minimum number of participants = degree of polynomial-1


        //generate secret polynomial: 
        for(let i=this.degree;i>0;i--){
            let ai=this.GetRandomElement();
            this.coeffs.push(int_from_bytes(ai));
        }
        this.coeffs.push(int_from_bytes(this.sk));//a0=P(0)=secret
        
       
        //Shares are evaluation of P starting from 1, P(0) being the secret
        for(let xi=1;xi<this.n+1;xi++){

            let yi=Evaluate(this.coeffs, BigInt(xi), this.curve.order);
            this.secshares.push([BigInt(xi),yi]);
            this.pubshares.push(this.curve.GetBase().multiply(BigInt(yi)));
      
        }

      }

      //interpolate the points (xi,P(xi)) in 0 (group secret key)
      Interpolate_group_seckey( points ){

        let P0=BigInt(0);
        for(let i=0;i<points.length;i++){
            let x=points[i][0];
            let delta=points[i][1] * Interpolate(points.map(points =>points[0]),x, this.curve.order);//yi * interpolate(L,xi)
            P0=(P0 + delta)%this.curve.order;
        }
        return P0;
      }

      //interpolate the points (xi,P(xi).G) in 0 (group public key)
      Interpolate_group_pubkey(pubkeys, ids){
        let Q = this.curve.GetZero();
        if(pubkeys.length!=ids.length){
            return false;
        }
        for(let i=0;i<pubkeys.length;i++){
            //console.log("Pi", pubkeys[i])
            //console.log("id", ids[i])
            
            let Xi=pubkeys[i];
           // console.log("Xi", Xi);
            let lam_i = Interpolate(ids, ids[i], this.curve.order);
           // console.log("lam_i", lam_i);
           // console.log("lam_i.Xi", Xi.multiply(lam_i));
            
            Q=Q.add(Xi.multiply(lam_i));

           // console.log("trace Q:", Q)
        }
        //todo: test infty
        return this.curve.PointCompress(Q);
      }


      Check_Shares()
      {
        if (this.n<this.min_participants)
            return false;
        //check secshares.G=pubshares
        console.log(this.secshares);

        for(let i=0;i<this.n;i++){
            let recPub=this.curve.GetBase().multiply(this.secshares[i][1]);
            if(recPub.equals(this.pubshares[i])==false)
                return false;
        }

        return true;
      }



}


export class SCL_FROST{

    constructor(curve, n, k, id, sk, pubkey) {

        this.curve=new SCL_ecc(curve);
        
        this.id=id;//i
        this.sk=sk;//P(i), P unknown secret polynomial
        this.pubkey=pubkey;//P(i).G
    
        this.n=n;
        this.degree=k;
        this.min_participants=k+1;
        
      }

/********************************************************************************************/
/* NONCE GENERATION FUNCTIONS*/   
/********************************************************************************************/

//identical to Musig2, except hash domain separation
Nonce_hash(rand, pk, aggpk, i, msgPrefixed, extraIn) {
    // Buffer to concatenate all inputs
    let buf =rand; 
  
    // Append all parts to the buffer
    
    buf = Buffer.concat([buf, new Uint8Array([pk.length])]); // Length of pk (1 byte)
    buf = Buffer.concat([buf, pk]);
    buf = Buffer.concat([buf, new Uint8Array([aggpk.length])]); // Length of aggpk (1 byte)
    buf = Buffer.concat([buf, aggpk]);
    buf = Buffer.concat([buf, msgPrefixed]);
    let extraInLengthBuffer = Buffer.alloc(4);
    extraInLengthBuffer.writeUInt32BE(extraIn.length);
    buf = Buffer.concat([buf, extraInLengthBuffer]); // Length of extraIn (4 bytes)
    buf = Buffer.concat([buf, extraIn]);
    buf = Buffer.concat([buf, new Uint8Array([i])]); // Index i (1 byte)
  
    // Compute the tagged hash with 'MuSig/nonce' as the tag
    const hash = this.TagHash('FROST/nonce', buf);
    // Return the result as a BigInt
    return hash;
  }
  



}