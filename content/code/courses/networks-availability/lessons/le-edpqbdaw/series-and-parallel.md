---
title: A chain and a pair
version: 1
---

A request for `www.example.com` in the lab crosses several things in a row: the ISP's router, the DNS
server that turns the name into an address, a load balancer and a web server. **Parts in series
multiply.** The request succeeds only if every one of them is up, so the chain's availability is the
product of theirs, and a product of numbers below one is lower than the lowest of them. Four parts at
99.9% each make 99.6%, before anything unusual has happened.

**Parts in parallel multiply their failures instead.** Two load balancers, either of which can carry the
load, are down together only when both are down at the same time. If each is down 0.1% of the time,
both are down 0.1% of 0.1%, one millionth. That is the arithmetic behind every redundant pair.

This program applies both rules to the lab's data centre. The availabilities in it are assumptions,
round figures for one machine of each kind, and not measurements of anything in the lab:

```schooling-example
{"language": "python", "file": "chain.py", "parts": [{"code": "def series(*parts):\n    \"\"\"Every part has to be up: multiply.\"\"\"\n    up = 1.0\n    for p in parts:\n        up *= p\n    return up", "note": "In series the request needs every part, so the availabilities multiply, and the result is below the weakest of them."}, {"code": "def parallel(*parts):\n    \"\"\"Any one part is enough: it is down only when all of them are.\"\"\"\n    down = 1.0\n    for p in parts:\n        down *= 1 - p\n    return 1 - down", "note": "In parallel it is the unavailabilities that multiply. Two parts down 0.1% of the time are down together 0.0001% of it, if nothing links their failures."}, {"code": "YEAR_MIN = 365 * 24 * 60\nisp, dns, lb, web = 0.999, 0.999, 0.999, 0.99  # assumed, one machine each", "note": "Assumptions, not measurements: three nines for one router, one DNS server or one balancer, two nines for one web server with its software and its deployments."}, {"code": "designs = {\n    \"one of everything\": series(isp, dns, lb, web),\n    \"two lb, three web\": series(isp, dns, parallel(lb, lb), parallel(web, web, web)),\n    \"and two isp, two dns\": series(parallel(isp, isp), parallel(dns, dns),\n                                   parallel(lb, lb), parallel(web, web, web)),\n}", "note": "Three designs of the same site. A design is a series of stages, and each stage is one part or a parallel group of identical ones."}, {"code": "for name, up in designs.items():\n    print(f\"{name:21} {up:.5%}  {(1 - up) * YEAR_MIN:7.1f} min down a year\")", "note": "Each design as a percentage and as the minutes a year it would be down."}], "output": "one of everything     98.70330%   6815.5 min down a year\ntwo lb, three web     99.79990%   1051.7 min down a year\nand two isp, two dns  99.99960%      2.1 min down a year"}
```

Three things show in the output. Doubling the balancers and tripling the web servers took the downtime
from 6815.5 minutes a year to 1051.7. The 1051.7 that remain belong almost entirely to the ISP link and
the DNS server, which are still single: **the weakest serial part sets the ceiling**, however much is
spent on the parts beside it. Only when those two are doubled as well does the figure fall to 2.1
minutes.

And that last figure should not be believed. The formula for a pair assumes the two fail
**independently**, as if the only way both could break at once were coincidence. Real pairs share
things: the same power feed, the same switch, the same software version with the same bug, the same
configuration pushed to both by the same person in the same minute. A fault that takes both at once is
a **common-mode failure**, and it is why two servers in one rack behave more like one server than the
arithmetic says.

So the formula gives the best case, and the design work is making the real case approach it:

| shared thing | what separating it looks like |
|---|---|
| power | two supplies per machine, on two circuits, behind two UPSs |
| the network | the pair on two switches, the site on two ISPs whose cables do not share a duct |
| the place | a second rack, room or site, far enough that one fire or flood does not reach both |
| software | upgrading one twin, waiting, then the other |
| people | a change applied to one side and checked before the other |

The last two rows are the ones outages actually come from, and no amount of hardware helps with them.
**A pair that receives every change at the same moment is one machine with two power cords.**
