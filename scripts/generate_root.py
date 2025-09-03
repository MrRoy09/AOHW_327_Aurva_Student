def is_primitive_root(r, n, q):
    # Check if r^n ≡ 1 mod q and r^(n/2) ≠ 1 mod q
    if pow(r, n, q) != 1:
        return False
    if pow(r, n // 2, q) == 1:
        return False
    return True

def find_root(n, q):
    assert (q - 1) % n == 0
    exponent = (q - 1) // n
    for g in range(2, q):
        r = pow(g, exponent, q)
        if is_primitive_root(r, n, q):
            return r
    return None

N = 256
Q = 132120577

root = find_root(N, Q)
print(f"root = {root}")
print(f"root_pw = {N}")
