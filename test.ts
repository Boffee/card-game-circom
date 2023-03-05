import { mimcSponge } from "@darkforest_eth/hashing";
import bigInt from "big-integer";
import MerkleTree from "merkletreejs";
import drawVKey from "./dist/draw_verification_key.json";
import playVKey from "./dist/play_verification_key.json";
const snarkjs = require("snarkjs");

export const decimalToHex = (decimal: string) => {
  let ret = bigInt(decimal).toString(16);
  if (ret.length % 2 === 1) {
    ret = "0" + ret;
  }
  return ret;
};

export const decimalToBuffer = (decimal: string) => {
  return Buffer.from(decimalToHex(decimal), "hex");
};

export const hexToDecimal = (hex: string) => {
  return bigInt(hex, 16).toString();
};

export const bufferToDecimal = (buffer: Buffer) => {
  return hexToDecimal(buffer.toString("hex"));
};

export const getMerkleTree = (leaves: string[]) => {
  const tree = new MerkleTree(leaves, (x: any) => x, {
    concatenator: (inputs) => hash(inputs),
  });
  return tree;
};

export const hash = (inputs: Buffer[]) => {
  return mimcSponge(
    inputs.map((i) => {
      const hex = i.toString("hex");
      return bigInt(hex, 16);
    }),
    1,
    4,
    0
  ).map((v) => decimalToBuffer(v.toString(10)))[0];
};

export const getMerkleProof = (leaves: string[], index: number) => {
  const tree = getMerkleTree(leaves);
  return tree.getHexProof(leaves[index], index);
};

export const fillLeaves = (leaves: string[], levels: number) => {
  const numLeaves = leaves.length;
  const numLeavesAtLevel = 2 ** levels;
  const numLeavesToFill = numLeavesAtLevel - numLeaves;
  const leavesToFill = Array(numLeavesToFill).fill("ff");
  return [...leaves, ...leavesToFill];
};

export const getlvl6Root = (leaves: string[]) => {
  const filledLeaves = fillLeaves(leaves, 6);
  return bufferToDecimal(getMerkleTree(filledLeaves).getRoot());
};

export const getlvl6Proof = (leaves: string[], index: number) => {
  const filledLeaves = fillLeaves(leaves, 6);
  return getMerkleProof(filledLeaves, index).map((p) =>
    bigInt(p.slice(2), 16).toString()
  );
};

export const removeLeaf = (leaves: string[], index: number) => {
  const newLeaves = replaceLeaf(leaves, index);
  newLeaves.pop();
  return newLeaves;
};

export const replaceLeaf = (leaves: string[], index: number) => {
  const newLeaves = [...leaves];
  newLeaves[index] = leaves[leaves.length - 1];
  return newLeaves;
};

export const addLeaf = (leaves: string[], leaf: string) => {
  return [...leaves, leaf];
};

async function play(hand: string[], playedCardIndex: number) {
  const leaves = hand.map((l) => decimalToHex(l));
  const playedCardLeaf = hexToDecimal(leaves[playedCardIndex]);
  const tailCardIndex = leaves.length - 1;
  const tailCardLeaf = hexToDecimal(leaves[tailCardIndex]);
  const newLeaves = removeLeaf(leaves, playedCardIndex);
  const handRoot = getlvl6Root(leaves);
  const newHandRoot = getlvl6Root(newLeaves);
  const playedCardHashPath = getlvl6Proof(leaves, playedCardIndex);
  const tailCardHashPath = getlvl6Proof(
    replaceLeaf(leaves, playedCardIndex),
    tailCardIndex
  );

  const { proof, publicSignals } = await snarkjs.plonk.fullProve(
    {
      handRoot,
      newHandRoot,
      playedCardLeaf,
      playedCardIndex,
      playedCardHashPath,
      tailCardLeaf,
      tailCardIndex,
      tailCardHashPath,
    },
    "dist/play_js/play.wasm",
    "dist/play_final.zkey"
  );

  console.log("Proof: ");
  console.log(JSON.stringify(proof, null, 1));

  const res = await snarkjs.plonk.verify(playVKey, publicSignals, proof);

  if (res === true) {
    console.log("Verification OK");
  } else {
    console.log("Invalid proof");
  }

  return res;
}

async function draw(deck: string[], hand: string[], deckDrawnCardRng: number) {
  const deckDrawnCardIndex = deckDrawnCardRng % deck.length;
  const deckLeaves = deck.map((l) => decimalToHex(l));
  const newDeckLeaves = removeLeaf(deckLeaves, deckDrawnCardIndex);
  const handLeaves = hand.map((l) => decimalToHex(l));
  const newHandLeaves = addLeaf(handLeaves, deckLeaves[deckDrawnCardIndex]);

  const deckRoot = getlvl6Root(deckLeaves);
  const newDeckRoot = getlvl6Root(newDeckLeaves);
  const handRoot = getlvl6Root(handLeaves);
  const newHandRoot = getlvl6Root(newHandLeaves);

  const drawnCardLeaf = hexToDecimal(deckLeaves[deckDrawnCardIndex]);
  const deckDrawnCardHashPath = getlvl6Proof(deckLeaves, deckDrawnCardIndex);
  const deckTailCardIndex = deckLeaves.length - 1;
  const deckTailCardLeaf = hexToDecimal(deckLeaves[deckTailCardIndex]);
  const deckTailCardHashPath = getlvl6Proof(
    replaceLeaf(deckLeaves, deckDrawnCardIndex),
    deckTailCardIndex
  );

  const handTailCardIndex = Math.max(handLeaves.length - 1, 0);
  const handTailCardLeaf = handLeaves.length
    ? hexToDecimal(handLeaves[handTailCardIndex])
    : "255";
  const handTailCardHashPath = getlvl6Proof(handLeaves, handTailCardIndex);
  const handDrawnCardHashPath = getlvl6Proof(handLeaves, handTailCardIndex + 1);

  const { proof, publicSignals } = await snarkjs.plonk.fullProve(
    {
      deckRoot,
      newDeckRoot,
      handRoot,
      newHandRoot,
      deckDrawnCardRng,
      drawnCardLeaf,
      deckDrawnCardHashPath,
      deckTailCardLeaf,
      deckTailCardIndex,
      deckTailCardHashPath,
      handTailCardLeaf,
      handTailCardIndex,
      handTailCardHashPath,
      handDrawnCardHashPath,
    },
    "dist/draw_js/draw.wasm",
    "dist/draw_final.zkey"
  );

  console.log("Proof: ");
  console.log(JSON.stringify(proof, null, 1));

  const res = await snarkjs.plonk.verify(drawVKey, publicSignals, proof);

  if (res === true) {
    console.log("Verification OK");
  } else {
    console.log("Invalid proof");
  }
  return res;
}

const testHand = ["1", "2", "3", "4", "5"];
const testDeck = [
  "6",
  "7",
  "8",
  "9",
  "10",
  "11",
  "12",
  "13",
  "14",
  "15",
  "16",
  "17",
  "18",
  "19",
  "20",
];

async function run() {
  await play(testHand, 1);
  await draw(testDeck, testHand, 50);
}

run();
