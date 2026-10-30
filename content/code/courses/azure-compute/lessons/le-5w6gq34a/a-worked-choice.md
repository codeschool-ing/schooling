---
title: A worked choice, from profile to decision
version: 1
---

The pieces of this lesson only earn their keep when they decide something, so here is one decision
taken end to end. **The case is invented, its rates are illustrative and its totals are an
example**; the method is the part to keep.

## The case

The shop in São Paulo runs its order API on one virtual machine in `brazilsouth`, as it has for
three years. Three developers maintain it, and lessons 7, 8, 11 and 18 have already run its image
four ways. Two more things live on the same machine. A cron job builds the **sales report** every
night at 23:30, which takes about six minutes. And the finance team asks for the **finance
export** from an internal page a few times a day: a day's orders come back in about 20 seconds, and
a whole month's, when finance closes the month, take up to five minutes while the page waits.

The request counts in the web server's log for the busiest week give a profile: a trickle of 2 a
second through the night, a climb from 07:00, a lunch shoulder, and an evening peak of 80 a second
from 18:00 to 20:00.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"The shop&#x27;s request profile as 24 bars: 2 requests a second from midnight to 07:00, rising to 40 at lunch, falling to 20 in the afternoon, and peaking at 80 from 18:00 to 20:00 before falling back to 2 at 23:00. Two dashed lines cross it: at 50 a second, what one Container Apps replica carries, which only the four evening hours from 17:00 to 21:00 exceed; and the shop&#x27;s average of 26.5 a second.\"><rect x=\"81.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"106.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"131.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"156.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"181.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"206.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"231.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"256.0\" y=\"205.0\" width=\"23.0\" height=\"25.0\" fill=\"var(--phosphor)\"></rect><rect x=\"281.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"306.0\" y=\"155.0\" width=\"23.0\" height=\"75.0\" fill=\"var(--phosphor)\"></rect><rect x=\"331.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"356.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"381.0\" y=\"155.0\" width=\"23.0\" height=\"75.0\" fill=\"var(--phosphor)\"></rect><rect x=\"406.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"431.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"456.0\" y=\"155.0\" width=\"23.0\" height=\"75.0\" fill=\"var(--phosphor)\"></rect><rect x=\"481.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"506.0\" y=\"80.0\" width=\"23.0\" height=\"150.0\" fill=\"var(--phosphor)\"></rect><rect x=\"531.0\" y=\"30.0\" width=\"23.0\" height=\"200.0\" fill=\"var(--phosphor)\"></rect><rect x=\"556.0\" y=\"30.0\" width=\"23.0\" height=\"200.0\" fill=\"var(--phosphor)\"></rect><rect x=\"581.0\" y=\"80.0\" width=\"23.0\" height=\"150.0\" fill=\"var(--phosphor)\"></rect><rect x=\"606.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"631.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"656.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><path d=\"M80 230 L680 230\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80 30 L80 230\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"72\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"72\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><text x=\"72\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">80</text><path d=\"M80 105.0 L680 105.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"88\" y=\"97.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">what one replica carries, 50 a second</text><path d=\"M80 163.8 L680 163.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"88\" y=\"175.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the shop's average, 26.5 a second</text><text x=\"80.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><text x=\"230.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">06:00</text><text x=\"380.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><text x=\"530.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><text x=\"680.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><text x=\"380.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requests per second, hour by hour</text><text x=\"555.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">peak 80, 18:00 to 20:00</text><text x=\"167.5\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a trickle of 2</text></svg>", "caption": "Only four hours of the day need a second replica, and the minimum of two covers them. The trickle keeps both replicas off the idle rate all night."}
```

## The arithmetic

The profile goes into `compare.py` as an argument, the 24 rates from midnight:

```
ana@laptop:~/azure$ python3 compare.py shop=2,2,2,2,2,2,2,10,20,30,40,40,30,20,20,30,40,60,80,80,60,40,20,2
profile    requests        two VMs Container Apps    App Service Functions Flex            AKS
shop         69.64M         146.00          85.81         219.00        3649.24         511.00

Functions costs what two VMs cost at 2.79M requests a month, 1.06 a second on average.
USD a month, at the rates in rates.json: illustrative, not Azure's prices.
```

Container Apps is the cheapest at 85.81 USD a month, against 146.00 for the two virtual machines,
and **the peak fits inside the minimum**: 80 a second needs two replicas of 50, and two is
the minimum the program keeps anyway. The figure shows it: only four hours of the day go above what
one replica carries. Functions costs 3,649.24, because 69.64 million requests a month is 25 times
the break-even of the last line, and the shop's average of 26.5 a second is 25 times its 1.06.

The trickle costs something, and the same profile with silent nights shows how much:

```
ana@laptop:~/azure$ python3 compare.py shop=0,0,0,0,0,0,0,10,20,30,40,40,30,20,20,30,40,60,80,80,60,40,20,0
profile    requests        two VMs Container Apps    App Service Functions Flex            AKS
shop         67.89M         146.00          69.34         219.00        3557.44         511.00

Functions costs what two VMs cost at 2.79M requests a month, 1.06 a second on average.
USD a month, at the rates in rates.json: illustrative, not Azure's prices.
```

16.47 USD a month separate the two Container Apps figures, all of it the replicas billed at the
active rate through eight hours when they could have been idle. It changes nothing here. It is
still the right reflex: before counting on the idle rate or on zero, find out whether the quiet
hours are really quiet. The shop's are not, and the trickle turns out to be an uptime monitor and
the phone app polling for order status.

## The constraints

The price says Container Apps, by a margin no other column comes near. Section 04's list either
confirms that or overrules it:

- **the month's export takes five minutes**, and Container Apps' ingress gives a request 240
  seconds. It cannot stay a page that waits. It becomes a job: the page puts a message on a Service
  Bus queue (lesson 20), an event-driven Container Apps job (lesson 8) builds the file, and finance
  collects it when it is ready. The same change would be forced on Functions or App Service, whose
  limit is 230 seconds; only a virtual machine would let it stay as it is;
- **the report takes six minutes**, which fits everything, including Flex Consumption's default
  timeout of 30 minutes. As a scheduled Container Apps job, at 1 vCPU and 1 GiB like lesson 7's
  group, it runs 360 seconds × 30.42 nights: 10,950 vCPU-seconds and as many GiB-seconds a month.
  The API has already used the free grants, so that is about 0.24 USD at the file's active rates. Lesson 8
  showed that its schedule is read in UTC, so 23:30 is `30 2 * * *`;
- **the orders live in memory**, and section 04 showed what two copies do to them. They move to a
  database whichever column wins, since every option in the table runs two of something;
- **the report's files live on the machine's disk**, and go to an Azure Files share as lesson 7
  mounted it. A week of work, whichever column wins;
- the team knows containers and has never run a function in production, which lessons 15 to 17
  show is a skill of its own.

## The decision

**The API goes to Container Apps with a minimum of two replicas; the report runs there as a
scheduled job, and the export as an event-driven job, in the internal environment lesson 8 gave
it.** It is the cheapest option and the cheapest move: the image exists, the code change is the one
every option needs, and there is no new way of packaging to learn. The virtual machines would cost
60.19 USD a month more and hand back the operating system. Functions would cost thousands more and
a rewrite into handlers. The minimum of two buys availability and also means no cold start for the
customer who orders at 03:00.

**A decision like this is only finished when it names what would reopen it.** The first trigger is
growth, and the program can say where it bites. Here is the shop's profile at three times today's
traffic:

```
ana@laptop:~/azure$ python3 compare.py shop3=6,6,6,6,6,6,6,30,60,90,120,120,90,60,60,90,120,180,240,240,180,120,60,6
profile    requests        two VMs Container Apps    App Service Functions Flex            AKS
shop3       208.93M         146.00         159.92         219.00       10947.72         511.00

Functions costs what two VMs cost at 2.79M requests a month, 1.06 a second on average.
USD a month, at the rates in rates.json: illustrative, not Azure's prices.
```

159.92 against 146.00: at that size the virtual machines and Container Apps change places, and two machines, or a
scale set (lesson 4) with reservations, are worth pricing properly. So three things would reopen it:

- **traffic near three times today's**, which the hourly request counts show long before it arrives;
- **real rates.** This decision was made at illustrative ones. Put the real rates in `rates.json`
  and run the same commands. Today Container Apps costs 41% less than the next column; if the gap
  falls under 20%, the price is a tie, and the effort of section 04 decides, which it still wins;
- **a second app in the subscription**, which spends the free grants this table counted on.

None of them is close today, and all three are cheap to watch. Lesson 22 is about writing this
down in a form somebody can find in two years, with the lock-in it accepts beside it.
