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


import {  ed25519 } from '@noble/curves/ed25519';
import { secp256k1 } from '@noble/curves/secp256k1';

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


        GetX(bytes_Point){
          if (this.curve === 'secp256k1') {
            return bytes_Point.slice(1,33);
          }
          if (this.curve === 'ed25519') {
            bytes_Point[0]=bytes_Point[0]&1;
            return bytes_Point;
        }
        }

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
            if( (RawHex_Point[0]&&1)==0x01)
                {
                  return false;
                }
                else 
                  return true;
            }
        }

    EqualsX(Point1, Point2){

            return true;
          }    

    //compress a point
    PointCompress(Point){
        if (this.curve === 'secp256k1') {//expecting a 33 bytes value, first byte is 0x02 or 0x03 according to parity
            return Point.toRawBytes();
          } else if (this.curve === 'ed25519') {//expecting a 32 bytes value, msb bit stores parity
            return Point.toRawBytes();;(tag, message);
          } else {
            throw new Error('Unsupported curve');
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

    PointDecompress(bytePoint){
        if (this.curve === 'secp256k1') {//expecting a 33 bytes value, first byte is 0x02 or 0x03 according to parity
            return secp256k1.ProjectivePoint.fromHex(bytePoint);
          } else if (this.curve === 'ed25519') {//expecting a 32 bytes value, msb bit stores parity
            return ed25519.ExtendedPoint.fromHex(bytePoint);(tag, message);
          } else {
            throw new Error('Unsupported curve');
          }
    }


}