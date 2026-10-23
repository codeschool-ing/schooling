---
title: By API, an answer now if everybody is up
version: 1
---

A call is the integration every developer already knows. One system sends a request, the other does
the work and answers, and the caller carries on with the answer in hand. Joana spent eight years
building services that called each other this way, and her first fix at Serra Alta, in lesson 1, was
one: instead of a stock file written every hour, the Portal B2B now asks SAP for available stock when
a bakery checks out. **An API gives the caller a current answer at the moment it needs one. The price
is that the caller, and everything between it and the answer, must be up and fast at that moment.**

Hohpe and Woolf call the style remote procedure invocation, which is the honest name: it makes a call
to another system look like a call to a function in your own. REST and SOAP are both this style. Lesson
8's SOAP envelope and a JSON request over HTTP differ in format, tooling and fashion, and they couple
two systems in time exactly the same way.

## Both up at once

The stock check at checkout does not go from the portal to SAP directly. It goes from the portal to an
ESB flow, which calls SAP, so three systems have to be working for one bakery to see a number. Over the
last twelve months each of the three was available about **99.5%** of the time. That sounds like
three good numbers. The chain is the product of them:

0.995 × 0.995 × 0.995 = 0.98507, so about **98.5%**.

**A chain of calls is less available than its weakest member**, because it fails whenever any one of
them fails. In a 30-day month of 720 hours, 99.5% allows 3.6 hours of outage for each system on its
own; the chain's 1.49% is about 10.7 hours in which a bakery's checkout cannot get a stock figure. The
arithmetic assumes the three fail independently, which they do not quite: the ESB and the portal share
a network, and a bad night for one is often a bad night for both. Lesson 12 develops the sums, and the
ways to buy back availability, properly.

Planned downtime comes on top. SAP stops every Sunday from 01:00 to 05:00 for maintenance, and that
window is not in the 99.5%. Lesson 1's design already knows it: on Sunday nights the portal shows the
last figure it had, with the time it was taken, and confirms the order later. Keep that design in
mind; it turns out to be the answer to more than Sundays.

## Who waits

Every call has somebody waiting at the end of it, and the useful question about any API integration is
**who waits, for how long, and what happens to them when the wait runs out**. In the stock check, the
person waiting is a bakery owner at a checkout page. Each system on the way has a timeout, the longest
it will wait before giving up, and Joana had set them the way most people do: separately, each to a
number that looked sensible on its own.

| hop | timeout | what happens when it runs out |
|---|---|---|
| browser → portal | none set; the bakery waits | the bakery gives up and leaves, or presses the button again |
| portal → ESB | 10 seconds, then two automatic retries | an error page after the third attempt |
| ESB → SAP | 60 seconds, the ESB's default | an error to the portal, which stopped listening long before |

On Friday 2 October 2026, in the closing week, SAP was busy with finance's month-end jobs and the
availability check, which normally answers in under a second, took between 20 and 40 seconds. The
portal waited 10 seconds and gave up; the ESB, with 60 seconds to wait, did not, so SAP went on working
on a request nobody wanted any more. Then the portal retried, which started a second SAP check beside
the first, and then a third.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l09-timeouts\" aria-label=\"A timeline of one checkout on 2 October 2026, from 0 to 60 seconds. The portal calls the ESB three times, each attempt timing out after 10 seconds, at 10, 20 and 30 seconds, and the bakery sees an error page at 30 seconds. The ESB, with a 60-second timeout, keeps each of its three calls to SAP open: the first from 0 to 35 seconds, the second from 10 to 42, the third from 20 to 55. Everything after the portal gave up on each attempt is shaded amber as work nobody is waiting for, and for most of the time SAP is working on three availability checks for one basket.\"><path d=\"M150.0 228.0 L630.0 228.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M150.0 228.0 L150.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"150.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 s</text><path d=\"M230.0 228.0 L230.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"230.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10 s</text><path d=\"M310.0 228.0 L310.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"310.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 s</text><path d=\"M390.0 228.0 L390.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"390.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 s</text><path d=\"M470.0 228.0 L470.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"470.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40 s</text><path d=\"M550.0 228.0 L550.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"550.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50 s</text><path d=\"M630.0 228.0 L630.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"630.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60 s</text><text x=\"14.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">bakery</text><rect x=\"150.0\" y=\"51.0\" width=\"240.0\" height=\"18.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">waiting</text><text x=\"398.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">error page</text><text x=\"14.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">portal → ESB</text><text x=\"14.0\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">timeout 10 s</text><rect x=\"151.0\" y=\"98.0\" width=\"78.0\" height=\"18.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"190.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">try 1</text><rect x=\"231.0\" y=\"98.0\" width=\"78.0\" height=\"18.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">try 2</text><rect x=\"311.0\" y=\"98.0\" width=\"78.0\" height=\"18.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">try 3</text><text x=\"14.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ESB → SAP</text><text x=\"14.0\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">timeout 60 s</text><rect x=\"150.0\" y=\"140.0\" width=\"80.0\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"230.0\" y=\"140.0\" width=\"200.0\" height=\"16.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"436.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">SAP answers at 35 s</text><rect x=\"230.0\" y=\"162.0\" width=\"80.0\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"310.0\" y=\"162.0\" width=\"176.0\" height=\"16.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"492.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">SAP answers at 42 s</text><rect x=\"310.0\" y=\"184.0\" width=\"80.0\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"390.0\" y=\"184.0\" width=\"200.0\" height=\"16.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"596.0\" y=\"192.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">SAP answers at 55 s</text><rect x=\"150.0\" y=\"266.0\" width=\"22.0\" height=\"12.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"180.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">work nobody is waiting for: the portal has already given up</text></svg>", "caption": "One checkout in the closing week. The portal gives up three times; the ESB never does, so SAP ends up checking the same basket three times over while it is slowest."}
```

Between 09:00 and 11:00 that morning, **212 checkouts failed after 30 seconds of waiting**, and SAP
received about three times its usual number of availability checks, at the moment it was least able to
answer them. The retries, meant to make the integration more reliable, multiplied the load on the
system that was already slow. The short cache Joana had added did not help, because a cache only
answers for a product somebody looked at in the last minute, and a bakery's basket is mostly products
nobody else had just asked about.

## Timeouts and retries that work together

Nothing in that incident was a bug. Every system did exactly what it was configured to do, and the
configuration was wrong as a whole. The rules that fix it are short.

**The deeper the hop, the shorter the timeout.** An inner timeout longer than the outer one guarantees
work nobody is waiting for. Serra Alta now gives the ESB 6 seconds to get an answer from SAP and the
portal 8 seconds to get one from the ESB, so the ESB gives up first and says so while the portal is
still listening.

**Retry only what is safe, and not into a system that is struggling.** Asking for stock again is
harmless; placing an order again is not, unless the receiver can recognise the second attempt as the
same order, which lesson 10 is about. And a retry when the cause is overload adds load: if retrying is
right at all, it waits longer between attempts and stops after one or two.

**Decide what the caller does when the answer does not come.** This is the step people leave out,
because it is a business decision, not a technical one. The portal already had an answer, built for
Sunday nights: show the last stock figure with its time, take the order, and confirm it when SAP
answers. From October the portal uses it whenever SAP takes longer than its timeout, and in the
November closing week no checkout failed. **A synchronous integration needs a planned behaviour for
when the other side is slow, and slow is more common than down.**

## When the call is the right style

None of this makes the call a bad style. It is the right one when three things hold together: the
caller cannot carry on without the answer, the answer has to be current, and somebody is waiting for
it. The stock check meets all three, which is why lesson 1 moved it from a file to a call. A quality
certificate that a supermarket asks for by batch number meets all three as well, and the last section
of this lesson gives it an API.

Where one of the three is missing, a call is coupling you pay for without needing it. If nobody is
waiting, as with the 1,900 farm lines that SAP will only use at the end of the month, the call adds a
time dependency to an integration that never needed one. And if the caller does not need an answer
at all, because it only wants to tell other systems that something happened, then making it call
each of them in turn is the next section's subject.
