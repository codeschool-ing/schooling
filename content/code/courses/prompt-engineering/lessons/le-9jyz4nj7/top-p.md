---
title: "Top-p: keep enough to reach p"
version: 1
---

Top-p, also called **nucleus sampling**, sets a share instead of a count. **It keeps the
smallest set of top words whose shares add up to at least p, and drops everything after them.**
The kept set is the nucleus, and the remaining shares are renormalised as with top-k.

With p set to 0.8 after `the coffee is`:

```
ana@lab:~/pe$ toylm dist "the coffee is" --top-p 0.8
context: trigram after 'coffee is'
  hot       66.7%  ###########################
  strong    20.8%  ########
  ready     12.5%  #####
```

`hot` alone is 59.3%, short of 80%. Adding `strong` reaches 77.8%, still short. Adding `ready`
reaches 88.9%, and the count stops there. Three words are kept, and `cold` and `bitter` go.

## It adapts to how sure the model is

The same p keeps a different number of words in different places. Where the model is nearly
sure:

```
ana@lab:~/pe$ toylm next "the coffee is hot"
context: trigram after 'is hot'
  .         85.0%  ##################################
  and       15.0%  ######
ana@lab:~/pe$ toylm dist "the coffee is hot" --top-p 0.8
context: trigram after 'is hot'
  .        100.0%  ########################################
```

The full stop has 85% on its own, which is already past 0.8, so the nucleus is one word and `and`
is gone. Where the model is torn:

```
ana@lab:~/pe$ toylm next "and the"
context: trigram after 'and the'
  cat       35.3%  ##############
  coffee    23.5%  #########
  bread     17.6%  #######
  café      11.8%  #####
  terrace   11.8%  #####
ana@lab:~/pe$ toylm dist "and the" --top-p 0.8
context: trigram after 'and the'
  cat       40.0%  ################
  coffee    26.7%  ###########
  bread     20.0%  ########
  café      13.3%  #####
```

It takes four words to pass 80%: 35.3, 58.8, 76.4 and then 88.2. `café` and `terrace` tied at
11.8%, and `toylm` keeps the tied word that sorts first alphabetically, the same rule it uses at
temperature 0.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three stacked bars with a line at 80 percent. After the coffee is hot: the full stop has 85 percent and crosses the line alone, so one word is kept and and, 15 percent, is dropped. After the coffee is: hot 59.3, strong 18.5 and ready 11.1 are needed to cross, so three are kept and cold and bitter are dropped. After and the: cat, coffee, bread and café are needed, so four are kept and terrace is dropped.\"><text x=\"140\" y=\"53\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">the coffee is hot</text><rect x=\"150\" y=\"40\" width=\"391.0\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"345.5\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"700\" fill=\"var(--paper)\">.</text><rect x=\"541.0\" y=\"40\" width=\"69.0\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 2\"></rect><text x=\"575.5\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and</text><text x=\"618\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 word kept</text><text x=\"140\" y=\"117\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">the coffee is</text><rect x=\"150\" y=\"104\" width=\"272.8\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"286.4\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">hot</text><rect x=\"422.8\" y=\"104\" width=\"85.1\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"465.3\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">strong</text><rect x=\"507.9\" y=\"104\" width=\"51.1\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"533.4\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ready</text><rect x=\"558.9\" y=\"104\" width=\"34.0\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 2\"></rect><text x=\"576.0\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cold</text><rect x=\"593.0\" y=\"104\" width=\"17.0\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 2\"></rect><text x=\"618\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 words kept</text><text x=\"140\" y=\"181\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">and the</text><rect x=\"150\" y=\"168\" width=\"162.4\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"231.2\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">cat</text><rect x=\"312.4\" y=\"168\" width=\"108.1\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"366.4\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">coffee</text><rect x=\"420.5\" y=\"168\" width=\"81.0\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"461.0\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">bread</text><rect x=\"501.4\" y=\"168\" width=\"54.3\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"528.6\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">café</text><rect x=\"555.7\" y=\"168\" width=\"54.3\" height=\"26\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 2\"></rect><text x=\"582.9\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">terrace</text><text x=\"618\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4 words kept</text><path d=\"M518.0 26 L518.0 38\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M518.0 68 L518.0 102\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M518.0 132 L518.0 166\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M518.0 196 L518.0 222\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"518.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">p = 0.8</text><rect x=\"150\" y=\"232\" width=\"12\" height=\"10\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"168\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kept</text><rect x=\"260\" y=\"232\" width=\"12\" height=\"10\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 2\"></rect><text x=\"278\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dropped</text></svg>", "caption": "Top-p at 0.8 in three contexts, from the tables in this section. Each bar is the model's shares laid end to end; the nucleus is every word up to the one that crosses the line."}
```

**When the model is confident, top-p cuts hard; when it is unsure, top-p leaves room.** Top-k
does neither. With k = 2 the same two contexts give:

```
ana@lab:~/pe$ toylm dist "the coffee is hot" --top-k 2
context: trigram after 'is hot'
  .         85.0%  ##################################
  and       15.0%  ######
ana@lab:~/pe$ toylm dist "and the" --top-k 2
context: trigram after 'and the'
  cat       60.0%  ########################
  coffee    40.0%  ################
```

After `is hot`, top-k keeps `and`, a word with 15% that top-p threw away. After `and the` it
drops `bread` and `café`, which top-p kept. A fixed count is too loose in the first place and too
tight in the second, and the share adjusts on its own.

Top-p does not protect you from every odd word. A word inside the nucleus can still be wrong for
your purpose, and a p close to 1 keeps nearly the whole tail. It removes the long tail of
unlikely words in each place, which is where most of the strange output comes from.
