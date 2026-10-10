---
title: Characters, words, and the pieces in between
version: 1
---

The picture most people bring is a model that reads: words go in, and something inside weighs them.
**What goes in is a list of integers.** Before a network sees a sentence, a separate program cuts it
into pieces and replaces each piece by its position in a fixed list. That list is the
**vocabulary**, the program is the **tokenizer**, and a piece is a **token**. Everything the model
knows about text, it learnt through those integers.

So the first decision is what a piece should be. This lesson answers it on a text small enough to
read, and the text is the same in every section: forty-five lines about a market town that does not
exist. Save it as `~/dl/corpus.txt`:

```
The market at Wenbury opens on Monday and closes on Saturday night.
On Monday the baker sells bread, and the farmer sells apples and pears.
On Tuesday the miller sells flour, and the farmer sells plums and cherries.
On Wednesday the potter sells bowls, and the baker sells cakes and buns.
On Thursday the farmer brings a goat, two sheep and a cow to the square.
On Friday the miller brings flour, and the potter brings jugs and cups.
On Saturday everyone comes, and the square is full until the lamps are lit.
The baker wakes before the sun. The farmer wakes before the baker.
The miller wakes when the river is loud, and the potter wakes last of all.
A child asked the baker why bread rises. The baker said it is the yeast.
A child asked the farmer why pears fall. The farmer said it is the wind.
A child asked the miller why the wheel turns. The miller said it is the river.
A child asked the potter why bowls crack. The potter said it is the fire.
The apples are red, the pears are green, and the plums are dark blue.
The cherries are red, the lemons are yellow, and the grapes are green.
The baker paints his door yellow. The potter paints her door blue.
The farmer paints the gate green, and the miller paints the wheel red.
The goat eats apples, the sheep eat grass, and the cow eats hay.
The dog sleeps by the door, the cat sleeps by the fire, and the hen sleeps in the barn.
On Monday the dog follows the baker. On Tuesday the dog follows the miller.
On Wednesday the cat follows the potter. On Thursday the cat follows the farmer.
The baker sells three loaves for one coin and six buns for two coins.
The farmer sells four apples for one coin and five pears for two coins.
The miller sells two bags of flour for three coins on a good day.
The potter sells one bowl for four coins and one jug for five coins.
In spring the farmer plants apples, pears, plums and cherries in long rows.
In summer the baker makes cakes with cherries, and the children run to the stall.
In autumn the miller grinds the wheat, and the river turns the wheel all night.
In winter the potter fires the kiln, and the whole square smells of smoke.
The goat is white, the sheep is grey, the cow is brown, and the dog is black.
The cat is black too, and it watches the hen from the barn roof.
Every Friday the baker and the potter argue about the price of cups.
Every Tuesday the miller and the farmer argue about the price of flour.
Nobody wins, and on Saturday they sit together and eat cherries.
The road to Wenbury is long, and the carts are slow when the road is wet.
A cart with two wheels carries bread. A cart with four wheels carries flour.
When it rains on Monday, the baker sells less bread and more cakes.
When it rains on Thursday, the farmer keeps the goat and the sheep at home.
When it rains on Friday, the potter covers the bowls and the jugs.
The old miller says the river remembers every wheel that ever turned.
The young potter says the fire remembers every bowl that ever cracked.
The baker says nothing, because the baker is busy selling bread.
At night the lamps go out one by one: first the baker, then the farmer,
then the miller, and last of all the potter, who is still at the wheel.
On Sunday the market is closed, and the square is quiet until Monday.
```

Three ways to cut it are obvious: into characters, into words, or into something between the two.
Save this as `~/dl/split.py`, which tries the first two:

```python
# split.py: the corpus cut into characters and into words, and a sentence it never saw
import re

text = open("corpus.txt").read()
chars = sorted(set(text))
words = re.findall(r"\w+|[^\w\s]", text)
vocab = sorted(set(words))
print(f"characters: {len(chars):4d} different, {len(text):5d} in the corpus")
print(f"words:      {len(vocab):4d} different, {len(words):5d} in the corpus")

new = "On Sunday the weaver sells blankets."
pieces = re.findall(r"\w+|[^\w\s]", new)
print("as words:     ", [w if w in vocab else "<unk>" for w in pieces])
print("as characters:", len(new), "symbols, none unknown:", all(c in chars for c in new))
```

```
PENDING split
```

## Characters: nothing unknown, and long

**Forty different characters cover the whole corpus**, capitals and punctuation and the newline
included, and any English sentence you type is made of them. The sentence the corpus never saw
comes out whole, every symbol known. The price is length: the text is 3,261 tokens long, one per
character, and a model has to work out from scratch that `b`, `a`, `k`, `e` and `r` in that order
mean somebody who sells bread. Every step of a network that reads a sequence costs time per token,
so a vocabulary of characters makes everything after it long.

## Words: short, and blind to anything new

**Cut at words, the same text is 713 tokens**, under a quarter of the length, with 187 different
entries. Each token now carries a meaning on its own. But `weaver` and `blankets` were not in the
corpus, so they have no entry, and the sentence reaches the model with two holes marked `<unk>`.
Whatever those words said is gone before the first layer.

A bigger corpus does not fix that, it only makes it rarer. A word vocabulary for real text needs
hundreds of thousands of entries and still misses names, misspellings and every word coined after it
was built. It also treats `baker` and `bakers` as two unrelated entries, which throws away the one
thing about them that is obvious.

## The pieces in between

The way out is a vocabulary of **subwords**: common words kept whole, rare words cut into smaller
pieces that are common, and single characters, or single bytes, at the bottom so that nothing is
ever unknown. `weaver` becomes a few pieces the vocabulary already has, the sentence keeps its
meaning, and the sequence stays close to the length of the word version.

Which pieces, though, is not something anybody writes down by hand. **It is learnt from text, by
counting**, and the next section does that counting in a page of Python.
