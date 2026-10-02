---
title: Using the controls together
version: 1
---

An API that offers temperature, top-k and top-p lets you set all three in one request, and the
belief that they are three separate dials is where people get surprised. **They act on the same
list one after another, so each one sees what the one before it left.**

`toylm` applies them in a fixed order, written in the docstring at the top of the program:

```localised
penalties → temperature → top-k → top-p → draw
```

Penalties are lesson 17. The rest you have already seen, and the order matters most between
temperature and top-p. In the previous section, p = 0.8 after `the coffee is` kept three words at
temperature 1. At temperature 2:

```
ana@lab:~/pe$ toylm dist "the coffee is" --temperature 2 --top-p 0.8
context: trigram after 'coffee is'
  hot       42.6%  #################
  strong    23.8%  ##########
  ready     18.5%  #######
  cold      15.1%  ######
```

The shares were flattened before top-p measured them, so it took four words to reach 80%. At
0.5 the leader already had 86.8% after the division (lesson 13), so the nucleus is `hot` alone:

```
ana@lab:~/pe$ toylm dist "the coffee is" --temperature 0.5 --top-p 0.8
context: trigram after 'coffee is'
  hot      100.0%  ########################################
```

**Raising the temperature also widens the nucleus, and lowering it narrows it.** Change the
temperature while top-p is set and you have changed two things.

In `toylm`, top-k and top-p together keep whichever set is smaller. Here top-k 3 keeps three words and top-p 0.8
also needs three, so the result is what top-p alone gave:

```
ana@lab:~/pe$ toylm dist "the coffee is" --top-k 3 --top-p 0.8
context: trigram after 'coffee is'
  hot       66.7%  ###########################
  strong    20.8%  ########
  ready     12.5%  #####
```

Not every implementation uses this order, and the tables above show that the order changes the
result. Where it matters, read the documentation of the API you call or, as here, the source of the
program.

## One control at a time

**Change one control, look at the output, and only then change the next.** With two changed at
once you cannot tell which one produced what you see, and as the tables above show, they do not
add up simply.

A sound way to start:

- leave top-k and top-p at the provider's defaults and adjust temperature first, because it is
  the one with a visible, continuous effect (lesson 13);
- reach for top-p when the output occasionally goes strange at a temperature you otherwise like.
  It removes the tail without making the common choices any more uniform;
- treat top-k as a blunt backstop, a cap on how many candidates a draw may ever consider.

Some providers recommend changing either temperature or top-p and not both; when the
documentation says so, follow it.

## Not every API offers all of them

The set of controls is the provider's choice. At the time of writing (2026), temperature is
nearly universal, top-p is widely offered, and top-k is missing from some well-known APIs. The
names differ too: one API spells it `top_p` and another `topP`. **Read the API reference of the
model you call, check the date on the page, and do not assume a parameter exists because another
provider has it.** An API may reject a parameter it does not know or quietly ignore it, and the
second is the one that costs an afternoon.
