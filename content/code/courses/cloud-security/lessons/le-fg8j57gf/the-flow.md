---
title: One road, with checkpoints on it
version: 1
---

**A deployment flow is the agreed road from a change somebody wrote to a change running in the account. Its security comes from two properties at once: every change on the road passes the same
checkpoints, and there is no other road.** Lesson 12 built the checkpoints by hand: a plan a person
reads, a scanner that reads the files. This lesson puts them in a fixed order, makes a machine run
them, and asks who holds the keys at the end.

The common wrong picture is that a pipeline is a convenience: it saves somebody typing `terraform
apply`. Then the checks inside it are a courtesy, and the day they are in the way somebody runs the
apply from a laptop. **A pipeline earns its place in a security course only when it is the one way
in**, which is as much a question of permissions as of scripts.

## The stages

A change to the clinic's infrastructure travels in this order. Each stage is cheaper than the next,
so the cheap ones go first and a change that fails early wastes nobody's time:

| stage | what it asks | what it costs |
|---|---|---|
| format | is the code written the agreed way? | under a second |
| validate | does Terraform understand it at all? | a second or two |
| scan | does any resource break a rule that matters? | seconds, and no account |
| plan | what exactly will AWS be asked to do? | a call to the account, read-only |
| review | does a person who did not write it agree? | a person's attention |
| apply | make it so, exactly as planned | write access to the account |

Two of the six are not like the others. **Review is the only stage that needs a human**, and it is
placed after the machines so that the human reads a plan that has already passed everything a machine
can check. **Apply is the only stage that changes anything**, and it applies the saved plan the
reviewer read, not a fresh one computed later that nobody saw.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" data-fig=\"l14-flow\" aria-label=\"The deployment flow as a row of six stages from a change to the account: format, validate, scan and plan are run by a machine; review is done by a person; apply is done by the pipeline's role, using the saved plan. A dashed amber arrow runs underneath, from a person's own credentials straight to the account, passing through none of the stages: the road around the road, which taking write access away from people closes and lesson 16 detects.\"><defs><marker id=\"l14-flow-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-flow-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l14-flow-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"8.0\" y=\"90.0\" width=\"72.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a change</text><rect x=\"92.0\" y=\"90.0\" width=\"80.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"132.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">format</text><path d=\"M81.0 115.0 L91.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-flow-af-ah-paper-dim)\"></path><rect x=\"184.0\" y=\"90.0\" width=\"80.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"224.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">validate</text><path d=\"M173.0 115.0 L183.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-flow-af-ah-paper-dim)\"></path><rect x=\"276.0\" y=\"90.0\" width=\"80.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"316.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">scan</text><path d=\"M265.0 115.0 L275.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-flow-af-ah-paper-dim)\"></path><rect x=\"368.0\" y=\"90.0\" width=\"80.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"408.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">plan</text><path d=\"M357.0 115.0 L367.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-flow-af-ah-paper-dim)\"></path><rect x=\"460.0\" y=\"90.0\" width=\"80.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"500.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">review</text><path d=\"M449.0 115.0 L459.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-flow-af-ah-paper-dim)\"></path><rect x=\"552.0\" y=\"90.0\" width=\"80.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"592.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">apply</text><path d=\"M541.0 115.0 L551.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-flow-af-ah-paper-dim)\"></path><rect x=\"644.0\" y=\"80.0\" width=\"70.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"679.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">account</text><path d=\"M633.0 115.0 L643.0 115.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-flow-af-ah-phosphor)\"></path><path d=\"M92.0 76.0 L448.0 76.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"270.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a machine, in this order</text><text x=\"500.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a person</text><text x=\"592.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the pipeline's</text><text x=\"592.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">role</text><text x=\"592.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">plan.bin</text><rect x=\"8.0\" y=\"200.0\" width=\"140.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"78.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a person's own</text><text x=\"78.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">credentials</text><path d=\"M150.0 223.0 L679.0 223.0 L679.0 152.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l14-flow-af-ah-amber)\"></path><text x=\"400.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">the road around the road</text><text x=\"400.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">closed by taking write access away; found by lesson 16</text></svg>", "caption": "Every stage can stop a change, and the cheap ones come first. None of them stops a change that never enters the road."}
```

## The road around the road

The dashed arrow in the figure is the reason this is a security topic. Anybody whose own credentials
can write to the account can change it from the console or the command line, and that change passes
through none of the stages. It is how most of the clinic's earlier mistakes were made: lesson 1's
bucket policy took one request from a person.

So a flow has two halves. The visible half is the pipeline, which the next two sections build. The
half that makes it mean anything is **taking write access away from people**, so that the pipeline's
identity is the one that can apply, which is the subject of the last section. What still slips past
both, a change made in an emergency or by a forgotten role, is found by reading the account as it is;
lesson 16 does that.

::: track devsecops
The `secure-pipeline` course built the application's side of this road: static analysis, dependency
scanning, image scanning, and the hardening of the runners themselves. This lesson adds the part
particular to cloud infrastructure: a plan as the thing reviewed, and an identity that can apply it.
:::

::: track *
The application that runs on this infrastructure has a pipeline of its own, with static analysis,
dependency scanning and image scanning, which is the subject of the `secure-pipeline` course. This
lesson is the part particular to cloud infrastructure: a plan as the thing reviewed, and an identity
that can apply it.
:::
