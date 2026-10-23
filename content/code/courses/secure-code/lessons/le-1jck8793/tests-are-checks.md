---
title: The tests you already have are security checks
version: 1
---

Every lesson of this course ended with a test that states a refusal: a patient cannot cancel
somebody else's booking, an impossible date is refused, a field the form never had is not stored,
a value is escaped for the place it is written. **Those tests are the project's first and best
automated security checks**, because they state what this particular application must refuse,
which no general tool can know.

They are also the cheapest kind of check to keep. A test runs in a fraction of a second, it fails
with a sentence that says what broke, and it keeps working after everybody who remembers the
original flaw has moved on. That last property is the one that matters for security: **a flaw
that was fixed once and has a test does not come back quietly.**

### What makes a security test worth keeping

| a good security test | a weak one |
|---|---|
| states a refusal: *a patient cannot read message 2* | only states that the feature works |
| uses the value that matters in that context: a quote in an attribute, the 31st of November | uses ordinary data that every version passes |
| checks what was refused **and** that nothing changed (`BOOKINGS[102]` still booked) | checks a status code alone |
| has a name that reads as the requirement | is called `test_cancel_2` |

The second column is how most test suites look, and it is why a project can have high coverage and
still ship lesson 1's flaw. Coverage measures which lines ran, not which refusals were asked for.

### Two more kinds of check

Tests know the application and nothing else. Two other kinds of tool know the opposite: what is
risky in **any** Python program, and what is published about **any** package. This lesson adds
one of each and runs all three from one command.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l19-layers\" aria-label=\"Three automated checks and what each one reads. pytest runs the tests, which state what the application must do and must refuse. bandit reads the source code without running it and reports calls known to be risky. pip-audit reads the list of dependencies and reports published advisories. All three run from one command, check.sh, before every commit. What none of them reads is whether a route checks whose data it serves, which stays with the review of lesson 18.\"><defs><marker id=\"l19-layers-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"260\" y=\"14\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">check.sh</text><text x=\"475\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">one command, before every commit</text><rect x=\"20\" y=\"100\" width=\"210\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pytest</text><rect x=\"20\" y=\"150\" width=\"210\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"168.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the tests: what must work,</text><text x=\"125.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">and what must be refused</text><path d=\"M360 54 L360 84 L125 84 L125 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-layers-ah-paper-dim)\"></path><rect x=\"255\" y=\"100\" width=\"210\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">bandit</text><rect x=\"255\" y=\"150\" width=\"210\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"168.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the source: calls known</text><text x=\"360.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">to be risky</text><path d=\"M360 54 L360 84 L360 84 L360 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-layers-ah-paper-dim)\"></path><rect x=\"490\" y=\"100\" width=\"210\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pip-audit</text><rect x=\"490\" y=\"150\" width=\"210\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"168.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the dependencies:</text><text x=\"595.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">published advisories</text><path d=\"M360 54 L360 84 L595 84 L595 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-layers-ah-paper-dim)\"></path><text x=\"360\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">none of them asks whose data a route serves</text></svg>", "caption": "Three tools, three things read. Each finds what the other two cannot see."}
```

This lesson's folder is `~/sc/checks`; make it and its repository as before:

```
(.venv) ana@vm:~/sc$ mkdir checks
(.venv) ana@vm:~/sc$ cd checks
(.venv) ana@vm:~/sc/checks$ git init -b main
Initialized empty Git repository in /home/ana/sc/checks/.git/
```
