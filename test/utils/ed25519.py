## modified from RFC8032 source to provide intermediary results for solidity validation

## First, some preliminaries that will be needed.

import hashlib

def sha512(s):
    return hashlib.sha512(s).digest()

# Base field Z_p
p = 2**255 - 19

def modp_inv(x):
    return pow(x, p-2, p)

# Curve constant
d = -121665 * modp_inv(121666) % p

# Group order
q = 2**252 + 27742317777372353535851937790883648493

def sha512_modq(s):
    print("hash not reduced:",hex(int.from_bytes(sha512(s), "little")))
    print("h:",hex(int.from_bytes(sha512(s), "little") % q))
   
    return int.from_bytes(sha512(s), "little") % q

## Then follows functions to perform point operations.

# Points are represented as tuples (X, Y, Z, T) of extended
# coordinates, with x = X/Z, y = Y/Z, x*y = T/Z

def point_add(P, Q):
    A, B = (P[1]-P[0]) * (Q[1]-Q[0]) % p, (P[1]+P[0]) * (Q[1]+Q[0]) % p;
    C, D = 2 * P[3] * Q[3] * d % p, 2 * P[2] * Q[2] % p;
    E, F, G, H = B-A, D-C, D+C, B+A;
    return (E*F, G*H, F*G, E*H);



# Computes Q = s * Q
def point_mul(s, P):
    Q = (0, 1, 1, 0)  # Neutral element
    while s > 0:
        if s & 1:
            Q = point_add(Q, P)
        P = point_add(P, P)
        s >>= 1
    return Q

def point_equal(P, Q):
    # x1 / z1 == x2 / z2  <==>  x1 * z2 == x2 * z1
    if (P[0] * Q[2] - Q[0] * P[2]) % p != 0:
        return False
    if (P[1] * Q[2] - Q[1] * P[2]) % p != 0:
        return False
    return True

## Now follows functions for point compression.

# Square root of -1
modp_sqrt_m1 = pow(2, (p-1) // 4, p)

print("SQRT(-1)=",hex(modp_sqrt_m1))
print("p+3 div 8",hex((p+3) // 8))

# Compute corresponding x-coordinate, with low bit corresponding to
# sign, or return None on failure
def recover_x(y, sign):
    if y >= p:
        return None
    x2 = (y*y-1) * modp_inv(d*y*y+1)
    if x2 == 0:
        if sign:
            return None
        else:
            return 0
    x = pow(x2, (p+3) // 8, p)
    if (x*x - x2) % p != 0:
        x = x * modp_sqrt_m1 % p
    if (x*x - x2) % p != 0:
        return None
    if (x & 1) != sign:
        x = p - x
    return x





# Base point
g_y = 4 * modp_inv(5) % p
g_x = recover_x(g_y, 0)
G = (g_x, g_y, 1, g_x * g_y % p)

def point_compress(P):
    zinv = modp_inv(P[2])
    x = P[0] * zinv % p
    y = P[1] * zinv % p
    print("x,y=", x,y)
    return int.to_bytes(y | ((x & 1) << 255), 32, "little")#encode parity of y

def point_decompress(s):
    if len(s) != 32:
        raise Exception("Invalid input length for decompression")
    y = int.from_bytes(s, "little")
    print("decompressing:", hex(y))
    sign = y >> 255
    y &= (1 << 255) - 1
    x = recover_x(y, sign)
    if x is None:
        return None
    else:
        return (x, y, 1, x*y % p)

## These are functions for manipulating the private key.

def secret_expand(secret):
    if len(secret) != 32:
        raise Exception("Bad size of private key")
    print("input to sha512 secret expand:", hex(int.from_bytes(secret[:32], "little")))
    h = sha512(secret)
    print("output h:", hex(int.from_bytes(h, "little")))
   
    a = int.from_bytes(h[:32], "little")
    print("output h cut:", hex(a))
   
    a &= (1 << 254) - 8
    a |= (1 << 254)
    print("output a :", hex(a))
    return (a, h[32:])

def secret_to_public(secret):
    (a, dummy) = secret_expand(secret)
    print("expanded secret:",a)
    return point_compress(point_mul(a, G))

def print_bytes_toint(comment, val):
  print(comment, hex(int.from_bytes(val,"big")))

def print_int_tobytes(val, len):
     print(int(val,16)).to_bytes(len, 'big');
     return 0;

#TBD
def is_oncurve(point):
    return false;

def normalize(point):
  x=point[0] %p;
  y=point[1] %p;
  z=point[2] %p;
  
  x=point[0]*modp_inv(point[2]) %p;
  y=point[1]*modp_inv(point[2])%p;
  z=1;
  t=(point[0] * point[1]) % p
  return (x,y,z,t);

## The signature function works as below.

def sign(secret, msg):
    a, prefix = secret_expand(secret)
    print("a=",a)
    print("prefix=", prefix)
    A = point_compress(point_mul(a, G))
    print_bytes_toint("input to sha512modq:",prefix+msg)
    r = sha512_modq(prefix + msg)
    print("r=",r)
    R = point_mul(r, G)
    print("R=", normalize(R))
    Rs = point_compress(R)
    h = sha512_modq(Rs + A + msg)
    s = (r + h * a) % q
    print("s=",s)
    return Rs + int.to_bytes(s, 32, "little")

## And finally the verification function.
	
def verify(public, msg, signature):
    if len(public) != 32:
        raise Exception("Bad public key length")
    if len(signature) != 64:	
        Exception("Bad signature length")
    A = point_decompress(public)
    print("A=",A)
    print("norm A=",normalize(A))
    if not A:
        return False
    Rs = signature[:32]
    print("Rs=",Rs)
    R = point_decompress(Rs)
    if not R:
        return False
    s = int.from_bytes(signature[32:], "little")
    if s >= q: return False
    print_bytes_toint("input to h:",Rs+public+msg)
    h = sha512_modq(Rs + public + msg)
    print("h=",hex(h));
    sB = point_mul(s, G)
    print("s=",hex(s));
    print("sb=",normalize(sB))
    hA = point_mul(h, A)
    print("hA=",normalize(hA))
    return point_equal(sB, point_add(R, hA))
    

print("G=",G); 
#reproduce RFC vectors
#-----TEST SHA(abc)
print("******-----TEST SHA(abc)")
ksec2="833fe62409237b9d62ec77587520911e9a759cec1d19755b7da901b96dca3d42";
ksec_bytes=(int(ksec2,16)).to_bytes(32, 'big');

kpub=secret_to_public(ksec_bytes)
print("kpub:",hex(int.from_bytes(kpub,"big")));

msg="ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f";
msg_bytes=(int(msg,16)).to_bytes(64, 'big');

sig=sign(ksec_bytes, msg_bytes)
print("Sig",hex(int.from_bytes(sig, "big")))
#expected=dc2a4459e7369633a52b1bf277839a00201009a3efbf3ecb69bea2186c26b58909351fc9ac90b3ecfdfbc7c66431e0303dca179c138ac17ad9bef1177331a704
print(verify(kpub, msg_bytes, sig))

#-----TEST 3	

print("******-----RFC TEST 3	")
ksec3="c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7";
ksec_bytes=(int(ksec3,16)).to_bytes(32, 'big');
kpub=secret_to_public(ksec_bytes)
print("kpub:",hex(int.from_bytes(kpub,"big")));

msg="af82";
msg_bytes=(int(msg,16)).to_bytes(2, 'big');
print("******Signature")
sig=sign(ksec_bytes, msg_bytes)
print("******Verif")
print(verify(kpub, msg_bytes, sig))
print("Sig2",hex(int.from_bytes(sig, "big")))





