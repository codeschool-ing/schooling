---
title: Numbered pieces of text
version: 1
---

It is natural to assume a model reads the way you do, letter by letter or word by word. It reads
neither. **Before a model sees any text, a tokenizer cuts it into pieces from a fixed list, and
replaces each piece with its number in that list.** The pieces are tokens, the list is the
vocabulary, and the numbers are all the model ever receives.

`tok` is a real tokenizer, the same code production systems run before a request reaches a model.
`tok show` prints the pieces in quotes, then their numbers, then the count:

```
ana@lab:~/pe$ tok show "The kitchen stops taking hot food orders thirty minutes before closing."
"The" " kitchen" " stops" " taking" " hot" " food" " orders" " thirty" " minutes" " before" " closing" "."
976 10084 29924 6167 3648 4232 12528 37650 5438 2254 23436 13
12 tokens, 71 characters (o200k_base)
```

Eleven words and a full stop, twelve tokens. Each word is one piece, and **the space in front of a
word belongs to the token**: the piece is `" kitchen"`, space included, and its number is 10084.
`"The"` has no space because it starts the text. The numbers mean nothing in themselves; 976 is
simply where `"The"` sits in the list.

The same sentence in Portuguese:

```
ana@lab:~/pe$ tok show "A cozinha para de aceitar pedidos de comida quente trinta minutos antes de fechar."
"A" " cozinha" " para" " de" " aceitar" " pedidos" " de" " comida" " quente" " tr" "inta" " minutos" " antes" " de" " fechar" "."
32 66509 1209 334 136247 88184 334 46215 109042 498 11405 22491 13290 334 128464 13
16 tokens, 82 characters (o200k_base)
```

Sixteen tokens. Most words are still one piece each, but `trinta` came out as `" tr"` and `"inta"`.
The vocabulary has a token for `" cozinha"` and none for `" trinta"`, so the tokenizer spelt the
word out of two smaller pieces it does have.

## Common is whole, rare is spelt

Which words get a token of their own is decided by how common they were in the text the tokenizer
was built from. A word that is not common enough is cut into pieces that are:

```
ana@lab:~/pe$ tok show "sourdough"
"s" "ourd" "ough"
82 43170 1870
3 tokens, 9 characters (o200k_base)
ana@lab:~/pe$ tok show "https://example.com/menu?day=sunday"
"https" "://" "example" ".com" "/menu" "?" "day" "=s" "unday"
4172 1684 18582 1136 90042 30 1635 32455 8514
9 tokens, 35 characters (o200k_base)
ana@lab:~/pe$ tok show "if price > 100: approve()"
"if" " price" " >" " " "100" ":" " approve" "()"
366 3911 1424 220 1353 25 45828 416
8 tokens, 25 characters (o200k_base)
```

`sourdough` is an ordinary English word and still three pieces. The address is nine, cut where
addresses are usually cut, at `://` and `.com`, until `sunday` arrives glued to the `=` before it
and comes out as `"=s"` and `"unday"`. The line of code is eight, and one of them is a space on its
own.

**The cut depends on the exact characters**, including the ones you would not think of as
different:

```
ana@lab:~/pe$ tok show "seven"; tok show "SEVEN"
"seven"
153671
1 tokens, 5 characters (o200k_base)
"SE" "VEN"
1529 70318
2 tokens, 5 characters (o200k_base)
ana@lab:~/pe$ tok show " strawberry"; tok show "strawberry"
" strawberry"
101830
1 tokens, 11 characters (o200k_base)
"st" "raw" "berry"
302 1618 19772
3 tokens, 10 characters (o200k_base)
```

`seven` is one token and `SEVEN` is two. `" strawberry"` with its space is one token, number 101830,
and `strawberry` without one is three. To you these are the same word; to the model they are
different sequences of numbers, which it learnt about separately.

## Why pieces, and not words or letters

There are two obvious alternatives, and both fail. **A vocabulary of whole words** would need a
number for every word in every language, every name and every typo, and it would still meet words
it had never seen. **A vocabulary of single letters** could spell anything, and would make every
text several times longer, which matters because everything a model does is paid for per token.

Pieces sit between the two. The method most tokenizers use, byte-pair encoding, starts from
single bytes and repeatedly merges the pair that occurs most often in a large body of text, until
the list reaches the size it was given. Frequent words end up whole; rare ones are spelt from
fragments; and since the single bytes are still in the list, **any text at all can be written down,
however unusual**. Nothing is ever "out of vocabulary". The worst case is that it costs more
tokens.

## Two vocabularies, two counts

The encoding `tok` uses unless told otherwise is `o200k_base`. OpenAI publishes it together with an
older one, `cl100k_base`, and the number in each name is roughly the size of its vocabulary: about
two hundred thousand pieces and about a hundred thousand. You can see it in the ids above, which
go past 150,000. Here is the Portuguese sentence cut by the smaller vocabulary:

```
ana@lab:~/pe$ tok show "A cozinha para de aceitar pedidos de comida quente trinta minutos antes de fechar." -e cl100k_base
"A" " coz" "inha" " para" " de" " ace" "itar" " ped" "idos" " de" " comida" " qu" "ente" " tr" "inta" " minutos" " antes" " de" " fe" "char" "."
32 85920 44338 3429 409 27845 12635 10696 13652 409 98878 934 6960 490 34569 52762 34435 409 1172 1799 13
21 tokens, 82 characters (cl100k_base)
```

Twenty-one tokens where `o200k_base` needed sixteen. `cozinha`, `aceitar`, `pedidos`, `quente` and
`fechar` all lost their place as whole words. The English sentence did not move:

```
ana@lab:~/pe$ tok show "The kitchen stops taking hot food orders thirty minutes before closing." -e cl100k_base
"The" " kitchen" " stops" " taking" " hot" " food" " orders" " thirty" " minutes" " before" " closing" "."
791 9979 18417 4737 4106 3691 10373 27219 4520 1603 15676 13
12 tokens, 71 characters (cl100k_base)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The sentence A cozinha para de aceitar pedidos de comida quente trinta minutos antes de fechar, shown twice as rows of boxes, one box per token. With o200k_base it is 16 pieces: every word is one piece except trinta, cut into tr and inta. With cl100k_base it is 21 pieces: cozinha, aceitar, pedidos, quente, trinta and fechar are each cut in two.\"><text x=\"14\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">o200k_base</text><text x=\"110\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">16 pieces</text><rect x=\"14\" y=\"42\" width=\"13.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"20.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">A</text><rect x=\"33.0\" y=\"42\" width=\"49.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"57.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cozinha</text><rect x=\"88.0\" y=\"42\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"103.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">para</text><rect x=\"125.0\" y=\"42\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"134.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">de</text><rect x=\"150.0\" y=\"42\" width=\"49.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"174.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">aceitar</text><rect x=\"205.0\" y=\"42\" width=\"49.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"229.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pedidos</text><rect x=\"260.0\" y=\"42\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"269.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">de</text><rect x=\"285.0\" y=\"42\" width=\"43.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"306.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">comida</text><rect x=\"334.0\" y=\"42\" width=\"43.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"355.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">quente</text><rect x=\"383.0\" y=\"42\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"392.5\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">tr</text><rect x=\"403.5\" y=\"42\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"419.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">inta</text><rect x=\"440.5\" y=\"42\" width=\"49.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"465.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">minutos</text><rect x=\"495.5\" y=\"42\" width=\"37.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">antes</text><rect x=\"538.5\" y=\"42\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"548.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">de</text><rect x=\"563.5\" y=\"42\" width=\"43.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"585.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fechar</text><rect x=\"612.5\" y=\"42\" width=\"13.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"619.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.</text><text x=\"14\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">cl100k_base</text><text x=\"118\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">21 pieces</text><rect x=\"14\" y=\"112\" width=\"13.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"20.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">A</text><rect x=\"33.0\" y=\"112\" width=\"25.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"45.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">coz</text><rect x=\"59.5\" y=\"112\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"75.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">inha</text><rect x=\"96.5\" y=\"112\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"112.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">para</text><rect x=\"133.5\" y=\"112\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"143.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">de</text><rect x=\"158.5\" y=\"112\" width=\"25.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"171.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ace</text><rect x=\"185.0\" y=\"112\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"200.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">itar</text><rect x=\"222.0\" y=\"112\" width=\"25.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"234.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ped</text><rect x=\"248.5\" y=\"112\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"264.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">idos</text><rect x=\"285.5\" y=\"112\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"295.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">de</text><rect x=\"310.5\" y=\"112\" width=\"43.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"332.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">comida</text><rect x=\"359.5\" y=\"112\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"369.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">qu</text><rect x=\"380.0\" y=\"112\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"395.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ente</text><rect x=\"417.0\" y=\"112\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"426.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">tr</text><rect x=\"437.5\" y=\"112\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"453.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">inta</text><rect x=\"474.5\" y=\"112\" width=\"49.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"499.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">minutos</text><rect x=\"529.5\" y=\"112\" width=\"37.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"548.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">antes</text><rect x=\"572.5\" y=\"112\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"582.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">de</text><rect x=\"597.5\" y=\"112\" width=\"19.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"607.0\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">fe</text><rect x=\"618.0\" y=\"112\" width=\"31.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"633.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">char</text><rect x=\"655.0\" y=\"112\" width=\"13.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"661.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.</text><rect x=\"14\" y=\"166\" width=\"14\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"34\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a whole word, with its space</text><rect x=\"300\" y=\"166\" width=\"14\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"320\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one word, cut</text></svg>", "caption": "One Portuguese sentence, cut by the two encodings. The bigger vocabulary keeps more words whole; the older one spells them out of smaller pieces, and the sentence costs five more tokens."}
```

**A bigger vocabulary, built from more text in more languages, closes some of the gap for languages
other than English**, and does not close all of it: Portuguese still took sixteen tokens where
English took twelve. The section after this one counts whole files, where the gap becomes money.

At the time of writing (2026), OpenAI's newer models use `o200k_base` and its older ones
`cl100k_base`. Other providers use tokenizers of their own; some publish them, and others only
count tokens for you through their API. **A count from one tokenizer is an estimate for any
other**, which is why the counts in this course always name the encoding they came from. To find
out which one a model uses, look in the provider's documentation for that model, and check the
date on the page.
