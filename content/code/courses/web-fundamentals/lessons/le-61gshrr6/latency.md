---
title: The time there and back
version: 1
---

**Latency is how long one thing takes to get there and come back.** It is measured in
milliseconds, nobody sells it to you, and for most of what you do on a computer it matters more
than bandwidth does.

The number usually quoted is the **round trip** — out and back — because that is what you can
actually measure from one end, and because almost everything you do waits for an answer.

## Four things add up to it

Latency is not one delay. It is four, and they behave completely differently.

| what | where it comes from | can it be reduced |
|---|---|---|
| propagation | distance, at the speed of light in glass | only by moving closer |
| transmission | putting the bits on the wire, at that link's capacity | yes — more bandwidth |
| processing | each router reading the header and deciding | a little, and it is already small |
| queuing | waiting behind other traffic at each hop | yes, and it is the whole of the next section |

The second one is the only place bandwidth appears, and for a small request it is tiny. The first
one is the interesting one, because it is a floor nobody can get under.

## The floor nobody can lower

Light in fibre travels at about **200,000 kilometres per second** — slower than in vacuum, because
glass. Divide any distance by that and you have a delay that no equipment, no money and no plan
can remove.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Three routes with their minimum round trips: within a city about two milliseconds, São Paulo to Miami about eighty, São Paulo to Tokyo about one hundred and ninety. A note says these are floors imposed by distance and cannot be bought down.\"><text x=\"360\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the least a round trip can possibly take</text><text x=\"30\" y=\"66\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">across a city</text><rect x=\"188\" y=\"52\" width=\"20\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><text x=\"224\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">~2 ms</text><text x=\"30\" y=\"116\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">São Paulo to Miami</text><rect x=\"188\" y=\"102\" width=\"150\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><text x=\"354\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">~80 ms</text><text x=\"30\" y=\"166\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">São Paulo to Tokyo</text><rect x=\"188\" y=\"152\" width=\"356\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><text x=\"560\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">~190 ms</text><text x=\"360\" y=\"208\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no plan, no equipment and no amount of money moves any of these</text></svg>", "caption": "Distance is the one component of latency that is physics rather than engineering. Everything else is negotiable."}
```

Real numbers are higher than these, because cables do not run in straight lines and every hop adds
its own small delays. But the floor is the floor, and it is why a service with users on two
continents cannot be fast for both from one building.

That is also the argument for a whole technology you will meet in lesson 9: if the distance cannot
be reduced, the only remaining move is to **put a copy of the content closer**. A CDN is that idea
and nothing more.

## Why it beats bandwidth for almost everything

Here is the arithmetic that makes this lesson worth having.

A page does not arrive as one lump. Your browser asks for the HTML, reads it, discovers it needs a
stylesheet and some scripts and images, asks for those, discovers more, and asks again. Each of
those discoveries is a **round trip** — and some of them cannot start until the one before has
finished.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"A timeline of one page load at two hundred milliseconds round trip. Four sequential waits are drawn: name lookup, connection, encryption and the first request, and only a short final block is the actual data transfer.\"><text x=\"360\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">one page, at a 200 ms round trip</text><rect x=\"20\" y=\"44\" width=\"150\" height=\"28\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".3\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"95\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">find the name</text><rect x=\"176\" y=\"44\" width=\"150\" height=\"28\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".3\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"251\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">open the connection</text><rect x=\"332\" y=\"44\" width=\"150\" height=\"28\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".3\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"407\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">agree encryption</text><rect x=\"488\" y=\"44\" width=\"150\" height=\"28\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".3\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"563\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ask for the page</text><rect x=\"644\" y=\"44\" width=\"54\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".4\" stroke=\"var(--phosphor)\"></rect><text x=\"671\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">data</text><text x=\"330\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor-dim)\">four round trips — 800 ms of waiting</text><text x=\"671\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the transfer</text><rect x=\"20\" y=\"130\" width=\"678\" height=\"46\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".08\" stroke=\"var(--amber)\"></rect><text x=\"360\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">double the bandwidth and only the last block shrinks</text><text x=\"360\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">halve the round trip and every block shrinks</text><text x=\"360\" y=\"210\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">this is why a faster plan so often changes nothing about how a site feels</text></svg>", "caption": "Most of a small page load is waiting, not transferring. Bandwidth only shortens the part that is already short."}
```

Four round trips at 200 ms each is 800 milliseconds before a byte of the page itself arrives. Now
double the bandwidth: those 800 milliseconds are **completely unchanged**, because none of them
were about capacity. Only the last little block gets shorter.

That is the sentence to keep: **bandwidth shortens the transfer, latency lengthens everything
else.**

## What the numbers feel like

Latency is one of the few technical quantities you can feel directly, and knowing roughly where
the thresholds are makes a complaint much easier to interpret.

| round trip | what it feels like |
|---|---|
| under 20 ms | instant — a remote machine feels local, typing in a remote terminal is comfortable |
| 20 – 60 ms | good — a video call is natural, a competitive game is playable |
| 60 – 150 ms | noticeable — conversation starts stepping on itself, pages feel sluggish rather than broken |
| 150 – 300 ms | clearly wrong — people begin saying "the internet is slow" without knowing why |
| over 300 ms | broken — interactive work becomes unpleasant whatever the bandwidth is |

Notice that the last row can happen on a connection with enormous capacity. Somebody on a fast
satellite link has more bandwidth than they need and a conversation that keeps colliding, and
every diagnosis that starts by measuring speed will miss it.

It is also why remote work across a large distance is a different experience from remote work
across a city, in a way nobody warns you about: the files download quickly either way, and the
video call is where the distance shows up.

## What makes it worse, and it is rarely distance

Two things inflate latency far beyond the physics, and both are worth recognising.

**The path is not the map.** Traffic between two cities in the same country sometimes travels via
another continent, because that is where the two providers exchange traffic. The straight line was
never available.

**The last stretch is often the worst.** Wi-Fi across a flat, a mobile connection negotiating with
a tower, an old cable — these can add tens of milliseconds before your traffic has left the
building. Connecting a computer with a cable is the single most reliable latency improvement most
people can make, and it costs nothing.

And satellite deserves its own line. A traditional satellite sits 36,000 km up, so the round trip
is at least **480 ms before anything else** — which is why those connections feel strange no
matter how much bandwidth they carry. Newer constellations fly far lower and bring it down to tens
of milliseconds, which is the whole reason they were worth building.

## Where this leaves you

Latency is the time there and back, it is built from distance, transmission, processing and
queuing, and only distance is physics. It decides how a page feels, because most of a small page
load is waiting rather than transferring — so bandwidth shortens the short part and latency
lengthens all of it.

Three of the four components are now covered. The fourth, **queuing**, is the one that moves the
most, changes minute by minute, and explains the complaint you hear most often at home — and it is
two sections away.
