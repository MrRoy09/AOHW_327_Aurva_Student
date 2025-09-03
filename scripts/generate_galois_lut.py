#!/usr/bin/env python3

def generate_galois_lut(N=256):
    """Generate Galois element LUT for CKKS rotation"""
    TWO_N = 2 * N  # 512 for N=256
    
    print(f"// Galois Element LUT for N={N}, 2N={TWO_N}")
    print("// Values are 5^r mod 2N for r = 0 to N-1")
    print()
    
    # Generate all values
    galois_values = []
    current = 1  # 5^0 = 1
    
    for i in range(N):
        galois_values.append(current)
        current = (current * 5) % TWO_N
    
    # Print as SystemVerilog initial block
    print("initial begin")
    for i in range(N):
        print(f"    galois_lut[{i}] = {galois_values[i]};")
    print("end")
    
    # Verify some values
    print(f"\n// Verification:")
    print(f"// 5^0 mod {TWO_N} = {galois_values[0]}")
    print(f"// 5^1 mod {TWO_N} = {galois_values[1]}")
    print(f"// 5^2 mod {TWO_N} = {galois_values[2]}")
    print(f"// 5^6 mod {TWO_N} = {galois_values[6]}")
    print(f"// 5^10 mod {TWO_N} = {galois_values[10]}")
    
    return galois_values

if __name__ == "__main__":
    generate_galois_lut(256)