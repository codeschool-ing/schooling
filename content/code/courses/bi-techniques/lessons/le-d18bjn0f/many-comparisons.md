---
title: Twenty numbers, one false alarm
version: 1
---

**The 5 per cent significance level is a promise about one comparison.** If nothing changed, one test
of one metric crosses the line by chance one time in twenty. A test report rarely has one comparison:
it has the primary metric, several secondary ones, the guardrails, and then the same metrics broken
down by device, region, new and returning visitors. Every one of those is another chance.

```schooling-example
{"language": "python", "file": "many.py", "parts": [{"code": "for k in (1, 5, 10, 20, 50):\n    print(f\"{k:2} independent metrics, none really moved: \"\n          f\"chance of at least one 'significant' = {1 - 0.95 ** k:.0%}\")", "note": "Each metric has a 95% chance of not producing a false alarm, so all of them stay quiet with probability 0.95 to the power of their number."}], "output": " 1 independent metrics, none really moved: chance of at least one 'significant' = 5%\n 5 independent metrics, none really moved: chance of at least one 'significant' = 23%\n10 independent metrics, none really moved: chance of at least one 'significant' = 40%\n20 independent metrics, none really moved: chance of at least one 'significant' = 64%\n50 independent metrics, none really moved: chance of at least one 'significant' = 92%"}
```

**With ten metrics that did not move, the chance that at least one looks significant is 40%; with
twenty, 64%.** The arithmetic assumes the metrics are independent; real ones are correlated, which
lowers these numbers somewhat, and does not change the shape. Look at enough numbers and one of them
will cross the line, and the one that crosses is the one that gets reported.

This is the **multiple comparisons problem**, and it is why lesson 7 insisted on one primary metric
chosen in advance. Secondary metrics and guardrails are still worth reporting, as descriptions.
**A secondary metric that comes out significant is a hypothesis for the next test, not a finding of
this one.**
