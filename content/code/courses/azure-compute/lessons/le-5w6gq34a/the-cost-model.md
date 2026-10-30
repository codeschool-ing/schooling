---
title: One workload, priced five ways
version: 1
---

**A comparison of compute prices is a calculation, and it belongs in a program rather than in a
spreadsheet nobody can rerun.** This one is two files. `rates.json` holds every rate the
calculation uses, and nothing else; `compare.py` holds the assumptions about the workload, written
at the top where you can see and change them, and prices every profile of the previous section five
ways: on two virtual machines, on Container Apps, on an App Service plan, on Functions in a Flex
Consumption plan and on AKS.

**The rates in the file are illustrative, not Azure's prices.** This course quotes no price from
Azure's price list, for the reason lesson 1 gave, so every rate below is a round number chosen to
make the arithmetic readable. The first key of the file says so, and so does the last line the
program prints. Three numbers in it are not illustrative: the monthly free grants of Container
Apps, which Microsoft's billing page states. The end of this section shows how to put the real
rates in, and until you have, read the table for its shape and never for its totals.

Copy the file with the button on the block and save it as `~/azure/rates.json`. The notes are not
copied.

```schooling-example
{"language": "json", "file": "rates.json", "parts": [{"code": "{\n  \"_\": \"ILLUSTRATIVE RATES, NOT AZURE'S PRICES: round numbers in USD. The three Container Apps free grants are Microsoft's documented ones. Replace every rate with the real one for your region before deciding anything.\",\n", "note": "**The first key says what the file is**, so the warning travels with the numbers: every rate below is a round number chosen for the arithmetic, not a price Azure charges. JSON has no comments, so the warning is a value; `compare.py` never reads it."}, {"code": "  \"vm_hour\": 0.10,\n", "note": "One `Standard_D2s_v5` for an hour, the illustrative rate lesson 1 used for the size the CLI picks by default."}, {"code": "  \"ca_vcpu_second\": 0.00002,\n  \"ca_gib_second\": 0.000002,\n  \"ca_idle_vcpu_second\": 0.000002,\n  \"ca_idle_gib_second\": 0.000002,\n  \"ca_million_requests\": 0.40,\n  \"ca_free_vcpu_seconds\": 180000,\n  \"ca_free_gib_seconds\": 360000,\n  \"ca_free_requests\": 2000000,\n", "note": "Container Apps on the Consumption profile: a vCPU-second and a GiB-second at the active rate, the same two at the reduced idle rate, and a price per million requests. **The last three lines are not illustrative**: they are the monthly free grants per subscription that Microsoft's billing page states, read on 30 October 2026."}, {"code": "  \"plan_instance_hour\": 0.15,\n", "note": "One instance of a `P1v3` App Service plan for an hour, the size lesson 18 gives the shop."}, {"code": "  \"flex_gb_second\": 0.000026,\n  \"flex_million_executions\": 0.40,\n  \"flex_free_gb_seconds\": 0,\n  \"flex_free_executions\": 0,\n  \"flex_always_ready_month\": 150.00,\n", "note": "Functions on Flex Consumption, as lesson 16 priced it: the GB-second and the million executions of Microsoft's own worked example, the free grants at zero because their size is on the pricing page only, and 150 USD a month for one always ready instance."}, {"code": "  \"node_hour\": 0.20,\n  \"control_plane_hour\": 0.10\n}\n", "note": "AKS: a node of 4 vCPUs for an hour, twice the two-vCPU machine above, and the hour of a Standard tier control plane. On the Free tier that second line would be 0."}]}
```

Then the program, saved beside it as `~/azure/compare.py`:

```schooling-example
{"language": "python", "file": "compare.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"One workload priced five ways, from the rates in rates.json.\n\n    python3 compare.py\n    python3 compare.py shop=2,2,2,2,2,2,2,10,...\n\nWith no argument it prices the five profiles below. Each argument is a\nprofile of its own instead: a name, then 24 rates in requests per second,\none for each hour of the day from 00:00. Every price comes from rates.json.\n\"\"\"\nimport json\nimport math\nimport sys\n\n", "note": "The docstring says how to run it. Three modules from the standard library, so nothing has to be installed, and **no price is written in the program**: they are all read from `rates.json`."}, {"code": "HOURS = 730                # an average month: 8,760 hours over 12\nDAYS = HOURS / 24          # 30.42 days\nPER_VCPU = 100             # one vCPU serves 100 requests a second\nLEAST = 2                  # never fewer than two of anything\n\n", "note": "The month, and two assumptions about the workload. **One vCPU serving 100 of the shop's requests a second is the example's guess, not a measurement**; measure your own and change it. `LEAST` keeps two of everything, so one failure never takes the service away."}, {"code": "VM_VCPU = 2                # Standard_D2s_v5, lesson 1\nCA_VCPU, CA_GIB = 0.5, 1   # one Container Apps replica, lesson 8\nCA_MIN = 2                 # replicas kept when nobody calls\nPLAN_VCPU = 2              # one P1v3 instance of an App Service plan\nFLEX_GB = 2                # a 2,048 MB Flex Consumption instance\nBILLED_S = 1.0             # each request billed as the 1,000 ms minimum\nALWAYS_READY = 0           # Flex instances kept ready: none\nNODE_VCPU, NODES = 4, 3    # AKS: three nodes of 4 vCPUs at least\n\n", "note": "The five ways, each in the shape an earlier lesson gave it. A replica of half a core carries 50 requests a second, which is the `concurrentRequests` of lesson 8's rule. A Flex request is billed as one second of a 2 GB instance, lesson 16's reading. Three nodes of 4 vCPUs are what lesson 11 recommends for a system pool."}, {"code": "PROFILES = {\n    'steady': [30] * 24,\n    'office': [0] * 9 + [60] * 9 + [0] * 6,\n    'nightly': [0] * 2 + [14] * 2 + [0] * 20,\n    'webhook': [0.05] * 24,\n    'busy': [400] * 24,\n}\n\n\n", "note": "The five profiles of the previous section, each a list of 24 rates, one per hour from midnight."}, {"code": "def copies(rate, vcpus, least=LEAST):\n    return max(least, math.ceil(rate / (vcpus * PER_VCPU)))\n\n\n", "note": "How many machines, instances, replicas or nodes an hour needs: enough for its rate, and never fewer than the floor."}, {"code": "def month(profile, r):\n    requests = sum(rate * 3600 for rate in profile) * DAYS\n    vm = plan = aks = active = idle = 0.0\n    for rate in profile:\n        vm += copies(rate, VM_VCPU) * r['vm_hour'] * DAYS\n        plan += copies(rate, PLAN_VCPU) * r['plan_instance_hour'] * DAYS\n        aks += (copies(rate, NODE_VCPU, NODES) * r['node_hour'] + r['control_plane_hour']) * DAYS\n        replica_s = copies(rate, CA_VCPU, CA_MIN) * 3600 * DAYS\n        if rate:\n            active += replica_s\n        else:\n            idle += replica_s\n", "note": "Hour by hour. Virtual machines, plan instances and nodes are paid for every hour they exist, whatever arrives. Container Apps counts replica-seconds instead, and **an hour with no request at all is counted as idle**; an hour with any request is counted as active."}, {"code": "    ca = (max(active * CA_VCPU - r['ca_free_vcpu_seconds'], 0) * r['ca_vcpu_second']\n          + max(active * CA_GIB - r['ca_free_gib_seconds'], 0) * r['ca_gib_second']\n          + idle * (CA_VCPU * r['ca_idle_vcpu_second'] + CA_GIB * r['ca_idle_gib_second'])\n          + max(requests - r['ca_free_requests'], 0) / 1e6 * r['ca_million_requests'])\n", "note": "Container Apps' bill: active vCPU-seconds and GiB-seconds less the free grants, idle seconds at the idle rates, and requests past the first two million. The billing page does not say whether the grants are taken from active or idle seconds; the program takes them from active ones, which is its own assumption."}, {"code": "    gb_s = requests * BILLED_S * FLEX_GB\n    if ALWAYS_READY:\n        flex = (ALWAYS_READY * r['flex_always_ready_month'] + gb_s * r['flex_gb_second']\n                + requests / 1e6 * r['flex_million_executions'])\n    else:\n        flex = (max(gb_s - r['flex_free_gb_seconds'], 0) * r['flex_gb_second']\n                + max(requests - r['flex_free_executions'], 0) / 1e6 * r['flex_million_executions'])\n    return requests, {'two VMs': vm, 'Container Apps': ca, 'App Service': plan,\n                      'Functions Flex': flex, 'AKS': aks}\n\n\n", "note": "Flex Consumption pays per request and nothing for an hour nobody calls. With always ready instances set, it adds their baseline and **drops the free grants**, because Microsoft's billing table says always ready billing has none."}, {"code": "def main():\n    with open('rates.json') as f:\n        r = json.load(f)\n    profiles = {} if sys.argv[1:] else dict(PROFILES)\n    for arg in sys.argv[1:]:\n        name, rates = arg.split('=')\n        profiles[name] = [float(x) for x in rates.split(',')]\n        if len(profiles[name]) != 24:\n            sys.exit(f'{name}: a profile is 24 rates, one per hour')\n    columns = month(PROFILES['busy'], r)[1]\n    print(f'{\"profile\":<9}{\"requests\":>10}' + ''.join(f'{k:>15}' for k in columns))\n    for name, profile in profiles.items():\n        requests, cost = month(profile, r)\n        print(f'{name:<9}{requests / 1e6:>9.2f}M' + ''.join(f'{v:>15.2f}' for v in cost.values()))\n", "note": "Reads the rates, takes the profiles from the command line if there are any, and prints one row per profile: the month's requests in millions, then the five bills."}, {"code": "    floor = LEAST * r['vm_hour'] * HOURS\n    per_request = BILLED_S * FLEX_GB * r['flex_gb_second'] + r['flex_million_executions'] / 1e6\n    grants = (r['flex_free_gb_seconds'] * r['flex_gb_second']\n              + r['flex_free_executions'] / 1e6 * r['flex_million_executions'])\n    even = (floor + grants) / per_request\n    print(f'\\nFunctions costs what two VMs cost at {even / 1e6:.2f}M requests a month,'\n          f' {even / (HOURS * 3600):.2f} a second on average.')\n    print(\"USD a month, at the rates in rates.json: illustrative, not Azure's prices.\")\n\n\nif __name__ == '__main__':\n    main()\n", "note": "The break-even: the monthly volume at which Flex costs exactly what the two virtual machines cost, as a total and as an average rate. A free grant moves it up by the requests it pays for. The last line repeats the warning, so a table copied anywhere carries it."}]}
```

Run it from `~/azure`, where it finds `rates.json`:

```
ana@laptop:~/azure$ python3 compare.py
profile    requests        two VMs Container Apps    App Service Functions Flex            AKS
steady       78.84M         146.00          89.49         219.00        4131.22         511.00
office       59.13M         146.00          52.04         219.00        3098.41         511.00
nightly       3.07M         146.00          15.82         219.00         160.66         511.00
webhook       0.13M         146.00          58.75         219.00           6.89         511.00
busy       1051.20M         146.00         667.65         219.00       55082.88         511.00

Functions costs what two VMs cost at 2.79M requests a month, 1.06 a second on average.
USD a month, at the rates in rates.json: illustrative, not Azure's prices.
```

The requests column is millions a month, and every other number is US dollars a month at the rates
in the file. **The five columns are five answers to the same question**, and the only thing that
differs between the rows is the profile.

## Reading the table

Three columns do not move. Two virtual machines cost 146.00 on every row, the App Service plan
219.00, AKS 511.00: each is a fixed number of machines paid by the hour, and none of these profiles
outgrows the floor of two, or of three nodes. **A fixed column is the same bill for 0.13 million
requests and for 1,051 million**, which is a bargain on the busy row and a waste on the webhook. The other two columns move with every row.

**steady, office and nightly: Container Apps.** 89.49, 52.04 and 15.82 USD. Two replicas of half a
core carry the steady 30 a second and the office 60, and the free grants of the subscription pay
the first 180,000 vCPU-seconds and 360,000 GiB-seconds. On the office and nightly rows the silent
hours are billed at the idle rate, a quarter of the active one in this file, which is why the
nightly service costs less than the price of one virtual machine.

**webhook: Functions, by a distance.** 0.13 million requests cost 6.89 USD on Flex, against 58.75 for
Container Apps. The webhook never has an idle hour, so both replicas are billed as active all
month; a function is billed for 131,400 seconds of execution and nothing for the rest.

**busy: the virtual machines.** At 400 a second the two `D2s_v5` machines are exactly full, and
they still cost 146.00. Container Apps costs 667.65: eight replicas run all day, and 1,049.20
million requests past the free two million cost 419.68 on their own.

**And Functions loses every row but one**: by ten times on the nightly row and by more than forty
on the others. That is the shop's assumption meeting Flex's meter: a request is billed as one second of a 2 GB instance, the
documented minimum, and a Python app takes one request per instance at a time. 78.84 million
requests a month are 157.68 million GB-seconds. The column is an upper bound, and the next
subsection says what moves it.

AKS costs more than Container Apps on every row but busy, and it would be wrong to read that as a
verdict on AKS. Three nodes of 4 vCPUs are the system pool lesson 11 recommends, and the Standard
tier is the one lesson 11 gives production. They are sized for a cluster's own system pods and for
many services, and one small API uses a corner of them. The next service the shop adds costs nothing more on AKS until the
nodes are full, and a new line on every other column.

## What zero is worth

The program keeps two replicas even when nobody calls. Lesson 8's file let the shop go to zero, and
one line of `compare.py` says which it is:

```
ana@laptop:~/azure$ sed 's/^CA_MIN = 2 /CA_MIN = 0 /' compare.py > zero.py
ana@laptop:~/azure$ python3 zero.py
profile    requests        two VMs Container Apps    App Service Functions Flex            AKS
steady       78.84M         146.00          57.95         219.00        4131.22         511.00
office       59.13M         146.00          42.18         219.00        3098.41         511.00
nightly       3.07M         146.00           0.43         219.00         160.66         511.00
webhook       0.13M         146.00          27.22         219.00           6.89         511.00
busy       1051.20M         146.00         667.65         219.00       55082.88         511.00

Functions costs what two VMs cost at 2.79M requests a month, 1.06 a second on average.
USD a month, at the rates in rates.json: illustrative, not Azure's prices.
```

The nightly service falls from 15.82 to 0.43 USD: its two busy hours run on one replica inside the
free grants, the 0.43 left is the requests past two million, and the 22 silent hours cost nothing.
The office tool falls from 52.04 to 42.18, its fifteen silent hours now free. That is what zero is
for. **Two other rows fell for a different reason**: with no floor, the steady service runs on one replica, and 89.49 becomes 57.95
because there is no second copy, not because anything went idle. That is availability sold, and it
belongs in the decision as such. The webhook halves for the same reason and never reaches zero at
all, because its calls arrive every twenty seconds. The cool-down lesson 8 read in the
documentation waits 300 seconds before the last replica goes, so a call every twenty seconds keeps
one replica up for ever, and Flex still costs a quarter of it.

The price of zero is paid by the first request after it: a cold start while a replica is
provisioned (lesson 8), or while a function's host and worker start (lesson 16).

## The break-even

The second-last line answers the question people actually ask: below what volume is a function
cheaper than keeping machines? Here a request costs one second of 2 GB at 0.000026 USD, which is
0.000052, plus 0.40 per million executions, 0.0000524 in all. Two virtual machines cost 146.00 a
month whatever happens. **Below 2.79 million requests a month, 1.06 a second on average, Functions is
the cheaper of the two**; above it, the machines are. The break-even moves with every assumption
in the file. A 512 MB instance bills a quarter of the GB-seconds and pushes it up nearly fourfold. A
free grant pushes it up by the requests the grant pays for. And a higher HTTP concurrency changes
the count itself, because Flex bills an instance's memory while it is executing, not per request:
lesson 16 followed Microsoft's example of ten requests in flight costing one instance instead of
ten. Change `FLEX_GB` or the grants, run it again, and see; that is the reason the program exists.

## Putting real rates in

**`rates.json` is the only file to change**, and the program needs no edit when you do. The two
machine rates come from the Retail Prices API of lesson 1, which needs no account. This request asks
for the four-vCPU size of the AKS column in São Paulo; change the name to `Standard_D2s_v5` for the
other one. It was not run in this course:

```sh
curl -s "https://prices.azure.com/api/retail/prices?\$filter=armRegionName%20eq%20'brazilsouth'%20and%20armSkuName%20eq%20'Standard_D4s_v5'" | jq '.Items[] | {productName, meterName, retailPrice, unitOfMeasure}'
```

Take the pay-as-you-go Linux item, whose unit is an hour. The per-second meters of Container Apps
and Functions, the plan instance of App Service and the AKS tier have no virtual machine size to
filter on; read them on each service's pricing page for `brazilsouth`, or in the pricing
calculator, and write them into the file with the units it already uses. Then run `compare.py`
again. Until then, the table above is a lesson in shapes.

## What the program leaves out

Four things, each of which can move a close result:

- **The front door.** Two virtual machines need a load balancer or an Application Gateway in front
  of them, which `azure-foundations` lesson 22 prices; AKS needs an ingress or a gateway, which
  lesson 14 is about. Container Apps, App Service and Functions each come with their own.
- **Discounts.** The API's answer for a machine size lists reservations beside pay as you go, and a
  steady load is what they reward; Spot, lesson 5, discounts work that can be interrupted. None of
  them is in the file.
- **Scaling as it really behaves.** The program sizes every hour perfectly. A scale set reacts
  minutes late (lesson 4), Container Apps waits 300 seconds before it removes replicas (lesson 8),
  and a cold function adds its start to the bill. Real fleets run a little more than this.
- **The grants are per subscription.** Container Apps' free seconds and requests are shared by every
  app in the subscription, so the second app the shop deploys finds them already spent.

**None of this makes the numbers wrong; it makes them approximate.** A comparison that comes out
within 20% either way is a tie, and a tie is decided by the next two sections: what the move costs,
and what the team can run.
