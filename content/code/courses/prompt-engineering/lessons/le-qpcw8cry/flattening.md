---
title: Dividing the scores by a number
version: 1
---

Temperature is usually described as a creativity dial: turn it up and the model gets more
imaginative, turn it down and it gets more careful. That picture is close enough to use and wrong
about what moves. **Temperature changes nothing the model knows. It reshapes the probabilities
the model gave, just before a word is drawn from them.** The words stay the same; only the
shares they get move.

Lesson 1 showed `toylm next`, which prints the model's own probabilities. `toylm dist` prints the
same table after the sampling controls have been applied, so you can see what a draw would
actually be made from. At temperature 1 nothing is changed:

```
ana@lab:~/pe$ toylm dist "the coffee is" --temperature 1
context: trigram after 'coffee is'
  hot       59.3%  ########################
  strong    18.5%  #######
  ready     11.1%  ####
  cold       7.4%  ###
  bitter     3.7%  #
```

Halve the temperature and the leader pulls away:

```
ana@lab:~/pe$ toylm dist "the coffee is" --temperature 0.5
context: trigram after 'coffee is'
  hot       86.8%  ###################################
  strong     8.5%  ###
  ready      3.1%  #
  cold       1.4%  #
  bitter     0.3%  
```

Double it and the field closes up:

```
ana@lab:~/pe$ toylm dist "the coffee is" --temperature 2
context: trigram after 'coffee is'
  hot       38.5%  ###############
  strong    21.5%  #########
  ready     16.7%  #######
  cold      13.6%  #####
  bitter     9.6%  ####
```

Each table has the same five words in the same order. **The ranking never moves; the gaps
between the ranks do.** At 0.5, `hot` takes 86.8% and `bitter` is down to 0.3%, a word that
would come up about three times in a thousand draws. At 2, `bitter` has 9.6%, roughly one draw in
ten.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three bar charts of the next word after the coffee is. At temperature 0.5: hot 86.8 percent, strong 8.5, ready 3.1, cold 1.4, bitter 0.3. At temperature 1: hot 59.3, strong 18.5, ready 11.1, cold 7.4, bitter 3.7. At temperature 2: hot 38.5, strong 21.5, ready 16.7, cold 13.6, bitter 9.6.\"><rect x=\"10\" y=\"10\" width=\"225\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"122\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">--temperature 0.5</text><text x=\"122\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sharper</text><text x=\"22\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hot</text><rect x=\"74\" y=\"72\" width=\"95.5\" height=\"14\" fill=\"var(--phosphor)\"></rect><text x=\"175.48000000000002\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">86.8%</text><text x=\"22\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">strong</text><rect x=\"74\" y=\"102\" width=\"9.3\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"89.35\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8.5%</text><text x=\"22\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ready</text><rect x=\"74\" y=\"132\" width=\"3.4\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"83.41\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3.1%</text><text x=\"22\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cold</text><rect x=\"74\" y=\"162\" width=\"1.5\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"81.54\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.4%</text><text x=\"22\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bitter</text><rect x=\"74\" y=\"192\" width=\"1\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"80.33\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.3%</text><rect x=\"247\" y=\"10\" width=\"225\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"359\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">--temperature 1</text><text x=\"359\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the model's own shares</text><text x=\"259\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hot</text><rect x=\"311\" y=\"72\" width=\"65.2\" height=\"14\" fill=\"var(--phosphor)\"></rect><text x=\"382.23\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">59.3%</text><text x=\"259\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">strong</text><rect x=\"311\" y=\"102\" width=\"20.4\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"337.35\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18.5%</text><text x=\"259\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ready</text><rect x=\"311\" y=\"132\" width=\"12.2\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"329.21\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">11.1%</text><text x=\"259\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cold</text><rect x=\"311\" y=\"162\" width=\"8.1\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"325.14\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7.4%</text><text x=\"259\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bitter</text><rect x=\"311\" y=\"192\" width=\"4.1\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"321.07\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3.7%</text><rect x=\"484\" y=\"10\" width=\"225\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"596\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">--temperature 2</text><text x=\"596\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">flatter</text><text x=\"496\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hot</text><rect x=\"548\" y=\"72\" width=\"42.4\" height=\"14\" fill=\"var(--phosphor)\"></rect><text x=\"596.35\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">38.5%</text><text x=\"496\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">strong</text><rect x=\"548\" y=\"102\" width=\"23.6\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"577.65\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">21.5%</text><text x=\"496\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ready</text><rect x=\"548\" y=\"132\" width=\"18.4\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"572.37\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16.7%</text><text x=\"496\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cold</text><rect x=\"548\" y=\"162\" width=\"15.0\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"568.96\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13.6%</text><text x=\"496\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bitter</text><rect x=\"548\" y=\"192\" width=\"10.6\" height=\"14\" fill=\"var(--phosphor-dim)\"></rect><text x=\"564.56\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9.6%</text></svg>", "caption": "The same five words after “the coffee is” at three temperatures, from the three tables above. The order never changes; the gap between the first word and the rest does."}
```

## What the number does

A model does not compute percentages first. It computes a score for every word, called a
**logit**, and the percentages come from those scores by a fixed step: raise *e* to each score
and divide by the total, so that the shares add up to 100%. Temperature goes in between. **Every
score is divided by the temperature before the percentages are worked out.**

Dividing by a number below 1 makes every score bigger, and the differences between them bigger
with it, so the top word's share grows. Dividing by a number above 1 shrinks the differences and
the shares move towards equal. In the tables above, `hot` was 3.2 times as likely as `strong`
at temperature 1 (59.3% against 18.5%). At 0.5 it is about ten times as likely (86.8% against
8.5%), because halving the temperature squares that ratio.

`toylm` does exactly this. Its scores are the logarithms of its counts, and the function that
applies the controls divides them by the temperature before it turns them back into shares. A
large model's scores come from its weights instead of from counts, and the division is the same.

## Two limits

Two settings sit at the ends, and both are worth knowing because both get used.

- As the temperature falls towards 0, the top word's share heads to 100%. At 0 itself the
  division is undefined, so implementations treat it as a rule of its own: take the top word.
  That is the next section.
- As the temperature rises, every word that had any score heads towards an equal share. A word
  the model gave 0.3% gets as many draws as the one it gave 86.8%.

**Neither end adds a word the model did not already score.** `toylm` will never say `sweet`
after `coffee is` at any temperature, because `sweet` never followed those two words in its
file. A large model scores every token in its vocabulary, so at a high temperature the rare and
strange ones get a real chance, and that is where the nonsense comes from.
