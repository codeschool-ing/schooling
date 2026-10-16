---
title: Thresholds and alerts
version: 1
---

A board waits to be looked at, and Marcos spends most of the morning loading trucks. So the board
also sends a message to his phone when a route crosses a line. **Everything about that message
depends on where the line is**, and the way to choose it is to count what each choice would have
done on a real day.

## The morning, in your sheet

These are Wednesday's fourteen routes at 11:00, with the minutes each was behind its plan. Type them
into a new sheet, starting in A1, and put the three candidate thresholds in D1, E1 and F1 as numbers:

| | A | B | C | D | E | F |
|---|---|---|---|---|---|---|
| 1 | Route | Area | Behind | 15 | 30 | 60 |
| 2 | 1 | Contagem Centro | 0 | | | |
| 3 | 2 | Eldorado | 6 | | | |
| 4 | 3 | Betim | 12 | | | |
| 5 | 4 | Barreiro | 18 | | | |
| 6 | 5 | Pampulha | 3 | | | |
| 7 | 6 | Venda Nova | 35 | | | |
| 8 | 7 | Savassi | 9 | | | |
| 9 | 8 | Nova Lima | 22 | | | |
| 10 | 9 | Sabará | 0 | | | |
| 11 | 10 | Santa Luzia | 41 | | | |
| 12 | 11 | Ribeirão das Neves | 74 | | | |
| 13 | 12 | Ibirité | 15 | | | |
| 14 | 13 | Lagoa Santa | 27 | | | |
| 15 | 14 | Vespasiano | 8 | | | |

In D2, a 1 if the route has reached the threshold at the top of the column, and a 0 if it has not:

```localised
=IF($C2>=D$1,1,0)      0
```

Copy D2 across to F2, then the three cells down to row 15. The two dollar signs do opposite jobs:
`$C` keeps every column reading the delay in C, and `D$1` keeps every row reading its threshold from
row 1. Route 4, in row 5, is 18 minutes behind, so D5 shows **1** and E5 shows 0. In A16 type
`Alerts`, and in D16:

```localised
=SUM(D2:D15)      7
```

Copy it to E16 and F16. **Your row 16 should read 7, 3 and 1**: seven alerts at 15 minutes, three at
30 and one at 60, all at the same moment of the same morning.

## Too many, and too late

At 15 minutes, half the fleet raises an alert at 11:00. Marcos cannot help seven trucks at once, and
two of the seven are 15 and 18 minutes behind, a gap a driver can close over an afternoon of stops. If his
phone buzzes for all of them, he learns within a week that most buzzes need nothing, and starts
ignoring them. **Hospitals have a name for this, alarm fatigue**, from monitors that sound so often
that the staff stop hearing them. An alert that fires too often is not a cautious alert. It is a
switched-off one, and the alert that matters arrives in a pile of ones that do not.

At 60 minutes, only route 11 fires, and by then its afternoon is already lost: three customers'
windows have closed. An alert at that line reports a failure instead of warning about one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Fourteen vertical bars, one per route, sorted from most behind to least: 74, 41, 35, 27, 22, 18, 15, 12, 9, 8, 6, 3, 0 and 0 minutes. Three dashed lines cross them. At 15 minutes, 7 bars reach the line; at 30 minutes, 3; at 60 minutes, 1.\" data-fig=\"l14-thresholds\"><path d=\"M64.0 270.0 L70.0 270.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"60.0\" y=\"274.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M64.0 212.5 L70.0 212.5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"60.0\" y=\"216.5\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><path d=\"M64.0 155.0 L70.0 155.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"60.0\" y=\"159.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">40</text><path d=\"M64.0 97.5 L70.0 97.5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"60.0\" y=\"101.5\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">60</text><path d=\"M64.0 40.0 L70.0 40.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"60.0\" y=\"44.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">80</text><path d=\"M70.0 34.0 L70.0 270.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><path d=\"M70.0 270.0 L540.0 270.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"24.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">minutes behind plan at 11:00</text><path d=\"M76.0 57.2 H97.6 V270.0 H76.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"86.8\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">11</text><path d=\"M109.6 152.1 H131.1 V270.0 H109.6 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"120.4\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><path d=\"M143.1 169.4 H164.7 V270.0 H143.1 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"153.9\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><path d=\"M176.7 192.4 H198.3 V270.0 H176.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"187.5\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">13</text><path d=\"M210.3 206.8 H231.9 V270.0 H210.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"221.1\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><path d=\"M243.9 218.2 H265.4 V270.0 H243.9 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"254.6\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><path d=\"M277.4 226.9 H299.0 V270.0 H277.4 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"288.2\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">12</text><path d=\"M311.0 235.5 H332.6 V270.0 H311.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"321.8\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><path d=\"M344.6 244.1 H366.1 V270.0 H344.6 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"355.4\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><path d=\"M378.1 247.0 H399.7 V270.0 H378.1 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"388.9\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">14</text><path d=\"M411.7 252.8 H433.3 V270.0 H411.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"422.5\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><path d=\"M445.3 261.4 H466.9 V270.0 H445.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"456.1\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><path d=\"M478.9 268.5 H500.4 V270.0 H478.9 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"489.6\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><path d=\"M512.4 268.5 H534.0 V270.0 H512.4 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"523.2\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><text x=\"305.0\" y=\"310.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">route, most behind first</text><path d=\"M70.0 226.9 L548.0 226.9\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></path><text x=\"554.0\" y=\"230.9\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">15 min: 7 alerts</text><path d=\"M70.0 183.8 L548.0 183.8\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></path><text x=\"554.0\" y=\"187.8\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">30 min: 3 alerts</text><path d=\"M70.0 97.5 L548.0 97.5\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></path><text x=\"554.0\" y=\"101.5\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">60 min: 1 alert</text></svg>", "caption": "The same fourteen routes against three thresholds. At 15 minutes half the fleet raises an alert; at 60, only the route that is already lost does. The bars in red are what the board shows at 30."}
```

At 30 minutes, three routes fire, and they are exactly the three where moving stops or calling a
customer still changes the outcome. That is why the board uses 30. **The threshold is a business
decision, not a statistical result.** It trades the cost of an alert nobody needed against the cost
of a late one. The person who pays both costs is Marcos, so he chooses it with Lívia rather than
having it chosen for him. `machine-learning` lesson 11 makes the same argument about the threshold of
a model.

## An alert that names an action

Compare two messages about the same route.

> Route 11 is 74 minutes behind.

> Route 11 (Ribeirão das Neves): 74 min behind, 22 stops left, 3 windows missed. Route 14
> (Vespasiano) is 8 min behind and next door: move 6 stops?

The first is a notification: it hands Marcos a fact and leaves him to work out what it means. The
second is an alert: **it says who should do what, now**. Lívia's rule for every alert on the board is
that it names a person, an action and the data needed to take it, or it is not sent.

Two more rules came out of the first week:

- **Once per crossing, not once per refresh.** The data is copied every ten minutes, so a route that
  stays over the line all morning would buzz 6 times an hour. It alerts when it crosses, and again
  only if it gets worse by another 30 minutes.
- **An alert on the exception, never on the average.** The fourteen routes averaged 19.3 minutes
  behind at 11:00, so an alert on an average above 15 would have fired that morning without saying
  where. On a day with route 11 at 74 minutes and the other thirteen on time, the average is 5.3 and
  it would stay silent.

## Measuring the alert itself

An alert is a small piece of BI and it gets measured like one. The number to keep is not how many
alerts fired but **how many led to an action**. If most alerts at 30 minutes end with Marcos doing
nothing, the line is too low for the routes Varanda runs, or the next step it suggests is wrong.
Lívia counts both every month with Marcos, which turns the threshold from a guess into a decision
somebody reviews.
