---
title: Choosing a model, and checking what you read
version: 1
---

The tempting way to choose is to find a comparison table, pick the model at the top, and move on.
The table was out of date before you found it, and it ranked models on somebody else's tasks.
**The model to use is the cheapest one that does your task well enough, measured on your task.**
Everything below is how to find it.

## The criteria

| criterion | the question to ask |
|---|---|
| quality on your task | how many of your own test cases does it get right? |
| cost | what does one of your typical requests cost, input and output together? |
| latency | how long does a reply take, and how long can your user wait? |
| context size | does your longest real input fit, with room for the reply (lesson 4)? |
| data policy | where do your prompts go, and what happens to them (the previous section)? |
| availability | is it offered in your region, and at the volume you need? |
| lifetime | when will this exact model be retired, and what will replacing it cost? |

The first row is the one people skip. **Twenty to fifty real examples from your own work, with
the answer you would accept for each, tell you more than any public score.** They are
your inputs, in your language, with your edge cases, and nobody trained a model on them (lesson
10). Run each candidate on the same set, count, and keep the set: when a model is retired, the same
set tells you whether its replacement is as good.

## A price per token is not a price per task

Providers price per million tokens, and it is tempting to compare those numbers directly. They do
not compare, because **each provider's models split text into tokens their own way**, so the same
request is a different number of tokens at each one. The workbench has two tokenizers, both
OpenAI's, an older encoding and a newer one, and they disagree on one Portuguese sentence:

```
ana@lab:~/pe$ tok show "O café abre às oito aos domingos." -e cl100k_base
"O" " café" " abre" " às" " o" "ito" " aos" " dom" "ing" "os" "."
46 53050 67441 53629 297 6491 43914 4824 287 437 13
11 tokens, 33 characters (cl100k_base)
ana@lab:~/pe$ tok show "O café abre às oito aos domingos." -e o200k_base
"O" " café" " abre" " às" " oito" " aos" " domingos" "."
46 30469 59024 16683 99497 13924 194577 13
8 tokens, 33 characters (o200k_base)
```

The older encoding cuts `oito` and `domingos` into pieces and needs 11 tokens; the newer one has
both as whole words and needs 8. On the café's English handbook the two are much closer:

```
ana@lab:~/pe$ tok count handbook/*.md -e cl100k_base
tokens  words  chars  file
    73     55    310  handbook/allergens.md
    61     44    249  handbook/deliveries.md
    66     46    261  handbook/hours.md
    59     50    260  handbook/loyalty.md
    75     62    318  handbook/refunds.md
    49     35    209  handbook/wifi.md
ana@lab:~/pe$ tok count handbook/*.md -e o200k_base
tokens  words  chars  file
    70     55    310  handbook/allergens.md
    60     44    249  handbook/deliveries.md
    65     46    261  handbook/hours.md
    58     50    260  handbook/loyalty.md
    74     62    318  handbook/refunds.md
    48     35    209  handbook/wifi.md
```

That is two encodings from one provider. Other providers' tokenizers differ again, and none of them
is in the workbench, so this course shows no count for them. The rule that follows does not need
one: **compare what a whole typical request costs at each provider**, which their own token
counters or a test request will tell you, not the price per million.

## How to check what you read

Every fact in this lesson's first section has a date on it, and so does everything you read about
models. Three sources, in order of trust:

- the model card, the provider's own page or file for one exact model, saying what it was
  built for, its context size, its limits and its licence. Read the card for the exact model and
  version you will call, not for the family;
- the provider's documentation and pricing pages, which say what is available, where and at what
  price. Look for the date the page was last updated, and treat an undated page with suspicion;
- everything else, including comparison tables, articles and this course, as a pointer to what to
  check in the first two.

**A comparison table in a course is out of date within months**, which is why this one has none.
What does not go out of date is the method: your own test set, the cost of a whole request, and
the provider's dated documents.

::: track ai
The `ai-models` course, further along this track, takes this on: the providers one by
one, when running open-weight models yourself pays, and how to evaluate candidates against your own
cases.
:::

::: track *
This course goes no further into choosing models. The method above is enough to choose one for
the prompts the rest of the course teaches.
:::
