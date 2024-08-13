pragma circom 2.1.9;

include "./node_modules/circomlib/circuits/poseidon.circom";

template PoseidonHash() {
    signal input in[4];
    signal output out;

    component poseidon = Poseidon(4);
    poseidon.inputs[0] <== in[0];
    poseidon.inputs[1] <== in[1];
    poseidon.inputs[2] <== in[2];
    poseidon.inputs[3] <== in[3];

    out <== poseidon.out;
}

component main = PoseidonHash();