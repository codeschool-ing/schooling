---
title: Adding processors
version: 1
---

A scalability test needs a second configuration to compare against, and a VM with four processors
can provide one without building anything. **`taskset` starts a program allowed to run on only the
processors you name**, numbered from 0. So the box office can be given one processor, then two,
and the load generator kept on two others where it does not compete with either.

In the server's terminal, stop the box office with `Ctrl+C` and start it on processor 0 alone:

```sh
taskset -c 0 python3 app.py
```

In the second terminal, a staircase from 20 to 80 a second, with the generator on processors 2
and 3:

```
ana@nft:~/loadtest$ taskset -c 2,3 python3 hammer.py http://127.0.0.1:8000/shows/990 20:2 40:2 60:2 80:2
second  sent  done  errors  median ms  max ms
     0    20    20       0         23      87
     1    20    20       0         25      43
     2    40    40       0         20      47
     3    40    39       0         23      66
     4    60    51       0        125     392
     5    60    48       0        341    1075
     6    80    46       0        944    3274
     7    80    47       0       1111    2326
89 answers came back after second 7; the last at 9.6 s
```

Then `Ctrl+C` in the server's terminal again, and the same box office on processors 0 and 1:

```sh
taskset -c 0,1 python3 app.py
```

The same run from the second terminal:

```
ana@nft:~/loadtest$ taskset -c 2,3 python3 hammer.py http://127.0.0.1:8000/shows/990 20:2 40:2 60:2 80:2
second  sent  done  errors  median ms  max ms
     0    20    20       0         25      62
     1    20    20       0         23      37
     2    40    40       0         29     108
     3    40    40       0         22      41
     4    60    59       0         22      39
     5    60    60       0         23      52
     6    80    77       0         41      75
     7    80    79       0         26      97
5 answers came back after second 7; the last at 8.0 s
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l02-scale\" aria-label=\"The same stepped load, 20 to 80 requests a second, against the box office on one processor and then on two. Both carry 20 and 40 a second. On one processor the answers stop at 51, 48, 46 and 47 a second while 60 and then 80 are sent. On two they reach 59, 60, 77 and 79, close to everything sent.\"><path d=\"M90.0 230.0 L550.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M90.0 30.0 L90.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M86.0 230.0 L90.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M86.0 190.0 L90.0 190.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><path d=\"M90.0 190.0 L550.0 190.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 150.0 L90.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><path d=\"M90.0 150.0 L550.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 110.0 L90.0 110.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">60</text><path d=\"M90.0 110.0 L550.0 110.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 70.0 L90.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">80</text><path d=\"M90.0 70.0 L550.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 30.0 L90.0 30.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><path d=\"M90.0 30.0 L550.0 30.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"118.8\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"176.2\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"233.8\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"291.2\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"348.8\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"406.2\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"463.8\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"521.2\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"320.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">second of the run</text><text x=\"56.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">per second</text><path d=\"M90.0 190.0 L147.5 190.0 L147.5 190.0 L205.0 190.0 L205.0 150.0 L262.5 150.0 L262.5 150.0 L320.0 150.0 L320.0 110.0 L377.5 110.0 L377.5 110.0 L435.0 110.0 L435.0 70.0 L492.5 70.0 L492.5 70.0 L550.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M118.8 190.0 L176.2 190.0 L233.8 150.0 L291.2 150.0 L348.8 112.0 L406.2 110.0 L463.8 76.0 L521.2 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"118.8\" cy=\"190.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"176.2\" cy=\"190.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"233.8\" cy=\"150.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"291.2\" cy=\"150.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"348.8\" cy=\"112.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"406.2\" cy=\"110.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"463.8\" cy=\"76.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"521.2\" cy=\"72.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><path d=\"M118.8 190.0 L176.2 190.0 L233.8 150.0 L291.2 152.0 L348.8 128.0 L406.2 134.0 L463.8 138.0 L521.2 136.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"118.8\" cy=\"190.0\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"176.2\" cy=\"190.0\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"233.8\" cy=\"150.0\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"291.2\" cy=\"152.0\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"348.8\" cy=\"128.0\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"406.2\" cy=\"134.0\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"463.8\" cy=\"138.0\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"521.2\" cy=\"136.0\" r=\"3\" fill=\"var(--amber)\"></circle><path d=\"M570.0 60.0 L592.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"598.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sent</text><path d=\"M570.0 84.0 L592.0 84.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"598.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">done, 2 processors</text><path d=\"M570.0 108.0 L592.0 108.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"598.0\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">done, 1 processor</text></svg>", "caption": "Throughput against the same load, with one processor and with two. Where the line on one processor goes flat is that configuration's capacity."}
```

On one processor the box office keeps up with 20 and 40 a second, then flattens: 51 and 48 answers
a second while 60 are sent, 46 and 47 while 80 are, with the median climbing to 1111 ms. **Its
capacity on one processor is somewhere near 50 requests a second.** On two it carries all of it, 79
answers in the last second of 80 sent, and the median never passes 41 ms. This run did not find
the two-processor capacity, because it stopped at 80; a scalability test would keep climbing until
it did, and compare the two capacities.

That ratio is the result. If two processors carry twice what one did, the operation scales with
processors, and for `GET /shows/{id}` the start of the evidence is here: the work is a database
query, and SQLite can run queries from several threads on several processors at once.

Not every operation in the box office would pass the same test. A booking holds `booking_lock`
for the whole of the payment, so two bookings never run at the same time whatever the machine
has, and adding processors to it adds nothing. **A system scales only as far as the part of it
that cannot be shared**, and lesson 9 measures exactly that part. Go back to the plain
`python3 app.py` when you are done here; the next lessons expect all four processors.
