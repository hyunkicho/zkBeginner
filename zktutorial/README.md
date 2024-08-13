# zkBeginner
circum tutorial

# docs
https://docs.circom.io/getting-started/installation/#installing-circom

install circum and snarkjs
cirucum is made up of rust so you need to install rust and then install circom
also you need to install snarkjs

```
npm install -g snarkjs
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
git clone https://github.com/iden3/circom.git
cd ./circom/
cargo build --release
cargo install --path circom
npm install -g snarkjs
```

# Writing circuits
write A*B + C = 0
which is basic format

signal could be written as input and output and it is private
https://docs.circom.io/circom-language/signals/

```
pragma circom 2.0.0;

template Multiplier2 () {  

   // Declaration of signals.  
   signal input a;  
   signal input b;  
   signal output c;  

   // Constraints.  
   c <== a * b;  //same as "a * b ==> c"
}
```
and file names should be .circom

# Compiling circuits

after writing mulitpier2.circum it should generate files with below command
it should be in same directory with multiplier2.circom
```
circom multiplier2.circom --r1cs --wasm --sym
```

- explanation
--r1cs: it generates the file multiplier2.r1cs that contains the R1CS constraint system of the circuit in binary format.
--wasm: it generates the directory multiplier2_js that contains the Wasm code (multiplier2.wasm) and other files needed to generate the witness.
--sym : it generates the file multiplier2.sym , a symbols file required for debugging or for printing the constraint system in an annotated mode.


# Computing Witnesses
https://docs.circom.io/getting-started/computing-the-witness/

- Using the generated Wasm binary and three JavaScript files, we simply need to provide a file with the inputs and the module will execute the circuit and calculate all the intermediate signals and the output.
- The set of inputs, intermediate signals and output is called witness.
- For instance, imagine that in the previous circuit, the input a is a private key and the input b is the corresponding public key. You may be okay with revealing b but you certainly do not want to reveal a. If we define a as a private input, b, c as public inputs and out as a public output, with zero-knowledge we are able to prove, without revealing its value, that we know a private input a such that, for certain public values b, c and out, the equation a*b + c = out mod 7 holds.
- An assignment of the signals is called a witness. For example, {a = 2, b = 6, c = -1, out = 4} would be a valid witness for the circuit. The assignment {a = 1, b = 2, c = 1, out = 0} would not be a valid witness, since it does not satisfy the equation a*b + c = out mod 7.

1. make input.json in multiplier2_js

* in js use string instard of number type
```
{"a": "3", "b": "11"}
```

compute witness to make witness.wtns

```
cd ./circom/multiplier2_js
node generate_witness.js multiplier2.wasm input.json witness.wtns
```

#  Proving circuit
https://docs.circom.io/getting-started/proving-circuits/
- we will prove that we are able to provide the two factors of the number 33.
- 
- We are going to use the Groth16 zk-SNARK protocol. To use this protocol, you will need to generate a trusted setup. Groth16 requires a per circuit trusted setup. In more detail, the trusted setup consists of 2 parts:

1. The powers of tau, which is independent of the circuit.
2. The phase 2, which depends on the circuit.

- specific tutorial of snarkjs
https://github.com/iden3/snarkjs

First, we start a new "powers of tau" ceremony:
```
snarkjs powersoftau new bn128 12 pot12_0000.ptau -v
```

Then, we contribute to the ceremony:
```
snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v
```

# Phase 2

The phase 2 is circuit-specific. Execute the following command to start the generation of this phase:
```
snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau -v
```

Next, we generate a .zkey file that will contain the proving and verification keys together with all phase 2 contributions. Execute the following command to start a new zkey:

* move multiplier2.r1cs to the same location in here
```
snarkjs groth16 setup multiplier2.r1cs pot12_final.ptau multiplier2_0000.zkey
```

Contribute to the phase 2 of the ceremony:

```
snarkjs zkey contribute multiplier2_0000.zkey multiplier2_0001.zkey --name="1st Contributor Name" -v
```

Export the verification key:

```
snarkjs zkey export verificationkey multiplier2_0001.zkey verification_key.json
```

Generating a Proof
Once the witness is computed and the trusted setup is already executed, we can generate a zk-proof associated to the circuit and the witness:

```
snarkjs groth16 prove multiplier2_0001.zkey witness.wtns proof.json public.json
````
This command generates a Groth16 proof and outputs two files:

Verifying a Proof
To verify the proof, execute the following command:

proof.json: it contains the proof.
public.json: it contains the values of the public inputs and outputs.

Verifying from a Smart Contract
​👉 It is also possible to generate a Solidity verifier that allows verifying proofs on Ethereum blockchain.

First, we need to generate the Solidity code using the command:
```
snarkjs zkey export solidityverifier multiplier2_0001.zkey verifier.sol
```
This command takes validation key multiplier2_0001.zkey and outputs Solidity code in a file named verifier.sol. 
The Verifier has a view function called verifyProof that returns TRUE if and only if the proof and the inputs are valid. To facilitate the call, you can use snarkJS to generate the parameters of the call by typing:
```
snarkjs generatecall
```
you could use this in js library when you make a service with zk

# Poseidon hash
https://socket.dev/npm/package/poseidon-lite

1. make r1cs , wasm ,sym
```
circom poseidon.circom --r1cs --wasm --sym
```

2. make input

input.json
```
{"in" : [1, 2, 3, 4]}
```

3. make input & witness 
```
node generate_witness.js poseidon.wasm input.json witness.wtns
```

4. make trusted setup (skip ceremoney in this case)
```
snarkjs powersoftau prepare phase2 pot12_0000.ptau pot12_final.ptau -v
```

5. make zkey
```
snarkjs groth16 setup poseidon.r1cs pot12_final.ptau poseidon_0000.zkey
```

6. export zkey
```
snarkjs zkey export verificationkey poseidon_0000.zkey verification_key.json
```

7. generate zk-proof associated to the circuit and the witness

```
snarkjs groth16 prove poseidon_0000.zkey witness.wtns proof.json public.json
```

8. generate solidity code that allows verification 

```
snarkjs zkey export solidityverifier poseidon_0000.zkey poseidon_verifier.sol
```

9. generatecall

```
snarkjs generatecall
```

