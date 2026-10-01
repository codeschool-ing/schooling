---
title: "Scaling policies, and the minutes they cannot remove"
version: 1
---

A group's desired count can be moved by hand, but the point of a group is that it moves itself.
A **scaling policy** is the rule that moves it. There are three kinds, and each one answers the
question "how many do we need now?" differently.

## Target tracking: keep a number near a target

You name a metric and a value: keep the group's average CPU at 50%. The group then does the
arithmetic a person would. If four instances are averaging 80%, the same work spread at 50% needs
4 × 80 / 50 = 6.4 instances, and since there is no such thing as 0.4 of a machine, it asks for 7.
When the load falls and seven instances are averaging 20%, the same arithmetic says three would do.

Target tracking is the one to start with, because you state the outcome and not the steps. The
metric does not have to be CPU; requests per instance, counted at the load balancer, is often a
better one for a web service, because it measures the work itself rather than one of its effects.

## Step scaling: thresholds and amounts

**Step scaling** is the older and more explicit form. You set alarms at thresholds and say what to
do at each one: above 70% average CPU add one instance, above 85% add three, below 30% remove one.
It gives exact control and asks you to get every number right; target tracking works the numbers
out for you.

## Scheduled: the clock, not the load

**A scheduled action** changes the counts at a time: at 07:30 on weekdays set the minimum to six,
at 20:00 set it back to two. It does not look at load at all. It is the only one of the three that
acts before the load arrives, which is precisely why it exists.

## The lag

**Every policy that watches a metric follows the load; none of them anticipates it.** Between the
moment the load rises and the moment a new instance takes a share of it, several things happen in
order:

1. the metric is collected, usually once a minute, and the policy waits for enough points to be
   sure the rise is real rather than a spike;
2. the group asks for instances and the provider places and starts them;
3. each one boots, then runs its user data;
4. the load balancer's health check passes, and traffic starts to reach it.

The first step is a minute or more, and the third is the one you control: a baked image boots
ready, while one that installs its software at boot adds every install to the wait. Added
together it is minutes, not seconds.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A chart with time across and load up the side, no numbers. The load curve climbs steeply. The capacity line is a staircase that rises only some minutes after the load passes it, so there is a shaded gap where the load is above capacity. Later the load falls and capacity steps down more slowly.\"><defs><marker id=\"lag-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 262 L700 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lag-ah)\"></path><path d=\"M70 262 L70 30\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lag-ah)\"></path><text x=\"700\" y=\"280\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">time</text><text x=\"78\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">requests per second</text><path d=\"M215 180 L230 170 L260 130 L290 100 L330 86 L380 82 L430 90 L430 100 L380 100 L380 140 L320 140 L320 180 Z\" fill=\"var(--amber)\" fill-opacity=\"0.22\" stroke=\"none\"></path><path d=\"M70 180 L320 180 L320 140 L380 140 L380 100 L430 100 L430 72 L560 72 L560 100 L620 100 L620 140 L690 140\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M70 210 L140 206 L190 196 L230 170 L260 130 L290 100 L330 86 L380 82 L430 90 L480 120 L520 160 L560 190 L620 204 L690 208\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"600\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">capacity</text><text x=\"640\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\" font-weight=\"600\">load</text><path d=\"M236 172 L236 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"236\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">alarm fires</text><path d=\"M320 52 L320 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M238 236 L318 236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-start=\"url(#lag-ah)\" marker-end=\"url(#lag-ah)\"></path><text x=\"244\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">boot + user data + health check</text><text x=\"324\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">new instance serving</text><text x=\"84\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">load above capacity</text><path d=\"M150 130 L262 164\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lag-ah)\"></path><text x=\"700\" y=\"16\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-style=\"italic\">illustrative shape, invented load</text></svg>", "caption": "A drawing of the shape, not a measurement: the load is made up. Capacity climbs in whole instances and each step lands minutes after the alarm that asked for it, because a new instance has to boot, run its user data and pass its health check. The shaded wedge is the time the existing instances carry more than they were sized for."}
```

During those minutes the instances already running carry the extra load alone. That is what the
target of 50% is for: **the headroom is what absorbs the lag**. A group that tracks CPU at 90% is
efficient right up to the first spike, and then every instance is saturated for the whole time
its reinforcements take to boot. Headroom costs money every hour; its absence costs the minutes in
the shaded wedge, and those are the minutes users notice.

Three things shorten the wedge, and none of them removes it:

- a faster boot: a baked image, a lighter user data;
- a metric that moves earlier: request count rises before CPU does;
- a schedule for the load you can predict: the Monday-morning rise that happens every Monday.

AWS also offers predictive scaling, which forecasts the next days from past weeks and scales ahead
of the forecast. It is a schedule written by a model, and it helps exactly as much as the load
repeats itself.

## Going down is slower on purpose

Groups remove instances more cautiously than they add them. Removing too early and adding again a
few minutes later is called **flapping**, and each round pays for a boot and a warm-up that served
nobody. The policies wait longer, and look at a longer window, before they scale in. The drawing
shows it: capacity steps up as fast as it can and steps down later.

Scaling in also means an instance is terminated while it may be serving somebody. The load balancer
stops sending it new requests and gives the ones in flight time to finish before it goes. Anything
it held that was not somewhere else is lost, which is where the next section begins.
