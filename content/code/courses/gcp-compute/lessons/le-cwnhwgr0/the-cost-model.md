---
title: One service, priced four ways
version: 1
---

**A comparison of compute prices is a calculation, and it belongs in a program rather than in a
spreadsheet nobody can rerun.** The program below takes the sheet `prices.py` prints (lesson 1,
prices as published on 30 October 2026) through a pipe, so no price in it is typed by hand. It adds
a handful of assumptions about the service, written at the top where you can see and change them,
and prices every profile of the previous section four ways: on Compute Engine machines, on Cloud
Run with each of its two billing modes, and on GKE Autopilot.

Copy it with the button on the block and save it as `~/gcp/compare.py`, beside `prices.py`. As
always, the notes are not copied.

```schooling-example
{"language": "python", "file": "compare.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"One service priced four ways, from the sheet prices.py prints.\n\n    python3 prices.py | python3 compare.py\n    python3 prices.py | python3 compare.py shop=2,2,2,2,2,2,2,10,...\n\nWith no argument it prices the four profiles below. Each argument is a\nprofile of its own instead: a name, then 24 rates in requests per second,\none for each hour of the day from 00:00. Every price is read from the sheet.\n\"\"\"\n", "note": "The docstring says how to run the program: the price sheet goes in through a pipe, so every price below is one prices.py printed, not one typed here."}, {"code": "import math\nimport re\nimport sys\n\n", "note": "Three modules from the standard library. Like prices.py, it needs nothing installed."}, {"code": "HOURS = 730                # an average month: 8,760 hours over 12\nDAYS = HOURS / 24          # 30.42 days\n\nMS = 100                   # each request runs for 100 ms\nPER_VCPU = 100             # one vCPU serves 100 requests a second\nRUN_VCPU, RUN_GIB = 1, 0.5         # one Cloud Run instance\nPOD_VCPU, POD_GIB = 0.5, 1         # one Autopilot pod\nVM = 'e2-standard-2'               # one Compute Engine machine\nLEAST = 2                  # never fewer than two machines or pods\n\n", "note": "The service, in seven numbers. **These are the example's assumptions, not measurements**: a request that runs 100 ms, one vCPU serving 100 requests a second, a Cloud Run instance of 1 vCPU and 512 MiB, an Autopilot pod of half a vCPU and 1 GiB. Change them to your own and the comparison changes with them. `LEAST` keeps two machines or pods, so one failure never takes the service away; Cloud Run needs no such floor, because it replaces an instance itself."}, {"code": "PROFILES = {\n    'steady': [30] * 24,\n    'office': [0] * 9 + [60] * 9 + [0] * 6,\n    'nightly': [0] * 2 + [14] * 2 + [0] * 20,\n    'busy': [400] * 24,\n    'sparse': [1] * 24,\n}\n\n\n", "note": "Five request profiles, each a list of 24 rates, one per hour. `steady` is 30 a second all day; `office` is 60 a second from 09:00 to 18:00; `nightly` is a two-hour burst of 14 a second; `busy` is 400 a second; `sparse` is one request a second, all day."}, {"code": "def read_sheet(lines):\n    \"\"\"{(block, label): price} out of the sheet's text.\"\"\"\n    sheet, block = {}, None\n    for line in lines:\n        if not line.strip() or line.startswith('    '):\n            continue\n        if not line.startswith(' '):\n            block = line.strip()\n            continue\n        vm = re.match(r'  (\\S+) +(\\d+) vCPU +\\d+ GiB +(\\S+)', line)\n        if vm:\n            sheet[(block, vm.group(1))] = float(vm.group(3))\n            continue\n        label, value = re.match(r'  (.+?) +(\\S+)  \\S', line).groups()\n        sheet[(block, label)] = float(value)\n    return sheet\n\n\n", "note": "Reads the sheet's text back into numbers. A line with no indentation is a block's heading. A machine row is read by its name and its hourly price; any other indented line is a label, a number and a unit."}, {"code": "def price(sheet, block, label):\n    for (b, l), p in sheet.items():\n        if b.startswith(block) and l.startswith(label):\n            return p\n    sys.exit(f'not on the sheet: {block} / {label}')\n\n\n", "note": "Finds one price by the start of its block and its label, and stops the program if it is missing, so a renamed line on the sheet is an error rather than a free service."}, {"code": "def copies(rate, capacity, least=0):\n    return max(least, math.ceil(rate / capacity))\n\n\n", "note": "How many copies an hour needs: enough for its rate, and never fewer than the floor it is given."}, {"code": "def month(profile, s):\n    requests = sum(rate * 3600 for rate in profile) * DAYS\n    machine = price(s, 'Compute Engine', VM)\n    vcpu_s = price(s, 'Cloud Run, request', 'vCPU, while')\n    gib_s = price(s, 'Cloud Run, request', 'memory, while')\n    per_request = price(s, 'Cloud Run, request', 'requests') / 1e6\n    inst_vcpu_s = price(s, 'Cloud Run, instance', 'vCPU')\n    inst_gib_s = price(s, 'Cloud Run, instance', 'memory')\n    pod = POD_VCPU * price(s, 'GKE', 'Autopilot pod vCPU') + POD_GIB * price(s, 'GKE', 'Autopilot pod memory')\n    fee = price(s, 'GKE', 'cluster management fee')\n    run_hour = 3600 * (RUN_VCPU * vcpu_s + RUN_GIB * gib_s)\n    inst_hour = 3600 * (RUN_VCPU * inst_vcpu_s + RUN_GIB * inst_gib_s)\n    vm = request = instance = autopilot = 0.0\n    for rate in profile:\n        vm += copies(rate, 2 * PER_VCPU, LEAST) * machine * DAYS\n        n = copies(rate, RUN_VCPU * PER_VCPU)\n        busy = 1 - math.exp(-rate / max(n, 1) * MS / 1000)\n        request += n * busy * run_hour * DAYS\n        instance += n * inst_hour * DAYS\n        autopilot += (copies(rate, POD_VCPU * PER_VCPU, LEAST) * pod + fee) * DAYS\n    request += requests * per_request\n    return requests, {'Compute Engine': vm, 'Run, request': request,\n                      'Run, instance': instance, 'Autopilot': autopilot}\n\n\n", "note": "The month, priced four ways, hour by hour. Compute Engine and Autopilot are sized to each hour's traffic and pay for every copy they run, Autopilot with its cluster fee on top. Cloud Run with instance-based billing pays for each instance it runs; with request-based billing it pays only for the fraction of the hour in which a request is in flight, which for requests arriving at random is `1 - e^(-rate × duration)`, and then the fee per request."}, {"code": "def main():\n    s = read_sheet(sys.stdin)\n    profiles = {} if sys.argv[1:] else dict(PROFILES)\n    for arg in sys.argv[1:]:\n        name, rates = arg.split('=')\n        profiles[name] = [float(r) for r in rates.split(',')]\n        if len(profiles[name]) != 24:\n            sys.exit(f'{name}: a profile is 24 rates, one per hour')\n    print(f'{\"profile\":<9}{\"requests\":>12}' + ''.join(f'{k:>16}' for k in month(PROFILES['busy'], s)[1]))\n    for name, profile in profiles.items():\n        requests, cost = month(profile, s)\n        print(f'{name:<9}{requests / 1e6:>11.2f}M' + ''.join(f'{v:>16.2f}' for v in cost.values()))\n    serving = RUN_VCPU * price(s, 'Cloud Run, request', 'vCPU, while') + RUN_GIB * price(s, 'Cloud Run, request', 'memory, while')\n    living = RUN_VCPU * price(s, 'Cloud Run, instance', 'vCPU') + RUN_GIB * price(s, 'Cloud Run, instance', 'memory')\n    print(f'\\nRequest-based billing is the cheaper of the two while an instance is busy less than'\n          f' {living / serving:.0%} of the time, before the charge per request.')\n    print('Autopilot includes the cluster fee; the free tier credit covers one cluster\\'s fee a month.')\n\n\nif __name__ == '__main__':\n    main()\n", "note": "Prints one row per profile, then the busy fraction below which request-based billing is the cheaper of Cloud Run's two modes, and a reminder about the GKE fee."}]}
```

Run it with the sheet piped in:

```
ana@laptop:~/gcp$ python3 prices.py | python3 compare.py
profile      requests  Compute Engine    Run, request   Run, instance       Autopilot
steady         78.84M           97.84           94.59           49.93          112.67
office         59.13M           97.84           48.47           18.72          112.67
nightly         3.07M           97.84            5.39            4.16          112.67
busy         1051.20M           97.84          685.90          199.73          231.69
sparse          2.63M           97.84            7.37           49.93          112.67

Request-based billing is the cheaper of the two while an instance is busy less than 75% of the time, before the charge per request.
Autopilot includes the cluster fee; the free tier credit covers one cluster's fee a month.
```

The requests column is millions a month, and every other number is US dollars a month at the list
price. **The four columns are four answers to the same question**, and the only thing that differs
between the rows is the profile.

## Reading the table

**sparse: Cloud Run with request-based billing, by a distance.** 7.37 dollars against 49.93 for the
same instance billed for its whole life. One request a second keeps an instance busy about a tenth
of the time, and request-based billing charges only for that tenth. This is the shape it was built
for.

**nightly and office: Cloud Run, either mode.** Twenty-two and fifteen idle hours a day cost Cloud
Run nothing, because it scales to zero, while the two machines and the two pods are paid through
every one of them: 97.84 and 112.67 whatever the profile. Inside the busy hours an instance is
almost never empty, so the instance-based mode, with its lower rate, comes out ahead: 4.16 against
5.39 at night, 18.72 against 48.47 in office hours.

**steady: Cloud Run, instance-based.** With an instance busy 95% of the time, request-based billing
pays its higher rate for nearly every second and the fee on 78.84 million requests besides: 94.59
against 49.93.

**busy: Compute Engine.** At 400 a second the program needs four Cloud Run instances, eight pods or
two `e2-standard-2` machines, and the machines win: 97.84 against 199.73 for Cloud Run billed by
instance, 231.69 for Autopilot and 685.90 for Cloud Run billed by request, of which 420.48 is the
fee on a billion requests. The same 97.84 appears on every other row too, and that is the other
half of the lesson: **the smallest pair of machines worth running is bigger than a small
service**, so Compute Engine is the dearest option until the traffic grows into it.

## The break-even between Cloud Run's two modes

The line under the table answers the question people ask about Cloud Run: which billing mode? An
instance of 1 vCPU and 512 MiB costs 0.000019 a second for its whole life under instance-based
billing, and 0.00002525 a second while serving under request-based billing. **Below a busy fraction
of 75%, request-based billing is the cheaper of the two before its fee per request; above it,
instance-based is.** The fee only pushes the line lower. Lesson 11 is where the mode is chosen on a
real service, and this is the arithmetic behind its advice.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"A chart of what one Cloud Run instance of 1 vCPU and 512 MiB costs per hour against how busy it is. Instance-based billing is a flat line at 0.0684 dollars an hour whatever the busy fraction. Request-based billing rises in a straight line from zero when idle to 0.0909 dollars when busy all the time. The two lines cross at a busy fraction of 75%; left of it request-based is cheaper, right of it instance-based is.\"><path d=\"M90 40 L90 290 L650 290\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90 290 L90 295\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"90\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0%</text><path d=\"M228 290 L228 295\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"228\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">25%</text><path d=\"M365 290 L365 295\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"365\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">50%</text><path d=\"M502 290 L502 295\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"502\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">75%</text><path d=\"M640 290 L640 295\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"640\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">100%</text><path d=\"M85 290 L90 290\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"81\" y=\"290\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.00</text><path d=\"M85 170 L90 170\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"81\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.05</text><path d=\"M85 50 L90 50\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"81\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.10</text><text x=\"365\" y=\"330\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">share of the hour with a request inside</text><text x=\"50\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">dollars per hour</text><path d=\"M90 125.8 L640 125.8\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M90 290.0 L640 71.8\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><circle cx=\"503.9\" cy=\"125.8\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"106\" y=\"116\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">instance-based: the whole hour</text><text x=\"255\" y=\"247\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">request-based: only while serving</text><text x=\"518\" y=\"156\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">they cross at 75%</text><text x=\"101\" y=\"56\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">request-based cheaper</text><text x=\"629\" y=\"56\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">instance-based cheaper</text></svg>", "caption": "One instance of 1 vCPU and 512 MiB, before the fee per request. The sparse profile sits near 10%, steady near 95%."}
```

## What the program leaves out

Four things, each of which can move a close result:

- **The front door.** Compute Engine and Autopilot need a load balancer to share requests between
  copies, and its hourly charge is not on this course's sheet; Cloud Run has one built in.
- **The free tiers.** Cloud Run's first 180,000 vCPU-seconds, 360,000 GiB-seconds and 2 million
  requests each month under request-based billing are left out, and so is GKE's credit, which
  covers one cluster's fee: the program says so under the table. For the sparse and nightly
  profiles the free tier would take the Cloud Run bill to nearly nothing.
- **Discounts.** Committed use discounts, of up to 55% on most machine types for one or three
  years, and the sustained use discount that E2 does not get. Lesson 23 weighs what a commitment
  ties you to.
- **The idle tail.** Cloud Run keeps an instance warm for a while after its last request, up to
  15 minutes, and under instance-based billing that tail is billed; the program starts and stops
  instances on the hour.

None of the four reverses the busy and sparse rows. Each could move the steady row, which is why
the program is a starting point for your own numbers and not a verdict.
