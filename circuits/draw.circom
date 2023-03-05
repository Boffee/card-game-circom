pragma circom 2.0.0;

include "./merkle.circom";

template Draw(levels) {
    signal input deckRoot;
    signal input newDeckRoot;
    signal input handRoot;
    signal input newHandRoot;
    signal input drawnCard;
    signal input deckDrawnCardIndex;
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
    checkRemoveLeaf.removeLeaf <== drawnCard;
    checkRemoveLeaf.removeIndex <== deckDrawnCardIndex;
    checkRemoveLeaf.removeHashPath <== deckDrawnCardHashPath;
    checkRemoveLeaf.tailLeaf <== deckTailCardLeaf;
    checkRemoveLeaf.tailIndex <== deckTailCardIndex;
    checkRemoveLeaf.tailHashPath <== deckTailCardHashPath;

    component checkAppendToTail = CheckAppendToTail(levels);
    checkAppendToTail.root <== handRoot;
    checkAppendToTail.newRoot <== newHandRoot;
    checkAppendToTail.appendLeaf <== drawnCard;
    checkAppendToTail.tailIndex <== handTailCardIndex;
    checkAppendToTail.tailLeaf <== handTailCardLeaf;
    checkAppendToTail.tailHashPath <== handTailCardHashPath;
    checkAppendToTail.appendHashPath <== handDrawnCardHashPath;
}

component main = Draw(5);