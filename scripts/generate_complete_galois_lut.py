#!/usr/bin/env python3
"""
Complete Galois Element Generator Script
Generates both the Python script and SystemVerilog module for CKKS Galois automorphism
"""

def extended_gcd(a, b):
    """Extended Euclidean Algorithm to find gcd and coefficients"""
    if a == 0:
        return b, 0, 1
    gcd, x1, y1 = extended_gcd(b % a, a)
    x = y1 - (b // a) * x1
    y = x1
    return gcd, x, y

def mod_inverse(a, m):
    """Find modular inverse of a modulo m"""
    gcd, x, y = extended_gcd(a, m)
    if gcd != 1:
        return None  # Modular inverse doesn't exist
    return (x % m + m) % m

def generate_complete_galois_generator(N=256):
    """Generate complete SystemVerilog file for galois_element_generator"""
    TWO_N = 2 * N  # 512 for N=256
    
    # Generate Galois elements (5^r mod 2N)
    galois_values = []
    galois_inv_values = []
    current = 1  # 5^0 = 1
    
    for i in range(N):
        galois_values.append(current)
        
        # Compute modular inverse of current galois element mod N
        inv = mod_inverse(current, N)
        if inv is None:
            print(f"ERROR: No inverse exists for {current} mod {N} at index {i}")
            inv = 0
        galois_inv_values.append(inv)
        
        current = (current * 5) % TWO_N
    
    # Generate complete SystemVerilog file with exact same interface
    sv_content = f"""`timescale 1ns / 1ps
`include "../ntt/params.vh"

module galois_element_generator #(
	parameter N = `N,
	parameter K = `K
) (
	input logic				clk,
	input logic				reset,
	input logic				enable,
	input logic [$clog2(N) - 1 : 0]		rotation_steps,
	
	output logic [$clog2(2 * N) - 1 : 0]	galois_element,
	output logic [$clog2(2 * N) - 1 : 0]	galois_element_inverse
);

	localparam ADDR_WIDTH = $clog2(N);
	localparam GALOIS_WIDTH = $clog2(2 * N) + 1;

	logic [GALOIS_WIDTH - 1 : 0]		galois_lut [N - 1 : 0];
	logic [GALOIS_WIDTH - 1 : 0]		galois_inv_lut [N - 1 : 0];

    // Galois Element LUT: 5^r mod 2N for r = 0 to N-1
    initial begin"""

    # Add galois_lut entries
    for i in range(N):
        sv_content += f"\n        galois_lut[{i}] = {galois_values[i]};"
    
    sv_content += "\n    end\n\n    // Galois Inverse LUT: (5^r)^(-1) mod N for r = 0 to N-1\n    initial begin"
    
    # Add galois_inv_lut entries
    for i in range(N):
        sv_content += f"\n        galois_inv_lut[{i}] = {galois_inv_values[i]};"
    
    sv_content += """
    end

	assign galois_element = enable ? galois_lut[rotation_steps] : '0;
	assign galois_element_inverse = enable ? galois_inv_lut[rotation_steps] : '0;
endmodule"""
    
    return sv_content, galois_values, galois_inv_values

def main():
    print("🚀 Generating corrected galois_element_generator.sv...")
    print("   This will replace the old module with correct inverse LUT values")
    
    sv_content, galois_vals, galois_inv_vals = generate_complete_galois_generator(256)
    
    # Write to SystemVerilog file
    output_file = "/home/da999/AMD_open_hardware/FPGA/the_one/second/Aurva/rtl/automorphism/galois_element_generator.sv"
    with open(output_file, 'w') as f:
        f.write(sv_content)
    
    print(f"✅ Successfully generated {output_file}")
    print(f"   Module interface unchanged - drop-in replacement!")
    
    # Print verification for key values
    print(f"\n📊 Verification (key rotation values):")
    for i in [0, 1, 2, 3, 6, 10]:
        galois = galois_vals[i]
        inverse = galois_inv_vals[i]
        check = (galois * inverse) % 256
        status = "✅" if check == 1 else "❌"
        print(f"   rotation_steps={i}: galois={galois}, inverse={inverse} -> check: ({galois} * {inverse}) mod 256 = {check} {status}")
    
    # Verify all inverses
    errors = 0
    for i in range(256):
        check = (galois_vals[i] * galois_inv_vals[i]) % 256
        if check != 1:
            errors += 1
    
    if errors == 0:
        print(f"✅ All 256 inverse values verified successfully!")
        print(f"\n🎯 Expected output for rotation_steps=1:")
        print(f"   galois_element_inverse = {galois_inv_vals[1]}")
        print(f"   First few source indices: ", end="")
        for k in range(8):
            src = (galois_inv_vals[1] * k) % 256
            print(f"{src}, ", end="")
        print("...")
    else:
        print(f"❌ Found {errors} errors in inverse calculations!")
        return False
    
    print(f"\n🔧 Integration: Just replace the old module - no interface changes needed!")
    return True

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)