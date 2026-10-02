---
title: The reliability diagram
version: 1
---

A stated confidence of 0.85 makes a claim that can be checked: of all the answers stated at about
0.85, about 85% should be right. **Calibration is checked over many answers, never one**, because a
single answer is either right or wrong, and neither outcome refutes a 0.85.

So group the answers by what they stated and count:

```
ana@lab:~/triage$ pl calibrate runs/v9.jsonl
stated         n  mean said  accuracy
0.50-0.60    0          -         -
0.60-0.70    2       0.69      0.00
0.70-0.80    7       0.73      0.29
0.80-0.90   27       0.85      0.81
0.90-1.00   34       0.96      0.94

replies 70, right 56, mean stated confidence 0.89
ECE 0.088   Brier 0.139
```

`pl calibrate` sorts the replies into bins by stated confidence, here five bins of width 0.1 from
0.5 up, and prints for each bin how many replies fell in it, their mean stated confidence and the
share that were right. The bin from 0.5 to 0.6 is empty, since the stand-in never states less than
0.62.

Read it bin by bin. The 34 replies stated above 0.9 said 0.96 on average and were right 0.94 of the
time: close. The 27 between 0.8 and 0.9 said 0.85 and were right 0.81. The seven between 0.7 and
0.8 said 0.73 and were right **0.29**, and the two below 0.7 said 0.69 and were right none of the
time. Overall, the mean stated confidence is 0.89 and the accuracy 56 of 70, 0.80.

## The picture

The table has two numbers per bin, and the shape is the argument, so this is the figure the topic
is known for. **A reliability diagram** puts stated confidence on one axis and accuracy on the
other. A perfectly calibrated model's points sit on the diagonal, where saying 0.85 means being
right 85% of the time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Reliability diagram of 70 replies. Stated confidence on the horizontal axis from 0.5 to 1, accuracy on the vertical axis from 0 to 1, and a diagonal for perfect calibration. Four bins: 2 replies said 0.69 and were right 0.00 of the time; 7 said 0.73 and were right 0.29; 27 said 0.85 and were right 0.81; 34 said 0.96 and were right 0.94. Every point is below the diagonal.\"><path d=\"M110 290 L450 290\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110 290 L110 40\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110.0 290 L110.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"110.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M178.0 290 L178.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"178.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.6</text><path d=\"M245.99999999999997 290 L245.99999999999997 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"245.99999999999997\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.7</text><path d=\"M314.0 290 L314.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"314.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.8</text><path d=\"M382.0 290 L382.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"382.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.9</text><path d=\"M450.0 290 L450.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"450.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.0</text><path d=\"M106 290 L110 290\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"102\" y=\"290\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0</text><path d=\"M106 165.0 L110 165.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"102\" y=\"165.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M106 40.0 L110 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"102\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.0</text><text x=\"280.0\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">stated confidence</text><text x=\"70\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">accuracy</text><path d=\"M110.0 165.0 L450.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M239.19999999999996 117.5 L239.19999999999996 290.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"239.19999999999996\" cy=\"290.0\" r=\"4.3\" fill=\"var(--phosphor)\"></circle><path d=\"M266.4 107.5 L266.4 217.5\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"266.4\" cy=\"217.5\" r=\"5.4\" fill=\"var(--phosphor)\"></circle><path d=\"M348.0 77.5 L348.0 87.5\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"348.0\" cy=\"87.5\" r=\"7.7\" fill=\"var(--phosphor)\"></circle><path d=\"M422.79999999999995 50.0 L422.79999999999995 55.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"422.79999999999995\" cy=\"55.0\" r=\"8.2\" fill=\"var(--phosphor)\"></circle><text x=\"253.19999999999996\" y=\"276.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n=2  0.69 → 0.00</text><text x=\"284.4\" y=\"217.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n=7  0.73 → 0.29</text><text x=\"366.0\" y=\"107.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n=27  0.85 → 0.81</text><text x=\"438.79999999999995\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n=34  0.96 → 0.94</text><path d=\"M500 200 L530 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"540\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">perfectly calibrated</text><circle cx=\"515\" cy=\"230\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"540\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a bin of replies</text></svg>", "caption": "Every bin lies below the diagonal: the stand-in said more than it delivered. The two large bins are close to the line; the gap is widest where the evidence was thin."}
```

Every point sits below the diagonal: in every bin the stand-in said more than it delivered. That is
**overconfidence**, and it is not evenly spread. The two big bins are close to the line, and the
damage is in the small bins, where the stand-in's evidence was thin and it still said 0.7.

Two cautions about reading one. A bin of two replies says almost nothing, so a point needs its `n`
beside it. And a diagram drawn from seventy answers is a sketch: seventy is a small sample, and a
bin of seven is smaller still.
