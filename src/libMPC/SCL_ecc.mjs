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
/* Description: A wrapper of ecc functions                              
/********************************************************************************************/


import { etc, utils, getPublicKey } from '@noble/secp256k1';

import {  ed25519 } from '@noble/curves/ed25519';
import { secp256k1 } from '@noble/curves/secp256k1';
import { reverse, int_from_bytes, int_to_bytes } from './common.mjs';

import { randomBytes } from 'crypto'; // Use Node.js's crypto module

// Utility to handle different curves
export class SCL_ecc
{
    constructor(curve) {
        this.curve = curve;
  
        if (this.curve === 'secp256k1') {
          this.order=secp256k1.CURVE.n;
        } else if (this.curve === 'ed25519') {
          this.order=ed25519.CURVE.n;
        } else {
          throw new Error('Unsupported curve');
        }
    }

    IndividualPubKey_array(scalar_array){
      
      if (this.curve === 'secp256k1') {
        const publicKey = getPublicKey(scalar_array); 
        return publicKey;
      }
      if (this.curve === 'ed25519') {
        const publicKey = this.GetBase().multiply(int_from_bytes(scalar_array)); // 'true' for compressed format
        return this.PointCompress(publicKey);//the getPublicKey is replaced by a scalar multiplication to be compatible with key aggregation
      }
  
      throw new Error('Unsupported curve');
    }

        GetBase(){
            if (this.curve === 'secp256k1') {
                return secp256k1.ProjectivePoint.BASE;
            }    
            if (this.curve === 'ed25519') {
                
                return ed25519.ExtendedPoint.BASE;
            }
    
            throw new Error('Unsupported curve');
        }
    
        GetZero(){
            if (this.curve === 'secp256k1') {
                return secp256k1.ProjectivePoint.ZERO;
            }    
            if (this.curve === 'ed25519') {
                return ed25519.ExtendedPoint.ZERO;
            }
    
            throw new Error('Unsupported curve');
        }    

        Get_Random_privateKey(){
          if (this.curve === 'secp256k1') {
            return secp256k1.utils.randomPrivateKey();
          }    
          if (this.curve === 'ed25519') {
            let tmp= (int_from_bytes(Buffer.from(randomBytes(64)))%ed25519.CURVE.n);
            return Buffer.from(int_to_bytes(tmp, 32));
          }

          throw new Error('Unsupported curve');
        }

        GetX(bytes_Point){
          if (this.curve === 'secp256k1') {
            return bytes_Point.slice(1,33);
          }
          if (this.curve === 'ed25519') {
            let cp=Buffer.from([...bytes_Point]);

            cp[0]=cp[0]&0x7f;//force parity bit to 0
            return cp;
        }
        }

       //return the parity of compressed coordinates (x in weierstrass representation, y for edwards) 
       Has_even_y(RawHex_Point){
        if (this.curve === 'secp256k1') {
            if(RawHex_Point[0]==0x03)
            {
              return false;
            }
            else 
              return true;
        }
        if (this.curve === 'ed25519'){
            if( ( (RawHex_Point[0]&(0x80))==0x80))
                {
                  return false;
                }
                else { 
                  return true;
                }
            }
        }

        Force_Even(Point){//if a point has odd parity coordinates, negates it
          let Pc=this.PointCompressXonly(Point);
          return this.PointDecompressEven(Pc);
        }

    EqualsX(Point1, Point2){

            return true;
          }    

    //compress a point, keeping parity information
    PointCompress(Point){
        if (this.curve === 'secp256k1') {//compress to a 33 bytes value, first byte is 0x02 or 0x03 according to parity
            return Point.toRawBytes();
          } else if (this.curve === 'ed25519') {//compress to a 32 bytes value, msb bit stores parity, noble use lsb rep, so it is reversed here
            return (Point.toRawBytes()).reverse();//reverse is required to keep msb representation
          } else {
            throw new Error('Unsupported curve');
          }
    }
    
     //compress a point, keeping parity information
     PointCompressXonly(Point){
      if (this.curve === 'secp256k1') {//compress to a 33 bytes value, first byte is 0x02 or 0x03 according to parity
        
          let R =this.PointCompress(Point);//sG-eP, compressed
          if(this.Has_even_y(R)!=true){
              console.log("parity fail");
              return false;
          }
          return R.slice(1,33);
        } else if (this.curve === 'ed25519') {//compress to a 32 bytes value, msb bit stores parity, noble use lsb rep, so it is reversed here
          let bytePoint=(Point.toRawBytes()).reverse();
          bytePoint[0]=bytePoint[0]&0x7f;
          return bytePoint;//reverse is required to keep msb representation
        } else {
          throw new Error('Unsupported curve');
        }
     }

    //takes as input a msb compressed key and return an even Xonly key 
    ForceXonly(bytePoint){
      if (this.curve === 'secp256k1') {
        return  bytePoint.slice(1,33);//x-only version for noncegen
      }
      if(this.curve=='ed25519') {
        let cp=Buffer.from([...bytePoint]);//avoid destruction of input
        cp[0]=cp[0]&0x7f;//force parity bit to 0
        return cp;
      }

    } 

    PointCompressExt(Point){
        if (this.curve === 'secp256k1') {
        if(secp256k1.ProjectivePoint.ZERO.equals(Point)) 
            return Buffer.from("000000000000000000000000000000000000000000000000000000000000000000",'hex');//infty encoded as  "OO" vector of size 33
        }
        if (this.curve === 'ed25519') {
            if(ed25519.ExtendedPoint.ZERO.equals(Point)) 
                return Buffer.from("0000000000000000000000000000000000000000000000000000000000000000",'hex');//infty encoded as  "OO" vector of size 32
            }
        return this.PointCompress(Point);    

    }

    //in both case, it is assumed a MSB representation of the point (noble uses lsb for ed25519) on 32 bytes
    //the point is assumed to have even decompressed coordinates
    PointDecompressEven(bytePointX){
      
      if (this.curve === 'secp256k1') {
        let RawP= Buffer.concat([ Buffer.from("02",'hex'), bytePointX]);//force parity byte to 0
        let P=this.PointDecompress(RawP);//extract even public key of coordinates x=pubkey

        return P;
      }
      if (this.curve === 'ed25519') {
        let cp=Buffer.from([...bytePointX]);//avoid destruction of input
        cp[0]=cp[0]&0x7f;//force parity bit to 0
        
        return ed25519.ExtendedPoint.fromHex(reverse(cp));
      }
      throw new Error('Unsupported curve');
    }

    //in both case, it is assumed a MSB representation of the point (noble uses lsb for ed25519)
    PointDecompress(bytePoint){
        if (this.curve === 'secp256k1') {//expecting a 33 bytes value, first byte is 0x02 or 0x03 according to parity
            return secp256k1.ProjectivePoint.fromHex(bytePoint);
          } else if (this.curve === 'ed25519') {//expecting a 32 bytes value, msb bit stores parity
            
            return ed25519.ExtendedPoint.fromHex(reverse(bytePoint));
          } else {
            throw new Error('Unsupported curve');
          }
    }


}