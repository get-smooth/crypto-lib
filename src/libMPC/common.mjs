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

export function bytes_xor(a,b){
    if (a.length !== b.length) {
      throw new Error('Byte arrays must be of the same length');
    }
    let c=a;
    for(let i=0;i<a.length;i++)
      c[i]^=b[i];
  
    return c;
  }

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
          return new Uint8Array([...padding, ...bytes]);
        } else if (byteLength && bytes.length > byteLength) {
          throw new Error(`BigInt does not fit in ${byteLength} bytes.`);
        }
      
        return Buffer.from(bytes);
      }
