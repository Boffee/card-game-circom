pragma circom 2.0.0;

include "./merkle.circom";

template Draw(levels) {
    signal input deckRoot;
    signal input newDeckRoot;
    signal input handRoot;
    signal input newHandRoot;
    signal input deckDrawnCardRng;
    signal input drawnCardLeaf;
    signal input deckDrawnCardHashPath[levels];
    signal input deckTailCardLeaf;
    signal input deckTailCardIndex;
    signal input deckTailCardHashPath[levels];
    signal input handTailCardLeaf;
    signal input handTailCardIndex;
    signal input handTailCardHashPath[levels];
    signal input handDrawnCardHashPath[levels];

    component checkRemoveLeaf = CheckRemoveLeaf(levels);
    checkRemoveLeaf.root <== deckRoot;
    checkRemoveLeaf.newRoot <== newDeckRoot;
    checkRemoveLeaf.removeLeaf <== drawnCardLeaf;
    checkRemoveLeaf.removeIndex <-- deckDrawnCardRng % (deckTailCardIndex + 1);
    checkRemoveLeaf.removeHashPath <== deckDrawnCardHashPath;
    checkRemoveLeaf.tailLeaf <== deckTailCardLeaf;
    checkRemoveLeaf.tailIndex <== deckTailCardIndex;
    checkRemoveLeaf.tailHashPath <== deckTailCardHashPath;

    component checkAppendToTail = CheckAppendToTail(levels);
    checkAppendToTail.root <== handRoot;
    checkAppendToTail.newRoot <== newHandRoot;
    checkAppendToTail.appendLeaf <== drawnCardLeaf;
    checkAppendToTail.tailIndex <== handTailCardIndex;
    checkAppendToTail.tailLeaf <== handTailCardLeaf;
    checkAppendToTail.tailHashPath <== handTailCardHashPath;
    checkAppendToTail.appendHashPath <== handDrawnCardHashPath;
}

component main {public [deckRoot, newDeckRoot, handRoot, newHandRoot, deckDrawnCardRng]} = Draw(6);