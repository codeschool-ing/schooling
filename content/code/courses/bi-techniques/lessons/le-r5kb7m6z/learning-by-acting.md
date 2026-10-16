---
title: Learning by acting
version: 1
---

An A/B test learns and then acts: it splits visitors evenly until the end, then ships the winner.
Every visitor sent to the worse page during the test is a cost paid for the knowledge. **A
multi-armed bandit**, the simplest form of reinforcement learning, mixes the two: it shifts visitors
towards whichever page is doing better while the test is still running.

```schooling-example
{"language": "python", "file": "bandit.py", "parts": [{"code": "import numpy as np\n\nrng = np.random.default_rng(16)\nrates = {\"old\": 0.042, \"new\": 0.046}\nvisitors = 50400", "note": "Two checkout pages whose true conversion rates the simulation knows and the strategies do not, and the same 50,400 visitors as lesson 10's test."}, {"code": "def run(choose):\n    shown = {\"old\": 0, \"new\": 0}\n    won = {\"old\": 0, \"new\": 0}\n    for n in range(visitors):\n        page = choose(n, shown, won)\n        shown[page] += 1\n        won[page] += rng.random() < rates[page]\n    return shown, sum(won.values())", "note": "One visitor at a time: a strategy chooses a page, the visitor converts or not, and the strategy sees the result."}, {"code": "def ab_test(n, shown, won):\n    return \"new\" if n % 2 else \"old\"\n\n\ndef epsilon_greedy(n, shown, won, epsilon=0.1):\n    if rng.random() < epsilon or min(shown.values()) == 0:\n        return \"new\" if rng.random() < 0.5 else \"old\"\n    return max(shown, key=lambda p: won[p] / shown[p])", "note": "The A/B test alternates and ignores results. Epsilon-greedy shows a random page one time in ten, to keep learning, and otherwise the page converting best so far."}, {"code": "for name, choose in ((\"A/B test, 50/50\", ab_test), (\"epsilon-greedy\", epsilon_greedy)):\n    shown, orders = run(choose)\n    cost = shown[\"old\"] * (rates[\"new\"] - rates[\"old\"])\n    print(f\"{name:16} new page shown to {shown['new'] / visitors:5.1%}, {orders:,} orders, \"\n          f\"about {cost:.0f} expected orders lost to the old page\")", "note": "The cost of each strategy is the visitors it sent to the worse page, times the difference in rates."}], "output": "A/B test, 50/50  new page shown to 50.0%, 2,133 orders, about 101 expected orders lost to the old page\nepsilon-greedy   new page shown to 66.7%, 2,335 orders, about 67 expected orders lost to the old page"}
```

**The bandit showed the new page to 66.7% of visitors and lost about 67 expected orders to the old
page; the even split lost about 101.** Shifting traffic towards the winner while learning is cheaper,
and the difference grows with the gap between the pages and with the length of the test.

It is not free, and the cost is the one the A/B lessons were about. The bandit's estimate of the old
page rests on far fewer visitors, so **its measurement of the difference is less precise**, and its
choices depend on early results, which lesson 11 showed to be noisy: a page that starts unlucky gets
fewer visitors and fewer chances to recover. In this run it showed the new page to only two visitors
in three, well short of the nine in ten its rule would reach once it was sure: with conversion rates
this close, the two pages trade places in its eyes for a long time.

**The trade is learning against earning.** When the question is "which page, so we can decide and
move on", an A/B test answers it cleanly and its result can be trusted. When the question is "show
the best of several headlines for the next two days and then forget about it", a bandit earns more.
Reinforcement learning at full scale, choosing sequences of actions in changing conditions, is far
beyond this course; the trade is the part a BI analyst meets.
