---
title: What DevSecOps changes, and what it does not
version: 1
---

The common picture of DevSecOps is a purchase: a scanner is bought, plugged into the pipeline, and
the team is now "doing security". A month later the scanner's job is red on every branch, somebody
has marked it "allowed to fail", and nobody reads its output. **Nothing about the routine changed,
so nothing about the security did either.** The tool was the cheap part.

What DevSecOps changes is **who finds a security defect, when, and where the finding goes**. The
practices of DevOps stay: small changes, a pipeline that checks every one of them, the people who
build a service also running it. DevSecOps adds security checks to the same pipeline and puts their
results in the same place as a failing test. That is the whole idea, and each half is harder than
it sounds.

### The model it replaces

In the arrangement most companies started from, security was a phase. A team built a release; a
security team reviewed it, or hired an outside firm to test it, shortly before it went out or
shortly after; the findings came back as a report, and the report became tickets. Three things
follow from that shape, and none of them is anybody's fault:

- **The finding arrives long after the code was written.** The developer has moved on to other
  work, the context is gone, and the fix competes with whatever is planned next.
- **The finding arrives in a different place.** A PDF, a spreadsheet, a ticket in somebody else's
  queue. A test failure stops a merge; a report does not.
- **The reviewers are outnumbered.** One security engineer for dozens of developers cannot read
  every change, so the review samples, and what is not sampled is not reviewed.

DevOps had removed the same kind of hand-over between building and running software. DevSecOps
removes it between building software and checking it is safe.

### What actually changes

| | security as a phase | DevSecOps |
|---|---|---|
| when a defect is found | at review, before or after a release | in the pipeline of the change that introduced it |
| where the finding goes | a report, then tickets | the build log, beside the failing tests |
| who fixes it | whoever the ticket is assigned to | the author of the change, while it is still in their head |
| what the security team does | reviews releases | chooses the checks, tunes them, decides the hard cases, trains |
| what a "pass" means | the reviewer found nothing | every check the team agreed on ran, and passed or was excepted on the record |

**The last row is the one people miss.** A pipeline does not make software secure. It makes a
specific, written list of checks run on every change, so the question "did anybody look?" always
has an answer. The list is a decision the team makes and revisits, and it is code in the
repository, which lesson 7 turns into a rule about when a check may stop a release.

### What does not change

Automating the checks does not remove the need for people who understand the threats. A scanner
finds the flaws somebody already wrote a rule for. It does not find a design that trusts the wrong
party, which is what `threat-modeling` is for, and it cannot judge whether a finding matters in
this system. **The security engineer's work moves from reading every change to deciding what the
machine reads for**, and to the cases where it cannot decide.

Neither does it remove the trade between speed and safety. Every check costs minutes on every
push, and lesson 2 is about spending that time where it pays. A pipeline that takes forty minutes
to say anything is one people route around.

### This course, on one pipeline

From here to lesson 20 the course adds checks to one pipeline, for one small service you will
build in this lesson. Each lesson adds a class of check, finds what it finds in the service, fixes
it and keeps the check in the pipeline. By the end the pipeline scans the code, the dependencies,
the secrets, the image and the infrastructure, and signs what it ships. The order of the stages it
ends with is not the order of the lessons, and the figure shows why:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 228\" role=\"img\" data-fig=\"sp-l01-stages\" aria-label=\"The stages of ci/stages in the order they run by the end of the course, each with the lesson that adds it: secrets 6, workflows 16, policy 19, test 1, sast 3, sca 5, build 1, image 8, push 8, sbom 13, sign 14. The nightly list holds rebuild, added in lesson 2, and dast, added in lesson 4.\"><defs><marker id=\"sp-l01-stages-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ci/stages: on every push</text><rect x=\"15\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"45.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">secrets</text><text x=\"45.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><rect x=\"78\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"108.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">workflows</text><text x=\"108.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><rect x=\"141\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"171.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">policy</text><text x=\"171.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">19</text><rect x=\"204\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"234.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">test</text><text x=\"234.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"267\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"297.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">sast</text><text x=\"297.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"330\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">sca</text><text x=\"360.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><rect x=\"393\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"423.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">build</text><text x=\"423.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"456\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"486.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">image</text><text x=\"486.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><rect x=\"519\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"549.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">push</text><text x=\"549.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><rect x=\"582\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"612.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">sbom</text><text x=\"612.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13</text><rect x=\"645\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"675.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">sign</text><text x=\"675.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14</text><path d=\"M15 100 L703 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l01-stages-ah-paper-dim)\"></path><text x=\"15\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the order they run in; the number is the lesson that adds the stage</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ci/nightly: once a day</text><rect x=\"15\" y=\"168\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">rebuild</text><text x=\"65.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"140\" y=\"168\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"190.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">dast</text><text x=\"190.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M117 191 L138 191\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l01-stages-ah-paper-dim)\"></path></svg>", "caption": "Lesson 1 starts with two stages. Each later lesson that adds one puts it where it belongs in the order, which is why the order is not the order of the lessons."}
```

The stages that cost the least and stop the most go first. A secret in a commit is the cheapest
thing to detect and the most expensive to leave, so lesson 6 puts its check at the head of the
list even though it comes after three others in the course.
