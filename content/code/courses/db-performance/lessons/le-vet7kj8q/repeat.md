---
title: Run it again, and again
version: 1
---

One run of a benchmark is an anecdote. It produced a number, and the next run, with nothing changed,
will produce another. **The difference between runs of the same thing is the noise, and it sets the
size of the smallest change you can believe.** Without it, a result of "8% faster" cannot be told
apart from "8% luckier".

## Three runs, from the same starting point

`place-order.sql` adds orders every time it runs, so a series of runs slowly changes the database it
is measuring. Start the series from a known state, `~/reset-market.sh` from lesson 2, and then run
the same command three times:

```
ana@vm:~$ ~/reset-market.sh
CREATE EXTENSION
Time: 8.774 ms
CREATE INDEX
Time: 720.199 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average)'
latency average = 6.917 ms
tps = 1156.560488 (without initial connection time)
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average)'
latency average = 5.579 ms
tps = 1433.898020 (without initial connection time)
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency average)'
latency average = 6.100 ms
tps = 1311.392039 (without initial connection time)
```

**1157, 1434 and 1311 transactions a second**; average latencies of 6.9, 5.6 and 6.1 milliseconds.
Same database, same scripts, same machine, a minute and a half apart. Put next to the pieces of runs
this lesson has already printed, the picture is consistent:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A dot plot of transactions per second, from 800 to 1500. Top row, the three ten-second intervals of one run: 1263, 1157 and 1289. Middle row, the six five-second intervals of the cold run: 1134, 1292, 975, 1086, 1103 and 864. Bottom row, three thirty-second runs after a fresh copy of market: 1157 for the first, then 1434 and 1311. The dots of every row spread over a hundred transactions a second or more.\"><text x=\"14\" y=\"40\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one run, 10-second intervals</text><path d=\"M230 40 L700 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"541.1400000000001\" cy=\"40\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"469.4985714285715\" cy=\"40\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"558.2614285714286\" cy=\"40\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"14\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cold run, 5-second intervals</text><path d=\"M230 92 L700 92\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"453.9885714285714\" cy=\"92\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"560.4771428571429\" cy=\"92\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"347.7685714285714\" cy=\"92\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"421.8942857142857\" cy=\"92\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"433.71142857142866\" cy=\"92\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"273.24\" cy=\"92\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"14\" y=\"144\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">three runs after a fresh copy</text><path d=\"M230 144 L700 144\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><circle cx=\"469.43142857142857\" cy=\"144\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"655.6185714285715\" cy=\"144\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"573.3685714285714\" cy=\"144\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"469.43142857142857\" y=\"160\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--amber)\">first run, discarded</text><path d=\"M230 186 L700 186\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M230.0 186 L230.0 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"230.0\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">800</text><path d=\"M297.1428571428571 186 L297.1428571428571 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"297.1428571428571\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">900</text><path d=\"M364.2857142857143 186 L364.2857142857143 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"364.2857142857143\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1000</text><path d=\"M431.42857142857144 186 L431.42857142857144 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"431.42857142857144\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1100</text><path d=\"M498.57142857142856 186 L498.57142857142856 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"498.57142857142856\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1200</text><path d=\"M565.7142857142858 186 L565.7142857142858 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"565.7142857142858\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1300</text><path d=\"M632.8571428571429 186 L632.8571428571429 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"632.8571428571429\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1400</text><path d=\"M700.0 186 L700.0 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"700.0\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1500</text><text x=\"700\" y=\"218\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"end\" fill=\"var(--paper-dim)\">transactions a second</text></svg>", "caption": "The same workload on the same machine, measured in pieces and in whole runs. No row is a single number."}
```

Two things are visible in the bottom row.

**The first run is the lowest.** It ran against a database just copied from `market_base`, whose
pages had not yet been asked for by anybody, and it paid for warming them up. That is the cold run of
the previous section in another form, and it is why the first run of a series is run and then thrown
away, not averaged in.

**The two that remain differ by 9%**, 1311 against 1434. That is this machine's noise for a
thirty-second run of this workload, measured rather than assumed, and it means a change that moves
the number by 5% has not been shown to do anything at all with runs this long.

## The rules for a series

- **Start from the same state.** Restore the data if the workload writes, restart or not as you
  decided in the previous section, and change nothing else between runs: the same command, the same
  clients, nothing else running on the machine.
- **Discard a warm-up run**, then keep **at least three**. If their spread is wide, run more, or run
  longer: a longer run averages more intervals and its total moves less.
- **Report the median and the range**, never one run and never only the best. "1311 a second,
  between 1311 and 1434 over two runs after a warm-up" is a measurement; "1434" is a choice.
- **Keep the commands with the numbers.** A result is reproducible only if somebody can run exactly
  what you ran, which is why every number in this course sits under the command that produced it.

Lesson 24 takes a series like this one before a change and another after it, and asks the question
this lesson stops short of: is the difference bigger than the noise, and is it worth what the change
costs? Everything it does rests on series measured the way this section describes.

## Back to the known rows

This lesson's runs added thousands of orders to `market` and built a database called `bench` that is
already dropped. Put `market` back as lesson 3 starts, by running `~/reset-market.sh` once more.
