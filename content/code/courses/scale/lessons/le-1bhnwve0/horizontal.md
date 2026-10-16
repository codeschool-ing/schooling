---
title: Horizontal scaling, more copies
version: 1
---

**Horizontal scaling runs more copies of the program and divides the work between them.** It needs
something in front to do the dividing, and it needs the copies to be interchangeable: any of them
must be able to answer any request.

The box office already has the first piece. `lb` is an nginx that sends each request to one of the
addresses Docker gives the name `app`, and so far there has been one address. Compose starts more
copies of a service with `--scale`:

```
ana@lab:~/tickets$ docker compose up -d --scale app=3
 Container tickets-app-1 Running 
 Container tickets-lb-1 Running 
 Container tickets-db-1 Running 
 Container tickets-app-3 Creating 
 Container tickets-app-2 Creating 
 Container tickets-app-2 Created 
 Container tickets-app-3 Created 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-app-3 Starting 
 Container tickets-app-3 Started 
 Container tickets-app-2 Starting 
 Container tickets-app-2 Started 
ana@lab:~/tickets$ docker compose restart lb
 Container tickets-lb-1 Restarting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ for i in 1 2 3 4 5 6; do curl -s localhost:8080/healthz; echo; done
{"host": "1734815cb5a4"}
{"host": "d79c69160da7"}
{"host": "8159e9da198f"}
{"host": "1734815cb5a4"}
{"host": "d79c69160da7"}
{"host": "8159e9da198f"}
```

Two new containers, `tickets-app-2` and `tickets-app-3`. nginx looks up the name `app` when it
starts and not afterwards, so it is restarted to see the three addresses. Then six requests to
`/healthz`, and each answer names the container that gave it: three different hosts, in turn.
nginx's default is **round robin**, each request to the next copy in the list.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The lab's layout. load.py, on the lab itself, sends requests to port 8080, where the lb container, nginx, passes each one in turn to one of three copies of app, tickets-app-1, 2 and 3. All three copies talk to one database container, db, which holds the shows and the tickets.\"><rect x=\"20\" y=\"100\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">load.py</text><text x=\"75\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on the lab</text><path d=\"M130 125 L200 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M200 125 L193.7 128.0 L193.7 122.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"165\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">:8080</text><rect x=\"200\" y=\"100\" width=\"100\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"250\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">lb</text><text x=\"250\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">nginx</text><path d=\"M300 125 L380 55\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M380 55 L377.3 61.4 L373.3 56.9 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"380\" y=\"30\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">tickets-app-1</text><text x=\"455\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">cpus: 1</text><path d=\"M530 55 L600 125\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M600 125 L593.4 122.7 L597.7 118.4 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><path d=\"M300 125 L380 125\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M380 125 L373.7 128.0 L373.7 122.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"380\" y=\"100\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">tickets-app-2</text><text x=\"455\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">cpus: 1</text><path d=\"M530 125 L600 125\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M600 125 L593.7 128.0 L593.7 122.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><path d=\"M300 125 L380 195\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M380 195 L373.3 193.1 L377.3 188.6 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"380\" y=\"170\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">tickets-app-3</text><text x=\"455\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">cpus: 1</text><path d=\"M530 195 L600 125\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M600 125 L597.7 131.6 L593.4 127.3 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"600\" y=\"95\" width=\"100\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"650\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">db</text><text x=\"650\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">PostgreSQL</text><text x=\"455\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">round robin: each request to the next copy</text></svg>", "caption": "Three copies of the box office behind one load balancer, and one database behind all three."}
```

Now the same test as in the last two sections, with one, two and three copies, each capped at one
processor:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1458 in 10.1 s = 144.8 per second
latency   p50 102.2 ms  p95 194.9 ms  p99 220.3 ms  max 341.4 ms
status    201: 1458
```

```
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  3056 in 10.0 s = 304.2 per second
latency   p50 41.9 ms  p95 122.7 ms  p99 174.2 ms  max 243.8 ms
status    201: 3056
```

```
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  4706 in 10.0 s = 469.9 per second
latency   p50 27.9 ms  p95 78.1 ms  p99 117.6 ms  max 326.3 ms
status    201: 4706
```

145, 304, 470: **every copy adds about 150 sales a second**, which is what one copy did alone.
That is the shape horizontal scaling promises, and on this machine it delivers it up to three
copies, which use three of the four processors. A fourth copy on the same four processors would
only fight the others for them; on a real system the fourth copy goes on another machine, and that
is where the ceiling of vertical scaling stops applying.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Two groups of bars, tickets sold per second with 16 workers over a hundred shows. Vertical: 143 with one processor, 314 with two, 433 with four. Horizontal: 145 with one copy, 304 with two copies, 470 with three copies, each copy capped at one processor. A dashed line at 140 marks what one show alone sold, 138 with three copies and 137 with one.\"><path d=\"M40 240 L690 240\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"200\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">vertical: one copy, more processors</text><text x=\"520\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">horizontal: more copies, one processor each</text><rect x=\"90\" y=\"185.546\" width=\"56\" height=\"54.45400000000001\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"118\" y=\"175.546\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">143</text><text x=\"118\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 cpu</text><rect x=\"170\" y=\"120.64199999999998\" width=\"56\" height=\"119.35800000000002\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"198\" y=\"110.64199999999998\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">314</text><text x=\"198\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 cpus</text><rect x=\"250\" y=\"75.38400000000001\" width=\"56\" height=\"164.61599999999999\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"278\" y=\"65.38400000000001\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">433</text><text x=\"278\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 cpus</text><rect x=\"410\" y=\"184.976\" width=\"56\" height=\"55.024\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"438\" y=\"174.976\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">145</text><text x=\"438\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 copy</text><rect x=\"490\" y=\"124.40400000000001\" width=\"56\" height=\"115.59599999999999\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"518\" y=\"114.40400000000001\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">304</text><text x=\"518\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 copies</text><rect x=\"570\" y=\"61.43800000000002\" width=\"56\" height=\"178.56199999999998\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"598\" y=\"51.43800000000002\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">470</text><text x=\"598\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 copies</text><path d=\"M42 187.56 L88 187.56\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M148 187.56 L168 187.56\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M228 187.56 L248 187.56\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M308 187.56 L408 187.56\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M468 187.56 L488 187.56\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M548 187.56 L568 187.56\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M628 187.56 L688 187.56\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M200 292 L240 292\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"248\" y=\"292\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">one show alone: 137 to 138 a second, with one copy or three</text></svg>", "caption": "Both directions add capacity on this machine until its four processors run out. Neither moves the dashed line, which is one show's row."}
```

## What makes the copies interchangeable

The box office scaled this cleanly for one reason: **it keeps nothing between requests**. Every
fact it needs, how many seats a show has left and which ones were sold, lives in the database. A
request can go to any copy because no copy knows anything the others do not. That property is
called being **stateless**, and it is the price of admission for horizontal scaling.

It is easy to lose by accident. Three things that look harmless and break it:

- **A session kept in memory.** A user logs in, the copy that answered remembers them, and the
  next request goes to another copy that does not. The workarounds are to send each user to the
  same copy every time, called **sticky sessions**, which makes one copy's failure log out
  everybody it held; or to keep sessions where every copy can read them, in the database or a
  cache like Redis.
- **A counter in a variable.** "Tickets sold today" counted in the program counts a third of the
  sales on each of three copies.
- **A file written to the local disk.** An uploaded picture saved by one copy is a 404 from the
  other two.

## What it costs

Horizontal scaling moved the limit from the size of a machine to the number of machines, and it
paid for that with new parts. **The load balancer is a new component**, and with one of it, it is
a new single point of failure; real systems run two. **The copies have to be deployed together**,
with the same configuration. And the moment the copies stop being independent, because they all
want the same thing, the scaling stops. The next section sells every ticket for one show.
