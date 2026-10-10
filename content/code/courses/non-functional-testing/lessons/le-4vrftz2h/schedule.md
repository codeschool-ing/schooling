---
title: On a schedule, and catching a failure
version: 1
---

A probe run once is a test. **Run on a schedule, it becomes a monitor**, and the schedule decides
how long an outage can last before anybody knows. The simplest scheduler is a shell loop. In the
second terminal, with `observed.py` running again in the first:

```
ana@nft:~/monitor$ for i in 1 2 3; do python3 probe.py; sleep 5; done
16:33:06 PASS list=200/24ms show=200/19ms book=201/57ms
16:33:11 PASS list=200/19ms show=200/12ms book=201/55ms
16:33:16 PASS list=200/22ms show=200/12ms book=201/56ms
```

Three runs, five seconds apart, three passes. A real loop has no `for` and sleeps for longer:

```sh
while true; do python3 probe.py >> probe.log; sleep 60; done
```

**That loop dies with the terminal it runs in**, which is fine for an afternoon and useless for a
monitor. Two programs that come with Ubuntu do better.

`watch -n 60 python3 probe.py` reruns the command every 60 seconds and redraws the screen with its
latest output. It is a way to look at a probe while you work on something, not a monitor: it keeps
no history, and it also dies with its terminal. It is not captured here, because it draws a full
screen rather than printing lines.

`cron` runs commands on a schedule with no terminal at all, and keeps doing it across reboots.
`crontab -e` opens your own schedule in an editor; one line runs the probe every minute and keeps
every result:

```sh
* * * * * cd ~/monitor && python3 probe.py >> probe.log 2>&1
```

The five fields are minute, hour, day of the month, month and day of the week, and `*` means every
one, so this line means every minute of every day. `crontab -l` lists what is installed. **The
machine these transcripts were recorded on has no `cron`**, so that line was not run here; on an
Ubuntu VM it is installed and running already. One minute is cron's finest grain, and it is the
common interval for a production check: often enough to catch an outage within minutes, rarely
enough that the probe is a small share of the traffic.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l23-interval\" aria-label=\"A time line of eight minutes with a check at every minute, drawn as a dot. The first three checks pass. An outage begins just after the third check, shown as a shaded band running to the end. The fourth check, almost a minute later, is the first to fail; the fifth fails too, and only then, with two failures in a row, is somebody told. Between the start of the outage and the person being told, nearly two intervals pass.\"><defs><marker id=\"l23-interval-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l23-interval-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"238.0\" y=\"70.0\" width=\"412.0\" height=\"100.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"244.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">outage begins</text><path d=\"M50.0 120.0 L650.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"70.0\" cy=\"120.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"70.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0:00</text><text x=\"70.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pass</text><circle cx=\"150.0\" cy=\"120.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"150.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1:00</text><text x=\"150.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pass</text><circle cx=\"230.0\" cy=\"120.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"230.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2:00</text><text x=\"230.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pass</text><circle cx=\"310.0\" cy=\"120.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"310.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3:00</text><text x=\"310.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fail</text><circle cx=\"390.0\" cy=\"120.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"390.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4:00</text><text x=\"390.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fail</text><circle cx=\"470.0\" cy=\"120.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"470.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5:00</text><text x=\"470.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fail</text><circle cx=\"550.0\" cy=\"120.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"550.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6:00</text><text x=\"550.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fail</text><circle cx=\"630.0\" cy=\"120.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"630.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7:00</text><text x=\"630.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fail</text><path d=\"M238.0 198.0 L306.0 198.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-interval-nf-ah-paper-dim)\"></path><text x=\"274.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">up to one interval</text><path d=\"M238.0 228.0 L386.0 228.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-interval-nf-ah-amber)\"></path><text x=\"398.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">two in a row: somebody is told</text></svg>", "caption": "Checking every minute, an outage is first seen up to a minute late, and confirmed a minute after that."}
```

The figure is the arithmetic of a schedule. A failure that begins just after a check is only seen
at the next one, so **the interval is the worst-case delay before the first failed check**. And
nobody pages a person on one failed check, for a reason the next section and lesson 24 both come
back to: a single failure can be the network between the probe and the server rather than the
server. Requiring two failures in a row doubles the delay and removes most of the false alarms.

## A failure that is not an outage

Stopping the server is the easy failure. The harder one is the box office that still answers,
correctly, and too slowly. `slow.py` is `observed.py` with the payment provider having a bad
afternoon: 900 ms a call instead of 40. Create it in `~/boxoffice`; like `observed.py`, it changes
nothing in `app.py` and only replaces one number after importing it:

```python
# boxoffice/slow.py
# observed.py with a payment provider having a bad afternoon: 900 ms a call.
import app, observed

app.PAYMENT_SECONDS = 0.9
observed.serve()
```

Stop `observed.py`, start `python3 slow.py > slow.log` in its place, and run the probe:

```
ana@nft:~/monitor$ python3 probe.py; echo "exit $?"
16:33:23 FAIL list=200/23ms show=200/15ms book=201/916ms -- book: 916 ms is over 500 ms (request 9e7fba65765e4940)
exit 1
```

The listing and the show are as fast as before. **The booking answered 201 and booked the seat,
and the probe still failed it**, because it took 916 ms against a limit of 500. Every status code the server
returned was a success, so an alert on 5xx would say nothing; lesson 22's metrics would show it
only as a duration percentile somebody was looking at. Searching the server's log for anything
over 500 ms finds the same request, by the id the probe printed:

```
ana@nft:~/boxoffice$ jq -c 'select(.ms > 500)' slow.log
{"ts":"2026-10-10T19:33:23.401+00:00","level":"info","request_id":"9e7fba65765e4940","method":"POST","route":"/bookings","path":"/bookings","status":201,"ms":915.3}
```

The server's own time for that booking was 915.3 ms, and 900 of it was the payment.
A probe and a log that share an id make that a one-line search. Stop `slow.py` and go back to
`python3 observed.py > requests.log` when you are done.
