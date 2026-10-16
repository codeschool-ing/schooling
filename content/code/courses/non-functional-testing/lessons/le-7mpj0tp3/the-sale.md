---
title: The ten o'clock sale, as a number
version: 1
---

Lesson 1 named the box office's busiest moment: a popular show, 300 seats, going on sale at 10:00.
Here it becomes a number of requests a second. **The arithmetic is short; the assumptions are the
work**, and they go in the test plan beside the result, so that the person who knows better can
correct one of them and the number follows.

## The assumptions

Each one is a guess with a reason. On a real system, last year's sale in the logs replaces them.

1. **Who comes.** Four people for every seat, 1,200 in all, and they arrive in the first minute,
   because they were waiting for 10:00. That is an arrival rate of 1,200 / 60 = **20 people a
   second**.
2. **What each one asks for.** The list of shows once, the show's page three times (to open it,
   after choosing a seat, after being told the seat is taken), and one booking. Five requests a
   visit.
3. **How long they think.** Four seconds between one request and the next. A visit of five
   requests has four gaps, so it lasts 4 × 4 = 16 seconds, plus responses of a few tens of
   milliseconds, which are small enough to leave out here.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l03-sale\" aria-label=\"The ten o'clock sale worked through in boxes. 1,200 people in the first minute is 20 people a second. Each person sends 5 requests, so the site receives 100 requests a second: 20 for the list of shows, 60 for a show page and 20 for bookings. Each visit lasts 16 seconds, four gaps of 4 seconds, so by Little's law 20 a second times 16 seconds is 320 people on the site at once. For the show page alone, 60 requests a second times 4.02 seconds is about 241 virtual users.\"><defs><marker id=\"l03-sale-nf-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"150.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"95.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">1,200 people</text><text x=\"95.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in the first minute</text><path d=\"M172.0 70.0 L210.0 70.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-sale-nf-ah-paper)\"></path><rect x=\"212.0\" y=\"30.0\" width=\"150.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"287.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">20 a second</text><text x=\"287.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">people arriving</text><path d=\"M364.0 70.0 L402.0 70.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-sale-nf-ah-paper)\"></path><text x=\"383.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">× 5</text><rect x=\"404.0\" y=\"30.0\" width=\"296.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"552.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">100 requests a second</text><text x=\"552.0\" y=\"75.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 GET /shows · 60 GET /shows/{id}</text><text x=\"552.0\" y=\"88.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 POST /bookings</text><path d=\"M287.0 112.0 L287.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-sale-nf-ah-paper)\"></path><text x=\"297.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">× 16 s a visit</text><rect x=\"212.0\" y=\"152.0\" width=\"150.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"287.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">320 people</text><text x=\"287.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">on the site at once</text><path d=\"M552.0 112.0 L552.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-sale-nf-ah-paper)\"></path><text x=\"562.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">60 × 4.02 s</text><rect x=\"452.0\" y=\"152.0\" width=\"200.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"552.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">≈ 241 virtual users</text><text x=\"552.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">for the show page alone</text><text x=\"20.0\" y=\"255.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">assumed: 4 people a seat, 5 requests a visit, 4 s of think time</text></svg>", "caption": "From a crowd to a rate, and from a rate to a number of users. Change an assumption at the top and every box below it moves."}
```

## The numbers that follow

**Requests a second**: 20 people a second × 5 requests each = **100 requests a second** across
the site. By operation, that is 20 a second for `GET /shows`, 60 a second for `GET /shows/{id}`
and 20 a second for `POST /bookings`. The split matters more than the total, because the show page
is the expensive read and the booking is the one that takes a lock.

**People on the site at once**, by Little's law: 20 arriving a second × 16 seconds each =
**320 people** in the middle of a visit at any moment of that minute. That is the number a closed
test would need as virtual users to reproduce the whole journey, with a think time of 4 s.

**Virtual users for the show page alone**: to offer 60 requests a second with 4 s of think time
and responses of about 20 ms, N = 60 × 4.02 ≈ **241 users**. That is the one this lesson can
check, with `users.py` from two sections back.

## Checking the show page against a measurement

This is the last run of that section, 240 users thinking four seconds each, ramped up over ten
seconds and measured for twenty:

```
ana@nft:~/loadtest$ python3 users.py http://127.0.0.1:8000/shows/990 240 4 10 20
240 users, think 4.0 s, ramp 10.0 s, measured for 20.0 s
requests 1197, errors 0
throughput X           59.9 requests/s
response time R        18.2 ms (mean)
in flight, counted      0.9 requests at a time
X × R                   1.1 requests at a time
X × (R + think)       240.5 users
```

**The model said 60 requests a second, and the box office received 59.9**, at a mean response
time of 18.2 ms. The arithmetic was right, and so was the assumption inside it that the server
keeps up. At this rate it did: 0.9 requests in flight on average. Lesson 2's stress staircase
broke the same page somewhere around 80 requests a second, so the sale's 60 is under it, with a
margin that one more assumption could eat: five people a seat instead of four is 75 a second.

## What the number does not say

The minute's average hides its first seconds. People who were waiting for 10:00 press the button at
10:00:00, so the first ten seconds are likely to carry more than a sixth of the arrivals, and the load
test for the sale is lesson 2's spike, starting from this number rather than from a guess.

And the bookings run out. Twenty a second for 300 seats sells the show in fifteen seconds, if each
booking succeeds at the first try. After that every `POST /bookings` is a quick refusal with a
`409`, and the people still arriving are being told the show is sold out. **That is load too**, and
the requirement should say how quickly they are told. How many bookings a second the box office can
take at all is a question lesson 9 measures.
