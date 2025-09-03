#!/usr/bin/env python3
"""
CKKS Key Generation Script for Convolution Unit
Generates evaluation keys ONLY for required rotations: -1, -16, -17
"""

import numpy as np
import random
import json
import os
from typing import List, Tuple, Dict, Any

class CKKSKeyGenerator:
    def __init__(self):
        # Parameters from params.vh
        self.N = 256            # Ring dimension
        self.Q = 132120577      # Modulus (27 bits)
        self.K = 27             # Coefficient bit width
        
        # CKKS specific parameters
        self.sigma = 3.2        # Gaussian noise standard deviation
        
        # NTT parameters
        self.primitive_root = self.find_primitive_root()
        self.ntt_root = pow(self.primitive_root, (self.Q - 1) // (2 * self.N), self.Q)
        self.inv_ntt_root = pow(self.ntt_root, self.Q - 2, self.Q)
        self.n_inv = pow(self.N, self.Q - 2, self.Q)
        
        # Precompute twiddle factors
        self.twiddle_factors = self.compute_twiddle_factors()
        self.inv_twiddle_factors = self.compute_inv_twiddle_factors()
        
        # PRECOMPUTED GALOIS ELEMENTS FOR REQUIRED ROTATIONS
        # These values are precomputed for N=256 (2N=512)
        self.required_rotations = {
            -1: 255,   # rotation by -1 slot
            -16: 240,  # rotation by -16 slots  
            -17: 239   # rotation by -17 slots
        }
        
    def find_primitive_root(self) -> int:
        """Find a primitive root modulo Q"""
        return 5
    
    def compute_twiddle_factors(self) -> List[int]:
        """Compute twiddle factors for NTT"""
        twiddles = []
        for i in range(self.N):
            twiddles.append(pow(self.ntt_root, i, self.Q))
        return twiddles
    
    def compute_inv_twiddle_factors(self) -> List[int]:
        """Compute inverse twiddle factors for INTT"""
        inv_twiddles = []
        for i in range(self.N):
            inv_twiddles.append(pow(self.inv_ntt_root, i, self.Q))
        return inv_twiddles
    
    def sample_gaussian(self) -> int:
        """Sample from discrete Gaussian distribution"""
        u1 = random.random()
        u2 = random.random()
        z = np.sqrt(-2 * np.log(u1)) * np.cos(2 * np.pi * u2)
        discrete_z = int(round(z * self.sigma))
        return discrete_z % self.Q
    
    def sample_uniform(self) -> int:
        """Sample uniformly from [0, Q-1]"""
        return random.randint(0, self.Q - 1)
    
    def sample_ternary(self) -> int:
        """Sample from {-1, 0, 1} with equal probability"""
        choice = random.randint(0, 2)
        if choice == 0:
            return self.Q - 1
        elif choice == 1:
            return 0
        else:
            return 1
    
    def ntt_transform(self, poly: List[int]) -> List[int]:
        """Forward NTT transformation"""
        result = poly.copy()
        n = len(result)
        
        # Bit-reverse permutation
        j = 0
        for i in range(1, n):
            bit = n >> 1
            while j & bit:
                j ^= bit
                bit >>= 1
            j ^= bit
            if i < j:
                result[i], result[j] = result[j], result[i]
        
        # NTT computation
        length = 2
        while length <= n:
            w = pow(self.ntt_root, (self.Q - 1) // length, self.Q)
            for i in range(0, n, length):
                wn = 1
                for j in range(length // 2):
                    u = result[i + j]
                    v = (result[i + j + length // 2] * wn) % self.Q
                    result[i + j] = (u + v) % self.Q
                    result[i + j + length // 2] = (u - v) % self.Q
                    wn = (wn * w) % self.Q
            length <<= 1
        
        return result
    
    def intt_transform(self, poly: List[int]) -> List[int]:
        """Inverse NTT transformation"""
        result = poly.copy()
        n = len(result)
        
        # Bit-reverse permutation
        j = 0
        for i in range(1, n):
            bit = n >> 1
            while j & bit:
                j ^= bit
                bit >>= 1
            j ^= bit
            if i < j:
                result[i], result[j] = result[j], result[i]
        
        # INTT computation
        length = 2
        while length <= n:
            w = pow(self.inv_ntt_root, (self.Q - 1) // length, self.Q)
            for i in range(0, n, length):
                wn = 1
                for j in range(length // 2):
                    u = result[i + j]
                    v = (result[i + j + length // 2] * wn) % self.Q
                    result[i + j] = (u + v) % self.Q
                    result[i + j + length // 2] = (u - v) % self.Q
                    wn = (wn * w) % self.Q
            length <<= 1
        
        # Multiply by N^(-1)
        for i in range(n):
            result[i] = (result[i] * self.n_inv) % self.Q
        
        return result
    
    def generate_secret_key(self) -> List[int]:
        """Generate secret key (ternary polynomial)"""
        return [self.sample_ternary() for _ in range(self.N)]
    
    def generate_public_key(self, secret_key: List[int]) -> Tuple[List[int], List[int]]:
        """Generate public key (pk0, pk1) where pk0 + pk1*s = e (mod Q)"""
        pk1 = [self.sample_uniform() for _ in range(self.N)]
        error = [self.sample_gaussian() for _ in range(self.N)]
        
        pk0 = []
        for i in range(self.N):
            temp = 0
            for j in range(self.N):
                if i >= j:
                    temp += pk1[j] * secret_key[i - j]
                else:
                    temp -= pk1[j] * secret_key[self.N + i - j]
            pk0.append((error[i] - temp) % self.Q)
        
        return pk0, pk1
    
    def galois_automorphism(self, poly: List[int], galois_element: int) -> List[int]:
        """Apply Galois automorphism σ_k to polynomial"""
        result = [0] * self.N
        for i in range(self.N):
            new_index = (i * galois_element) % (2 * self.N)
            if new_index < self.N:
                result[new_index] = poly[i]
            else:
                result[new_index - self.N] = (-poly[i]) % self.Q
        return result
    
    def generate_evaluation_key_ntt(self, secret_key: List[int], galois_element: int) -> Tuple[List[int], List[int]]:
        """Generate evaluation key for Galois automorphism in NTT domain.
           evk = Enc_{σ_k(s)}(s)
        """
        # Apply automorphism to secret key to get σ_k(s)
        rotated_secret_key = self.galois_automorphism(secret_key, galois_element)
        
        # Transform both keys to NTT domain
        s_ntt = self.ntt_transform(secret_key)
        sigma_s_ntt = self.ntt_transform(rotated_secret_key)
        
        # Generate random polynomial 'a' and error 'e'
        a_poly = [self.sample_uniform() for _ in range(self.N)]
        e_poly = [self.sample_gaussian() for _ in range(self.N)]
        
        # Transform to NTT domain
        a_ntt = self.ntt_transform(a_poly)
        e_ntt = self.ntt_transform(e_poly)
        
        # Compute evk0_ntt = -a_ntt * sigma_s_ntt + e_ntt + s_ntt
        evk0_ntt = []
        for i in range(self.N):
            product = (a_ntt[i] * sigma_s_ntt[i]) % self.Q
            evk0_val = (e_ntt[i] - product + s_ntt[i]) % self.Q
            evk0_ntt.append(evk0_val)
        
        return evk0_ntt, a_ntt
    
    def generate_all_keys(self) -> Dict[str, Any]:
        """Generate all keys for CKKS with evaluation keys ONLY for required rotations"""
        print("Generating CKKS keys for convolution unit...")
        print(f"Required rotations: {list(self.required_rotations.keys())}")
        
        # Generate secret key
        print("Generating secret key...")
        secret_key = self.generate_secret_key()
        
        # Generate public key
        print("Generating public key...")
        pk0, pk1 = self.generate_public_key(secret_key)
        
        # Generate evaluation keys ONLY for required rotations
        evaluation_keys_ntt = {}
        
        print("Generating evaluation keys for required rotations...")
        for shift, galois_exp in self.required_rotations.items():
            galois_elem = pow(5, galois_exp, 2 * self.N)
            
            print(f"  Rotation {shift} (Galois exponent {galois_exp}, element {galois_elem})...")
            evk0_ntt, evk1_ntt = self.generate_evaluation_key_ntt(secret_key, galois_elem)
            evaluation_keys_ntt[galois_exp] = {
                'evk0': evk0_ntt,
                'evk1': evk1_ntt,
                'rotation_shift': shift,
                'galois_element': galois_elem
            }
        
        # Transform other keys to NTT domain
        print("Transforming secret and public keys to NTT domain...")
        
        secret_key_ntt = self.ntt_transform(secret_key)
        pk0_ntt = self.ntt_transform(pk0)
        pk1_ntt = self.ntt_transform(pk1)
        
        return {
            'parameters': {
                'N': self.N,
                'Q': self.Q,
                'K': self.K,
                'primitive_root': self.primitive_root,
                'ntt_root': self.ntt_root,
                'inv_ntt_root': self.inv_ntt_root,
                'n_inv': self.n_inv
            },
            'required_rotations': self.required_rotations,
            'polynomial_domain': {
                'secret_key': secret_key,
                'public_key': {'pk0': pk0, 'pk1': pk1}
            },
            'ntt_domain': {
                'secret_key': secret_key_ntt,
                'public_key': {'pk0': pk0_ntt, 'pk1': pk1_ntt},
                'evaluation_keys': evaluation_keys_ntt
            }
        }
    
    def save_keys_to_files(self, keys: Dict[str, Any], output_dir: str = "ckks_conv_keys"):
        """Save keys to files - evaluation keys ONLY for required rotations"""
        os.makedirs(output_dir, exist_ok=True)
        
        # Save parameters
        with open(f"{output_dir}/parameters.json", 'w') as f:
            json.dump(keys['parameters'], f, indent=2)
        
        # Save rotation mapping
        with open(f"{output_dir}/rotation_mapping.json", 'w') as f:
            json.dump(keys['required_rotations'], f, indent=2)
        
        # Save polynomial domain keys
        poly_dir = f"{output_dir}/polynomial_domain"
        os.makedirs(poly_dir, exist_ok=True)
        
        with open(f"{poly_dir}/secret_key.json", 'w') as f:
            json.dump(keys['polynomial_domain']['secret_key'], f)
        
        with open(f"{poly_dir}/public_key.json", 'w') as f:
            json.dump(keys['polynomial_domain']['public_key'], f)
        
        # Save NTT domain keys
        ntt_dir = f"{output_dir}/ntt_domain"
        os.makedirs(ntt_dir, exist_ok=True)
        
        with open(f"{ntt_dir}/secret_key.json", 'w') as f:
            json.dump(keys['ntt_domain']['secret_key'], f)
        
        with open(f"{ntt_dir}/public_key.json", 'w') as f:
            json.dump(keys['ntt_domain']['public_key'], f)
        
        with open(f"{ntt_dir}/evaluation_keys.json", 'w') as f:
            json.dump(keys['ntt_domain']['evaluation_keys'], f, indent=2)
        
        print(f"Keys saved to {output_dir}/")
        print(f"Evaluation keys generated for rotations: {list(keys['required_rotations'].keys())}")
        
        # Generate SystemVerilog include files
        self.generate_sv_includes(keys, output_dir)
    
    def generate_sv_includes(self, keys: Dict[str, Any], output_dir: str):
        """Generate SystemVerilog include files with hardcoded keys"""
        sv_dir = f"{output_dir}/systemverilog"
        os.makedirs(sv_dir, exist_ok=True)
        
        # Generate evaluation keys include file
        with open(f"{sv_dir}/evk_hardcoded.sv", 'w') as f:
            f.write("// Auto-generated evaluation keys for CKKS Convolution Unit\n")
            f.write("// Evaluation keys for specific rotations: -1, -16, -17\n")
            f.write("// Organized as 2D arrays: [rotation_id][coefficient]\n\n")
            
            f.write("// Rotation ID mapping:\n")
            f.write("// 0 -> rotation by -1 (galois exponent 255)\n")
            f.write("// 1 -> rotation by -16 (galois exponent 240)\n")
            f.write("// 2 -> rotation by -17 (galois exponent 239)\n\n")
            
            f.write("logic [K-1:0] evk0_keys [2:0][N-1:0];\n")
            f.write("logic [K-1:0] evk1_keys [2:0][N-1:0];\n\n")
            
            f.write("// Initialize evaluation key arrays\n")
            f.write("initial begin\n")
            
            # Map galois exponents to rotation IDs
            rotation_ids = {255: 0, 240: 1, 239: 2}
            
            for galois_exp, evk_data in keys['ntt_domain']['evaluation_keys'].items():
                rot_id = rotation_ids[galois_exp]
                shift = evk_data['rotation_shift']
                f.write(f"\n    // Rotation {shift} (rotation_id = {rot_id})\n")
                
                # EVK0 assignment
                f.write(f"    evk0_keys[{rot_id}] = '{{\n")
                coeffs = evk_data['evk0']
                for i, coeff in enumerate(coeffs):
                    f.write(f"        {self.K}'d{coeff}")
                    if i < len(coeffs) - 1:
                        f.write(",")
                    f.write("\n")
                f.write("    };\n")
                
                # EVK1 assignment  
                f.write(f"    evk1_keys[{rot_id}] = '{{\n")
                coeffs = evk_data['evk1']
                for i, coeff in enumerate(coeffs):
                    f.write(f"        {self.K}'d{coeff}")
                    if i < len(coeffs) - 1:
                        f.write(",")
                    f.write("\n")
                f.write("    };\n")
            
            f.write("end\n")

def main():
    # Set random seed for reproducibility
    random.seed(42)
    np.random.seed(42)
    
    # Generate keys
    keygen = CKKSKeyGenerator()
    keys = keygen.generate_all_keys()
    
    # Save to files
    keygen.save_keys_to_files(keys)
    
    print("\nCKKS key generation for convolution unit complete!")
    print(f"Generated keys for N={keygen.N}, Q={keygen.Q}")
    print(f"Evaluation keys created for rotations: {list(keygen.required_rotations.keys())}")

if __name__ == "__main__":
    main()
