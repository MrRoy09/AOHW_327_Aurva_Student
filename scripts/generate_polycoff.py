import random

q = 132120577

N = 256

filename = "polycoff.mem"

coeffs = [random.randint(0, q - 1) for _ in range(N)]

with open(filename, "w") as f:
    for coeff in coeffs:
        f.write(f"{coeff:08x}\n")
