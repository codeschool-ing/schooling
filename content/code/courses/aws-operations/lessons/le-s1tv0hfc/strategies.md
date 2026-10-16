---
title: Four ways to replace a running version
version: 1
---

A deployment replaces version 1.4.0 with 1.4.1 while customers are using the service. The picture
most people start from is a switch: off with the old, on with the new. **Every strategy that is worth
using keeps both versions running for a while**, and the strategies differ in how the traffic moves
between them and how quickly it can move back.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Four small charts of the share of traffic on the new version over fifteen minutes. Rolling climbs in steps of 20% every two minutes, reaching 100% at minute 8, mixing versions throughout. Blue/green all at once jumps from 0 to 100% in one move, and moves back in seconds. Canary holds 10% for five minutes, then jumps to 100%. Linear climbs 10% every minute until 100% at minute 10.\"><defs><marker id=\"stg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"160\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\" font-weight=\"600\">rolling</text><path d=\"M46 58 L46 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M46 178 L166 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"42\" y=\"58\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"42\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">0</text><text x=\"166\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">15 min</text><path d=\"M46.0 178.0 L46.0 154.0 L62.0 154.0 L62.0 130.0 L78.0 130.0 L78.0 106.0 L94.0 106.0 L94.0 82.0 L110.0 82.0 L110.0 58.0 L166.0 58.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"100.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">mixed versions throughout</text><rect x=\"195\" y=\"20\" width=\"160\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\" font-weight=\"600\">blue/green, all at once</text><path d=\"M221 58 L221 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M221 178 L341 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"217\" y=\"58\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"217\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">0</text><text x=\"341\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">15 min</text><path d=\"M221.0 178.0 L229.0 178.0 L229.0 58.0 L341.0 58.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"275.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">one move, back in seconds</text><rect x=\"370\" y=\"20\" width=\"160\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\" font-weight=\"600\">canary 10%, 5 min</text><path d=\"M396 58 L396 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M396 178 L516 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"392\" y=\"58\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"392\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">0</text><text x=\"516\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">15 min</text><path d=\"M396.0 178.0 L396.0 166.0 L436.0 166.0 L436.0 58.0 L516.0 58.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"450.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a small test, then all</text><rect x=\"545\" y=\"20\" width=\"160\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\" font-weight=\"600\">linear 10% a minute</text><path d=\"M571 58 L571 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M571 178 L691 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"567\" y=\"58\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"567\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">0</text><text x=\"691\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">15 min</text><path d=\"M571.0 178.0 L571.0 166.0 L579.0 166.0 L579.0 166.0 L579.0 154.0 L587.0 154.0 L587.0 154.0 L587.0 142.0 L595.0 142.0 L595.0 142.0 L595.0 130.0 L603.0 130.0 L603.0 130.0 L603.0 118.0 L611.0 118.0 L611.0 118.0 L611.0 106.0 L619.0 106.0 L619.0 106.0 L619.0 94.0 L627.0 94.0 L627.0 94.0 L627.0 82.0 L635.0 82.0 L635.0 82.0 L635.0 70.0 L643.0 70.0 L643.0 70.0 L643.0 58.0 L651.0 58.0 L691.0 58.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"625.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">equal steps</text></svg>", "caption": "The share of traffic on the new version, minute by minute, for each strategy."}
```

**In place, or rolling.** The service's own tasks are replaced a few at a time: stop one old, start
one new, repeat. It needs no extra capacity, and it is ECS's own default for a service. Its weakness
is the way back: rolling back is another rolling deployment, of the old version, at the same pace,
and for its whole length the service runs a mixture.

**Blue/green.** A complete second set of tasks, the green one, starts beside the blue one that is
serving. Nothing reaches green until it is healthy; then the load balancer's listener moves from the
blue target group to the green one. **Rolling back is moving the listener back**, which takes seconds,
because blue is still running. The price is double capacity for as long as blue is kept.

**Canary.** Blue/green, with the move made in two steps: a small share of the traffic first, say 10%,
for a fixed time, and then the rest. The small share is a test with real users and limited damage.

**Linear.** Blue/green, with the move made in equal steps: 10% more every minute, or every three, until
green has everything. It spreads the risk over the whole deployment instead of concentrating the
evidence in one early window.

## The names CodeDeploy gives them

For ECS, CodeDeploy runs only blue/green, and the strategy is a **deployment configuration**, a name
the deployment group refers to. The predefined ones are:

| configuration | what it does |
|---|---|
| `CodeDeployDefault.ECSAllAtOnce` | all traffic to green at once |
| `CodeDeployDefault.ECSCanary10Percent5Minutes` | 10%, then the rest after 5 minutes |
| `CodeDeployDefault.ECSCanary10Percent15Minutes` | 10%, then the rest after 15 minutes |
| `CodeDeployDefault.ECSLinear10PercentEvery1Minutes` | 10% more every minute |
| `CodeDeployDefault.ECSLinear10PercentEvery3Minutes` | 10% more every three minutes |

A team can define its own, say 5% for 30 minutes, with `create-deployment-config`. moto does not
implement deployment configurations at all, so neither that command nor a listing of the predefined
ones was run for this course; the table is AWS's documentation.

Which to choose is not a matter of taste, and the section after next counts why: **a canary is only
as good as the alarm that watches it**, and the wrong alarm makes a canary worse than no canary.
