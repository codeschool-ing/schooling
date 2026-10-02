---
title: A search, not a line
version: 1
---

Chain of thought (lesson 26) writes one path from the question to the answer. If its first step
is a poor one, everything after it is built on that step, and the chain has no way back.
Self-consistency (lesson 27) runs several whole paths and compares only where they end. **Tree of
thoughts treats the problem as a search: at each step it proposes several possible next steps,
judges how promising each one is, keeps the best few and abandons the rest**, then repeats from
every step it kept. The paths branch like a tree, and the weak branches are cut before anybody
pays to finish them.

## The puzzle

The Game of 24: given four numbers, combine them with `+`, `-`, `*` and `/`, each number used
once, to make 24. It suits the method well, because every intermediate state can be judged. After
one step you have three numbers left, and either 24 can still be reached from them or it cannot.

`tot` is a real program, printed in `lab.sh`. **A "thought" is one step**: pick two of the
numbers left, combine them, put the result back. At each level `tot` proposes every possible
step from every state it kept, judges each new state as `sure` (24 can still be reached) or
`impossible`, and keeps the best `--breadth` of them, three by default:

```
ana@lab:~/pe$ tot 4 9 10 13
level 1: 36 proposed, 36 different, 7 sure, 29 impossible
  keep  [9 13 -6]  after  4 - 10 = -6
  keep  [4 13 19]  after  9 + 10 = 19
  keep  [4 10 -4]  after  9 - 13 = -4
level 2: 54 proposed, 47 different, 2 sure, 45 impossible
  keep  [-6 -4]  after  9 - 13 = -4
  keep  [4 6]  after  19 - 13 = 6
level 3: 12 proposed, 7 different, 1 sure, 6 impossible
  keep  [24]  after  -6 * -4 = 24
solved: 4 - 10 = -6; 9 - 13 = -4; -6 * -4 = 24
```

Read it a level at a time. From `4 9 10 13` there are 36 possible first steps. Only 7 leave
numbers from which 24 is still reachable; **29 are dead ends, and they are dropped before a
second step is spent on any of them.** Three of the seven are kept. From those three, 54 second
steps are proposed, 47 of them different states, and only 2 can still reach 24. One of those
leads to `-6 * -4 = 24`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 800 340\" role=\"img\" aria-label=\"A tree drawn from the tot capture. The start, 4 9 10 13, has three kept children at level 1: 9 13 -6 after 4 - 10, 4 13 19 after 9 + 10, and 4 10 -4 after 9 - 13; 36 states were proposed, 7 were sure and 29 were dropped. At level 2, 54 were proposed and 2 were sure: -6 -4 under 9 13 -6, and 4 6 under 4 13 19; the third branch kept nothing. At level 3, -6 times -4 gives 24, and the search is solved.\"><defs><marker id=\"tot-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">start</text><text x=\"40\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">level 1</text><text x=\"40\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">level 2</text><text x=\"40\" y=\"305\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">level 3</text><rect x=\"265\" y=\"25\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[4 9 10 13]</text><path d=\"M320 55 L140 113\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tot-ah)\"></path><text x=\"150\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 - 10 = -6</text><rect x=\"85\" y=\"115\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[9 13 -6]</text><path d=\"M320 55 L320 113\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tot-ah)\"></path><text x=\"328\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">9 + 10 = 19</text><rect x=\"265\" y=\"115\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[4 13 19]</text><path d=\"M320 55 L500 113\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tot-ah)\"></path><text x=\"445\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">9 - 13 = -4</text><rect x=\"445\" y=\"115\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[4 10 -4]</text><path d=\"M140 145 L140 203\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tot-ah)\"></path><text x=\"148.0\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">9 - 13 = -4</text><rect x=\"85\" y=\"205\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[-6 -4]</text><path d=\"M320 145 L320 203\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tot-ah)\"></path><text x=\"328.0\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19 - 13 = 6</text><rect x=\"265\" y=\"205\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[4 6]</text><text x=\"500\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no slot left</text><path d=\"M140 235 L140 288\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tot-ah)\"></path><text x=\"148.0\" y=\"262.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-6 * -4 = 24</text><rect x=\"85\" y=\"290\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">[24]</text><text x=\"600\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">36 proposed, 7 sure</text><text x=\"600\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 kept, 29 dropped</text><text x=\"600\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">54 proposed, 47 different</text><text x=\"600\" y=\"229\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 sure, both kept</text><text x=\"600\" y=\"297\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">12 proposed, 7 different</text><text x=\"600\" y=\"314\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 sure: solved</text></svg>", "caption": "The search tot printed for 4 9 10 13, level by level. Every possible step is proposed, each new state is judged, and only the best three stay in the tree; the solution is the path down the left."}
```

The answer, (4 − 10) × (9 − 13), uses negative numbers, which is not the first idea most people
try. A chain that started with `9 + 10 = 19`, the most obvious move, would have needed to find
`19 - 13 = 6` and then 4 × 6 = 24, which `tot` also kept at level 2. A chain that started with
4 × 10 = 40 would have gone nowhere, and would have had to admit it at the end.

## How many branches to keep

`--breadth` is how many states survive each level. With 1, the search keeps a single path:

```
ana@lab:~/pe$ tot 4 9 10 13 --breadth 1
level 1: 36 proposed, 36 different, 7 sure, 29 impossible
  keep  [9 13 -6]  after  4 - 10 = -6
level 2: 18 proposed, 18 different, 1 sure, 17 impossible
  keep  [-6 -4]  after  9 - 13 = -4
level 3: 6 proposed, 6 different, 1 sure, 5 impossible
  keep  [24]  after  -6 * -4 = 24
solved: 4 - 10 = -6; 9 - 13 = -4; -6 * -4 = 24
```

It solved the puzzle with 60 proposals instead of 102 (36 + 18 + 6 against 36 + 54 + 12). That is
not luck, and it is the most important thing to read in this capture: **`tot`'s judge is never
wrong.** It decides `sure` by trying every remaining combination, so a kept state always leads to
24, and one branch is enough.

A model's judgement is not like that. It reads three numbers and estimates whether 24 is still
reachable, and it can be wrong in both directions. With breadth 1, one wrong `sure` sends the whole
search down a dead end. **A larger breadth is insurance against a fallible judge**: the extra
branches cost proposals and judgements, and they are what is left when the favourite turns out to
be wrong. The method also allows going back: when every child of a kept state is judged
impossible, a depth-first version of the search returns to an earlier state and tries its next
branch. `tot` searches level by level and never needs to.

## When there is nothing to find

Some puzzles have no answer. A chain of thought asked for one tends to produce something anyway,
since an answer is the likely way for its text to end. The search reports the truth instead:

```
ana@lab:~/pe$ tot 1 1 1 1
level 1: 36 proposed, 3 different, 0 sure, 3 impossible
no state left: 24 cannot be made from 1 1 1 1
```

The 36 first steps reduce to 3 different states (two ones become 2, 0 or 1), none of them can
reach 24, and the search stops on the first level. **Running out of branches is an answer**: it
says no path was found, which is more useful than a fluent wrong one.
