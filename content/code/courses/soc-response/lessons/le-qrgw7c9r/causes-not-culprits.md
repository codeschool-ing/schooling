---
title: Causes, not culprits
version: 1
---

Thursday has an obvious candidate for blame: bruno's password was weak enough to guess. A review that stops
there writes "bruno will choose a better password" as its action, and changes nothing else. The next weak
password, on the next account, works just as well.

A **blameless** review assumes that everybody acted reasonably on what they knew at the time, and asks what
about the *system* let a reasonable action lead to harm. It is not kindness. It is accuracy, and it is how the
review gets the truth: people who expect to be blamed describe what they should have done, and people who do
not describe what they did.

The difference shows in how a finding is written:

| blaming | blameless |
|---|---|
| bruno chose a weak password | `gw` accepted passwords from the whole internet, with no limit on attempts |
| nobody saw the alert for five hours | critical alerts went to a queue nobody watched at night |
| the file server sent 612 MB out | `files` could reach any address on the internet |
| nobody noticed the new key | there was no inventory of keys to compare against |

Each sentence on the right is a **contributing factor**: something that, had it been different, would have
stopped the incident or shortened it. There is rarely one root cause. Thursday needed all four: a password
that could be guessed, *and* a server that let it be tried 57 times, *and* a file server that could send to
anywhere, *and* an alert that reached no one. Removing any one of them would have changed the night.

Asking **"why?"** repeatedly is the usual tool, and it works as long as each answer is about a condition, not a
person. Why did the guessing work? Because passwords were accepted from the internet. Why were they? Because
`gw` was set up from the default configuration, and nobody had decided otherwise. Why not? Because there was
no standard build for servers. That last answer is the one worth an action: it is why lesson 14's fix had to go
into a build.
