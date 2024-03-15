#/********************************************************************************************/
#/*
#/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
#/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
#/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
#/*              
#/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
#/* License: This software is licensed under MIT License (and allways will)   
#/* Description: This file implements basic operations on elliptic curve                       
#/********************************************************************************************/
#// SPDX-License-Identifier: MIT


load('SCL_ellipticZoo.sage');

#//initialize elliptic curve , short weierstrass form	
def SCL_ecSetCurve(curve_characteristic,curve_a, curve_b,Gx, Gy, curve_Order):    
	Fp=GF(curve_characteristic); 				#Initialize Prime field of Point
	Fq=GF(curve_Order);					#Initialize Prime field of scalars
	Curve=EllipticCurve(Fp, [curve_a, curve_b]);		#Initialize Elliptic curve
	curve_Generator=Curve([Gx, Gy]);
	
	return [Curve,curve_Generator];


#//decompress even y from x value to point (x,y)    
def SCL_ecDecompressEven(curve, pubkey_x):    
  y2=pubkey_x**3+ curve.a4()*pubkey_x+curve.a6();
  y=sqrt(y2);
  if (int(y)%2):
   return -y;
  return y;	
  
#//decompress even y from x value to point (x,y)    
def SCL_ecDecompress(curve, pubkey_x, parity):    
  y2=pubkey_x**3+ curve.a4()*pubkey_x+curve.a6();
  y=sqrt(y2);
 
  if ((int(y)%2)!=parity):
   return -y;
  return y;	
    
def SCL_SetKey(curve,x,y):
 
 PubKey=Curve([Gx, Gy]);
 PubKey128=PubKey*2**128;#precomputed value for 4 dimensionals Shamir's trick

 return -1;



