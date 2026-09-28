---
title: The floor under every round trip
version: 1
---

The usual picture of a slow connection is a narrow one: not enough bandwidth, and a bigger link would
fix it. Bandwidth is how much arrives per second once data is flowing. **Latency is how long one
thing takes to get there and back**, and it has a floor that no purchase moves, because the signal
has to cover the distance.

In an optical fibre the signal is light, and light in glass is slower than light in a vacuum: about
two thirds of it, near 200,000 km a second. That is **200 km per millisecond**, and it is the number
this whole section rests on. A request to a server 2,000 km away cannot get an answer back in less
than 20 ms, because the light needs 10 ms each way.

The program below works out that floor from São Paulo to three places. It is arithmetic on
coordinates written into it; it sends no packet and measures nothing:

```schooling-example
{"language": "python", "file": "floor.py", "parts": [{"code": "from math import radians, sin, cos, asin, sqrt"}, {"code": "EARTH_KM = 6371          # mean radius of the Earth\nFIBRE_KM_PER_MS = 200    # light in glass: about two thirds of c", "note": "**Two constants carry the whole argument.** The Earth's mean radius turns degrees into kilometres. Light in a vacuum covers about 300,000 km a second; in the glass of an optical fibre it slows to about two thirds of that, near 200,000 km a second, which is 200 km in every millisecond."}, {"code": "PLACES = {               # latitude, longitude in degrees\n    'Sao Paulo': (-23.55, -46.63),\n    'Fortaleza': (-3.72, -38.54),\n    'Ashburn':   (39.04, -77.49),\n    'Frankfurt': (50.11, 8.68),\n}", "note": "The four places, written into the program so you can check them on any map. Ashburn stands in for `us-east-1`, which the CLI's list calls US East (N. Virginia), and Frankfurt for `eu-central-1`. The points are cities, not datacentres: providers do not publish where their buildings are."}, {"code": "def great_circle_km(a, b):\n    lat1, lon1, lat2, lon2 = map(radians, (*a, *b))\n    h = sin((lat2 - lat1) / 2) ** 2 + cos(lat1) * cos(lat2) * sin((lon2 - lon1) / 2) ** 2\n    return 2 * EARTH_KM * asin(sqrt(h))", "note": "The haversine formula: the length of the shortest path over the surface of a sphere between two points. It is the straight line a cable would follow if the sea floor, the coast and the countries in between allowed it."}, {"code": "for dest in ('Fortaleza', 'Ashburn', 'Frankfurt'):\n    km = great_circle_km(PLACES['Sao Paulo'], PLACES[dest])\n    rtt_ms = 2 * km / FIBRE_KM_PER_MS\n    print(f'Sao Paulo -> {dest:<10} {km:6.0f} km   round trip >= {rtt_ms:5.1f} ms')", "note": "**The round trip is the distance twice**, out and back, divided by the speed in fibre. That is the least time any request can take to reach the other end and bring an answer, before a single router, queue or server has done anything."}], "output": "Sao Paulo -> Fortaleza    2370 km   round trip >=  23.7 ms\nSao Paulo -> Ashburn      7664 km   round trip >=  76.6 ms\nSao Paulo -> Frankfurt    9829 km   round trip >=  98.3 ms"}
```

**The floor from São Paulo to Northern Virginia is 76.6 ms.** To Fortaleza, which is still in Brazil,
it is 23.7 ms, and to Frankfurt it is 98.3 ms. Divide two of them and the shape appears: 76.6 / 23.7
is 3.2, so every round trip to Virginia costs at least three times as much time as one to Fortaleza.

## Why real numbers are higher

**Every real round trip is longer than this floor**, for reasons that only add:

- Cables do not follow great circles. They run along coasts, under particular stretches of sea,
  and into the cities where they land. Many of the submarine cables that leave Brazil land near
  Fortaleza, so traffic from São Paulo to North America on those cables travels up the coast first,
  which is a longer path than the straight line the program measured.
- Each router on the way reads the packet and queues it behind others before sending it on. A
  single router adds little; a path through a dozen of them, some of them busy, adds up.
- The server itself takes time to answer, and so does the operating system at each end.

So the number the program printed is a bound, and a real measurement would come out above it. How far
above is something you find out by measuring your own path with `ping` and `traceroute`, the tools of
the `networks` course. This course does not measure it for you, because a number measured from one
machine on one day would be presented as a fact about everyone's path. **Nothing in this section was
measured on a network.**

## What the floor is good for

A bound you cannot beat is still the most useful number here, for two reasons.

**It tells you which designs cannot work.** If a user in São Paulo must get an answer in under 50 ms,
a server in Virginia is ruled out before any benchmark is run: 76.6 ms is already over budget with a
perfect network and an instant server. No amount of tuning or bandwidth changes that; only moving the
server does.

**It scales with the number of trips.** One round trip of 76.6 ms is hard to notice. The next section
takes a page that waits for twenty of them, one after another, and the floor turns into more than a
second of waiting that the user sees on every load.

A rule of thumb follows directly from the constant, and it is worth keeping: **one millisecond of round
trip for every 100 km of straight-line distance.** São Paulo to Fortaleza is 2,370 km, so at least
23.7 ms. The rule is the same division the program does, done in your head, and it is why the choice
of region in the next sections is a question about geography before it is a question about anything
else.
