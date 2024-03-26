/********************************************************************************************/
/*
/*     ___                _   _       ___               _         _    _ _    
/*    / __|_ __  ___  ___| |_| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__ 
/*    \__ \ '  \/ _ \/ _ \  _| ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
/*   |___/_|_|_\___/\___/\__|_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
/*                                         |__/|_|           
/*              
/* Copyright (C) 2023 - Renaud Dubois - This file is part of SCL (Smooth CryptoLib) project
/* License: This software is licensed under MIT License                                        
/********************************************************************************************/
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import "@solidity/hash/SCL_sha512.sol";

contract SCL_sha512Test is Test {

    function test_k512()public view{
        SCL_sha512.SHA512_CTX memory ctx=SCL_sha512.Sha_Init();
        bytes memory _k512=SCL_sha512.K512;

        uint64 cst=SCL_sha512.k512(ctx, 79);
        //assertEq(0x6c44198c4a475817, cst);//last value of k512
        uint j=79;
        assembly{
            cst:=shr(192,mload(add(add(_k512, 32),mul(8,j))))
        }
        console.log("read: %x",cst);
    }

    function test_abc() public view{
        uint64[16] memory buffer;
        buffer[0] = 0x6162638000000000; //"message abc";
        buffer[15] = 0x18; //"padding"
        uint256[2] memory res;

        (res[0], res[1]) = SCL_sha512.SHA512(buffer);
        console.log("res %x %x ", res[0], res[1]);
        //expected by https://asecuritysite.com/encryption/md5?word=abc: 
        //DDAF35A193617ABACC417349AE20413112E6FA4E89A97EA20A9EEEE64B55D39A2192992A274FC1A836BA3C23A3FEEBBD454D4423643CE80E2A9AC94FA54CA49F

    }

    //validate core sha this vector corresponds to the third vector of RFC8032
     //intermediate values obtained through simultations with python
    //input to h: 0x0x6291d657deec24024827e69c3abe01a30ce548a284743a445e3680d7db5ac3acfc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025af82
    //66 bytes=0x210 bits
    //h=0xbf62c3fb850acebf2d240df6fe5f136359ab6728da6056e3c6ddabb4ae5748549ec08df799a1bc959b0558f8675832c0648b4a939956f62e8ff39319ffb4bf09
    //h mod q= 0x60ab51a60e3f1ceb60549479b152ae2f4a41d9dd8da0f6c3ef2892d51118e95

    function test_SHA512_ed25519_3() public {
        uint256[2] memory res;
        uint64[16] memory buffer;

        //Rs, A, msg
        buffer[0] = 0x6291d657deec2402;//Rs
        buffer[1] = 0x4827e69c3abe01a3;
        buffer[2] = 0x0ce548a284743a44;//
        buffer[3] = 0x5e3680d7db5ac3ac;
        buffer[4] = 0xfc51cd8e6218a1a3;//pubY
        buffer[5] = 0x8da47ed00230f058;
        buffer[6] = 0x0816ed13ba3303ac;
        buffer[7] = 0x5deb911548908025;
        buffer[8] = 0xaf82800000000000;
        buffer[15] = 0x210; //padding, 66bytes=0x210 bits
        console.log("buffer:");
        for(uint i=0;i<16;i++){
            console.log("%x",buffer[i]);
        }
        for(uint i=0;i<10;i++){
        (res[0], res[1]) = SCL_sha512.SHA512(buffer);
         }
        //console.log("hash=%x %x", res[0], res[1]);
        res = SCL_sha512.Swap512(res); //endianness curse
       
        //16962727616734173323702303146057009569815335830970791807500022961899349823996 is pubY
        //=0x258090481591eb5dac0333ba13ed160858f03002d07ea48da3a118628ecd51fc
        assertEq(res[0], 0xbf62c3fb850acebf2d240df6fe5f136359ab6728da6056e3c6ddabb4ae574854);
        assertEq(res[1], 0x9ec08df799a1bc959b0558f8675832c0648b4a939956f62e8ff39319ffb4bf09);
    }

    function test_SHA512_ed25519_3_2() public{
        uint256[2] memory res;
        uint256 A=0x258090481591eb5dac0333ba13ed160858f03002d07ea48da3a118628ecd51fc;
        uint256 r=0xacc35adbd780365e443a7484a248e50ca301be3a9ce627480224ecde57d69162;// r after before forcing msb
        //uint256 s=0x0ac41eeacebe27c08dd26e71e9157c4a59c64d9860f767ae90f2168d539bff18;
        bytes memory msgo=hex"af82";
        uint256 temp;
        uint64[16] memory tampon;
        tampon=SCL_sha512.eddsa_sha512(r,A,msgo);
        console.log("tampon:");
        for(uint i=0;i<16;i++){
            console.log("%x",tampon[i]);
        }
        assembly{
            temp:=mload(add(32,msgo))
        }
        console.log("lengz=%d temp=%x",msgo.length, temp);

           //console.log("hash=%x %x", res[0], res[1]);
        (res[0], res[1]) = SCL_sha512.SHA512(tampon);
        res= SCL_sha512.Swap512(res); //endianness curse
       
        console.log(res[0]);
        assertEq(res[0], 0xbf62c3fb850acebf2d240df6fe5f136359ab6728da6056e3c6ddabb4ae574854);
        assertEq(res[1], 0x9ec08df799a1bc959b0558f8675832c0648b4a939956f62e8ff39319ffb4bf09);
    }

    function test_SHA512_ed25519_3_3() public{
        uint256[2] memory res;
        uint256 A=0x258090481591eb5dac0333ba13ed160858f03002d07ea48da3a118628ecd51fc;
        uint256 r=0x2eee1d83a93b0aa1fc9403ece9a3a53ef80a2abce6af8d22a52eecff374e97aa;// r value after forcing msb
        //uint256 s=0x0ac41eeacebe27c08dd26e71e9157c4a59c64d9860f767ae90f2168d539bff18;
        bytes memory msgo=hex"af82caca";
        uint256 temp;
        uint64[16] memory tampon;
        tampon=SCL_sha512.eddsa_sha512(r,A,msgo);
        console.log("tampon:");
        for(uint i=0;i<16;i++){
            console.log("%x",tampon[i]);
        }
        assembly{
            temp:=mload(add(32,msgo))
        }
        console.log("lengz=%d temp=%x",msgo.length, temp);

           //console.log("hash=%x %x", res[0], res[1]);
        (res[0], res[1]) = SCL_sha512.SHA512(tampon);
        res= SCL_sha512.Swap512(res); //endianness curse
       
        console.log("%x",res[0]);
        //0xd2b6dab72047e62cf39f03e531e25d1df9e0a5e6f757678a57697f51fa23cc4ddddee3306d2adeda7ea3d0361c7f346711f421db627f43316c08653bb54504d0

       assertEq(res[0], 0xd2b6dab72047e62cf39f03e531e25d1df9e0a5e6f757678a57697f51fa23cc4d);
       assertEq(res[1], 0xdddee3306d2adeda7ea3d0361c7f346711f421db627f43316c08653bb54504d0);
    }


}

