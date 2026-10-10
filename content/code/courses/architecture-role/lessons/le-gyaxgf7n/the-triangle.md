---
title: Quality is not the free corner
version: 1
---

Anybody who has worked on a project knows the triangle: scope, time and cost, where fixing any two
moves the third. It is usually credited to Martin Barnes, who drew it in 1969, and many versions
put quality in the middle or add it as a fourth corner. **The trouble starts when quality becomes
the variable that absorbs whatever the other three cannot.** The date is fixed, the budget is fixed,
the scope was promised, so the team goes faster by skipping the tests and the design. This section
argues that for the kind of quality a customer cannot see, that trade stops paying within weeks.

## Two kinds of quality

**External quality is what a user can see**: whether the Driver app crashes, whether a quote is
right, how fast the shipper's map loads. It can be traded legitimately. A plainer screen or fewer
options in the first version is a smaller scope, and the business is entitled to choose a smaller
scope.

**Internal quality is what only developers see**: whether the code is clear, whether the modules
have sensible boundaries, whether there are tests that make a change safe. No shipper will ever
notice it directly. What it decides is how much the next change costs, and that is why cutting it
is not the saving it looks like.

## Fowler's design stamina hypothesis

In 2007 Martin Fowler drew a graph with time along one axis and cumulative functionality, the total
of what has been delivered, up the other. It has two lines. One is a project that pays no attention
to design; the other is a project that keeps its design healthy as it goes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A graph of cumulative functionality against time, with two lines. The no-design line starts higher and bends flatter as time passes. The good-design line starts lower and stays straight. They cross at the design payoff line. Before it, skimping delivers more; after it, the gap grows every week.\"><defs><marker id=\"stamina-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M80 270 L690 270\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#stamina-ah)\"></path><path d=\"M80 270 L80 30\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#stamina-ah)\"></path><text x=\"690\" y=\"288\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">time</text><text x=\"90\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cumulative functionality</text><path d=\"M80.0 270.0 L95.0 254.1 L110.0 246.7 L125.0 240.9 L140.0 235.9 L155.0 231.4 L170.0 227.4 L185.0 223.6 L200.0 220.1 L215.0 216.7 L230.0 213.6 L245.0 210.5 L260.0 207.6 L275.0 204.8 L290.0 202.1 L305.0 199.4 L320.0 196.9 L335.0 194.4 L350.0 192.0 L365.0 189.7 L380.0 187.4 L395.0 185.1 L410.0 182.9 L425.0 180.8 L440.0 178.6 L455.0 176.6 L470.0 174.5 L485.0 172.5 L500.0 170.6 L515.0 168.6 L530.0 166.7 L545.0 164.8 L560.0 163.0 L575.0 161.1 L590.0 159.3 L605.0 157.6 L620.0 155.8 L635.0 154.1 L650.0 152.4 L665.0 150.7 L680.0 149.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><path d=\"M80 270 L680 72.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><path d=\"M280.8 270 L280.8 44\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></path><text x=\"288.8458033442822\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">design payoff line</text><text x=\"650\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">good design</text><text x=\"676\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">no design</text><text x=\"180\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">before it, skimping</text><text x=\"180\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">delivers more</text><text x=\"500\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">after it, the gap</text><text x=\"500\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">grows every week</text></svg>", "caption": "Fowler's design stamina hypothesis, redrawn. The whole argument is where the dashed line falls, and Fowler puts it weeks into a project, not months."}
```

The no-design line starts faster, because no time goes into design. Then it bends: every new feature
takes longer than the one before, as the code gets harder to understand and to change. The
good-design line starts slower and keeps its slope. The two cross at what Fowler called the design
payoff line. **Before the line, skimping on design delivers more. After it, the skimping project is
behind and falling further behind every week.**

Fowler called it a hypothesis on purpose. Productivity in software cannot be measured well enough
to prove it, so it rests on the experience of people who have worked on both kinds of code. The
part that matters most to an architect is where the line falls. In a later essay, "Is High Quality
Software Worth the Cost?" from 2019, Fowler argued that it comes within weeks rather than months,
far sooner than most people assume when they decide to cut corners.

## What it means for a deadline

If the payoff line is weeks away, cutting internal quality to hit a date pays only for work whose
life ends before the line: a prototype that will be thrown away, a demonstration for one meeting, a
one-off migration script. For anything that will be changed again, and at Carreto that is almost
everything, the shortcut is paid back inside the same quarter, with interest.

Carreto met this in Renata's second quarter. Helena Prado wanted multi-stop loads, in which one
truck collects from two shippers on the same trip, by the end of the quarter. The Pricing team
estimated two ways of building it:

- **6 weeks** with tests, extending the quote model so that a load has a list of stops;
- **4 weeks** by special-casing a second stop inside the existing single-stop code, with few tests.

The second saves two weeks. But the next two items on Pricing's roadmap, return loads and quotes for
refrigerated cargo, both change the same code, and the team estimated that each would take 2 to 3
weeks longer on top of the special case. **At the low end of that estimate the two weeks are gone
with the first feature, and the second is pure loss.** Renata did not decide anything here. What
she did was put the three estimates on one page, where Helena could see the second and third
features beside the first. Helena chose the six weeks.

## Where the time really comes from

If internal quality is not the free corner, something else has to move when the date is tight.
There are three honest candidates.

**Scope.** Build less, or a smaller version first. This is the corner that moves most often, and the
next section is about doing it well.

**Time.** Move the date. Sometimes it is possible and nobody asked. Sometimes, as the next section's
regulatory case shows, the date belongs to somebody outside the company and nothing will move it.

**Cost.** Add people. This works far less than it promises, and Fred Brooks, whose essay opened
lesson 12, gave the reason in *The Mythical Man-Month* in 1975: adding manpower to a late software
project makes it later. People who join need to learn the system from people who are already busy,
and every person added creates more paths of communication. Among *n* people there are
*n*(*n* − 1) / 2 pairs, so five people have 10 pairs to keep in step and eight people have 28.

**Quality is missing from that list on purpose.** Internal quality is not a corner to trade away;
it is the condition under which the other three estimates mean anything, because every estimate a
team gives assumes it can change the code at the speed it is used to. The next section asks how
good is good enough, which is a different question from how much quality can be cut.
