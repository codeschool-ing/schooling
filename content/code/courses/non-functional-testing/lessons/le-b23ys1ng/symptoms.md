---
title: Alert on what the user feels
version: 1
---

Some defects only exist with real users: the error that needs a particular account, the slowness
that needs a thousand people at once, the payment provider that fails at 21:00 on a Friday. **No
test before the release could have caught them**, because the conditions did not exist before the
release. Monitoring, lessons 22 and 23, makes them visible. An alert makes somebody look, and the
whole difficulty of alerting is making somebody look at the right things and nothing else.

## Symptoms, not causes

The first alerts a team writes are usually about causes: CPU above 90%, memory above 80%, a disk
three quarters full, a queue longer than a thousand. Each one is about a machine, and each one
fires on nights when every customer is served perfectly well. **A processor at 95% that answers
every booking in time is a processor earning its keep.** And the outage that actually happens is
usually one nobody wrote a cause for: lesson 23's payment provider, slow, with every machine idle.

A symptom is what the user feels, and RED from lesson 22 already lists them:

| | a symptom: page somebody | a cause: look at it in the morning, or on the dashboard |
|---|---|---|
| errors | more than 2% of requests answered with a 5xx | the payment provider's error log has lines in it |
| duration | the 95th percentile of booking above 500 ms | CPU above 90% |
| availability | the synthetic probe failing from two regions | one of three servers restarted |

**Page on symptoms, investigate with causes.** The cause metrics are still collected, still drawn,
and they are what the person who was paged opens next, which is the USE method's job. They just do
not wake anybody up on their own.

## SLOs, and burning through a budget

A threshold like 2% is easiest to defend when it comes from an agreement about the service.
**A service level objective**, an SLO, says how good the service must be over a period: *99.5% of
booking requests succeed, measured over 30 days*. The 0.5% left over is the *error budget*, the
failures the service is allowed. A month of 300,000 booking requests may fail 1,500 of them, and
every failure spends some of that.

That turns the alert into a question about speed. A ratio of 1% spends the budget twice as fast as
the SLO allows, which would exhaust it in fifteen days: worth a ticket, not a phone call at night.
A ratio of 2% exhausts it in about a week. A ratio of 7.2% is a *burn rate* of 14.4, which spends a
whole month's budget in about two days; that is the rate Google's SRE workbook uses for its fastest
page. Alerting on the burn rate rather than on a fixed ratio gives every threshold a reason, and
lets a slow, steady leak open a ticket while a fast one wakes somebody.

Lesson 1's requirement is the simpler form, a fixed 2%, and it is what the next section writes. The
SLO version is the same rule with a number derived instead of chosen.

## Waiting, and the time budget

A ratio that touches 2% for one scrape and falls back is noise. **`for:` makes a rule wait** until
the condition has held for a stated time before it fires. Too short, and every blip pages
somebody; too long, and the alert arrives after the customers have given up and written in.

Lesson 1 gave the alert five minutes, counted from the moment the error ratio passes 2%. Those five
minutes are spent in several places, and each is a setting somebody chose:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l24-budget\" aria-label=\"A time line of five minutes, starting when the five-minute error ratio passes 2%. A few seconds go on scraping and evaluating the rule. Then two minutes of for, while the alert is pending. Then 30 seconds of Alertmanager group_wait. Then the paging service rings a phone, a few seconds more. The rest, a little over two minutes, is the margin for a person to wake and acknowledge before the five minutes are up. Below it, the same line with for set to five minutes: the for alone reaches the end of the five minutes, and the notification arrives after it.\"><text x=\"60.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the ratio passes 2%</text><text x=\"660.0\" y=\"26.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">5 minutes</text><path d=\"M60.0 36.0 L60.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M660.0 36.0 L660.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"60.0\" y=\"56.0\" width=\"20.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><rect x=\"80.0\" y=\"56.0\" width=\"240.0\" height=\"34.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"200.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">for: 2m</text><rect x=\"320.0\" y=\"56.0\" width=\"60.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"350.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">group_wait</text><rect x=\"380.0\" y=\"56.0\" width=\"20.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><rect x=\"400.0\" y=\"56.0\" width=\"260.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"530.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">margin to wake and acknowledge</text><text x=\"70.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">scrape, evaluate</text><text x=\"390.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">phone rings</text><rect x=\"60.0\" y=\"156.0\" width=\"20.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><rect x=\"80.0\" y=\"156.0\" width=\"580.0\" height=\"34.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"370.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">for: 5m</text><text x=\"668.0\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">then</text><text x=\"360.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">with for: 5m the requirement is broken before anybody is told</text></svg>", "caption": "Lesson 1's five minutes, spent. Each block is a setting somebody chose."}
```

Prometheus has to scrape the failures and evaluate the rule, a few seconds each at this course's
intervals. `for: 2m` holds it for two minutes. Alertmanager waits 30 seconds to group it with
others. The paging service rings a phone. What is left is the margin for a person to wake up and
acknowledge. **With `for: 5m`, the requirement is already broken before anybody is told**, which
the next section proves with a test.

## Fewer alerts, so that each one is read

**Alert fatigue** is what happens to a team paged for things that need no action: it stops
reading the pages. The alert that matters arrives in a stream of ones that did not, at 03:00, and
it is acknowledged and ignored with the others. Many accounts of an outage that the monitoring
caught and nobody acted on describe exactly this.

The rules against it are short. **Every page must need a human, now.** If the right response is
"look tomorrow", it is a ticket. If nobody can do anything about it, it is a graph. If it fires
weekly and is always fine, the threshold is wrong or the alert should go, and deleting an alert is
as much a part of the work as writing one. A team that counts its pages per week, and treats a
rising count as a defect, keeps the next one worth reading.
