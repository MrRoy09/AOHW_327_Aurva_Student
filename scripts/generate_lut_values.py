#!/usr/bin/env python3

def generate_automorphism_luts():
    """
    Generate LUT values for automorphism rotations -1, -16, -17
    For N=256, galois inverse values: -1->5, -16->65, -17->13
    """
    N = 256
    
    # Galois inverse values for each rotation
    galois_inverses = {
        'neg1': 5,   # -1 rotation
        'neg16': 65, # -16 rotation  
        'neg17': 13  # -17 rotation
    }
    
    luts = {}
    
    for rotation, galois_inv in galois_inverses.items():
        lut = []
        print(f"\n// LUT for rotation {rotation.replace('neg', '-')} (galois_inverse = {galois_inv})")
        
        for i in range(N):
            # Calculate target index with MSB stripping for N=256
            target = (galois_inv * i) & 0xFF  # Mask to 8 bits (strip MSB)
            lut.append(target)
            
        luts[rotation] = lut
    
    # Generate memory initialization files
    for rotation, lut in luts.items():
        filename = f"automorphism_lut_{rotation}.mem"
        with open(filename, 'w') as f:
            f.write(f"// Automorphism LUT for rotation {rotation.replace('neg', '-')}\n")
            f.write(f"// galois_inverse = {galois_inverses[rotation]}\n")
            for i, target in enumerate(lut):
                f.write(f"{target:02X}\n")  # Write in hex format
        
        print(f"Generated {filename}")
    
    # Generate SystemVerilog parameter arrays for direct inclusion
    sv_filename = "automorphism_lut_params.vh"
    with open(sv_filename, 'w') as f:
        f.write("// Automorphism LUT parameter definitions\n")
        f.write("// Generated automatically - do not edit manually\n\n")
        
        for rotation, lut in luts.items():
            f.write(f"// LUT for rotation {rotation.replace('neg', '-')}\n")
            f.write(f"parameter logic [7:0] LUT_{rotation.upper()}[256] = {{\n")
            
            # Write in groups of 16 for readability
            for i in range(0, 256, 16):
                line_values = []
                for j in range(16):
                    if i + j < 256:
                        line_values.append(f"8'h{lut[i+j]:02X}")
                f.write("    " + ", ".join(line_values))
                if i + 16 < 256:
                    f.write(",")
                f.write(f"  // {i:3d}-{min(i+15, 255):3d}\n")
            
            f.write("};\n\n")
    
    print(f"Generated {sv_filename}")
    
    # Print first few values for verification
    print("\nFirst 10 LUT values for verification:")
    for rotation, lut in luts.items():
        print(f"{rotation}: {lut[:10]}")

if __name__ == "__main__":
    generate_automorphism_luts()