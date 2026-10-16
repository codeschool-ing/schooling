---
title: Jitter
version: 1
---

Backoff alone has a flaw that only shows with many callers. Suppose payments stops for a moment and
a thousand sales fail together. With plain exponential backoff, every one of them waits exactly
200 ms and retries, all at the same instant; fails again, waits exactly 400 ms, and retries
together again. The callers have spread nothing: they have scheduled a series of synchronised
spikes, each one the size of the original failure, and a service trying to recover meets a
thousand requests in the same millisecond, over and over.

**Jitter** makes each wait random. With **full jitter**, the box office's choice, the wait is a
uniform random number between zero and the exponential ceiling, so the retries spread over the whole
interval instead of landing at its end. This program simulates the thousand callers both ways and
counts where their retries land. Save it as `storm.py`:

```python
# storm.py
"""A thousand clients see the same failure at the same moment, and each retries
four times with exponential backoff. Where do the retries land, with and
without jitter? Every attempt fails, as it would while a service is down."""
import random

CLIENTS, BASE, CAP = 1000, 0.1, 2.0
random.seed(1)


def retries(jitter):
    times = []
    for _ in range(CLIENTS):
        t = 0.0
        for attempt in range(1, 5):
            ceiling = min(CAP, BASE * 2 ** attempt)
            t += random.uniform(0, ceiling) if jitter else ceiling
            times.append(t)
    return times


for jitter in (False, True):
    times = retries(jitter)
    fine = [0] * 320
    for t in times:
        fine[min(int(t * 100), 319)] += 1
    print("full jitter" if jitter else "no jitter",
          f"- at most {max(fine)} retries in any 10 ms")
    for start in range(0, 320, 20):
        n = sum(fine[start:start + 20])
        print(f"  {start / 100:3.1f} s {n:5}  " + "#" * round(n / 25))
```

It needs nothing but Python:

```
ana@lab:~/tickets$ python3 storm.py
no jitter - at most 1000 retries in any 10 ms
  0.0 s     0  
  0.2 s  1000  ########################################
  0.4 s     0  
  0.6 s  1000  ########################################
  0.8 s     0  
  1.0 s     0  
  1.2 s     0  
  1.4 s  1000  ########################################
  1.6 s     0  
  1.8 s     0  
  2.0 s     0  
  2.2 s     0  
  2.4 s     0  
  2.6 s     0  
  2.8 s     0  
  3.0 s  1000  ########################################
full jitter - at most 85 retries in any 10 ms
  0.0 s  1267  ###################################################
  0.2 s   639  ##########################
  0.4 s   511  ####################
  0.6 s   291  ############
  0.8 s   321  #############
  1.0 s   266  ###########
  1.2 s   168  #######
  1.4 s   109  ####
  1.6 s   105  ####
  1.8 s   127  #####
  2.0 s    81  ###
  2.2 s    69  ###
  2.4 s    35  #
  2.6 s    11  
  2.8 s     0  
  3.0 s     0  
```

**Without jitter, all thousand retries of each round land within the same 10 ms**, four times. With
full jitter, the most that land in any 10 ms is 85, and the rounds blur into one falling slope: the
retries arrive at the rate they were going to arrive anyway, just not all at once.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two timelines of retries over three seconds. Above, without jitter: four tall spikes at 0.2, 0.6, 1.4 and 3.0 seconds, each holding all thousand retries of a round. Below, with full jitter: the same four thousand retries spread into a slope that is highest at the start and falls away, with no spike.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">no jitter</text><path d=\"M120 90 L680 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"152.0\" y=\"20\" width=\"6\" height=\"70\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"222.0\" y=\"20\" width=\"6\" height=\"70\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"362.0\" y=\"20\" width=\"6\" height=\"70\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"642.0\" y=\"20\" width=\"6\" height=\"70\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">full jitter</text><path d=\"M120 190 L680 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"122.0\" y=\"165.0\" width=\"31.0\" height=\"25.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"157.0\" y=\"177.39147592738752\" width=\"31.0\" height=\"12.60852407261247\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"192.0\" y=\"179.91712707182322\" width=\"31.0\" height=\"10.082872928176796\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"227.0\" y=\"184.25808997632203\" width=\"31.0\" height=\"5.741910023677979\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"262.0\" y=\"183.6661404893449\" width=\"31.0\" height=\"6.33385951065509\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"297.0\" y=\"184.75138121546962\" width=\"31.0\" height=\"5.248618784530387\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"332.0\" y=\"186.68508287292818\" width=\"31.0\" height=\"3.314917127071823\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"367.0\" y=\"187.8492501973165\" width=\"31.0\" height=\"2.1507498026835044\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"402.0\" y=\"187.9281767955801\" width=\"31.0\" height=\"2.071823204419889\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"437.0\" y=\"187.49408050513023\" width=\"31.0\" height=\"2.505919494869771\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"472.0\" y=\"188.4017363851618\" width=\"31.0\" height=\"1.5982636148382006\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"507.0\" y=\"188.63851617995263\" width=\"31.0\" height=\"1.361483820047356\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"542.0\" y=\"189.30939226519337\" width=\"31.0\" height=\"0.6906077348066298\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"577.0\" y=\"189.78295185477506\" width=\"31.0\" height=\"0.2170481452249408\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><text x=\"295.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1 s</text><text x=\"470.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2 s</text><text x=\"645.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3 s</text><text x=\"680\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">1000 in 10 ms</text><text x=\"680\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">85 in 10 ms at most</text></svg>", "caption": "The same retries, synchronised and spread."}
```

There are other shapes. *Equal jitter* waits half the ceiling plus a random half, so no wait is very
short; *decorrelated jitter* bases each wait on the previous one rather than the attempt number.
They differ in the details and agree on the point: **any randomness breaks the synchrony**, and the
synchrony is what turns a blip into an outage.

The same mistake appears far from retries: cron jobs that every machine starts at midnight, caches
that all expire at the hour, clients that all reconnect when a server restarts. Wherever many
callers react to one event, a little randomness in when they react is cheap protection.
