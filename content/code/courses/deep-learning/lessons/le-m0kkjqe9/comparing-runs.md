---
title: Comparing runs against the spread
version: 1
---

The usual way to decide that a change helped is to run the old setting and the new one once each
and keep the higher number. **That compares two seeds as much as two settings**, and the spread of
the previous sections says how much a seed alone moves the result: four images out of 360, for
nothing.

The honest version costs more runs and nothing else. Run each configuration on the same five seeds,
and ask whether the gap between the configurations is larger than the spread inside each one. Three
configurations here: the one from before, a hidden layer twice as wide, and a learning rate five
times higher.

```
PENDING compare
```

Fifteen lines appended to `runs.jsonl`, each with its commit and nothing dirty. Reading them is one
more program, which needs nothing from PyTorch. Save as `~/dl/report.py`:

```schooling-example
{
  "language": "python",
  "file": "report.py",
  "parts": [
    {
      "code": "\"\"\"report: what runs.jsonl says, one block per configuration and commit.\"\"\"\nimport json\nimport statistics\nfrom collections import defaultdict\n\ngroups, dirty = defaultdict(dict), 0\nfor line in open(\"runs.jsonl\"):\n    run = json.loads(line)\n    if run[\"code\"][\"dirty\"]:\n        dirty += 1\n        continue",
      "note": "A run made from uncommitted code is left out and counted. Nobody can get that code back, so its number cannot be checked, only believed."
    },
    {
      "code": "    key = (json.dumps(run[\"config\"], sort_keys=True), run[\"code\"][\"commit\"])\n    groups[key][run[\"seed\"]] = run[\"metrics\"][\"val_acc\"]",
      "note": "Runs are grouped by configuration AND commit: the same settings on different code are different experiments. Inside a group, a seed run twice keeps its latest result instead of counting twice."
    },
    {
      "code": "for (config, commit), by_seed in groups.items():\n    accs = list(by_seed.values())\n    sd = statistics.stdev(accs) if len(accs) > 1 else 0.0\n    print(f\"{config}  commit {commit}\")\n    print(f\"  {len(accs)} seeds  mean {statistics.mean(accs):.4f}  \"\n          f\"min {min(accs):.4f}  max {max(accs):.4f}  sd {sd:.4f}\")\nprint(f\"left out: {dirty} run(s) from uncommitted code\")"
    }
  ]
}
```

```
PENDING report
```

`report.py` is code like the rest, so the transcript ends by committing it. Left uncommitted, it
would mark every later run as dirty.

## Reading the report

The six seed-0 runs made so far collapsed into one per configuration, and the dirty run from the
previous section is out of the report with a count beside it. What is left is three groups of five.

**The wider layer changed nothing measurable.** Its mean, 0.9200, sits 0.0011 below the narrower
one's 0.9211, which is less than half an image, against a standard deviation near 0.006 for each.
Its five runs fall between 0.9111 and 0.9278, entirely inside the same band as the 32-unit runs. And
note what a single run would have said: **on seed 0 the wider layer won, 0.9194 to 0.9167**, and on
seed 4 it lost, 0.9111 to 0.9250. Either result, alone, would have been written up as a finding.

**The higher learning rate is a real difference.** Its worst seed, 0.9500, beat the best seed of
either other configuration, 0.9278. The mean moved by 0.037, about thirteen images out of 360, which
is several times the spread.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" aria-label=\"A horizontal axis of validation accuracy from 0.90 to 0.98 and three rows of five dots, one per seed. The rows for hidden 32 and hidden 64 with a learning rate of 0.01 sit on top of each other between 0.911 and 0.928. The row with a learning rate of 0.05 sits entirely to the right, between 0.950 and 0.972.\"><path d=\"M190 50 L670 50\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">hidden 32  lr 0.01</text><circle cx=\"290.2\" cy=\"50\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"340.0\" cy=\"50\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"273.4\" cy=\"50\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"340.0\" cy=\"41\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"340.0\" cy=\"32\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><path d=\"M190 100 L670 100\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">hidden 64  lr 0.01</text><circle cx=\"306.4\" cy=\"100\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"356.8\" cy=\"100\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"290.2\" cy=\"100\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"340.0\" cy=\"100\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><circle cx=\"256.6\" cy=\"100\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><path d=\"M190 150 L670 150\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">hidden 32  lr 0.05</text><circle cx=\"623.2\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"539.8\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"523.6\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"523.6\" cy=\"141\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"490.0\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><rect x=\"248.60000000000002\" y=\"28\" width=\"116.2\" height=\"92\" rx=\"6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"306.7\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">the five seeds overlap</text><text x=\"556.6\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">no overlap</text><path d=\"M190 200 L670 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M190.0 200 L190.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"190.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.90</text><path d=\"M310.0 200 L310.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"310.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.92</text><path d=\"M430.0 200 L430.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"430.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.94</text><path d=\"M550.0 200 L550.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"550.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.96</text><path d=\"M670.0 200 L670.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"670.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.98</text><text x=\"430\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">validation accuracy, one dot per seed</text></svg>", "caption": "Fifteen runs, one dot each. The width of a hidden layer moved nothing the seeds did not already move; the learning rate moved the whole row."}
```

## A rule of thumb, and its limit

Lay the runs side by side and look for overlap. **When the ranges overlap heavily, the change has
not been shown to do anything**, whatever the means say. When the worst run of one configuration
beats the best of the other on the same seeds, the change did something.

Between those two cases sits a grey zone, where the means differ by about one standard deviation and
the ranges overlap a little. A statistical test, a paired t-test on the five seeds for instance, puts
a number on how surprising the gap would be by chance. With five seeds no test can see a small
effect, and **the answer is more seeds, not a cleverer test.**

Two habits keep this honest:

- **The same seeds for every configuration.** Seed 0 of one against seed 0 of the other compares
  like with like: the same starting weights, as far as the shapes allow, and the same batch order.
- **Choose on validation, report on test.** Every comparison here read the validation set. Picking
  the best of fifteen runs on validation and quoting that number overstates it, which is lesson 1's
  point about any setting chosen by looking at a set. The test set is read once, for the configuration already
  chosen.
