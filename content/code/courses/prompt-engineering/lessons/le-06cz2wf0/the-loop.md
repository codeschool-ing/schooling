---
title: Why greedy decoding goes round in circles
version: 1
---

Repetition looks like a fault in the model, a bug somebody should fix. It is closer to the
opposite. **A model that always takes its likeliest next word will repeat itself whenever the
likeliest words lead back to where they started**, and nothing in the scores knows that the text
has been there before.

Lesson 15 used this run to show what a token limit is for:

```
ana@lab:~/pe$ toylm generate "the cat" --temperature 0 --max-tokens 20
sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat
-- finish: length, prompt 2 tokens, output 20 tokens
```

Now look at why. Each step looks only at the last two words, and here is what each pair offers:

```
ana@lab:~/pe$ toylm next "the cat"
context: trigram after 'the cat'
  sleeps    66.7%  ###########################
  wakes     20.0%  ########
  sat       13.3%  #####
ana@lab:~/pe$ toylm next "cat sleeps"
context: trigram after 'cat sleeps'
  and       60.0%  ########################
  on        40.0%  ################
ana@lab:~/pe$ toylm next "sleeps and"
context: trigram after 'sleeps and'
  the      100.0%  ########################################
ana@lab:~/pe$ toylm next "and the"
context: trigram after 'and the'
  cat       35.3%  ##############
  coffee    23.5%  #########
  bread     17.6%  #######
  café      11.8%  #####
  terrace   11.8%  #####
```

Follow the top line of each table: after `the cat`, `sleeps`; after `cat sleeps`, `and`; after
`sleeps and`, `the`; after `and the`, `cat`. **The four likeliest steps form a circle**, and at
temperature 0 the loop takes the likeliest step every time, so it goes round until the limit
stops it. Each choice is reasonable on its own. `and` beats `on` by 60% to 40%, and `cat` leads
after `and the`. The sentence is absurd only as a whole.

## The same thing in a large model

A large model looks much further back than two words, and its circles are bigger: the same
sentence repeated, a list that keeps adding the same item, a paragraph that restates the one
above it. The cause is the same. Text that has just appeared makes similar text likely, and
**a model scores the next token without any rule against saying the same thing again**.

Sampling at a temperature above 0 breaks many circles by chance, since a draw sometimes takes the
second choice. That is why repetition is most visible at low temperatures, exactly where you set
them for reliability (lesson 13). The two controls in the next section break the circle on
purpose instead of by luck: they lower the score of words the output has already used.
