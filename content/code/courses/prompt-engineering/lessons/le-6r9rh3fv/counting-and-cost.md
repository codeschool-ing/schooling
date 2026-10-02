---
title: Counting tokens, and what they cost
version: 1
---

When people estimate the size of a prompt they count words, or characters, because that is what a
word processor shows. **Every limit and every price on a language model is counted in tokens**,
and the three numbers do not move together. Two files with the café's opening hours, one in each
language, say the same thing:

```
ana@lab:~/pe$ cat hours.en.txt hours.pt.txt
Café Aurora opens at seven and closes at six from Monday to Saturday.
On Sundays and public holidays it opens at eight and closes at noon.
The kitchen stops taking hot food orders thirty minutes before closing.
O Café Aurora abre às sete e fecha às seis, de segunda a sábado.
Aos domingos e feriados, abre às oito e fecha ao meio-dia.
A cozinha para de aceitar pedidos de comida quente trinta minutos antes de fechar.
```

`tok count` gives tokens, words and characters for each file:

```
ana@lab:~/pe$ tok count hours.en.txt hours.pt.txt
tokens  words  chars  file
    41     37    211  hours.en.txt
    48     39    207  hours.pt.txt
```

The Portuguese is two words longer and four characters shorter, and it is **seven tokens more**:
48 against 41. Neither the word count nor the character count would have told you which file was
bigger to a model. Counted with the older vocabulary from the section before, the gap opens
further:

```
ana@lab:~/pe$ tok count hours.en.txt hours.pt.txt -e cl100k_base
tokens  words  chars  file
    42     37    211  hours.en.txt
    59     39    207  hours.pt.txt
```

59 against 42. The same text, sent in Portuguese to a model that uses `cl100k_base`, costs about
two-fifths more than in English, and fills its window faster. **If your users write in a language
other than English, measure with their text**, never with an English sample and a rule of thumb.

## Why the meter runs in tokens

Lesson 1 showed generation as a loop: score the next piece, pick one, add it, score again. `toylm`
reported its own accounting at the end of each run, `prompt 4 tokens, output 2 tokens`, and a model
API returns the same two numbers with every reply. They are the honest measure of the work done:

- every **input** token has to be read by the model before it writes anything;
- every **output** token is one turn of the loop, written one after another.

So a provider bills both, per token, and **prices them separately**. The input tokens can be
processed together, in one pass; the output tokens cannot, because each one depends on the one
before it. In the price lists of the large providers at the time of writing (2026), an output token
costs more than an input token, often several times more. Prices change, and differ between models
of the same provider, so the only number worth using is the one on the provider's pricing page on
the day you calculate, with the date written beside it.

## Working out a cost

`tok cost` takes a file as the input, the number of output tokens you expect, and two prices per
million tokens. **The prices below are illustrative, typed on the command line**: 2 per million for
input and 8 for output, in no particular currency. They are not any provider's prices.

```
ana@lab:~/pe$ tok cost hours.pt.txt -o 300 -i 2 -p 8
input  48 tokens x 2 per million = 0.000096
output 300 tokens x 8 per million = 0.002400
one request: 0.002496
10,000 requests: 24.96
```

The input is the 48 tokens `tok count` measured; the output is a guess of 300, a long reply. A
single request costs 0.002496, too little for anybody to notice, and ten thousand of them cost
24.96. Shorten the expected reply to 30 tokens and nothing else changes:

```
ana@lab:~/pe$ tok cost hours.pt.txt -o 30 -i 2 -p 8
input  48 tokens x 2 per million = 0.000096
output 30 tokens x 8 per million = 0.000240
one request: 0.000336
10,000 requests: 3.36
```

From 24.96 to 3.36. **Here the output was most of the bill**, because there were six times as many
output tokens as input ones and each cost four times as much. With a short prompt and a long reply
that is the usual shape; with a long document pasted into the prompt and a one-line answer, the
input dominates instead. The calculation is the same either way, and it is worth doing before you
build, not after the first invoice.

Three things make a real bill larger than one prompt suggests:

- the whole conversation is sent again with every turn (lesson 2), so the tenth message of a chat
  **pays for the nine before it** as input;
- the system prompt is sent with every request, however many there are, so a long one is **paid
  for thousands of times a day**;
- the output length is not yours to decide unless you set a limit, which is lesson 15.

Lesson 4 is about the other thing tokens are counted against: the size of the window a model can
see at once.
