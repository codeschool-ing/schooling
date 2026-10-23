---
title: Grouping, waiting and merging without a person
version: 1
---

Both bots can be told to merge their own pull requests: Renovate with `automerge` in a package rule,
and on GitHub any pull request, Dependabot's included, with the repository's auto-merge, which merges
the moment the required checks pass. **Auto-merge is a decision to let the pipeline be the
reviewer**, and the previous section is the reason to make it narrowly. It is only as good as what
the pipeline checks, and the pipeline checks what its stages were written to check, not what a
person reading the diff would notice.

### The three settings that decide the noise

The configurations in this lesson set three things, and each one trades something.

**Grouping** puts several updates in one pull request. One review instead of five, and one run of the
pipeline instead of five, at a price: when the group fails, somebody has to find which of the five
broke it. Grouping minor and patch updates and leaving majors alone is the common middle, because a
major version is the one that is allowed to break things, and it deserves a pull request whose
failure has one possible cause.

**A schedule** decides when proposals arrive. A team that sees eight pull requests trickle in through
the week reviews them between other work, which means half-reading them; a team that gets them on
Monday morning can give them an hour on purpose. Security updates ignore the schedule in both bots,
and should.

**A cooldown**, Dependabot's `cooldown` and Renovate's `minimumReleaseAge`, decides how old a release
must be before it is proposed. It is the same idea as lesson 15's `--exclude-newer` date, applied
every week instead of once: let other people install a release first, and let the registry's own
checks and the community's reports catch a bad one before your bot reaches for it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"sp-l18-wait\" aria-label=\"Two timelines over thirty days. A version update: a release on day 0, a cooldown of fourteen days in which the bot holds it back, then a pull request on the first scheduled Monday after day 14. A security update: an advisory published on day 20, and the pull request opened the same day, with no cooldown and no schedule.\"><defs><marker id=\"sp-l18-wait-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><line x1=\"190\" y1=\"170\" x2=\"670\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"190\" y1=\"166\" x2=\"190\" y2=\"174\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"190\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">day 0</text><line x1=\"302\" y1=\"166\" x2=\"302\" y2=\"174\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"302\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">day 7</text><line x1=\"414\" y1=\"166\" x2=\"414\" y2=\"174\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"414\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">day 14</text><line x1=\"526\" y1=\"166\" x2=\"526\" y2=\"174\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"526\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">day 21</text><line x1=\"638\" y1=\"166\" x2=\"638\" y2=\"174\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"638\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">day 28</text><text x=\"10\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">version update</text><rect x=\"190\" y=\"48\" width=\"224\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"302\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">cooldown: 14 days</text><line x1=\"190\" y1=\"40\" x2=\"190\" y2=\"80\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"190\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">release</text><rect x=\"478\" y=\"46\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"578.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">pull request, next Monday</text><path d=\"M414 60 L476 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l18-wait-ah-phosphor)\"></path><text x=\"10\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">security update</text><line x1=\"510\" y1=\"106\" x2=\"510\" y2=\"146\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"510\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">advisory</text><rect x=\"522\" y=\"112\" width=\"160\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">pull request the same day</text></svg>", "caption": "The cooldown and the schedule slow the routine updates down on purpose. An advisory skips both."}
```

### The cooldown's cost, said plainly

A cooldown delays the good releases too. A bug fix you are waiting for arrives two weeks late, and so
does the fix for a vulnerability that has no advisory yet, because a fix often ships before the
advisory is published. Two things keep the cost bounded. Once an advisory is published, a security
update is proposed straight away in both bots, and the branch in the previous section showed that
the pipeline breaks on it whatever the bot does. And a person can always update by hand, which is
what the cooldown exists to make deliberate rather than accidental.

### What may merge with nobody looking

The rule that follows from the whole course is short: **auto-merge only what the pipeline can judge
completely**. For linkbox that gives a table.

| update | auto-merge? | why |
|---|---|---|
| a patch to a test-only package (pytest, pluggy) | yes, after the cooldown | it runs only in the test stage; if the tests pass, it did its job |
| a patch or minor release of Flask, Werkzeug or gunicorn | no | the tests cover the routes, not every behaviour the release can change |
| a major version of anything | no | a major version is allowed to break things the tests do not look at |
| a new base image digest | no | the image scan and the signature run, but nothing tests the new operating system packages' behaviour |
| a new commit for a pinned action | no | the action runs with the workflow's permissions, so its code is what lesson 16 asked you to review |
| a security update with the gate breaking without it | no, but first in the queue | the fix is urgent and still needs the same reading |

The table is a judgement about linkbox, and another project's will differ. A library with a test
suite that covers its public interface completely could auto-merge minor updates of its
dependencies; a service whose tests are thin should auto-merge nothing. The test is the same one the
first section asked: for this kind of update, does a green pipeline mean it is right?

Two conditions make any auto-merge safe enough to switch on. The branch must be protected, so the
merge waits for the checks, all of them, and a check that did not run counts as failed, which is
lesson 7's fail-closed rule applied to merging. And the bot's own permissions must be narrow: a bot
that can push to `main` directly does not need auto-merge to bypass the pipeline.
