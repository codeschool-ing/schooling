---
title: "Traffic splitting: blue/green and canary"
version: 1
---

The wrong picture of a 90/10 split is a doorman counting: nine customers to the old version, the
tenth to the new, and round again. **A weight is a share of the requests that reach the app's
address, and nothing in Microsoft's documentation promises how any single request is assigned.**
Over a day the shares come out as written; over twenty requests they can come out very differently,
and the end of this section works out how differently. A weight is also not a number of replicas:
each revision scales on its own share of the traffic, by its own rule. And beside the weights there
is a second mechanism, the **label**, which gives one revision an address of its own that no weight
touches. This section reads both from the documentation, compiles one mistake the compiler lets
through, and runs the arithmetic.

## Weights

With ingress on and nothing said, all the traffic goes to the latest revision. In multiple mode the
`traffic` list in the ingress says otherwise. Each entry names a revision, by `revisionName`, by
`label`, or as `latestRevision: true`, and gives it a `weight`. The shop's file names both
revisions:

```bicep
traffic: [
  { revisionName: 'shop--v1-0', weight: 90 }
  { revisionName: 'shop--v1-1', weight: 10, label: 'canary' }
]
```

**The weights must add up to 100**, the documentation says. The compiler does not add them:

```
ana@laptop:~/azure$ sed 's/weight: 10,/weight: 20,/' shop-app.bicep > sum.bicep
ana@laptop:~/azure$ bicep build sum.bicep
ana@laptop:~/azure$ jq -c '[.resources[1].properties.configuration.ingress.traffic[].weight]' sum.json
[90,20]
```

A template asking for 110 percent of the traffic, compiled without a word, and only Azure would
refuse it. On the command line the same split is one command, with the help
describing its two ways of naming a revision:

```
ana@laptop:~/azure$ az containerapp ingress traffic set --help | sed -n '/^Arguments/,/^$/p'
Arguments
    --label-weight                : A list of label weight(s) for the container app. Space-separated
                                    values in 'label_name=weight' format.
    --revision-weight             : A list of revision weight(s) for the container app. Space-
                                    separated values in 'revision_name=weight' format. For latest
                                    revision, use 'latest=weight'.
    --traffic-weight [Deprecated] : A list of revision weight(s) for the container app. Space-
                                    separated values in 'revision_name=weight' format. For latest
                                    revision, use 'latest=weight'.
        WARNING: Option '--traffic-weight' has been deprecated and will be removed in a future
        release. Use '--revision-weight' instead.
```

On a subscription the shop's split would be set with
`az containerapp ingress traffic set --name shop --resource-group shop --revision-weight shop--v1-0=90 shop--v1-1=10`,
not run in this course. `latest` stands for whichever revision is newest. That suits an app where
every deployment should take all the traffic at once, and it is the wrong choice for a canary,
where the newest is exactly the revision you do not yet trust with everything.

**Each revision scales separately.** The scale block from section 03 belongs to the template, so
both revisions have their own, and each counts only the requests it is sent. During the split the
old revision may run up to 10 replicas and the new one up to 10 more, and the new one, with a tenth
of the traffic, reaches zero more often. Its customers meet more cold starts than the others do,
which is worth knowing before comparing the two revisions' response times.

## Labels

A label is a name on one revision, and it comes with an address. Microsoft's blue-green page
reaches a labelled revision at the app's name, three dashes and the label, under the environment's
domain: `shop---canary.` followed by the domain. **A label's address reaches its revision whatever
the weights say**, including a weight of 0, so a revision can be tested on its real address, in the
real environment, by the three developers, before any customer is sent there.

Three rules come with them. A label is on one revision at a time, and a revision carries one label;
adding a label to a revision that already has one replaces it. Moving a label to another revision
keeps its address, so testers keep the same bookmark from one release to the next. And a label
does not need a weight at all. On a subscription the label above would be added with
`az containerapp revision label add --revision shop--v1-1 --label canary`, with the resource group,
not run here.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 304\" role=\"img\" aria-label=\"The shop's container app during a canary. Customers call the app's address, which sends 90 percent of the requests to revision shop--v1-0, running four replicas, and 10 percent to revision shop--v1-1, running one. The three developers call the label's address, shop---canary, which reaches shop--v1-1 whatever the weights say. Everything sits inside the environment shop-env.\"><rect x=\"12\" y=\"52\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"77\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">customers</text><rect x=\"12\" y=\"196\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"77\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the three developers</text><rect x=\"160\" y=\"12\" width=\"548\" height=\"280\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"174\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the environment</text><text x=\"694\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">shop-env</text><rect x=\"180\" y=\"50\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"192\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the app's address</text><text x=\"192\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop.&lt;domain&gt;</text><rect x=\"180\" y=\"194\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"192\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the label's address</text><text x=\"192\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop---canary.&lt;domain&gt;</text><rect x=\"500\" y=\"46\" width=\"196\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">shop--v1-0</text><text x=\"512\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SHOP_VERSION=1.0</text><rect x=\"512\" y=\"96\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"538\" y=\"96\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"564\" y=\"96\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"590\" y=\"96\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"624\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4 replicas</text><rect x=\"500\" y=\"170\" width=\"196\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">shop--v1-1</text><rect x=\"616\" y=\"178\" width=\"70\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"651\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">canary</text><text x=\"512\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SHOP_VERSION=1.1</text><rect x=\"512\" y=\"220\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"546\" y=\"231\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 replica</text><path d=\"M142 72 L172 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M180 72 L172 67.5 L172 76.5 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M142 216 L172 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M180 216 L172 211.5 L172 220.5 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M380 66 C430 66 450 80 492 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M500 80 L492 75.5 L492 84.5 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"436\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">90%</text><path d=\"M380 86 C440 86 440 196 492 196\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M500 196 L492 191.5 L492 200.5 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"430\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">10%</text><path d=\"M380 222 L492 222\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M500 222 L492 217.5 L492 226.5 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"440\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">at any weight</text></svg>", "caption": "The shop during its canary. The app's address shares the customers between two revisions, each scaled on its own share of them; the label's address reaches the new revision directly, at any weight, including 0."}
```

## Blue/green

Blue/green is two revisions and two labels, and Microsoft documents it end to end. The revision
customers use carries the label `blue` and all the weight. The new one is deployed with the label
`green` and a weight of 0. The developers test it on its label's address. When it is right, one
change moves the whole weight across, `--label-weight blue=0 green=100`, and **rolling back is the
same command the other way round**, for as long as the blue revision is still active. The next
release takes the label the old one gave up, so the two names alternate and nobody renames a
bookmark.

**Blue/green moves everybody at once**, which is its strength and its risk. The switch is clean, and
a rollback is one command; but the moment after the switch, every customer is on a revision that
only the testers have used.

## Canary

A canary moves the customers in steps, and the shop's file is its second step:

1. `shop--v1-0` has all the traffic, and `shop--v1-1` is deployed beside it with the label `canary`
   and a weight of 0, and tested on the label's address;
2. the weights become 90 and 10, and the two revisions' errors and response times are compared;
3. 50 and 50, if nothing is worse;
4. 0 and 100, and the old revision stays active a while, so going back is still one command;
5. the old revision is deactivated, and costs nothing from then on.

Where blue/green trusts the tests, a canary trusts the customers, a few at a time. What a canary
needs is enough of them, and that is arithmetic.

## The arithmetic of ten percent

The documentation states a weight as a percentage of the traffic and is silent on how each request
is chosen. The safe assumption for planning is that **each request goes to the canary with a
probability of one in ten, independently of the others**. Under it, the number the canary receives
out of N requests has an expected value of N/10, and a spread that the binomial distribution gives.
This program works out both, for three sizes of sample. Save it as `~/azure/split.py`:

```python
# split.py
import math

CANARY = 0.10  # the new revision's weight, as a share

for n in (20, 200, 2000):
    expected = n * CANARY
    spread = 2 * math.sqrt(n * CANARY * (1 - CANARY))
    none = (1 - CANARY) ** n
    print(f'{n:5} requests: {n - expected:5.0f} to v1-0, {expected:4.0f} to v1-1, '
          f'give or take {spread:2.0f}; none to v1-1: {none:.3f}')
```

`spread` is two standard deviations, the distance within which the count lands about 95 times in
100. `none` is the chance that the canary receives nothing at all. Run:

```
ana@laptop:~/azure$ python3 split.py
   20 requests:    18 to v1-0,    2 to v1-1, give or take  3; none to v1-1: 0.122
  200 requests:   180 to v1-0,   20 to v1-1, give or take  8; none to v1-1: 0.000
 2000 requests:  1800 to v1-0,  200 to v1-1, give or take 27; none to v1-1: 0.000
```

**Twenty requests prove nothing about a canary.** The expected two can be anything from none to
five, and one time in eight it is none: the canary was not tested, and the dashboard shows a
version with no errors. At 200 requests the canary's 20 is give or take 8, enough to notice a
version that fails half the time and not one that fails one time in fifty. At 2,000 the 200 is
give or take 27, a sample worth comparing. For the shop, that means a canary is judged on a day
of traffic and not on its first minutes.
