---
title: Temperature
version: 1
---

**Temperature divides every score before softmax.** Below 1 it stretches the gaps between scores,
so the top candidate takes more of the probability. Above 1 it shrinks them, so the tail gets more.
Here are the same eight scores at 0.2 and at 1.5:

```
ana@lab:~/triage$ pl sample --temperature 0.2
Your parcel is ___   temperature 0.2, top-k off, top-p 1, 1000 draws
  on         92.2%    914  #####################################
  delayed     7.6%     85  ###
  here        0.2%      1  
  lost        0.0%      0  
  ready       0.0%      0  
  wet         0.0%      0  
  singing     0.0%      0  
  purple      0.0%      0  
ana@lab:~/triage$ pl sample --temperature 1.5
Your parcel is ___   temperature 1.5, top-k off, top-p 1, 1000 draws
  on         35.3%    386  ##############
  delayed    25.3%    248  ##########
  here       15.9%    135  ######
  lost        9.9%     90  ####
  ready       8.7%     86  ###
  wet         3.4%     44  #
  singing     0.8%      7  
  purple      0.6%      4  
```

At 0.2 the half-point gap between `on` and `delayed` becomes a gap of 2.5, and *e* to the 2.5 is
about 12, which is the ratio between 92.2% and 7.6%. Five of the eight words now have a probability
that rounds to zero. At 1.5 the same gap shrinks to a third of a point, and `on` falls to 35.3%.
**Flattening gives the nonsense its chances too**: `singing` and `purple` were drawn 7 and 4 times
in a thousand.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 272\" role=\"img\" aria-label=\"The probability of each of eight next words after &#x27;Your parcel is&#x27;, at two temperatures. At 0.2: on 92.2%, delayed 7.6%, here 0.2%, the rest nearly zero. At 1.5: on 35.3%, delayed 25.3%, here 15.9%, lost 9.9%, ready 8.7%, wet 3.4%, singing 0.8%, purple 0.6%.\"><path d=\"M74 240 L700 240\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"68\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0%</text><text x=\"68\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">50%</text><path d=\"M74 145.0 L700 145.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"68\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">100%</text><path d=\"M74 50.0 L700 50.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">probability</text><rect x=\"90\" y=\"64.8308961109781\" width=\"22\" height=\"175.1691038890219\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"116\" y=\"172.9154293311659\" width=\"22\" height=\"67.08457066883409\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"114\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">on</text><rect x=\"166\" y=\"225.62124434832006\" width=\"22\" height=\"14.37875565167995\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"192\" y=\"191.93180465938033\" width=\"22\" height=\"48.06819534061967\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"190\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">delayed</text><rect x=\"242\" y=\"239.4\" width=\"22\" height=\"0.6\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"268\" y=\"209.85695935312424\" width=\"22\" height=\"30.143040646875765\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"266\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">here</text><rect x=\"318\" y=\"239.4\" width=\"22\" height=\"0.6\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"344\" y=\"221.09762821340212\" width=\"22\" height=\"18.90237178659787\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"342\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lost</text><rect x=\"394\" y=\"239.4\" width=\"22\" height=\"0.6\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"420\" y=\"223.45714854573936\" width=\"22\" height=\"16.542851454260628\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"418\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ready</text><rect x=\"470\" y=\"239.4\" width=\"22\" height=\"0.6\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"496\" y=\"233.49467716890442\" width=\"22\" height=\"6.505322831095588\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"494\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">wet</text><rect x=\"546\" y=\"239.4\" width=\"22\" height=\"0.6\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"572\" y=\"238.3958071403918\" width=\"22\" height=\"1.6041928596081882\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"570\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">singing</text><rect x=\"622\" y=\"239.4\" width=\"22\" height=\"0.6\" rx=\"1\" fill=\"var(--phosphor)\"></rect><rect x=\"648\" y=\"238.85054558789184\" width=\"22\" height=\"1.14945441210817\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"646\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">purple</text><rect x=\"420\" y=\"16\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"438\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">temperature 0.2</text><rect x=\"570\" y=\"16\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"588\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">temperature 1.5</text></svg>", "caption": "The same eight scores, divided by two temperatures. At 0.2 nearly every draw is the top word; at 1.5 the tail gets real chances, including words that make no sense."}
```

Temperature 0 cannot be computed this way, since nothing can be divided by zero, so it is defined as
the limit: always take the top candidate, with no draw at all. That is what the stand-in does at 0,
which is the default for `pl run`. `pl sample` takes only temperatures above 0, because it shows the
draw.

**The number is relative to the scores it divides.** In the stand-in the category scores for a
message often sit within a point of each other, so a temperature of 1 is a lot of randomness there.
On another model the same setting does not promise the same amount, and the way to know is to
measure on your own task, as the last section of this lesson does.
