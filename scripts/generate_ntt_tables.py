from sympy import mod_inverse, isprime, primitive_root
from pathlib import Path

N = 256
Q = 132120577

assert isprime(Q)
assert (Q - 1) % N == 0
assert (Q - 1) % (2 * N) == 0

g = primitive_root(Q)
w = pow(g, (Q - 1) // N, Q)
psi = pow(g, (Q - 1) // (2 * N), Q)
winv = mod_inverse(w, Q)
psiinv = mod_inverse(psi, Q)

def gen_table(root, size):
    return [pow(root, i, Q) for i in range(size)]

W_table = gen_table(w, N)
Winv_table = gen_table(winv, N)
Psi_table = gen_table(psi, N)
Psiinv_table = gen_table(psiinv, N)

combined_values = W_table + Winv_table + Psi_table + Psiinv_table

def make_coe_file(values, radix=10):
    content = f"memory_initialization_radix = {radix};\nmemory_initialization_vector =\n"
    content += ",\n".join(str(v) for v in values)
    content += ";\n"
    return content

output_path = Path("../ntt/NTT_tables.coe")
output_path.write_text(make_coe_file(combined_values))
print(f".coe file written to: {output_path.resolve()}")
