---
title: The autopsy of a tool nobody uses
version: 1
---

Every engineering organisation has one. It works, it was built carefully, it was launched with a
demo, and hardly anybody opens it. **The usual reaction is to promote it harder** — another demo, a
better guide, a reminder in the engineering channel — on the theory that people would use it if
they knew it was there. Coreto tried that. It changed nothing, because nobody had stayed away for
lack of information.

The useful reaction is an autopsy: a written account of what was expected, what happened and why the
two differ, written without blame and read by the people who will propose the next tool.

## The facts

Before Rafaela Nunes led the Platform team, it built a deploy portal. In a web application, an engineer could see which version of each service was running in staging and production, press a button to deploy, press another to roll back, and ask for an approval before a production deploy.

| | |
|---|---|
| effort | 1,100 engineer-hours |
| cost, at R$ 150 an hour | R$ 165,000 |
| as a share of an engineer-year | 1,100 ÷ 1,760 = 0.625 |
| services deploying through it, six months after launch | 3 of 41 (7%) |
| cost per service that uses it | R$ 165,000 ÷ 3 = R$ 55,000 |

The last row is the uncomfortable one. Spread across the services it was built for, the portal would
have been a modest investment; spread across the services that chose it, each one cost Coreto the
price of a small project.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 258\" role=\"img\" aria-label=\"Forty-one squares, one per Coreto service, six months after the deploy portal launched. Three are lit: those services deploy through the portal. Thirty-eight are unlit: they deploy the way they already did. Below, the portal's cost: 1,100 engineer-hours, R$ 165,000.\"><text x=\"360\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">Coreto's 41 services, six months after the portal launched</text><rect x=\"56\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"100\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"144\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"188\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"232\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"276\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"320\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"364\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"408\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"452\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"496\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"540\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"584\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"628\" y=\"48\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"56\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"100\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"144\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"188\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"232\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"276\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"320\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"364\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"408\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"452\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"496\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"540\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"584\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"628\" y=\"92\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"56\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"100\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"144\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"188\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"232\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"276\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"320\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"364\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"408\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"452\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"496\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"540\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"584\" y=\"136\" width=\"36\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"56\" y=\"198\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"78\" y=\"210\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">deploy through the portal: 3 (7%)</text><rect x=\"396\" y=\"198\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"418\" y=\"210\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">deploy the way they already did: 38</text><text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">built in 1,100 engineer-hours: R$ 165,000</text></svg>", "caption": "The portal, six months after launch. Thirty-eight of Coreto's services kept deploying the way they already did; three moved to the portal, and all three had no deploy pipeline of their own before it."}
```

## What the portal did well

**Nothing in the autopsy says the portal was badly built.** The version view was accurate, the
rollback worked, the approval step recorded who approved what. The engineers who built it were
good, and they solved the problem they were given. That is what makes the case worth studying: a
tool that fails because it is broken teaches you about testing, and a tool that works and goes
unused teaches you about deciding what to build.

## Who used it, and who did not

One of Rafaela's first moves as the team's lead was to look at who used the portal, and the three users
had something in common. **None of the three had a deploy pipeline before the portal existed.** They
were services whose owners had deployed by asking Platform in the chat channel, and the portal was a
real improvement on asking.

The other 38 had pipelines. A change merged to the main branch went through the build, the tests
and the deploy without anybody opening a browser. For those teams the portal offered a button to
do something that already happened by itself, plus an approval step that slowed the deploy down.
Several engineers had tried it once, during the launch week, and gone back.

So the gap between the expectation and the result had a precise shape:

| what Platform expected | what happened | why |
|---|---|---|
| teams would move their deploys to the portal | teams with pipelines stayed on them | the portal added a step to something already automatic |
| the guide and the demo would bring the rest | usage did not move after either | nobody was missing information |
| the approval step would be welcome | it was the reason engineers gave for abandoning their first try | it slowed every production deploy for a check nobody had asked for |

## What it still costs

The 1,100 hours are spent, and no decision made today gets any of them back. **Money already spent
is a sunk cost, and it belongs in the autopsy but not in the next decision.** The argument "we spent
R$ 165,000 on it, so teams should be told to use it" is the trap. It would turn a measurement into a mandate, which lesson 14 showed hides the evidence. And it would spend more of the other teams' time to justify money nobody can recover.

What the portal costs from now on is a different number, and it is the one that matters. It runs on
Coreto's infrastructure, it depends on libraries that need security patches, it holds credentials
that can deploy to production, and somebody on Platform is on call for it. A tool with three users
keeps all of those costs and spreads them over three. The decision about that future cost — keep
it, shrink it or switch it off — is the end of this lesson, and it comes after the question of why
a team of capable engineers built it in the first place.
