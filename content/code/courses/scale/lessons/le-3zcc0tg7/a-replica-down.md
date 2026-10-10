---
title: A replica down
version: 1
---

A read, then the replica stopped, then the same read:

```
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "615b3114daa0", "source": "replica"}
ana@lab:~/tickets$ docker compose stop replica
 Container tickets-replica-1 Stopping 
 Container tickets-replica-1 Stopped 
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "615b3114daa0", "source": "primary"}
ana@lab:~/tickets$ docker compose logs app --no-log-prefix | grep 'fell back' | tail -1
{"time": "2026-10-10T19:39:46.379+00:00", "level": "warning", "message": "read fell back", "host": "615b3114daa0", "source": "replica", "error": "terminating connection due to administrator command", "trace_id": "d8058267e23a74fdc1a2f5aef50d4b1d"}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"A read tries four things in order, left to right: the replica, then the primary, then the last answer this copy saw, which carries its age, and finally a 503 that asks the caller to come back in five seconds. Each arrow to the right is labelled 'fails'.\"><rect x=\"20\" y=\"50\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">replica</text><text x=\"90\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as usual</text><path d=\"M160 78 L196 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M196 78 L189.7 81.0 L189.7 75.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"178\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fails</text><rect x=\"198\" y=\"50\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"268\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">primary</text><text x=\"268\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">same data, busier</text><path d=\"M338 78 L374 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M374 78 L367.7 81.0 L367.7 75.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"356\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fails</text><rect x=\"376\" y=\"50\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">memory</text><text x=\"446\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">with its age</text><path d=\"M516 78 L552 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M552 78 L545.7 81.0 L545.7 75.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"534\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">fails</text><rect x=\"554\" y=\"50\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"624\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">503</text><text x=\"624\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">come back in 5 s</text><text x=\"360\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reads degrade; a sale needs the primary and pauses without it</text></svg>", "caption": "Where a read comes from, in order."}
```

The first answer came from the replica, the second from **the primary**, and the buyer could not
tell the difference except by the `source` field. The log says what happened: the connection the
box office held to the replica was ended when the replica shut down, so `read_event` dropped it and
moved on to the next place in its list, in the same request.

This is the easy case, and also the one to watch. The primary now carries every read as well as
every sale. In the lab that is a few hundred reads a second more on a database that can take them;
in production, a primary sized for its writes alone may not survive its replicas' traffic arriving
all at once. Falling back to something that cannot hold the load is not degradation, it is moving
the outage, and the capacity sections of this lesson are how to know in advance which it will be.
