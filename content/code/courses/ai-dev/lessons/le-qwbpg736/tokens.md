---
title: Tokens are not words
version: 2
---

The obvious guess is that a model reads words. It does not: it reads **tokens**, pieces of text
from a fixed vocabulary that a **tokenizer** chose before the model was trained. Common words are
one token. Rare words, other languages, numbers and code are split into several. Since every
limit and every price in this course is counted in tokens, it is worth seeing where the
boundaries fall.

## Splitting text into tokens

`~/shop/scratch/tokens.py` prints each line's token count, its character count, and the pieces
with a `|` between them. The encoding is `o200k_base`, through OpenAI's own `tiktoken` library;
the next part of this section shows which models it belongs to:

```python
import sys

import tiktoken

enc = tiktoken.get_encoding(sys.argv[1])
for line in sys.stdin:
    text = line.rstrip("\n")
    ids = enc.encode(text)
    print(f"{len(ids):3} tokens  {len(text):3} chars  " + "|".join(enc.decode([i]) for i in ids))
```

```
ana@dev:~/shop$ printf "%s\n" "Tokenisation is not splitting on spaces." "Tokenization is not splitting on spaces." "A tokenização não divide o texto nos espaços." "def total(self) -> int:" "        return self.subtotal()" "1290 12900 129000 1290000" | python scratch/tokens.py o200k_base
  8 tokens   40 chars  Token|isation| is| not| splitting| on| spaces|.
  8 tokens   40 chars  Token|ization| is| not| splitting| on| spaces|.
 10 tokens   45 chars  A| token|ização| não| divide| o| texto| nos| espaços|.
  7 tokens   23 chars  def| total|(self|)| ->| int|:
  6 tokens   30 chars         | return| self|.sub|total|()
 12 tokens   25 chars  129|0| |129|00| |129|000| |129|000|0
```

Five things to read off that:

- **The space belongs to the word after it.** ` is`, ` not` and ` splitting` are single tokens,
  space included, which is why section 06's distribution was full of `' sum'` rather than
  `'sum'`.
- **A word the tokenizer saw often is one token; a rarer one is two.** `Tokenisation` and
  `Tokenization` both split into `Token` plus a suffix.
- **The Portuguese sentence costs more.** Ten tokens for a sentence a Portuguese reader finds
  no longer than the English one. Text in languages that were rarer in the tokenizer's training
  data splits into more pieces, so the same request costs more and fills the window faster.
- **Code splits at its punctuation.** `(self`, `.sub` and `total` are tokens; seven of the eight
  spaces of indentation are one more, and the eighth goes with ` return`.
- **Numbers are cut into groups of up to three digits.** The model never sees `1290000` as a
  number, only as the pieces `129`, `000` and `0`. That is one reason models are unreliable at
  arithmetic done digit by digit, and why the shop in this course does its money in code
  rather than asking a model to add.

## Different tokenizers, different counts

A tokenizer belongs to a model family. `tiktoken` knows which of OpenAI's encodings goes with
which model:

```
ana@dev:~/shop$ python -c 'import tiktoken; [print(m, tiktoken.encoding_name_for_model(m)) for m in ("gpt-4", "gpt-4o", "gpt-5")]'
gpt-4 cl100k_base
gpt-4o o200k_base
gpt-5 o200k_base
```

And the same text gives different counts under different encodings:

```
ana@dev:~/shop$ printf "%s\n" "A tokenização não divide o texto nos espaços." "        return self.subtotal()" | python scratch/tokens.py cl100k_base
 11 tokens   45 chars  A| token|ização| não| divide| o| texto| nos| espa|ços|.
  6 tokens   30 chars         | return| self|.sub|total|()
```

The code came out the same and the Portuguese did not: `espaços` is one token in the newer
vocabulary and two in the older. **A token count is only meaningful for a named tokenizer.**
OpenAI publishes its encodings, which is why `tiktoken` can run them on your machine. Anthropic and
Google do not publish theirs, and offer an endpoint that counts tokens for you instead, which
lesson 2 uses. `llama3.2:3b` has a tokenizer of its own, Meta's, and Ollama reports its counts in
every reply. **What you measure with `tiktoken` for any other model is an estimate.**

## How many tokens is a file?

Code is denser in tokens than prose. Here are the shop's source files:

```
ana@dev:~/shop$ python -c 'import tiktoken, pathlib; e = tiktoken.get_encoding("o200k_base"); [print(f"{len(e.encode(p.read_text())):5} tokens {len(p.read_text().split()):5} words  {p}") for p in sorted(pathlib.Path("shop").glob("*.py"))]'
    0 tokens     0 words  shop/__init__.py
  265 tokens   121 words  shop/cart.py
   91 tokens    41 words  shop/coupons.py
  137 tokens    66 words  shop/money.py
```

`cart.py` is 265 tokens for 121 whitespace-separated words, a little over two tokens a word. The
project's `CONVENTIONS.md`, which is English sentences, comes to far fewer per word:

```
ana@dev:~/shop$ python -c 'import tiktoken, pathlib; t = pathlib.Path("CONVENTIONS.md").read_text(); print(len(t.split()), "words,", len(tiktoken.get_encoding("o200k_base").encode(t)), "tokens")'
272 words, 374 tokens
```

That is about 1.4 tokens a word. **Measure your own
material rather than trusting a rule of thumb**, because the ratio moves with the language, the
subject and the tokenizer, and a cost estimate inherits whatever error the ratio has.
