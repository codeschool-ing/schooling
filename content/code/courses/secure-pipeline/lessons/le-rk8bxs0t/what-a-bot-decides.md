---
title: What a bot can decide, and what it cannot
version: 1
---

Lesson 15 made linkbox's dependencies a lock: every version pinned, every file's hash written down,
resolved as of one date. A lock does not age gracefully. The day after it is compiled, a new release
of something in it is published; a month later an advisory names one of its versions. **Somebody has
to keep proposing the next lock**, and that work is regular, dull and easy to forget, which is the
description of a job for a program.

Programs that do it are called dependency bots. The two this lesson uses are GitHub's
**Dependabot** and Mend's **Renovate**. Both read a repository's dependency files, ask the package
indexes what is newer, and open a pull request per update with the files changed. The pull request
then goes through the same pipeline as anybody's change.

### The wrong picture

The common picture is that the bot fixes vulnerabilities. It does not fix anything. It **proposes**
a version, and whether the proposal is right is decided somewhere else. A bot that merged its own
proposals would be a program that changes production code on the strength of a version number, and
version numbers are written by strangers.

So the useful question about each step of remediation is who decides it:

| step | who decides | how |
|---|---|---|
| a newer version exists | the bot | it asks the index |
| an advisory applies to a pinned version | a scanner (`pip-audit`, lesson 5) | it compares versions with advisories |
| the change is written correctly | the bot, and the pipeline checks it | the tests install from the lock and the build runs |
| the new version still behaves | the tests, as far as they reach | lesson 1's suite, and whatever it does not cover nobody checked |
| the advisory is still a risk without the update | a person | lesson 7's gate and exceptions |
| the change goes in | a person, or a rule a person wrote | review, or auto-merge for what the pipeline can judge |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"sp-l18-loop\" aria-label=\"Who decides each step of remediating a dependency. A new release or an advisory is found by the package index or a scanner. A bot proposes a change as a pull request. The pipeline judges it with the tests and the security gates; when it breaks, the change goes back to a person. A person, or an auto-merge rule a person wrote, merges what passed.\"><defs><marker id=\"sp-l18-loop-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l18-loop-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l18-loop-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"30\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">found</text><text x=\"90.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">index, scanner</text><rect x=\"190\" y=\"30\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">proposed</text><text x=\"270.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the bot</text><rect x=\"370\" y=\"30\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">judged</text><text x=\"450.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tests and gates</text><rect x=\"550\" y=\"30\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">merged</text><text x=\"630.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a person, or a rule</text><path d=\"M170 58 L188 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l18-loop-ah-paper-dim)\"></path><path d=\"M350 58 L368 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l18-loop-ah-paper-dim)\"></path><text x=\"270\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">pull request</text><path d=\"M530 58 L548 58\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l18-loop-ah-phosphor)\"></path><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">passes</text><path d=\"M450 86 L450 130 L270 130 L270 88\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l18-loop-ah-amber)\"></path><text x=\"360\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">breaks: a person takes over</text></svg>", "caption": "The bot owns one box of four. The pipeline decides whether its change is right, and a person decides whether it goes in."}
```

### What a bot cannot know

**Whether the new version is safe to run.** A version number says what its author claims changed.
`3.1.8` to `3.1.9` promises a fix; it cannot promise that nothing else moved, and lesson 12 placed
real incidents on the supply chain where the new version was the attack. Lesson 15's resolution
date and this lesson's cooldown exist because the newest release is also the least examined one.

**Whether the update matters.** A bot proposes every release with the same urgency, the patch to a
test plugin and the fix to the web framework alike. A scanner can tell the second from the first,
and lesson 5 showed that even an advisory needs reading before anybody knows whether it applies.

**Whether your tests cover what changed.** The pipeline judges the bot's change exactly as well as
the tests cover the code that uses the dependency. linkbox's suite exercises every route, so a
Flask update that broke routing would fail it. A change in how gunicorn handles a slow client would
pass every test linkbox has.

**How the lock was built.** This is the one the next sections run into for real. A tool that edits a
version number in a file it does not understand writes a change that looks right and is not, and
only the pipeline notices.

### What this lesson does

It writes the configuration for both bots, checks it in the pipeline, and watches what each
proposes. Dependabot runs only on GitHub, so it is taught from GitHub's documentation and **was not
run**, though its file passes through zizmor here like any workflow. Renovate has a mode that runs on
your own machine against a local repository and changes nothing, and it was run. Then a branch with
a month-old lock gets the fix a bot would propose, `pip-audit --fix`, and the pipeline judges it.
The last two sections are about the people at the end of all this: what may merge without them, and
how many of these pull requests they can actually read.
