pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/comparators.circom";


// Computes Poseidon([left, right])
template HashLeftRight() {
    signal input left;
    signal input right;
    signal output hash;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== left;
    hasher.inputs[1] <== right;
    hash <== hasher.out;
}

// if s == 0 returns [in[0], in[1]]
// if s == 1 returns [in[1], in[0]]
template DualMux() {
    signal input in[2];
    signal input s;
    signal output out[2];

    s * (1 - s) === 0;
    out[0] <== (in[1] - in[0]) * s + in[0];
    out[1] <== (in[0] - in[1]) * s + in[1];
}

// Verifies that merkle proof is correct for given merkle root and a leaf
// pathIndices input is an array of 0/1 selectors telling whether given pathElement is on the left or right side of merkle path
template CheckMembership(levels) {
    signal input root;
    signal input leaf;
    signal input index;
    signal input hashPath[levels];

    component constructRoot = ConstructRoot(levels);
    constructRoot.leaf <== leaf;
    constructRoot.index <== index;
    constructRoot.hashPath <== hashPath;

    root === constructRoot.root;
}

template CheckAppendToTail(levels) {
    signal input root;
    signal input newRoot;
    signal input appendLeaf;
    signal input tailLeaf;
    signal input tailIndex;
    signal input tailHashPath[levels];
    signal input appendHashPath[levels];

    component checkTail = CheckTail(levels);
    checkTail.leaf <== tailLeaf;
    checkTail.index <== tailIndex;
    checkTail.hashPath <== tailHashPath;

    component checkTailMembership = CheckMembership(levels);
    checkTailMembership.root <== root;
    checkTailMembership.leaf <== tailLeaf;
    checkTailMembership.index <== tailIndex;
    checkTailMembership.hashPath <== tailHashPath;

    component checkReplaceTail = CheckReplaceLeaf(levels);
    checkReplaceTail.root <== root;
    checkReplaceTail.newRoot <== newRoot;
    checkReplaceTail.currLeaf <== 255;
    checkReplaceTail.newLeaf <== appendLeaf;
    checkReplaceTail.index <== tailIndex + 1;
    checkReplaceTail.hashPath <== appendHashPath;
}

template CheckRemoveLeaf(levels) {
    signal input root;
    signal input newRoot;
    signal input removeLeaf;
    signal input removeIndex;
    signal input removeHashPath[levels];
    signal input tailLeaf;
    signal input tailIndex;
    signal input tailHashPath[levels];    

    component checkTail = CheckTail(levels);
    checkTail.leaf <== tailLeaf;
    checkTail.index <== tailIndex;
    checkTail.hashPath <== tailHashPath;

    component checkRemoveMembership = CheckMembership(levels);
    checkRemoveMembership.root <== root;
    checkRemoveMembership.leaf <== removeLeaf;
    checkRemoveMembership.index <== removeIndex;
    checkRemoveMembership.hashPath <== removeHashPath;

    component constructTempRoot = ConstructRoot(levels);
    constructTempRoot.leaf <== tailLeaf;
    constructTempRoot.index <== removeIndex;
    constructTempRoot.hashPath <== removeHashPath;

    component checkReplaceTail = CheckReplaceLeaf(levels);
    checkReplaceTail.root <== constructTempRoot.root;
    checkReplaceTail.newRoot <== newRoot;
    checkReplaceTail.currLeaf <== tailLeaf;
    checkReplaceTail.newLeaf <== 255;
    checkReplaceTail.index <== tailIndex;
    checkReplaceTail.hashPath <== tailHashPath;
}

template CheckReplaceLeaf(levels) {
    signal input root;
    signal input newRoot;
    signal input currLeaf;
    signal input newLeaf;
    signal input index;
    signal input hashPath[levels];

    component checkBefore = CheckMembership(levels);
    component checkAfter = CheckMembership(levels);


    checkBefore.root <== root;
    checkBefore.leaf <== currLeaf;
    checkBefore.index <== index;
    checkBefore.hashPath <== hashPath;

    checkAfter.root <== newRoot;
    checkAfter.leaf <== newLeaf;
    checkAfter.index <== index;
    checkAfter.hashPath <== hashPath;
}

template CheckTail(levels) {
    signal input leaf;
    signal input index;
    signal input hashPath[levels];

    component leafIsNull = IsEqual();
    component index2path = InverseNum2Bits(levels);

    leafIsNull.in[0] <== leaf;
    leafIsNull.in[1] <== 255;
    leafIsNull.out === 0;

    index2path.in <== index;

    for (var i = 0; i < levels; i++) {
        var s = index2path.out[i];
        var hash = hashPath[i];
        // hash must be null if sibling is on the right
        // TODO: replace 255 with hash at depth
        (1 - s) * (255 - hash) === 0;
    }
}

template ConstructRoot(levels) {
    signal output root;
    signal input leaf;
    signal input index;
    signal input hashPath[levels];
    
    component selectors[levels];
    component hashers[levels];
    component index2path = InverseNum2Bits(levels);

    index2path.in <== index;

    for (var i = 0; i < levels; i++) {
        selectors[i] = DualMux();
        selectors[i].in[0] <== i == 0 ? leaf : hashers[i - 1].hash;
        selectors[i].in[1] <== hashPath[i];
        selectors[i].s <== index2path.out[i];

        hashers[i] = HashLeftRight();
        hashers[i].left <== selectors[i].out[0];
        hashers[i].right <== selectors[i].out[1];
    }

    root <== hashers[levels - 1].hash;
}

template Invert(n) {
    signal input in[n];
    signal output out[n];

    for (var i = 0; i<n; i++) {
        out[i] <== in[n - 1 - i];
    }
}

template InverseNum2Bits(n) {
    signal input in;
    signal output out[n];

    component numb2Bits = Num2Bits(n);
    numb2Bits.in <== in;

    component invert = Invert(n);
    invert.in <== numb2Bits.out;

    out <== invert.out;
}