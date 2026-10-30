---
title: A day of syncing, in numbers
version: 1
---

**How much does polling cost, against one batched job?** No program on your computer can measure a
phone's radio, and a number invented to look like a measurement would be worse than none. What a
program can do is **work out the consequence of a stated assumption**, and say so. `batch.ts` is
that: a model of one day, built on the one radio the previous sections quoted, and on nothing else.

## The assumptions, written down

Every number the model uses is a constant at the top of the file, with where it came from:

| constant | value | where it comes from |
|---|---|---|
| `TRANSFER_S` | 1 second | assumed: a sync of the planner's week moves a few hundred bytes |
| `FULL_TAIL_S` | 5 seconds | Android's guide to network access, for a typical 3G radio |
| `LOW_TAIL_S` | 12 seconds | the same page |
| `LOW_SHARE` | 0.5 | the same page: low power "cuts battery power consumption by around 50%" |

**It leaves out everything else on purpose**: the screen, the processor, the time it takes to wake
up, and the fact that a real network is not 3G. So its numbers are not minutes of battery. They are
the minutes the radio spends awake, and the same minutes weighted by how hard it is working, which
is enough to compare four ways of syncing with each other.

## The model

Save it in `~/planner` as `batch.ts`:

```typescript
// batch.ts: a model, not a measurement, of how long a phone's radio stays awake for a sync
// The radio's timings are the typical 3G radio in Android's guide to network access.
const TRANSFER_S = 1; // assumed: one small sync moves its data in about a second
const FULL_TAIL_S = 5; // the radio stays at full power this long after the transfer
const LOW_TAIL_S = 12; // then at low power, which drains about half as much
const LOW_SHARE = 0.5;
const DAY_S = 24 * 60 * 60;

type Strategy = { name: string; everyS: number };
const strategies: Strategy[] = [
  { name: "poll every 10 seconds", everyS: 10 },
  { name: "poll every minute", everyS: 60 },
  { name: "every 15 minutes", everyS: 15 * 60 },
  { name: "one batched job a day", everyS: DAY_S },
];

// One wake-up keeps the radio up for the transfer and both tails, unless the next
// wake-up arrives first and keeps it up instead.
function day(s: Strategy) {
  const wakeUps = DAY_S / s.everyS;
  const full = Math.min(s.everyS, TRANSFER_S + FULL_TAIL_S);
  const low = Math.min(s.everyS - full, LOW_TAIL_S);
  const awake = (wakeUps * (full + low)) / 60; // minutes, at any power
  const cost = (wakeUps * (full + low * LOW_SHARE)) / 60; // minutes' worth of full power
  return { wakeUps, awake, cost };
}

const base = day(strategies[strategies.length - 1]).cost;
console.log("strategy".padEnd(24) + "wake-ups".padStart(9) + "awake min".padStart(11) +
  "cost min".padStart(10) + "  x batched");
for (const s of strategies) {
  const d = day(s);
  console.log(s.name.padEnd(24) + String(d.wakeUps).padStart(9) + d.awake.toFixed(1).padStart(11) +
    d.cost.toFixed(1).padStart(10) + `  ${Math.round(d.cost / base)}`);
}
```

**The one line that needs a second look is the `Math.min`.** A wake-up keeps the radio up for 18
seconds, but if the next one comes after 10, the radio never gets to the end of its tail: it is
woken again first. So at ten seconds the tails overlap, and the model counts each second once.

## The day

```
ana@dev:~/planner$ node batch.ts
strategy                 wake-ups  awake min  cost min  x batched
poll every 10 seconds        8640     1440.0    1152.0  5760
poll every minute            1440      432.0     288.0  1440
every 15 minutes               96       28.8      19.2  96
one batched job a day           1        0.3       0.2  1
```

Read it from the bottom. One batched job wakes the radio once, for 18 seconds; the cost column says
it is worth 0.2 minutes of the radio at full power. Every fifteen minutes, the shortest periodic
work WorkManager accepts, is 96 wake-ups, 28.8 minutes awake, and 96 times the batched job. Polling
every minute is **1,440 wake-ups and 432 minutes awake: more than seven hours** of a radio that
would otherwise be on standby. Polling every ten seconds keeps it awake for all 1,440 minutes of
the day, the radio Android's guide describes as "perpetually active".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l15-wakeups\" aria-label=\"Radio wake-ups over one day, from midnight to midnight, for three ways to sync. Polling every minute: 1,440 wake-ups, so close together that they make a solid band all day. Every 15 minutes: 96 thin marks spread across the day. One batched job a day: a single mark at three in the morning, on the charger.\"><text x=\"20\" y=\"39\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">every minute</text><text x=\"20\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,440</text><rect x=\"130\" y=\"30\" width=\"576\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"99\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">every 15 min</text><text x=\"20\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">96</text><rect x=\"130\" y=\"90\" width=\"576\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"159\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">once a day</text><text x=\"20\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"130\" y=\"150\" width=\"576\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"131\" y=\"31\" width=\"574\" height=\"32\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"0.5\"></rect><path d=\"M133.0 92 L133.0 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M138.9 92 L138.9 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M144.9 92 L144.9 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M150.8 92 L150.8 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M156.8 92 L156.8 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M162.7 92 L162.7 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M168.6 92 L168.6 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M174.6 92 L174.6 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M180.5 92 L180.5 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M186.4 92 L186.4 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M192.4 92 L192.4 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M198.3 92 L198.3 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M204.2 92 L204.2 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M210.2 92 L210.2 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M216.1 92 L216.1 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M222.1 92 L222.1 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M228.0 92 L228.0 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M233.9 92 L233.9 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M239.9 92 L239.9 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M245.8 92 L245.8 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M251.8 92 L251.8 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M257.7 92 L257.7 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M263.6 92 L263.6 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M269.6 92 L269.6 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M275.5 92 L275.5 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M281.4 92 L281.4 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M287.4 92 L287.4 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M293.3 92 L293.3 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M299.2 92 L299.2 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M305.2 92 L305.2 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M311.1 92 L311.1 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M317.1 92 L317.1 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M323.0 92 L323.0 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M328.9 92 L328.9 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M334.9 92 L334.9 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M340.8 92 L340.8 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M346.8 92 L346.8 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M352.7 92 L352.7 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M358.6 92 L358.6 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M364.6 92 L364.6 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M370.5 92 L370.5 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M376.4 92 L376.4 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M382.4 92 L382.4 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M388.3 92 L388.3 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M394.2 92 L394.2 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M400.2 92 L400.2 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M406.1 92 L406.1 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M412.1 92 L412.1 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M418.0 92 L418.0 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M423.9 92 L423.9 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M429.9 92 L429.9 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M435.8 92 L435.8 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M441.8 92 L441.8 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M447.7 92 L447.7 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M453.6 92 L453.6 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M459.6 92 L459.6 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M465.5 92 L465.5 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M471.4 92 L471.4 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M477.4 92 L477.4 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M483.3 92 L483.3 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M489.2 92 L489.2 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M495.2 92 L495.2 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M501.1 92 L501.1 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M507.1 92 L507.1 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M513.0 92 L513.0 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M518.9 92 L518.9 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M524.9 92 L524.9 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M530.8 92 L530.8 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M536.8 92 L536.8 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M542.7 92 L542.7 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M548.6 92 L548.6 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M554.6 92 L554.6 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M560.5 92 L560.5 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M566.4 92 L566.4 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M572.4 92 L572.4 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M578.3 92 L578.3 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M584.2 92 L584.2 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M590.2 92 L590.2 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M596.1 92 L596.1 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M602.1 92 L602.1 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M608.0 92 L608.0 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M613.9 92 L613.9 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M619.9 92 L619.9 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M625.8 92 L625.8 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M631.8 92 L631.8 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M637.7 92 L637.7 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M643.6 92 L643.6 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M649.6 92 L649.6 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M655.5 92 L655.5 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M661.4 92 L661.4 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M667.4 92 L667.4 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M673.3 92 L673.3 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M679.2 92 L679.2 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M685.2 92 L685.2 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M691.1 92 L691.1 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M697.1 92 L697.1 122\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M202 152 L202 182\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"210\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">on the charger</text><text x=\"130\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><text x=\"274\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">06:00</text><text x=\"418\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><text x=\"562\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><text x=\"706\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><text x=\"706\" y=\"214\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">hour of the day</text></svg>", "caption": "The same day, three ways. Each mark is a wake-up with its 18-second tail; at one a minute they merge into a band."}
```

**The ratios hold whatever the radio's real timings are; the minutes do not.** On an LTE or 5G
network with other tails the minutes change, and the ratio between polling every minute and one job
a day stays at the number of wake-ups, because each wake-up costs the same. That is the shape the
section on energy promised, now in numbers: the cost of a sync is mostly the cost of waking up for
it, so the fewer wake-ups, the cheaper, almost regardless of how much each one carries.

And the batched job has an advantage the model does not count at all. **It runs on the charger**,
where the energy it uses is not taken from the student's day.
