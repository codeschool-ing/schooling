---
title: What a weight is
version: 1
---

Two pictures of a model's insides are common, and both are wrong. One is a library: the model
keeps the sentences it read and finds the right one when asked. The other borrows a word from the
API: a model's "parameters" are its settings, the temperature and the token limit. **A model's
parameters are the numbers it learnt, and the model is those numbers.** It stores no sentences,
and the settings you pass with a request are something else, which lessons 13 to 17 cover.

The smallest model you can open is the one in the workbench. Lesson 1 printed its size, and the
last line is the one this lesson is about:

```
ana@lab:~/pe$ toylm info
corpus:        761 words in corpus.txt
vocabulary:    72 distinct words
trigram rows:  152 contexts, 212 counts
bigram rows:   72 contexts, 152 counts
parameters:    436 stored counts
```

`toylm` has **436 parameters**, and every one is a count. `toylm save` writes them all to a file,
which is the whole model on disk:

```
ana@lab:~/pe$ toylm save model.json
ana@lab:~/pe$ ls -l model.json
-rw-r--r-- 1 ana ana 7478 Oct  2 00:14 model.json
ana@lab:~/pe$ head -c 240 model.json; echo
{"bigram": {",": {"bread": 2}, ".": {"</s>": 98, "question": 6}, ":": {"at": 4, "is": 6, "tomato": 2, "what": 2, "when": 4, "yes": 6}, "<s>": {"ana": 4, "bruno": 5, "it": 6, "question": 6, "the": 77}, "?": {"answer": 12}, "a": {"coffee": 5,
```

Read one entry: `"<s>": {... "the": 77}` says that 77 lines of the corpus begin with `the`. Each
number is a parameter. The percentages lesson 1 printed come straight out of them:

```
ana@lab:~/pe$ python3 -c "import json; print(json.load(open('model.json'))['trigram']['coffee is'])"
{'bitter': 1, 'cold': 2, 'hot': 16, 'ready': 3, 'strong': 5}
```

Those five counts add up to 27, and `hot` is 16 of them, which is the 59.3% that `toylm next "the
coffee is"` showed. **Change a number in this file and the model's answer changes with it.** There
is nothing else in the model to change.

## What a large model's weights are

A large language model has the same arrangement, and lesson 1 named the difference that matters
here: its parameters are not counts. **They are numbers learnt by training**, usually
called weights, and no single one means anything you could read. Where `toylm` has `"hot": 16`, a
neural network has billions of numbers like `-0.4121` and `0.0173`, and the score for `hot` comes
out of multiplying the text's tokens through all of them.

Training is how they get their values. The network starts with random numbers, reads a stretch of
text, scores every possible next token, and checks the score it gave to the token that really came
next. Every weight is then nudged a tiny amount in the direction that would have made that token
more likely. Repeated over an enormous amount of text, the nudges add up to grammar, facts that
were common in the text, and the shapes of programs and arguments.

That has two consequences that surprise people:

- you cannot search the weights for a sentence: what the model read is spread across all of
  them, mixed with everything else it read. That is why it can produce fluent text that appears
  nowhere in its training data, and why it can be wrong about a fact it read many times;
- the weights do not change while you use the model, and a conversation does not teach it
  anything; what it "remembers" within a chat is the earlier text sent again as input, which is
  lesson 4. Changing the weights is a separate job, and lesson 9 is about when it is worth doing.

## What "7B" means

When a model is described as **7B, it has seven billion weights**; 70B is seventy billion. The
letter is the word *billion* and nothing more. "Parameters" and "weights" are used for the same
thing in announcements, and strictly the parameters are all the learnt numbers, weights and a
smaller set of offsets called biases together.

The count is a measure of size, not of quality. A larger model has room for more patterns, and two
models with the same count can differ a great deal because of what they were trained on and for
how long. What the count does decide, exactly, is how much memory the model needs, and that is the
next section.
