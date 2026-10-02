---
title: Order and length
version: 1
---

Kappa says the judge is weak. It does not say why. The two biases the stand-in declares can each be
measured from outside, without reading its code, and that is how you would find them in a real one.

## Position

`--swap` asks every question twice, the second time with the replies in the other order, and maps
the second answer back:

```
ana@lab:~/triage$ pl judge cases/pairs.jsonl --swap
j01  human b  judge a  swapped a
j02  human b  judge b  swapped b
j03  human a  judge a  swapped b  FLIP
j04  human a  judge a  swapped a
j05  human b  judge b  swapped b
j06  human a  judge a  swapped a
j07  human b  judge a  swapped b  FLIP
j08  human a  judge a  swapped b  FLIP
j09  human b  judge b  swapped b
j10  human a  judge a  swapped b  FLIP
j11  human b  judge a  swapped b  FLIP
j12  human a  judge a  swapped a
j13  human b  judge a  swapped b  FLIP
j14  human b  judge b  swapped b
j15  human a  judge b  swapped b
j16  human a  judge b  swapped b

agrees with the human on 10 of 16
Cohen's kappa 0.25
changes its mind when the order is swapped: 6 of 16
agrees AND keeps its verdict: 7 of 16
```

Six of sixteen verdicts flip: `j03`, `j07`, `j08`, `j10`, `j11` and `j13`. In every one the judge
picked `a` when `a` was shown first and `b` when `b` was shown first. **A verdict that changes when
only the order changes is a verdict about the order.** Three of those six, `j03`, `j08` and `j10`,
had agreed with the person in the first run, and that agreement was an accident of seating.

## Length

The ten verdicts that survive the swap agree with the person seven times. The three that survive and
are still wrong are `j01`, `j15` and `j16`:

```
ana@lab:~/triage$ python3 -c 'import json; [print(p["id"], p["human"], len(p["a"]), len(p["b"])) for p in map(json.loads, open("cases/pairs.jsonl"))]'
j01 b 274 137
j02 b 22 158
j03 a 151 220
j04 a 134 23
j05 b 225 135
j06 a 126 62
j07 b 199 47
j08 a 153 115
j09 b 24 177
j10 a 153 286
j11 b 231 115
j12 a 123 30
j13 b 211 113
j14 b 37 220
j15 a 107 187
j16 a 92 209
ana@lab:~/triage$ grep '"j16"' cases/pairs.jsonl
{"id": "j16", "message": "Do you buy second-hand books?", "a": "We don't, sorry, but the Bookswap in Market Street does, and it's two minutes from the shop.", "b": "Thank you for thinking of us! We're always delighted to hear from book lovers. Second-hand books are a wonderful way to give stories a new life, and there are many good places in town where you can sell yours.", "human": "a"}
```

In each of the three the person chose the shorter reply and the judge the longer: 274 characters
against 137 in `j01`, 187 against 107 in `j15`, 209 against 92 in `j16`. In `j16`, `a` answers the
question and sends the customer somewhere useful; `b` is warm and says nothing. **No swap can catch
this bias, because the longer reply is longer in both orders.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two bars of 16 pairs. Judged in one order, the judge agrees with the person on 10 and disagrees on 6. Judged in both orders, it changes its verdict with the order on 6; of the 10 it keeps, it agrees on 7 and disagrees on 3, and in all three it chose the longer reply.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the stand-in&#x27;s judge on 16 pairs with a human verdict</text><text x=\"138\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one order</text><rect x=\"150\" y=\"50\" width=\"298\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"50\" width=\"178\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"640\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">16</text><text x=\"138\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">both orders</text><rect x=\"150\" y=\"112\" width=\"208\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"360\" y=\"112\" width=\"88\" height=\"28\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"450\" y=\"112\" width=\"178\" height=\"28\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"640\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">16</text><path d=\"M360 146 L360 152 L448 152 L448 146\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"404.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">all three: the longer reply</text><rect x=\"150\" y=\"208\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"168\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">agrees with the person</text><rect x=\"330\" y=\"208\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"348\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">disagrees</text><rect x=\"510\" y=\"208\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--wire)\"></rect><text x=\"528\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">changes with the order</text></svg>", "caption": "Swapping the order removes the verdicts that depended on position. The three that survive and are still wrong are the ones where the judge preferred the longer reply, which no swap can catch."}
```

## What the literature found

The stand-in's biases were put there on purpose, and they were chosen because real judges were found
to have them. *Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena* (Zheng and others, 2023)
documented position bias, a preference for the answer in a particular position, and verbosity bias,
a preference for the longer answer, in language models used as judges. The same paper reported that
a strong model's verdicts agreed with human preferences about as often as people agreed with each
other, which is why the technique spread, and why its biases matter.

## What reduces them

- **Ask both orders and keep only the verdicts that agree.** Treat a flip as no verdict. Here that
  leaves ten verdicts, seven of them right, instead of sixteen with ten right.
- **Calibrate against people first**, on the task the judge will do, and report kappa rather than
  raw agreement.
- **Measure the length preference directly.** Count how often the judge picks the longer reply, and
  compare that with how often people do; here the judge chose the longer reply in all three of its
  stable mistakes.
- **Keep a person reading a sample** of the judge's verdicts for as long as it is in use, because a
  judge's habits can change when its model does.
