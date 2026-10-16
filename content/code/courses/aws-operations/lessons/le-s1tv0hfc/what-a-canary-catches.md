---
title: What a canary catches, and when it catches nothing
version: 1
---

The canary's promise is arithmetic: if a release is bad, only a tenth of the users meet it, for only
five minutes. **That promise holds only if something notices**, and what notices is an alarm. Where
the alarm looks decides whether the canary protects anybody, and the clearest way to see it is to
count. moto runs no deployment, so this section counts with a model: a short program that plays a bad
release through each strategy, minute by minute.

```schooling-example
{"language": "python", "file": "canary.py", "parts": [{"code": "\"\"\"canary.py: how many requests a bad release fails under each strategy.\n\nA model, not CodeDeploy. Each minute the new version takes a share of the\ntraffic; a share of its requests fail; an alarm watches an error rate and\nfires after two minutes in a row above the threshold; the minute after it\nfires, all traffic is back on the old version.\n\"\"\"\n", "note": "**A model, and the docstring says so first.** It has four assumptions in it, all stated, and none of them is how CodeDeploy measures anything."}, {"code": "RPM = 1000          # requests a minute\nBAD = 0.20          # share of the new version's requests that fail\nTHRESHOLD = 0.02    # the alarm fires above a 2% error rate\nMINUTES = 15\n\n", "note": "The numbers to change: a thousand requests a minute, a release that fails one request in five, and an alarm that fires above 2%."}, {"code": "STRATEGIES = {\n    'all at once': lambda m: 1.0,\n    'canary 10%, 5 min': lambda m: 0.1 if m < 5 else 1.0,\n    'linear 10%/min': lambda m: min(1.0, 0.1 * (m + 1)),\n}\n\n\n", "note": "Each strategy is a function from the minute to the new version's share. The canary holds 10% for five minutes and then takes everything; the linear one adds 10% a minute."}, {"code": "def run(share, scope):\n    failed, above = 0, 0\n    for m in range(MINUTES):\n        s = share(m)\n        errors = RPM * s * BAD\n        failed += errors\n        seen = RPM * s if scope == 'new version' else RPM\n        above = above + 1 if errors / seen > THRESHOLD else 0\n        if above == 2:\n            return round(failed), m + 1\n    return round(failed), None\n\n\n", "note": "Minute by minute: the new version's share of the traffic fails at the bad rate. The alarm sees the errors divided by **either all the requests or only the new version's**, and that one choice is what the output is about. Two minutes above the line and it fires; the next minute is back on the old version."}, {"code": "print(f'{\"strategy\":<20}{\"alarm watches\":<16}{\"failed\":>8}  rolled back')\nfor name, share in STRATEGIES.items():\n    for scope in ('whole service', 'new version'):\n        failed, when = run(share, scope)\n        after = f'after minute {when}' if when else 'never'\n        print(f'{name:<20}{scope:<16}{failed:>8}  {after}')\n", "note": "Each strategy twice, once per scope of the alarm."}]}
```

Save it as `canary.py` and run it:

```
ana@laptop:~/aws/deploy$ python3 canary.py
strategy            alarm watches     failed  rolled back
all at once         whole service        400  after minute 2
all at once         new version          400  after minute 2
canary 10%, 5 min   whole service        500  after minute 7
canary 10%, 5 min   new version           40  after minute 2
linear 10%/min      whole service        120  after minute 3
linear 10%/min      new version           60  after minute 2
```

Read the third line first. **A canary watched by an alarm on the whole service failed 500 requests,
more than releasing everything at once.** At 10% of the traffic, a release that fails 20% of its
requests raises the service's error rate to exactly 2%, which is not above the threshold, so the
alarm stays quiet for the five canary minutes, the deployment shifts everything, and then it takes
two more minutes to fire. The canary diluted its own signal by ten and the alarm could not see it.

The fourth line is the same canary with the alarm on **the new version only**: 40 failed requests,
rolled back after the second minute. Same release, same threshold, a twelfth of the damage. That is
the whole argument for the alarm names in the deployment group of this lesson, `api-green-5xx` and
`api-green-p99`: on ECS, the green task set sits behind its own target group, and the load balancer
reports `HTTPCode_Target_5XX_Count` per target group, so the alarm can watch the new version alone.

## What the model leaves out

It is worth being exact about the simplifications, because each one moves a number:

- **real traffic is not flat**, and a canary at 3 a.m. sees a fraction of the requests it would see at
  noon, so the same five minutes carry less evidence;
- **an error is not the only symptom**: a release that is slow rather than failing needs a latency
  alarm, which is why the group names two;
- **a minute is a coarse clock**: CloudWatch can evaluate an alarm every ten seconds for high-resolution
  metrics, and lesson 10 is about how many periods an alarm should wait;
- **a rollback is not instant**, though in blue/green it is fast, because the old tasks are still
  running and only the listener moves.

Change `BAD` to `0.05` and run it again. At 5% failures a 10% canary raises the service's rate to
0.5%, and an alarm on the whole service stays quiet through the entire canary: it can fire only once
more than 40% of the traffic is on the new version. **Small failures need the narrow alarm most.**
