---
title: The reliability diagram
version: 2
---

A stated confidence of 0.8 makes a claim that can be checked: of all the answers stated at 0.8,
about 80% should be right. **Calibration is checked over many answers, never one**, because a single
answer is either right or wrong, and neither outcome refutes a 0.8.

So group the answers by what they stated and count. This program does that, and with
`--thresholds` it also prints the trade the last section of this lesson uses. Save it as
`calibrate.py`:

```python
"""calibrate: does the confidence a reply states match how often its category
is right? Replies are grouped by what they stated, and each group is counted."""
import sys

from pl import parse, read_jsonl

rows = read_jsonl(sys.argv[1])
expect = {c["id"]: c["expect"] for c in read_jsonl(rows[0]["cases"])}
pairs, missing = [], 0
for r in rows:
    obj = parse(r["text"]) or {}
    conf = obj.get("confidence")
    if isinstance(conf, bool) or not isinstance(conf, (int, float)) or not 0 <= conf <= 1:
        missing += 1
        continue
    pairs.append((float(conf), obj.get("category") == expect[r["case"]]["category"]))

edges = [0.0, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
print("stated         n  mean said  accuracy")
ece = 0.0
for lo, hi in zip(edges, edges[1:]):
    group = [(c, ok) for c, ok in pairs if lo <= c < hi or (hi == 1.0 and c == 1.0)]
    if not group:
        print("%.2f-%.2f %5d %10s %9s" % (lo, hi, 0, "-", "-"))
        continue
    said = sum(c for c, _ in group) / len(group)
    right = sum(ok for _, ok in group) / len(group)
    ece += len(group) / len(pairs) * abs(said - right)
    print("%.2f-%.2f %5d %10.2f %9.2f" % (lo, hi, len(group), said, right))
brier = sum((c - ok) ** 2 for c, ok in pairs) / len(pairs)
print("\nreplies %d, %d with no usable confidence; right %d of %d, mean stated %.2f"
      % (len(rows), missing, sum(ok for _, ok in pairs), len(pairs),
         sum(c for c, _ in pairs) / len(pairs)))
print("ECE %.3f   Brier %.3f" % (ece, brier))
if "--thresholds" in sys.argv:
    print("\nanswer if      answered  accuracy")
    for t in (0.0, 0.8, 0.85, 0.9, 0.95):
        kept = [ok for c, ok in pairs if c >= t]
        acc = "%.2f" % (sum(kept) / len(kept)) if kept else "-"
        print("conf >= %.2f %8d %9s" % (t, len(kept), acc))
```

A confidence that is missing, not a number, or outside 0 to 1 is counted and left out, never
guessed. Run it over the seventy replies:

```
ana@lab:~/triage$ python3 calibrate.py runs/v9.jsonl
stated         n  mean said  accuracy
0.00-0.50     1       0.00      1.00
0.50-0.60     0          -         -
0.60-0.70     0          -         -
0.70-0.80     0          -         -
0.80-0.90    46       0.80      0.72
0.90-1.00    23       0.90      0.78

replies 70, 0 with no usable confidence; right 52 of 70, mean stated 0.82
ECE 0.108   Brier 0.212
```

`calibrate.py` sorts the replies into bins by stated confidence: one bin below 0.5 and five of width
0.1 above it. For each bin it prints how many replies fell in it, their mean stated confidence and
the share that were right. Three bins have anything in them, because the model used four values.

Read it bin by bin. The 46 replies that said 0.8 were right 0.72 of the time. The 23 that said 0.9,
or 0.95 once, were right 0.78. The one that said 0.0 was right. Overall, the mean stated confidence
is 0.82 and the accuracy 52 of 70, 0.74.

## The picture

The table has two numbers per bin, and the shape is the argument, so this is the figure the topic
is known for. **A reliability diagram** puts stated confidence on one axis and accuracy on the
other. A perfectly calibrated model's points sit on the diagonal, where saying 0.8 means being right
80% of the time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Reliability diagram of 70 replies. Stated confidence on the horizontal axis from 0 to 1, accuracy on the vertical axis from 0 to 1, and a diagonal for perfect calibration. Three bins: 1 reply said 0.00 and was right; 46 said 0.80 and were right 0.72 of the time; 23 said 0.90 and were right 0.78. The two large bins are below the diagonal.\"><path d=\"M110 290 L450 290\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110 290 L110 40\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110.0 290 L110.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"110.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0</text><path d=\"M178.0 290 L178.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"178.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.2</text><path d=\"M246.0 290 L246.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"246.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.4</text><path d=\"M314.0 290 L314.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"314.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.6</text><path d=\"M382.0 290 L382.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"382.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.8</text><path d=\"M450.0 290 L450.0 294\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"450.0\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.0</text><path d=\"M106 290.0 L110 290.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"102\" y=\"290.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0</text><path d=\"M106 165.0 L110 165.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"102\" y=\"165.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M106 40.0 L110 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"102\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.0</text><text x=\"280\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">stated confidence</text><text x=\"70\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">accuracy</text><path d=\"M110 290 L450 40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M110.0 290.0 L110.0 40.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"110.0\" cy=\"40.0\" r=\"4.2\" fill=\"var(--phosphor)\"></circle><text x=\"124\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n=1  0.00 → 1.00</text><path d=\"M382.0 90.0 L382.0 110.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"382.0\" cy=\"110.0\" r=\"9.0\" fill=\"var(--phosphor)\"></circle><text x=\"394\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n=46  0.80 → 0.72</text><path d=\"M416.0 65.0 L416.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"416.0\" cy=\"95.0\" r=\"7.4\" fill=\"var(--phosphor)\"></circle><text x=\"432\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">n=23  0.90 → 0.78</text><path d=\"M560 200 L590 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"600\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">perfectly calibrated</text><circle cx=\"575\" cy=\"230\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"600\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a bin of replies</text></svg>", "caption": "Almost every reply said 0.8 or 0.9, the numbers its examples showed. Both large bins sit below the diagonal, and they are close together: the stated number barely separates one group from the other."}
```

The two large bins sit below the diagonal: in both, the model said more than it delivered. That is
**overconfidence**, and here it is mild, eight and twelve points. The more telling thing is how
close the two bins are to each other. Replies stated at 0.9 were right 0.78 of the time and replies
stated at 0.8 were right 0.72. **A confidence is useful when it separates the answers that are right
from the ones that are not**, and this one barely does.

Two cautions about reading one. A bin of one reply says nothing at all, so a point needs its `n`
beside it. And a diagram drawn from seventy answers is a sketch: seventy is a small sample, and the
difference between 0.72 and 0.78 is well within what a different seventy messages could move.
