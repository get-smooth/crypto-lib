"""Vecteurs pour les moteurs SCL : ecGenMulmuladdB4W et ecGenMulmuladdX_store sur P-256 (a=-3),
secp256k1 (a=0), Wei25519 (a generique) et BabyJubJub (modele a=-3), ECDSA P-256 avec 2^128.Q precalcule.
usage: python3 scl_vec.py <out.json> [courbe ...]
avec une liste de courbes, seules celles-ci sont regenerees dans <out.json>, le reste est conserve."""
import hashlib, json, os, secrets, sys
import rare_cases
import bjj

CURVES = {
    "p256": dict(p=0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF,
                 a=0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC,
                 b=0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B,
                 g=(0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296,
                    0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5),
                 n=0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551),
    "k1": dict(p=0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F, a=0, b=7,
               g=(0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798,
                  0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8),
               n=0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141),
    "wei25519": dict(p=0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed,
                     a=19298681539552699237261830834781317975544997444273427339909597334573241639236,
                     b=55751746669818908907645289078257140818241103727901012315294400837956729358436,
                     g=(0x2aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaad245a,
                        0x20ae19a1b8a086b4e01edd2c7748d14c923d4d7e6d7c61b229e9c5a27eced3d9),
                     n=0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed),
    "bjj": dict(p=bjj.r, a=bjj.r - 3, b=bjj.b_iso, g=bjj.G, n=bjj.l),
}


class Curve:
    def __init__(self, p, a, b, g, n):
        self.p, self.a, self.b, self.G, self.n = p, a, b, g, n
        assert (g[1] ** 2 - g[0] ** 3 - a * g[0] - b) % p == 0

    def add(self, P, Q):
        p = self.p
        if P is None: return Q
        if Q is None: return P
        if P[0] == Q[0]:
            if (P[1] + Q[1]) % p == 0: return None
            lam = (3 * P[0] * P[0] + self.a) * pow(2 * P[1], -1, p) % p
        else:
            lam = (Q[1] - P[1]) * pow(Q[0] - P[0], -1, p) % p
        x = (lam * lam - P[0] - Q[0]) % p
        return (x, (lam * (P[0] - x) - P[1]) % p)

    def mul(self, k, P):
        R = None
        k %= self.n
        while k:
            if k & 1: R = self.add(R, P)
            P = self.add(P, P)
            k >>= 1
        return R


def H(v): return hex(v)


only = sys.argv[2:]
out = json.load(open(sys.argv[1])) if only and os.path.exists(sys.argv[1]) else {}
for name, prm in CURVES.items():
    if only and name not in only:
        continue
    C = Curve(**prm)
    n = C.n
    rnd = lambda: secrets.randbelow(n - 1) + 1
    cases = [(rnd(), rnd(), rnd()) for _ in range(16)]
    cases += [(rnd(), rnd(), 0), (rnd(), 0, rnd()), (rnd(), n - 1, n - 1), (rnd(), 1, 1)]
    for _ in range(3):
        q, u = rnd(), rnd()
        cases.append((q, u, (-u) * pow(q, -1, n) % n))
    cases += rare_cases.extra(n)
    cases += rare_cases.extra_b4(n)
    d = {k: [] for k in ("qx", "qy", "q128x", "q128y", "u", "v", "x", "y")}
    for q, u, v in cases:
        Q = C.mul(q, C.G)
        Q128 = C.mul(1 << 128, Q)
        R = C.add(C.mul(u, C.G), C.mul(v, Q)) or (0, 0)
        for k, val in zip(d, (Q[0], Q[1], Q128[0], Q128[1], u, v, R[0], R[1])):
            d[k].append(H(val))
    G128 = C.mul(1 << 128, C.G)
    d["curve"] = [H(C.p), H(C.a), H(C.b), H(C.G[0]), H(C.G[1]), H(G128[0]), H(G128[1]), H(n)]
    out[name] = d

# ECDSA P-256 : signatures valides et alterees, cles avec 2^128.Q
if only and "ecdsa" not in only:
    json.dump(out, open(sys.argv[1], "w"))
    print({k: len(v["u"]) for k, v in out.items() if k != "ecdsa"})
    sys.exit()
C = Curve(**CURVES["p256"])
n = C.n
e = {k: [] for k in ("h", "r", "s", "qx", "qy", "q128x", "q128y", "ok")}
for i in range(32):
    dk = secrets.randbelow(n - 1) + 1
    Q = C.mul(dk, C.G)
    Q128 = C.mul(1 << 128, Q)
    h = int.from_bytes(hashlib.sha256(secrets.token_bytes(32)).digest(), "big")
    k = secrets.randbelow(n - 1) + 1
    r = C.mul(k, C.G)[0] % n
    s = pow(k, -1, n) * (h + r * dk) % n
    ok = 1
    if i % 4 == 3:
        h ^= 1 << secrets.randbelow(256)
        ok = 0
    for kk, val in zip(e, (h, r, s, Q[0], Q[1], Q128[0], Q128[1], ok)):
        e[kk].append(H(val))
out["ecdsa"] = e
json.dump(out, open(sys.argv[1], "w"))
print({k: len(v["u"]) for k, v in out.items() if k != "ecdsa"}, "ecdsa", len(e["h"]))
