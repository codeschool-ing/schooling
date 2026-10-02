---
title: Two ways to penalise a repeat
version: 1
---

A penalty is sometimes described as an instruction to "be more varied". The model receives no
such instruction. **A penalty is arithmetic on the scores: before each step, every word that has
already appeared in the output has an amount subtracted from its score.** The two penalties
differ only in how that amount is worked out.

`toylm` applies them first, before temperature, top-k and top-p (lesson 14), and counts only the
words it has written, not the prompt. For each word already in the output:

| penalty | what is subtracted from the word's score |
|---|---|
| frequency penalty F | F × the number of times the word has appeared so far |
| presence penalty P | P, once, if the word has appeared at all |

The frequency penalty grows with every repeat. The presence penalty is a flat charge for having
been used, the same after one use or ten.

## Both break this loop

```
ana@lab:~/pe$ toylm generate "the cat" --temperature 0 --max-tokens 20 --frequency-penalty 0.5
sleeps and the cat sleeps on the chair by the window.
-- finish: end, prompt 2 tokens, output 12 tokens
ana@lab:~/pe$ toylm generate "the cat" --temperature 0 --max-tokens 20 --presence-penalty 1
sleeps and the cat sleeps on the chair by the window.
-- finish: end, prompt 2 tokens, output 12 tokens
```

With either penalty, the second time the text reaches `cat sleeps` the word `and` has already
been used once. Its score drops below `on`, the loop takes `on`, and the sentence finishes the
way the corpus finishes it: `on the chair by the window`, then the end.

## And they are not the same control

The gap they have to close is fixed. In the scores, `and` leads `on` by the logarithm of 60/40,
about 0.41. A penalty breaks the loop only when what it subtracts from `and` exceeds that. Set
both to 0.2:

```
ana@lab:~/pe$ toylm generate "the cat" --temperature 0 --max-tokens 20 --frequency-penalty 0.2
sleeps and the cat sleeps and the cat sleeps and the cat sleeps on the chair by the window.
-- finish: length, prompt 2 tokens, output 20 tokens
ana@lab:~/pe$ toylm generate "the cat" --temperature 0 --max-tokens 20 --presence-penalty 0.2
sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat
-- finish: length, prompt 2 tokens, output 20 tokens
```

**The frequency penalty got there after the third `and`; the presence penalty never did.** After
one `and`, F = 0.2 subtracts 0.2; after two, 0.4, still just short; after three, 0.6, and `on`
wins. The presence penalty subtracts 0.2 after the first `and` and never more, so `and` keeps its
lead for ever and the loop runs to the limit. The frequency run happened to end its sentence on
the twentieth token, which is why it still reports `length` (lesson 15).

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A line chart. The horizontal axis is how many times and has already been written, 0 to 4. The vertical axis is the amount subtracted from its score. A dashed line at 0.41 marks the lead and has over on. The frequency penalty of 0.2 rises 0, 0.2, 0.4, 0.6, 0.8 and crosses the dashed line between 2 and 3. The presence penalty of 0.2 goes 0, then 0.2 and stays flat, below the line.\"><path d=\"M90 45 L90 220 L580 220\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"210.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"330.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"450.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"570.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"82\" y=\"182.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.2</text><text x=\"82\" y=\"144.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.4</text><text x=\"82\" y=\"106.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.6</text><text x=\"82\" y=\"68.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.8</text><text x=\"330.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">times “and” has already been written</text><text x=\"40\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">subtracted from its score</text><path d=\"M90 143.5 L570 143.5\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"576\" y=\"143.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the gap to beat: 0.41</text><path d=\"M90.0 220.0 L210.0 182.2 L330.0 144.4 L450.0 106.7 L570.0 68.9\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M90.0 220.0 L210.0 182.2 L330.0 182.2 L450.0 182.2 L570.0 182.2\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"576.0\" y=\"68.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">frequency 0.2</text><text x=\"576.0\" y=\"182.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">presence 0.2</text><rect x=\"446.0\" y=\"102.7\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"450.0\" y=\"90.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">breaks here</text></svg>", "caption": "What each penalty subtracts from the score of “and”, as the loop repeats it. The frequency penalty climbs past the 0.41 lead that “and” has over “on”, and the loop breaks on the third repeat; the presence penalty stays at 0.2 and never does."}
```

So the frequency penalty is the one that leans harder on a word the more it is repeated, and
suits loops and lists that grind on. The presence penalty pushes the text towards words it has
not used yet at all, which is closer to "change the subject".

## Too much of either

A penalty cannot tell a repeat that is a fault from a repeat that is the language. Words like
`is` and `the` have to appear again and again in ordinary sentences. With no penalty, `toylm`
writes this after `question :`:

```
ana@lab:~/pe$ toylm generate "question :" --temperature 0
is the bread is fresh.
-- finish: end, prompt 2 tokens, output 6 tokens
```

Clumsy, because two words of context cannot see the whole question, and built from pieces of its
file. With a presence penalty of 5, every word it has used is pushed far down:

```
ana@lab:~/pe$ toylm generate "question :" --temperature 0 --presence-penalty 5
is the bread comes out of the day? answer: yes.
-- finish: end, prompt 2 tokens, output 13 tokens
```

After `the bread` the likeliest word is `is`, by a long way:

```
ana@lab:~/pe$ toylm next "the bread"
context: trigram after 'the bread'
  is        76.5%  ###############################
  comes     11.8%  #####
  fresh     11.8%  #####
```

`is` had already been used at the start of the question, so the penalty pushed it below `comes`,
and from there the text wandered: `comes out of the`, then `day`, then a question mark where `is`
would have gone. **A penalty set too high forces the model off the words a sentence needs onto
words it did not need**, and the output gets stranger, not better.

The damage is worse wherever repetition is the point: a JSON reply repeats quotes and braces, a
program repeats its variable names, and an answer about one person repeats their name. Penalties
for those are left at 0.

## Ranges and defaults

Where an API offers these two controls, the usual pattern is that both default to 0, which means
off, and that the provider documents a range, sometimes including negative values that make
repetition more likely. Not every API offers them, and whether they count the output alone, as
`toylm` does, or the prompt as well is the provider's decision. **Start at 0, raise one of them in small steps while you read the
output, and stop as soon as the repetition stops.** Read the reference of the API you call, and
the date on it, for the range and for what it counts.
