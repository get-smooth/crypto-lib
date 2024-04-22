#/********************************************************************************************/
#/*
#/*   ╔═╗╔╦╗╔═╗╔═╗╔╦╗╦ ╦  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗╦  ╦╔╗ 
#/*   ╚═╗║║║║ ║║ ║ ║ ╠═╣  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║║  ║╠╩╗
#/*   ╚═╝╩ ╩╚═╝╚═╝o╩ ╩ ╩  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝╩═╝╩╚═╝
#/*              
#/* Copyright (C) 2024 - Renaud Dubois - This file is part of SCL (Smoo.th CryptoLib) project
#/* License: This software is licensed under MIT License (and allways will)   
#/* Description: Producing a secure palindromic elliptic curve for Easter 2024                   
#/********************************************************************************************/
#// SPDX-License-Identifier: MIT
load('SCL_elliptic.sage');

p=0x1000000000000000000000000040001000400000000000000000000000001;


b= (1<<224)+(1<<112)+1;
flag=false;

while flag == false:
    b=(1<<224)+(1<<112)+1+(randrange(1,254)<<112);

    r=randrange(4, 14)
    v=1<<(randrange(1,7));
    coeff_a=b+(v<<(8*r))+(v<<(224-8*r))

    r=randrange(4, 14)
    v=1<<(randrange(1,7));
    coeff_b=b+(v<<(8*r))+(v<<(224-8*r))

   
   
    Curve=EllipticCurve(GF(p), [coeff_a, coeff_b]);
    print("Curve",Curve);
    q=Curve.order();
    print("q=",hex(coeff_a), hex(coeff_b),q);
    flag=is_prime(q);
   
print(hex(coeff_a), hex(coeff_b), hex(q))

#EECC2024, easter egg crypto curve 2024
#paste me here:https://sagecell.sagemath.org/
p=0x1000000000000000000000000040001000400000000000000000000000001;
a=0x1000000000000000000000020005b0020000000000000000000000001 ;
b=0x1000000000000000002000000005b0000000002000000000000000001;
x=0x1000000000000000000000000000000000000000000000000000000000001;

y2=GF(p)(x**3+a*x+b);
is_square(y2);

EFp=EllipticCurve(GF(p), [a, b]);
q=EFp.order();
is_prime(q)

t=(p+1-q);
qtwist=p+1+t;

is_prime(qtwist))
