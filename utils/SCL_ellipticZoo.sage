#/********************************************************************************************/
#/*
#/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
#/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
#/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
#/*              
#/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
#/* License: This software is licensed under MIT License (and allways will)   
#/* Description: This file implements some well known elliptic curve                             
#/********************************************************************************************/
#// SPDX-License-Identifier: MIT



#//Curve secp256r1, aka p256	
#//curve prime field modulus
sec256p_p = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
#//short weierstrass first coefficient (=a4 in sage)
sec256p_a =0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC;
#//short weierstrass second coefficient    
sec256p_b =0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B;
#//generating point affine coordinates  (=a6 in sage)  
sec256p_gx =0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296;
sec256p_gy =0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5;
#//curve order (number of points)
sec256p_n =0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;    	



#//Curve wei25519, weierstrass isogeneous to ed25519
wei25519_p = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;
#// short weierstrass first coefficient a
wei25519_a = 19298681539552699237261830834781317975544997444273427339909597334573241639236;
#// short weierstrass second coefficient 0x41a3b6bfc668778ebe2954a4b1df36d1485ecef1ea614295796e102240891faa
wei25519_b = 55751746669818908907645289078257140818241103727901012315294400837956729358436;
wei25519_gx=0x2aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaad245a;
wei25519_gy=0x20ae19a1b8a086b4e01edd2c7748d14c923d4d7e6d7c61b229e9c5a27eced3d9;
wei25519_n = 0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed;



#//Curve secp256k1, aka bitcoin curve, aka ethereum curve
sec256k_p=0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
sec256k_a=0;
sec256k_b=7;
sec256k_gx=0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798 ;
sec256k_gy=0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
sec256k_n=0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;


#//Curve StarkCurve, aka Starknet curve
stark_p=2^251+17*2^192+1     
stark_a=1;
stark_b=0x6f21413efbe40de150e596d72f7a8c5609ad26c15c915c1f4cdfcb99cee9e89;
stark_q=0x800000000000010ffffffffffffffffb781126dcae7b2321e66a241adc64d2f;
stark_gx = 0x1ef15c18599971b7beced415a40f0c7deacfd9b0d1819e03d723d8bc943cfca;
stark_gy = 0x5668060aa49730b7be4801df46ec62de53ecd11abe43a32873000c36e8dc1f;	
stark_n=0x800000000000010ffffffffffffffffb781126dcae7b2321e66a241adc64d2f;


#//Curve BabyJuJub, aka Circom curve
#//https://github.com/bellesmarta/baby_jubjub is compliant with https://github.com/iden3/circomlibjs/blob/4f094c5be05c1f0210924a3ab204d8fd8da69f49/src/babyjub.js in non reduced Ted form
#//https://github.com/iden3/circomlib/blob/master/test/babyjub.js
#//https://github.com/iden3/circomlibjs/blob/4f094c5be05c1f0210924a3ab204d8fd8da69f49/test/eddsa.js
#//here it is a twisted edwards curve:https://hyperelliptic.org/EFD/g1p/auto-twisted.html
#//generate poseidon:https://github.com/iden3/circomlibjs/blob/main/src/poseidon_gencontract.js
babyjj_p=21888242871839275222246405745257275088548364400416034343698204186575808495617;
babyjj_n=21888242871839275222246405745257275088614511777268538073601725287587578984328;
babyjj_A=168700;
babyjj_D=168696;
#//https://github.com/bellesmarta/baby_jubjub, unreduced
babyjj_gx=995203441582195749578291179787384436505546430278305826713579947235728471134;
babyjj_gy=5472060717959818805561601436314318772137091100104008585924551046643952123905;


