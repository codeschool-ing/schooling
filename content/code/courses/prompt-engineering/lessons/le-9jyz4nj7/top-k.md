---
title: "Top-k: keep the k best"
version: 1
---

Temperature reshapes the whole list of next words, and the tail stays in it: at temperature 1,
`bitter` still has 3.7% after `the coffee is`, and in a large model's vocabulary of many thousands
of tokens the tail is enormous. Each word in it is unlikely, and together they are not. **Top-k
and top-p remove the tail before the draw instead of shrinking it.** Top-k is the simpler of the
two.

**Top-k keeps the k words with the highest scores, throws the rest away, and shares 100% among
the ones that are left.** With k set to 2:

```
ana@lab:~/pe$ toylm dist "the coffee is" --top-k 2
context: trigram after 'coffee is'
  hot       76.2%  ##############################
  strong    23.8%  ##########
```

`hot` and `strong` had 59.3% and 18.5%. Together that is 77.8%, and each is divided by it, so
`hot` becomes 76.2% and `strong` 23.8%. That step is called **renormalising**: the shares of what
survived are scaled up until they add up to 100% again, and the order between them does not
change. `ready`, `cold` and `bitter` cannot be drawn at all.

Six draws can only land on the two that are left:

```
ana@lab:~/pe$ toylm generate "the coffee is" --top-k 2 --samples 6
[seed 1] hot.
[seed 2] strong.
[seed 3] hot.
[seed 4] hot.
[seed 5] hot.
[seed 6] strong.
```

With k set to 1, top-k keeps a single word, and that is greedy decoding by another route:

```
ana@lab:~/pe$ toylm dist "the coffee is" --top-k 1
context: trigram after 'coffee is'
  hot      100.0%  ########################################
```

## What k does not know

The number is fixed, and the list it cuts is not. After `the coffee is`, keeping 2 drops
three words the model gave 22.2% between them. After `at seven` the model gives the full stop
100%, and k = 2 keeps one word because there is only one. At the start of a sentence, after
`the`, there are eight candidates:

```
ana@lab:~/pe$ toylm next "the"
context: trigram after '<s> the'
  coffee    29.9%  ############
  café      18.2%  #######
  bread     15.6%  ######
  cat       11.7%  #####
  tea       10.4%  ####
  cake       6.5%  ###
  soup       5.2%  ##
  menu       2.6%  #
```

Here k = 2 keeps `coffee` and `café`, 48.1% between them, and throws away more than half of what
the model considered likely: `bread`, `cat` and `tea` included.

**Top-k cuts the same number of words whether the model is sure or torn.** A k that is right for
one context is too tight for the next and too loose for the one after. That is the problem the
next section solves.
