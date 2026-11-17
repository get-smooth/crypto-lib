"""BabyJubJub vectors for test/libSCL_babyjujub.t.sol (random values from secrets).
- w8: circomlib keys A (keys.json) -> W8 = phi(8A) and 2^128.W8,
- weak: raw signatures for crafted keys 8A = c.B8 whose window table is degenerate, in the joint 2-bit window
  (ecGenMulmuladdB4W) or in the 4-dimensional table (ecGenMulmuladdX_store), with an altered copy each.
usage: python3 bjj_vec.py <keys.json> <out.json>"""
import json, secrets, sys

from bjj import l, B8, G, ed_mul, ed2w, w_mul

K = 1 << 128
H = lambda v: hex(v)


def solve(P1, P2):
    """values of c making the addition P1 + P2 degenerate (P1 = +/-P2), P = (alpha, beta) means alpha.G + beta.c.G"""
    out = set()
    for sg in (1, -1):
        db = (P1[1] - sg * P2[1]) % l
        da = (sg * P2[0] - P1[0]) % l
        if db:
            out.add(da * pow(db, -1, l) % l)
    return out


def table_w():
    """addition chain of the joint 2-bit window table (same order as the generated engine)"""
    G_, Q = (1, 0), (0, 1)
    add = lambda P, R: (P[0] + R[0], P[1] + R[1])
    ops = [(Q, G_)]  # Q+G
    pts = [(2, 0), (3, 0), (0, 2), (0, 3), add(Q, G_)]
    for k in (1, 2, 3):
        src = (1, k) if k == 1 else (0, k)
        if k > 1:
            ops.append((src, G_))
            src = add(src, G_)
            pts.append(src)
        for _ in range(2):
            ops.append((src, G_))
            src = add(src, G_)
            pts.append(src)
    ops.append(((0, 2), (0, 1)))  # 3Q = 2Q + Q
    return ops, pts


def table_b4():
    Gp = (1, 0)
    Gq = (K, 0)
    Q, Qq = (0, 1), (0, K)
    add = lambda P, R: (P[0] + R[0], P[1] + R[1])
    ops = [(Q, Gp), (Q, Gq), (Qq, Gp), (Qq, Gq), (Q, Qq), (add(Q, Gq), Gp), (add(Qq, Gq), Gp), (add(Q, Qq), Gp),
           (add(Q, Qq), Gq), (add(add(Q, Qq), Gq), Gp)]
    pts = [add(a, b) for a, b in ops] + [add(Gp, Gq)]
    return ops, pts


def weak_set(table):
    ops, pts = table()
    cs = set()
    for P1, P2 in ops:
        cs |= solve(P1, P2)
    for P in pts:  # entry at infinity
        cs |= solve(P, (0, 0))
    cs.discard(0)
    return cs


def chk(cs, table):
    """the degenerate entries are found by direct computation"""
    ops, pts = table()
    for c in cs:
        hit = any((a1 + b1 * c - s * (a2 + b2 * c)) % l == 0 for (a1, b1), (a2, b2) in ops for s in (1, -1))
        hit |= any((a + b * c) % l == 0 for a, b in pts)
        assert hit


cw, cb = weak_set(table_w), weak_set(table_b4)
chk(cw, table_w)
chk(cb, table_b4)
i2, i3 = pow(2, -1, l), pow(3, -1, l)
# the library rewrites Q = +/-c.G, c in {1, 2, 3, 1/2, 3/2, 1/3, 2/3}, as (u + c.v).G: superset of the degenerate keys
small = {s * c % l for c in (1, 2, 3, i2, 3 * i2, i3, 2 * i3) for s in (1, -1)}
assert cw <= small
cw = small

keys = json.load(open(sys.argv[1]))
w8 = {k: [] for k in ("ax", "ay", "wx", "wy", "w128x", "w128y")}
for x, y in keys:
    A = (int(x), int(y))
    A8 = ed_mul(8, A)
    W, W128 = ed2w(A8), ed2w(ed_mul(K, A8))
    if W is None:
        W = W128 = (0, 0)
    for k, v in zip(w8, (A[0], A[1], W[0], W[1], W128[0], W128[1])):
        w8[k].append(H(v))

inv8 = pow(8, -1, l)
weak = {k: [] for k in ("ax", "ay", "hm", "r8x", "r8y", "s", "ok", "tag")}
for name, cs in (("w", cw), ("b4", cb)):
    for c in sorted(cs):
        A = ed_mul(c * inv8 % l, B8)  # 8A = c.B8
        assert ed2w(ed_mul(8, A)) == w_mul(c, G)
        rr = secrets.randbelow(l - 1) + 1
        hm = secrets.randbits(254)
        R8 = ed_mul(rr, B8)
        S = (rr + hm * c) % l  # S.B8 = R8 + hm.(8A)
        for ok, s in ((1, S), (0, (S + 1) % l)):
            for k, v in zip(weak, (A[0], A[1], hm, R8[0], R8[1], s, ok)):
                weak[k].append(H(v) if k != "ok" else v)
            weak["tag"].append(f"{name} 8A={H(c)}.B8" + ("" if ok else " S+1"))
json.dump({"w8": w8, "weak": weak}, open(sys.argv[2], "w"))
print(len(keys), "keys,", len(cw), "weak keys (2-bit window),", len(cb), "weak keys (4-dim),", len(weak["ok"]), "signatures")
