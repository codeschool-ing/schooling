---
title: The numbers behind a bad call
version: 1
---

Two more numbers, and between them they explain almost every complaint about a call, a stream or a
game that the first three could not.

**Jitter** is how much the latency *varies*. **Loss** is the fraction of packets that never
arrive.

Neither appears on a plan, both are reported by tools people rarely open, and for live traffic
they matter more than bandwidth by a wide margin.

## Jitter: the average was fine

Latency is usually quoted as one number, which hides the thing that matters. Ten packets that each
take 40 ms and ten packets that take 10, 90, 15, 80, 20, 95, 12, 75, 30 and 73 have the same
average and produce completely different experiences.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Two rows of ten packet arrivals. The top row is evenly spaced at forty milliseconds each. The bottom row is uneven, ranging from ten to ninety-five milliseconds, with the same average. A note says the second one produces a broken call.\"><text x=\"30\" y=\"38\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">steady — 40 ms each</text><rect x=\"30\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"94\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"158\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"222\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"286\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"350\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"414\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"478\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"542\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"606\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><text x=\"360\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">every gap the same — the player always has the next piece ready</text><text x=\"30\" y=\"152\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">jittery — same average</text><rect x=\"30\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"48\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"180\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"206\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"238\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"396\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"424\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"556\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"590\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"640\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><text x=\"360\" y=\"226\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">bunched and then nothing — the player runs dry, then has to catch up</text></svg>", "caption": "Identical average latency. The top one is a conversation; the bottom one is the call everybody has had."}
```

Live audio has to be played out at a constant rate — twenty milliseconds of speech every twenty
milliseconds, without exception. If the next piece has not arrived when its moment comes, there is
nothing to play, and silence or a click is the only option.

So the receiver keeps a small **jitter buffer**: it holds a few packets back before starting, so a
late one has a margin to arrive in. And now you can see the trade, because it is the same one as
the last section on a much smaller scale. A bigger jitter buffer absorbs more variation and adds
its own delay to every word. Applications tune it constantly, growing it when the network is
unstable and shrinking it when it settles — which is why a call sometimes develops a lag that was
not there at the start and never quite goes away.

**Where jitter comes from** is mostly the previous section. A queue that is sometimes empty and
sometimes full delivers exactly this pattern. Wi-Fi adds its own, since the radio is shared and a
frame may wait for its turn. So does anything that occasionally decides to do something else with
the link.

## Loss: the fraction that never arrives

Loss is quoted as a percentage, and the percentages that matter are much smaller than people
expect.

| loss | what it does |
|---|---|
| 0% | nothing to discuss |
| under 0.5% | invisible on a call, essentially invisible on a download |
| 1 – 2% | audible on a call; a download slows noticeably as TCP backs off |
| 2 – 5% | calls become hard work, pages stall in bursts |
| over 5% | most things stop being usable |

Two percent looks tiny and is not, and the reason is the two halves of lesson two.

**For TCP, loss is a brake.** Loss is the only signal the network gives, so TCP treats every drop
as congestion and reduces its rate. A link losing 2% has a sender that spends its life slowing
down and cautiously speeding up, and throughput collapses to a fraction of capacity. **A small
loss rate costs a large amount of bandwidth** — which is why "the connection is fine, it is just
slow" so often means a cable that is quietly dropping packets.

**For UDP, loss is a hole.** Nothing is resent, so each lost packet is twenty milliseconds of
speech that will never exist. Codecs conceal a little of it by guessing, and at one percent you
hear almost nothing; at five you hear a conversation made of fragments.

## Where it comes from, in order of likelihood

Worth knowing the order, because the first two are far more common than the last and far easier to
check.

**A full buffer.** When the queue from the last section actually runs out of room, the packets
after it are dropped. Loss and bloat are the same event at different stages.

**Something physical.** A damaged cable, a loose connector, interference, a marginal Wi-Fi
signal — errors corrupt frames, and a corrupted frame is discarded silently, exactly as lesson two
described.

**Congestion somewhere in the middle.** A link between providers running at capacity at nine in
the evening, which you cannot see, cannot fix, and can only recognise by the fact that it appears
at the same hour every day.

## Putting all five together

You now have every number this lesson was about, and the useful thing is which complaint each one
explains.

| the complaint | the number |
|---|---|
| large downloads take too long | bandwidth |
| everything feels sluggish, but files arrive fine | latency |
| a download is slower than the plan promises | throughput |
| the call breaks only when somebody downloads | queuing |
| the voice is choppy and keeps cutting | jitter, and loss |
| the connection is fine and the site is slow | latency, or the other end |

That table is the whole lesson. Somebody says *it is slow*, and the work is finding out which row
they are on.

## Where this leaves you

Jitter is variation in delay, and live audio cares about it more than about the average, because it
must be played out at a constant rate. Loss is the fraction that never arrives — a brake for TCP,
a hole for UDP — and it matters at percentages far smaller than they look.

The three tools everybody reaches for measure some of this and quietly hide the rest, so the last
section of this lesson is reading them honestly.
