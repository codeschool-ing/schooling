---
title: A worked choice, from profile to decision
version: 1
---

The pieces of this lesson only earn their keep when they decide something, so here is one decision
taken end to end. **The case is invented and its numbers are an example**; the method is the part
to keep.

## The case

A shop in São Paulo is moving its order API off a single EC2 instance that has run it for three
years. Three developers maintain it. They already build a container image of the API for their own
laptops, the kind of image lessons 8 to 10 work with. Two more things live on the same machine: a
**sales report** that a cron job builds every night, which takes about six minutes, and an
**export** endpoint that the finance team calls a few times a day and that answers in up to 45
seconds. The AWS account was opened this year.

The load balancer's request counts for the busiest week give a profile: a trickle of 2 a second
through the night, a climb from 07:00, a lunch shoulder, and an evening peak of 80 a second from
18:00 to 20:00.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"The shop&#x27;s request profile as 24 bars: 2 requests a second from midnight to 07:00, rising to 40 at lunch, falling to 20 in the afternoon, and peaking at 80 from 18:00 to 20:00 before falling back to 2 at 23:00. Two dashed lines cross it: the shop&#x27;s average of 26.5 a second, and below it the break-even with two Fargate tasks, 21.8 a second.\"><rect x=\"81.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"106.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"131.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"156.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"181.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"206.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"231.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"256.0\" y=\"205.0\" width=\"23.0\" height=\"25.0\" fill=\"var(--phosphor)\"></rect><rect x=\"281.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"306.0\" y=\"155.0\" width=\"23.0\" height=\"75.0\" fill=\"var(--phosphor)\"></rect><rect x=\"331.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"356.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"381.0\" y=\"155.0\" width=\"23.0\" height=\"75.0\" fill=\"var(--phosphor)\"></rect><rect x=\"406.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"431.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"456.0\" y=\"155.0\" width=\"23.0\" height=\"75.0\" fill=\"var(--phosphor)\"></rect><rect x=\"481.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"506.0\" y=\"80.0\" width=\"23.0\" height=\"150.0\" fill=\"var(--phosphor)\"></rect><rect x=\"531.0\" y=\"30.0\" width=\"23.0\" height=\"200.0\" fill=\"var(--phosphor)\"></rect><rect x=\"556.0\" y=\"30.0\" width=\"23.0\" height=\"200.0\" fill=\"var(--phosphor)\"></rect><rect x=\"581.0\" y=\"80.0\" width=\"23.0\" height=\"150.0\" fill=\"var(--phosphor)\"></rect><rect x=\"606.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"631.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"656.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><path d=\"M80 230 L680 230\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80 30 L80 230\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"72\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"72\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><text x=\"72\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">80</text><path d=\"M80 163.8 L680 163.8\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"88\" y=\"155.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the shop's average, 26.5 a second</text><path d=\"M80 175.5 L680 175.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"88\" y=\"187.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">break-even with two tasks, 21.8</text><text x=\"80.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><text x=\"230.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">06:00</text><text x=\"380.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><text x=\"530.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><text x=\"680.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><text x=\"380.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requests per second, hour by hour</text><text x=\"555.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">peak 80, 18:00 to 20:00</text><text x=\"167.5\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a trickle of 2</text></svg>", "caption": "The peak decides how many tasks run; the average decides Lambda's bill. The shop's average sits above the break-even, so the tasks are cheaper."}
```

## The arithmetic

The profile goes into `compare.py` as an argument, the 24 rates from midnight:

```
ana@laptop:~/aws$ python3 prices.py | python3 compare.py shop=2,2,2,2,2,2,2,10,20,30,40,40,30,20,20,30,40,60,80,80,60,40,20,2
profile      requests   EC2 c7g.large    Fargate, Arm     Lambda, Arm     App Runner*
shop           69.64M          162.21           49.60           60.36           56.94

Lambda costs what two Fargate tasks cost at 57.23M requests a month, 21.8 a second on average.
* App Runner is priced in us-east-1: it is not offered in sa-east-1.
```

Fargate is the cheapest at 49.60 USD a month, because the peak of 80 fits in the two tasks the
program keeps anyway. Lambda costs 60.36: 69.64 million requests is above the break-even of 57.23,
and the shop's average of 26.5 a second is above the 21.8 of the last line. App Runner would be
56.94, and **the trickle is why**: two requests a second at 03:00 keep its instances active all
night. The same profile with silent nights shows how much that trickle costs:

```
ana@laptop:~/aws$ python3 prices.py | python3 compare.py shop=0,0,0,0,0,0,0,10,20,30,40,40,30,20,20,30,40,60,80,80,60,40,20,0
profile      requests   EC2 c7g.large    Fargate, Arm     Lambda, Arm     App Runner*
shop           67.89M          162.21           49.60           58.84           41.37

Lambda costs what two Fargate tasks cost at 57.23M requests a month, 21.8 a second on average.
* App Runner is priced in us-east-1: it is not offered in sa-east-1.
```

15.57 USD a month separate the two App Runner figures, all of it the processor
billed at night. It does not matter here, because the account is new and App Runner is closed to it
(lesson 22). It is still the right reflex: before choosing App Runner or Lambda for their idle
hours, find out whether the hours are really idle.

## The constraints

The price says Fargate, narrowly. Section 04's list either confirms that or overrules it:

- the export takes 45 seconds, which no HTTP API integration allows; on Lambda behind API
  Gateway it would have to become a job on a queue. Behind a load balancer and on a task, it works
  as it is, inside the 60 seconds an
  Application Load Balancer waits by default;
- the report takes six minutes, which a function allows, since the limit is fifteen. It could
  be a Lambda function on a schedule, or the same image run once a night as a Fargate task. The
  second needs no new packaging;
- the instance's disk holds the generated reports, and that has to change on any move: they go
  to S3, which in this example is a week of work whichever column wins;
- the team knows containers and has never run a function in production, which lessons 14 to
  18 show is a skill of its own.

## The decision

**The API goes to Fargate as two tasks, the export stays a synchronous endpoint on it, and the
report runs as a scheduled task from the same image.** It is the cheapest option and the cheapest
move, and it needs the smallest change to the code. Lambda loses on price by nearly eleven dollars
a month, and would have cost a queue for the export and a new way of packaging on top.

A decision like this is only finished when it names what would reopen it. Two numbers come straight
out of the program:

- if the average traffic falls below about **21.8 requests a second** and stays there, Lambda
  becomes cheaper, and the price difference grows as it falls;
- if the API grows towards **400 a second**, the busy row of section 03 applies: instances, and a
  Savings Plan, beat tasks.

Neither is close today, and both are cheap to watch. Lesson 24 is about writing this down in a form
somebody can find in two years, with the lock-in it accepts beside it.
