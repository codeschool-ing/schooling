---
title: What costs energy on a phone
version: 1
---

**The common picture is that an app costs battery while it computes, so a fast app is a frugal
one.** On a phone the processor is rarely what empties the battery. The expensive parts are the
ones that talk to the outside world or light up: the radio, the satellite receiver, the screen.
And the most expensive habit is not doing a lot of work. It is doing a little work often, because
each time wakes something up that then takes a while to go back to sleep.

| what | why it costs | the habit that wastes it |
|---|---|---|
| the mobile radio | it powers up for every connection and stays up after the last byte | small requests, often |
| GPS | a satellite fix keeps a receiver running | asking for the precise position continuously, when the city would do |
| the screen | the largest single drain while it is on | keeping it awake when the user has stopped looking |
| a wake lock | keeps the processor running with the screen off | holding one and forgetting to release it |
| polling | wakes all of the above on a timer | asking "anything new?" every minute |

## The radio, which stays awake after you finish

**The radio is the one most programmers have never been told about, and it is the one that
changes how you write a sync.** Android's guide to network access, as read on 30 October 2026,
describes the state machine of a typical 3G radio with timings from the carrier AT&T. The radio has
three states: *full power* while it transfers; *low power*, which cuts the drain by around half;
and *standby*, which costs very little. Moving up from standby to full power takes more than two
seconds, so the radio does not drop down the moment a transfer ends. It waits.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l15-tail\" aria-label=\"One small transfer on a typical 3G radio, along a time line in seconds. The transfer takes about one second at full power. The radio then stays at full power for 5 more seconds, then at low power, about half the drain, for 12 seconds, and only then drops to standby. In all, at least 18 seconds of drawing energy for one transfer.\"><rect x=\"40\" y=\"60\" width=\"32\" height=\"50\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"72\" y=\"60\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"152.0\" y=\"78.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">full power,</text><text x=\"152.0\" y=\"91.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">waiting</text><rect x=\"232\" y=\"60\" width=\"384\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"424.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">low power: about half the drain</text><rect x=\"616\" y=\"60\" width=\"80\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"656.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">standby</text><text x=\"56.0\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">transfer</text><path d=\"M40 130 L696 130\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M40 126 L40 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"40\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M72 126 L72 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"72\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M232 126 L232 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"232\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M616 126 L616 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"616\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18</text><text x=\"692\" y=\"146\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">seconds</text><text x=\"360\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a typical 3G radio, as Android's guide to network access describes it</text></svg>", "caption": "The transfer is the short part. The radio is drawing energy for at least 18 seconds per transfer, whatever the transfer carried."}
```

For that radio, the same page gives the waits: full power for the length of the transfer **plus 5
seconds**, then **12 seconds** at low power, so every data transfer keeps the radio drawing energy
for at least 18 seconds. Its example is the habit this lesson is about. An app that makes a
one-second transfer three times a minute keeps the radio permanently awake; the same data sent as
one three-second transfer a minute leaves it in standby for 40 seconds of every minute.

The page is just as clear that **these numbers belong to one radio on one network**. The tail times
vary with the technology, 3G, LTE or 5G, and the carrier configures them. So the exact seconds are
not something to build on. The shape is: a radio woken for one byte costs nearly as much as a radio
woken for many, and the cost of a request is mostly the cost of waking up for it.

## Wake locks and polling, the two that are your fault

**A wake lock is a promise to the system that you need the processor, and the battery pays until
you take the promise back.** On Android an app can hold one to keep working with the screen off.
The danger is a code path that acquires it and an error that skips the release. A phone with the
screen off and a lock held does not sleep, and nothing on screen says why.

**Polling is a timer that wakes everything else.** "Every minute, ask the server whether anything
changed" sounds modest, and on the radio above it is a wake-up every minute of the day: 1,440 of
them, each with its tail. The alternative is to be told: the server sends a push message when
something did change, which lesson 17 is about, and anything else waits for a moment the system
chooses, which is the next section.

## The user can see who did it

**Both systems show the user a list of apps ranked by the battery they used.** That list is where
a careless sync is found, by the person whose phone died by four in the afternoon, and the remedy
they have is the uninstall button. It is the reason the systems in the next section are as strict
as they are, and the reason to treat the battery as something you borrow.
