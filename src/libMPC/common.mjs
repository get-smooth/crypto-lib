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

import { createHash } from 'crypto';


export function bytes_xor(a,b){
    if (a.length !== b.length) {
      throw new Error('Byte arrays must be of the same length');
    }
    let c=a;
    for(let i=0;i<a.length;i++)
      c[i]^=b[i];
  
    return c;
  }

/********************************************************************************************/
/* ENCODINGS */
/********************************************************************************************/
//convert bytes to bigInt
export function int_from_bytes(bytes){
    return BigInt('0x' + Buffer.from(bytes).toString('hex'));
  }

  
function bytesToHex(bytes) {
    return Buffer.from(bytes).toString('hex');
  }

//todo: add a setlength
export function int_to_bytes(value, byteLength){
        if (value < 0) {
          throw new Error("Negative BigInts are not supported.");
        }
      
        // Convert BigInt to hexadecimal and remove the "0x" prefix
        let hex = value.toString(16);
      
        // Ensure the hex string has an even number of characters
        if (hex.length % 2 !== 0) {
          hex = '0' + hex;
        }
      
        // Convert hex to a Uint8Array
        const bytes = Uint8Array.from(hex.match(/.{2}/g).map(byte => parseInt(byte, 16)));
      
        // Pad the result to the desired byte length (if specified)
        if (byteLength && bytes.length < byteLength) {
          const padding = new Uint8Array(byteLength - bytes.length);
          let res= new Uint8Array([...padding, ...bytes]);
          return Buffer.from(res);
        } else if (byteLength && bytes.length > byteLength) {
          throw new Error(`BigInt does not fit in ${byteLength} bytes.`);
        }
      
        return Buffer.from(bytes);
      }

//reverse the byte endianness of a buffer (mirroring from/to lsb/msb)      
  export function reverse(msb){
    return Buffer.from([...msb].reverse());
  }

/********************************************************************************************/
/* HASHES */
/********************************************************************************************/
// Tagged hash function compliant with BIP327
// tag: str
// message: bytes 
export function tagged_hashBTC(tag, message) {
  // Convert the tag to a sha256 hash (as bytes)
  const tagHash = sha256(Buffer.from(tag, 'utf-8'));
  
  // Concatenate (encodePacked) tagHash, tagHash, and the message
  const encoded = Buffer.concat([tagHash, tagHash, message]);
 
  // Compute final sha256 hash
  const finalHash = sha256(encoded);
  
  return finalHash;
}


//look at endianness error
export function taghash_rfc8032(tag, message){
  // Convert the tag to a sha256 hash (as bytes)
  const U8tag = Buffer.from(tag, 'utf-8');
  
  // Concatenate (encodePacked) tagHash, tagHash, and the message
  let encoded = Buffer.concat([U8tag,  message]);
  
  // Compute final sha256 hash
  let finalHash = sha512(encoded);
  //swap then reduce mod q (damned endians)
  finalHash=finalHash.reverse();

  finalHash= int_from_bytes(finalHash) % BigInt('7237005577332262213973186563042994240857116359379907606001950938285454250989');


  return int_to_bytes(finalHash,32);
}


// Function to compute sha256 hash
export function sha256(data) {
  return createHash('sha256').update(data).digest();
}


// Function to compute sha256 hash
export function sha512(data) {
  return createHash('sha512').update(data).digest();
}
