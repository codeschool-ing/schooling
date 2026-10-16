---
title: When to retrain, and what retraining can reach
version: 1
---

**Retraining is the same pipeline run on newer data**, and the question is never how, which lessons
5 to 7 settled, but when. Three triggers are in common use, and they combine:

| trigger | fires when | its weakness |
| --- | --- | --- |
| a schedule | every month, every quarter | retrains when nothing changed, waits when something did |
| drift in the inputs | PSI against the training data crosses a threshold | drift is not always damage, as `tenure_days` showed |
| the report card | performance on the latest night with outcomes falls past a bound | arrives 90 days after the change |

**The label delay limits every one of them.** A model can only learn from outcomes that have
closed, so the newest night it can be trained on is 90 days old. On 30 June, that is a night at the
start of April at best, and a change that began on 1 April has barely reached the labels.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l10-label-delay\" aria-label=\"A calendar from December 2025 to June 2026. The training night, 28 December, has labels that close on 28 March. The test night, 29 March, has labels that close on 27 June. The rival opens on 1 April, after the training labels closed, and the data ends on 30 June.\"><path d=\"M30.0 190.0 L690.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M30.0 186.0 L30.0 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"56.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Dec</text><path d=\"M126.5 186.0 L126.5 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"152.5\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Jan</text><path d=\"M223.0 186.0 L223.0 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"249.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Feb</text><path d=\"M310.2 186.0 L310.2 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"336.2\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Mar</text><path d=\"M406.7 186.0 L406.7 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"432.7\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Apr</text><path d=\"M500.1 186.0 L500.1 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"526.1\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">May</text><path d=\"M596.6 186.0 L596.6 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"622.6\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Jun</text><circle cx=\"114.1\" cy=\"70.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"106.1\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">training night</text><rect x=\"120.1\" y=\"63.0\" width=\"274.2\" height=\"14.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"257.2\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its 90 days of labels</text><circle cx=\"397.4\" cy=\"120.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"389.4\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">test night</text><rect x=\"403.4\" y=\"113.0\" width=\"274.2\" height=\"14.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.5\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its 90 days of labels</text><path d=\"M406.7 40.0 L406.7 104.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"406.7\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the rival opens</text><path d=\"M686.9 40.0 L686.9 186.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"686.9\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the data ends</text></svg>", "caption": "The newest training night the rule allows has labels that closed before anything changed. The change is in the test night's outcomes and in no training label."}
```

**Retraining also needs a test, and lesson 3 set its rule**: the test night comes at least one
label window after the training night, so that every training label had closed by the night the
model is tested on, as it would have in production. With the data ending on 30 June, the newest
test night whose outcomes have closed is 29 March, which closes on 27 June. The newest training
night the rule allows before it is 28 December 2025, whose labels closed on 28 March.

**So no label a challenger can honestly be tested with comes from after 1 April**, and the rival
opened on 1 April. A model trained on newer nights could be built today; what cannot be built today
is evidence that it is better, because that evidence is outcomes, and they are still being written.

That is the honest shape of retraining under delayed labels: **one label window behind to train, two
to prove.** It is also why the earlier checks matter. The drift report, the split card and the
canary are what a team has while the next set of labels matures.

The policy for Ponto Final, written down so a person does not have to decide it every time:

- **retrain monthly**, tested on the newest night whose outcomes have closed, and trained on the
  newest night the 90-day rule allows before it;
- **retrain early** when the split card shows a group's gap past 0.15 for two nights in a row;
- **promote only if the challenger beats the champion on the same test night**, in average precision
  and in calibration, and passes a canary;
- **never promote a model that was not the one tested**: retraining "one more time on the newest
  data" after the test produces a model nobody has measured.
