"""Cherche des (c, u, v) qui font passer la boucle par chaque chemin rare (Q = c.G, c hors petits multiples)."""
def events(n, c, u, v):
    ev = []
    if u == 0 and v == 0:
        return ev
    i = 252
    while not ((u >> i) | (v >> i)):
        i -= 4
    b, first = 0, True
    while i >= 0:
        for sh in (2, 0):
            du, dv = (u >> (i + sh)) & 3, (v >> (i + sh)) & 3
            b = 4 * b % n
            if du or dv:
                t = (du + dv * c) % n
                if b == 0 and not first:
                    ev.append("O_mid")
                elif b != 0 and b == t:
                    ev.append("dbl")
                elif b != 0 and (b + t) % n == 0:
                    ev.append("inf")
                first = False
                b = (b + t) % n
        i -= 4
    return ev

def find(n, cs=(4, 5, 6, 7, 9, 10, 11, 12)):
    want = {"dbl": [], "inf": [], "O_mid": []}
    for c in cs:
        for u in range(0, 256):
            for v in range(0, 64):
                for e in set(events(n, c, u, v)):
                    if len(want[e]) < 4:
                        want[e].append((c, u, v))
                # grands scalaires : meme motif decale (bits hauts)
        if all(len(x) >= 4 for x in want.values()):
            break
    return want


def balanced(n, c):
    """(U, V) positifs ~sqrt(n) avec U + c.V = 0 mod n (Euclide etendu tronque)."""
    r0, r1, t0, t1 = n, c, 0, 1
    while r1 * r1 >= n:
        q = r0 // r1
        r0, r1, t0, t1 = r1, r0 - q * r1, t1, t0 - q * t1
    # r1 = t1.c mod n -> r1 - t1.c = 0 ; on veut V = -t1 > 0
    U, V = r1, -t1
    if V < 0:
        U, V = r0, -t0
    assert (U + c * V) % n == 0 and U > 0 and V > 0 and U < 1 << 130 and V < 1 << 130
    return U, V


def extra(n, cs=(0x5f1d6b2a9c3e8d4f7a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f708192a3b4c5,
                  0x3a7c9e1b5d2f4a6c8e0b1d3f5a7c9e1b2d4f6a8c0e2b4d6f8a1c3e5b7d9f0a2c)):
    """cas rares a ajouter : dbl (petits scalaires), inf en fin, O en milieu de boucle."""
    out = []
    for c in cs:
        c %= n
        U, V = balanced(n, c)
        out += [(c, U, V)]                                    # resultat O, dernier ajout -> inf
        out += [(c, (U << 124) | 0x9, (V << 124) | 0x6)]       # O au milieu puis reprise
        out += [(c, (U << 124), (V << 124) | 0x3)]
    out += [(4, 4, 1), (4, 16, 4), (4, 12, 3), (5, 20, 4), (7, 28, 4)]
    return out


def events_b4(n, c, u, v):
    """4-dim Shamir (bit i of u, u>>128, v, v>>128 together, Q = c.G): rare paths met by the loop."""
    G1 = pow(2, 128, n)
    w = [(u >> 128 * k) & ((1 << 128) - 1) for k in (0, 1)] + [(v >> 128 * k) & ((1 << 128) - 1) for k in (0, 1)]
    ev, b, first = [], 0, True
    for i in range(127, -1, -1):
        d = [(x >> i) & 1 for x in w]
        b = 2 * b % n
        if any(d):
            t = (d[0] + d[1] * G1 + c * (d[2] + d[3] * G1)) % n
            if b == 0 and not first:
                ev.append("O_mid")
            elif b != 0 and b == t:
                ev.append("dbl")
            elif b != 0 and (b + t) % n == 0:
                ev.append("inf")
            first = False
            b = (b + t) % n
    return ev


def extra_b4(n):
    """rare paths of the 4-dim loop: Q = 2G, (2,1) doubles, (n-2,1) and (n-4,2) end at infinity,
    and a prefix summing to n (A + 2B = n split on the two 128-bit halves) reaches infinity before the last digit"""
    M = (1 << 128) - 1
    N1, N0 = n >> 128, n & M
    B1, B0 = N1 // 3, N0 // 3
    A1, A0 = N1 - 2 * B1, N0 - 2 * B0
    u = (2 * A0 + 1) | ((2 * A1) << 128)
    v = (2 * B0) | ((2 * B1) << 128)
    return [(2, 2, 1), (2, n - 2, 1), (2, n - 4, 2), (2, u, v), (5, n - 5, 1)]
