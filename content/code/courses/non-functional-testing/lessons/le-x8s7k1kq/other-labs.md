---
title: Throttling, the spread between runs, and the other labs
version: 1
---

The slow page took 13.1 s to paint its picture, on a VM that fetched it from `127.0.0.1` in a few
milliseconds. **Lighthouse did not report what happened on this machine; it reported what would
have happened on a slow phone on a mobile network.** That translation is called throttling, and
it is the first thing to know about any Lighthouse number.

## Simulated throttling

The settings are in every report:

```
ana@nft:~/boxoffice$ jq -c '.configSettings | [.formFactor, .throttlingMethod, .throttling]' slow.json
["mobile","simulate",{"rttMs":150,"throughputKbps":1638.4,"requestLatencyMs":562.5,"downloadThroughputKbps":1474.5600000000002,"uploadThroughputKbps":675,"cpuSlowdownMultiplier":4}]
```

A mobile form factor, and a network of 150 ms round trip at about 1.6 megabits a second, with a
processor four times slower than the one running the test: a mid-range phone on a poor 4G
connection. `simulate` is the default method, and it does not slow anything down while the page
loads. **Lighthouse loads the page at full speed, records every request and every task, and then
computes how long the same load would have taken under those settings.** That is why
`long-tasks` printed 2,000 ms for a loop of 500: the recorded task was multiplied by
`cpuSlowdownMultiplier`. And 2,431,680 bytes over 1.6 megabits a second is about twelve seconds
before the picture can be painted, which is most of the 13.1 s.

The other methods are `devtools`, which really slows the browser's network and processor while
the page loads, and `provided`, which applies nothing and reports what this machine did:

```
ana@nft:~/boxoffice$ lighthouse http://127.0.0.1:8000/ --quiet --only-categories=performance --output=json --chrome-flags="--headless=new --no-sandbox" --throttling-method=provided --output-path=raw.json
ana@nft:~/boxoffice$ jq -f metrics.jq raw.json
{
  "score": 0.9,
  "FCP": "2.3 s",
  "LCP": "2.3 s",
  "TBT": "0 ms",
  "CLS": "0.139",
  "Speed Index": "2.3 s"
}
```

**A score of 0.9 for the page that scored 0.37**, because a 2.4 MB picture costs nothing over
loopback. TBT is 0 ms: on the real load the list's loop finished before anything was painted, and
TBT only counts from the first paint. CLS is unchanged, because movement is measured on the real
load whatever the method. FCP and LCP are 2.3 s, which is what this machine took and describes no
visitor. Keep the default unless you are matching a specific device, and when you compare two
runs, compare runs made with the same settings.

## Why the score moves between runs

Run the same command five times, on the same page, on the same machine:

```
ana@nft:~/boxoffice$ for i in 1 2 3 4 5; do lighthouse http://127.0.0.1:8000/ --quiet --only-categories=performance --output=json --chrome-flags="--headless=new --no-sandbox" --output-path=run.json; jq -r '[.categories.performance.score, .audits["largest-contentful-paint"].displayValue, .audits["total-blocking-time"].displayValue, .audits["cumulative-layout-shift"].displayValue] | @tsv' run.json; done
0.37	13.1 s	1,420 ms	0.139
0.39	13.1 s	1,420 ms	0.139
0.37	12.9 s	1,420 ms	0.139
0.37	12.9 s	1,420 ms	0.139
0.37	13.1 s	1,420 ms	0.139
```

Here the spread is small: the score between 0.37 and 0.39 and LCP between 12.9 s and 13.1 s,
while TBT and CLS printed the same value five times. Simulation is part of the reason, since most
of the calculation is network arithmetic that does not change between loads over loopback. The
processor part does change: the tasks Lighthouse multiplies by four are the ones it measured, and
a machine busy with something else measures longer tasks. A page fetched across the internet adds
the variation of the network and of the server, and a real site's spread is wider than this one's.

So one run is one sample. **A number that decides anything, a comparison between two versions or
a pass and a fail, comes from several runs and their median.** Lighthouse's own documentation
recommends five. Lesson 11 builds that into its gate.

## WebPageTest

**WebPageTest** is an online service, now run by Catchpoint, that loads a page on real browsers
and devices in real locations: a phone in São Paulo, a desktop in Frankfurt, over a network shaped
to a profile you pick. It was not run for this course, since it needs a page reachable from the
internet and the box office answers only on your VM. What it adds to Lighthouse is the view
of a load as it happened:

- **the filmstrip**, screenshots taken at short intervals through the load, so you can see the
  page blank, then the heading, then the picture, and point at the frame where the banner pushed everything down;
- **the waterfall**, one bar per request on a common time axis, split into DNS lookup,
  connection, TLS, waiting for the first byte and downloading. A render-blocking script shows up
  as a bar the first paint has to wait for; a heavy picture as one long bar;
- **repeat views and several runs**, the first visit with an empty cache and a second with a
  warm one, and the median run picked out for you.

It answers "what does a visitor in that city, on that device, see", which a lab on your own
machine cannot, and it costs a real page on the internet.

## Chrome's own developer tools

The browser on your own computer has the same engine. With the box office opened to your desktop
(`BOXOFFICE_HOST=0.0.0.0 python3 app.py`, as lesson 1 explains), open the page in Chrome, then the
developer tools with `F12`:

- the **Lighthouse panel** runs the same audits as the command line and draws the HTML report,
  with the same throttling settings to choose from;
- the **Performance panel** records a load or an interaction as a timeline: every task on the main
  thread, with long tasks marked in red, the layout shifts, and the LCP element. It is the one
  place in this lesson where INP can be measured in a lab, because you are there to click, and it
  shows the interactions and how long each took.

**Neither was captured here**, since the VM has no desktop. They are the tools to reach for while
fixing a page; the command line is the one to reach for when the check has to run without you.
Remember to start the box office again with the plain `python3 app.py` afterwards.
