---
title: One workload, priced four ways
version: 1
---

**A comparison of compute prices is a calculation, and it belongs in a program rather than in a
spreadsheet nobody can rerun.** The program below takes the sheet `prices.py` prints (lesson 1,
prices as published on 16 October 2026) through a pipe, so no price in it is typed by hand. It adds
a handful of assumptions about the workload, written at the top where you can see and change them,
and prices every profile of the previous section four ways: on EC2 instances, on Fargate tasks, on
Lambda and on App Runner.

Copy it with the button on the block and save it as `~/aws/compare.py`, beside `prices.py`. As
always, the notes are not copied.

```schooling-example
{"language": "python", "file": "compare.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"One workload priced four ways, from the sheet prices.py prints.\n\n    python3 prices.py | python3 compare.py\n    python3 prices.py | python3 compare.py shop=2,2,2,2,2,2,2,10,...\n\nWith no argument it prices the four profiles below. Each argument is a\nprofile of its own instead: a name, then 24 rates in requests per second,\none for each hour of the day from 00:00. Every price is read from the sheet.\n\"\"\"\n", "note": "The docstring says how to run the program: the price sheet goes in through a pipe, so every price below is one prices.py printed, not one typed here."}, {"code": "import math\nimport re\nimport sys\n\n", "note": "Three modules from the standard library. Like prices.py, it needs nothing installed."}, {"code": "HOURS = 730                # an average month: 8,760 hours over 12\nDAYS = HOURS / 24          # 30.42 days\n\nMS = 100                   # each request runs for 100 ms\nLAMBDA_GB = 0.5            # in a function of 512 MB\nPER_VCPU = 100             # one vCPU serves 100 requests a second\nTASK_VCPU, TASK_GB = 0.5, 1                 # one container\nINSTANCE, INSTANCE_VCPU = 'c7g.large', 2    # one machine\nLEAST = 2                  # never fewer than two of anything\n\n", "note": "The workload, in eight numbers. **These are the example's assumptions, not measurements**: a request that runs 100 ms in a 512 MB function, and one vCPU serving 100 requests a second. Change them to your own and the comparison changes with them. `LEAST` keeps two of everything, so one failure never takes the service away."}, {"code": "PROFILES = {\n    'steady': [30] * 24,\n    'office': [0] * 9 + [60] * 9 + [0] * 6,\n    'nightly': [0] * 2 + [14] * 2 + [0] * 20,\n    'busy': [400] * 24,\n}\n\n\n", "note": "Four request profiles, each a list of 24 rates, one per hour. `steady` is 30 a second all day; `office` is 60 a second from 09:00 to 18:00 and nothing else; `nightly` is a two-hour burst of 14 a second; `busy` is 400 a second, all day."}, {"code": "def read_sheet(lines):\n    \"\"\"{(block, label): price} out of the sheet's text.\"\"\"\n    sheet, block = {}, None\n    for line in lines:\n        if not line.strip():\n            continue\n        if not line.startswith(' '):\n            block = line.strip()\n            continue\n        label, price, _ = re.match(r'  (.+?) +(\\S+)  (per .+)', line).groups()\n        if price != '-':\n            sheet[(block, label)] = float(price)\n    return sheet\n\n\n", "note": "Reads the sheet's text back into numbers. A line with no indentation is a block's heading; an indented line is a label, a price and a unit. A price printed as a dash was not found, and is left out rather than read as zero."}, {"code": "def price(sheet, block, label):\n    for (b, l), p in sheet.items():\n        if b.startswith(block) and l.startswith(label):\n            return p\n    sys.exit(f'not on the sheet: {block} / {label}')\n\n\n", "note": "Finds one price by the start of its block and its label, and stops the program if it is missing, so a renamed line on the sheet is an error rather than a free service."}, {"code": "def copies(rate, capacity):\n    return max(LEAST, math.ceil(rate / capacity))\n\n\n", "note": "How many copies an hour needs: enough for its rate, and never fewer than `LEAST`."}, {"code": "def month(profile, s):\n    requests = sum(rate * 3600 for rate in profile) * DAYS\n    machine = price(s, 'EC2', INSTANCE + ' ')\n    task = TASK_VCPU * price(s, 'Fargate', 'vCPU, Arm') + TASK_GB * price(s, 'Fargate', 'memory, Arm')\n    serving = TASK_VCPU * price(s, 'App Runner', 'vCPU') + TASK_GB * price(s, 'App Runner', 'memory')\n    waiting = TASK_GB * price(s, 'App Runner', 'memory')\n    ec2 = fargate = runner = 0.0\n    for rate in profile:\n        ec2 += copies(rate, INSTANCE_VCPU * PER_VCPU) * machine * DAYS\n        fargate += copies(rate, TASK_VCPU * PER_VCPU) * task * DAYS\n        runner += copies(rate, TASK_VCPU * PER_VCPU) * (serving if rate else waiting) * DAYS\n    gb_seconds = requests * MS / 1000 * LAMBDA_GB\n    lam = requests / 1e6 * price(s, 'Lambda', 'requests') + gb_seconds * price(s, 'Lambda', 'duration, Arm')\n    return requests, {'EC2 ' + INSTANCE: ec2, 'Fargate, Arm': fargate,\n                      'Lambda, Arm': lam, 'App Runner*': runner}\n\n\n", "note": "The month, priced four ways, hour by hour. EC2 and Fargate are sized to each hour's traffic and pay for every copy they run. App Runner runs the same copies, but an hour with no requests pays memory only. Lambda pays per request and per GB-second, and nothing at all for an hour nobody calls it."}, {"code": "def main():\n    s = read_sheet(sys.stdin)\n    profiles = {} if sys.argv[1:] else dict(PROFILES)\n    for arg in sys.argv[1:]:\n        name, rates = arg.split('=')\n        profiles[name] = [float(r) for r in rates.split(',')]\n        if len(profiles[name]) != 24:\n            sys.exit(f'{name}: a profile is 24 rates, one per hour')\n    print(f'{\"profile\":<9}{\"requests\":>12}' + ''.join(f'{k:>16}' for k in month(PROFILES['busy'], s)[1]))\n    for name, profile in profiles.items():\n        requests, cost = month(profile, s)\n        print(f'{name:<9}{requests / 1e6:>11.2f}M' + ''.join(f'{v:>16.2f}' for v in cost.values()))\n    floor = LEAST * (TASK_VCPU * price(s, 'Fargate', 'vCPU, Arm') + TASK_GB * price(s, 'Fargate', 'memory, Arm')) * HOURS\n    per_request = price(s, 'Lambda', 'requests') / 1e6 + MS / 1000 * LAMBDA_GB * price(s, 'Lambda', 'duration, Arm')\n    even = floor / per_request\n    print(f'\\nLambda costs what two Fargate tasks cost at {even / 1e6:.2f}M requests a month,'\n          f' {even / (HOURS * 3600):.1f} a second on average.')\n    print('* App Runner is priced in us-east-1: it is not offered in sa-east-1.')\n\n\nif __name__ == '__main__':\n    main()\n", "note": "Prints one row per profile, then the break-even: the monthly volume at which Lambda costs exactly what the two smallest Fargate tasks cost, as a total and as an average rate."}], "output": "profile      requests   EC2 c7g.large    Fargate, Arm     Lambda, Arm     App Runner*\nsteady         78.84M          162.21           49.60           68.33           56.94\noffice         59.13M          162.21           49.60           51.25           27.74\nnightly         3.07M          162.21           49.60            2.66           14.11\nbusy         1051.20M          162.21          198.38          911.04          227.76\n\nLambda costs what two Fargate tasks cost at 57.23M requests a month, 21.8 a second on average.\n* App Runner is priced in us-east-1: it is not offered in sa-east-1.\n"}
```

Run it with the sheet piped in. The EC2 file makes `prices.py` take a few seconds, as lesson 1
measured:

```
ana@laptop:~/aws$ python3 prices.py | python3 compare.py
profile      requests   EC2 c7g.large    Fargate, Arm     Lambda, Arm     App Runner*
steady         78.84M          162.21           49.60           68.33           56.94
office         59.13M          162.21           49.60           51.25           27.74
nightly         3.07M          162.21           49.60            2.66           14.11
busy         1051.20M          162.21          198.38          911.04          227.76

Lambda costs what two Fargate tasks cost at 57.23M requests a month, 21.8 a second on average.
* App Runner is priced in us-east-1: it is not offered in sa-east-1.
```

The requests column is millions a month, and every other number is US dollars a month at the list
price. **The four columns are four answers to the
same question**, and the only thing that differs between the rows is the profile.

## Reading the table

The busy profile is the one that reorders everything, so start with the other three.

**nightly: Lambda, by a distance.** 3.07 million requests cost 2.66 USD as functions, against
49.60 for the two smallest Fargate tasks that the program never lets fall below two. Twenty-two
silent hours a day are paid in full by every option except Lambda. App Runner, at 14.11, pays
memory through them, which is cheaper than paying for a whole task.

**office: App Runner, then a near tie.** Fifteen idle hours a day are what App Runner is built for:
27.74 USD, with memory alone billed at night. Lambda (51.25) and Fargate (49.60) come out almost
level, because 59.13 million requests a month sits close to the break-even the last line prints.

**steady: Fargate.** With no idle hour, App Runner's advantage is gone and it costs 56.94 against
Fargate's 49.60. Lambda, at 68.33, now pays for 78.84 million requests that two small tasks absorb
without noticing.

**busy: EC2.** At 400 a second the program needs eight tasks, eight App Runner instances, or two
`c7g.large` instances of 2 vCPU each, and the machines win: 162.21 USD against 198.38 for Fargate,
227.76 for App Runner and 911.04 for Lambda. The same 162.21 appears on every other row too, and
that is the other half of the lesson: **the smallest instance worth running is bigger than a small
service**, so EC2 is the most expensive option until the traffic grows into the machine.

## The break-even

The last line answers the question people actually ask: at what volume does a container beat a
function? Each request here costs 0.2 USD per million plus 0.05 GB-second at 0.0000133334, which is
0.8667 USD per million requests. Two Fargate tasks cost 49.60 a month whatever happens. **Below
57.23 million requests a month, 21.8 a second on average, Lambda is the cheaper of the two**; above
it, the tasks are. That break-even moves with the assumptions: a request of 200 ms doubles the
GB-seconds and brings it down to about 32 million, and a function of 256 MB pushes it up. Change
`MS` or `LAMBDA_GB` and run it again, which is the reason the program exists.

## What the program leaves out

Four things, each of which can move a close result:

- **The front door.** EC2 and Fargate need a load balancer, whose hourly and capacity charges are
  not on this course's sheet; `aws-foundations` lesson 22 prices it. Lambda can be reached through a
  function URL, which AWS does not bill separately, or through an HTTP API at 1.59 USD per million
  (lesson 19), which would add 125.36 USD to the steady profile, more than the function itself.
  App Runner includes its own.
- **The region.** App Runner's prices are `us-east-1`'s, because it is not offered in São Paulo.
  Everything else is `sa-east-1`'s, and São Paulo is among the dearer regions, so App Runner's
  column is flattered.
- **Discounts.** Savings Plans cover EC2, Fargate and Lambda, and Reserved Instances cover EC2. Their
  rates are not on the sheet, and `aws-foundations` lesson 14 and `aws-operations` lesson 22 are
  where they are weighed. A steady load is exactly what they reward.
- **Scaling as it really behaves.** The program sizes every hour perfectly. A real auto scaling
  group reacts minutes late (lesson 5) and a cold function adds its start-up time (lesson 17), so
  real containers run a little more capacity than this, and real functions a little more duration.

**None of this makes the numbers wrong; it makes them a floor.** A comparison that comes out within
20% either way is a tie, and a tie is decided by the next two sections: what the move costs, and
what the team can run.
