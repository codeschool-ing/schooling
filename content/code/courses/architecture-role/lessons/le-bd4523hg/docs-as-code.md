---
title: Documentation next to the code
version: 1
---

**Keep the documentation in the same repository as the code, as plain text, changed in the same pull
request as the code it describes and reviewed by the same people.** The idea is called docs as code.
It does not make anybody write more; it puts the documentation where a change to the system already
passes, so that keeping it true is part of the change rather than a separate chore nobody schedules.

The usual home for architecture documentation is a wiki, chosen because anybody can edit it. That is
the problem. Anybody can, so nobody has to, and nothing in the way code changes ever leads anybody
to it.

## Why the wiki drifts

Carreto's page "Payments architecture" was last edited in March 2023. Since then the Payments
repository has merged more than 1,100 pull requests. **None of them touched the page, because none of
them could**: the page lives somewhere else, with no review, no link to the code it describes and no
way for a pull request to show that it is now wrong.

The wiki is not badly written. Its problem is structural, and it has four parts:

- **A change to the code never passes through it.** The developer changing how payouts are retried
  has no reason to open the wiki and no moment in their work where it appears.
- **Nobody reviews it.** A wrong sentence in code review gets a comment; a wrong sentence in the wiki
  gets read.
- **Its history is not the code's history.** There is no way to see the page as it was when version
  2.4 shipped, which is exactly what somebody investigating an incident in version 2.4 needs.
- **Nothing can check it.** A pipeline can fail a build on a broken test; it cannot see a wiki.

## Docs as code at Carreto

The change Renata asked the teams for was small. Each repository gets a `docs/` directory beside the
code, holding Markdown files and diagrams written as text:

```
payments/
  src/
  tests/
  docs/
    README.md
    architecture/
      workspace.dsl
      requirements.md
    adr/
      0001-record-architecture-decisions.md
      0002-pay-drivers-by-pix.md
    runbooks/
      payout-stuck.md
```

What follows from that one move is most of the value:

- **A pull request that changes the architecture changes the documentation in the same diff.** The
  reviewer sees both. "This changes how Payments learns that a delivery was proved; the container
  diagram still shows the old arrow" is a review comment, and the pull request waits for it like it
  would for a failing test.
- **The pull request template asks.** Carreto's has one line for it: "Does this change a diagram, a
  runbook or a requirement in `docs/`?" It costs a second when the answer is no.
- **History comes for free.** `git log docs/` shows when each page changed and in which pull request,
  with the reason in the description. The documentation for version 2.4 is in the tag for version 2.4.
- **The pipeline can check it.** Links that point nowhere, an ADR with no status, a diagram file that
  no longer renders: each of these can fail a build, and lesson 9 goes further, checking that the
  dependencies the code actually has are the ones the design allows.

**A document needs an owner as much as code does**, and in a repository that comes almost for free:
the team that owns the code owns the `docs/` beside it. GitHub's CODEOWNERS file, or its equivalent
elsewhere, can require that team's review for any change to it.

## Diagrams as text

A diagram drawn in a drawing tool is saved as a binary file, or as XML that no reviewer reads in a
diff. When it changes, the pull request shows that a file changed and nothing about what. **A diagram
written as text can be reviewed like code**: the line that adds an arrow is the line in the diff.

There are several tools for this, and `architecture-modeling` lesson 12 compares Mermaid, PlantUML
and Structurizr properly. One property of the last of these is worth seeing here, because it changes
what a diagram is. In Structurizr's language you describe **one model** of the system, and then ask
for views of it. Here is a cut-down version of what the `workspace.dsl` above might hold:

```
workspace "Carreto" {
    model {
        shipper = person "Shipper" "A company with loads to move"
        driver = person "Driver" "An independent truck driver"
        carreto = softwareSystem "Carreto" {
            shipperApp = container "Shipper web app"
            driverApp = container "Driver app" "" "Mobile"
            monolith = container "Monolith" "" "Django"
            tracking = container "Tracking service"
        }
        sefaz = softwareSystem "SEFAZ" "Authorises the CT-e"
        bank = softwareSystem "Bank partner" "Sends Pix payments"

        shipper -> shipperApp "Quotes and books loads"
        driver -> driverApp "Accepts loads, proves delivery"
        shipperApp -> monolith "Calls" "HTTPS"
        driverApp -> tracking "Sends positions" "HTTPS"
        monolith -> sefaz "Requests CT-e authorisation"
        monolith -> bank "Requests payouts"
    }
    views {
        systemContext carreto {
            include *
            autolayout lr
        }
        container carreto {
            include *
            autolayout lr
        }
    }
}
```

The `model` block says what exists and who talks to whom, once. The `views` block asks for two
pictures of it: the context view, where Carreto is a single box, and the container view, which opens
that box. **Because both views are drawn from the same model, they cannot disagree** about which
outside systems exist. With two hand-drawn diagrams, each is a separate claim, and the day somebody
adds the bank partner to one and forgets the other, the two are contradicting each other and nobody
has noticed.

The price is layout. An automatically laid-out diagram is tidy and rarely beautiful, and for a board
presentation Renata still draws one by hand. She draws it from the model, though, so that the picture
on the slide shows the same system as the one in the repository.

## Where docs as code does not reach

Sílvio does not open repositories, and he should not have to. **The source lives in one place and is
published to wherever its readers are**: Carreto's pipeline renders the Markdown and the diagrams of
every `docs/` directory into the internal site on each merge, with a link back to the file and the
date of its last change. The readers outside engineering read the published copy; nobody edits it,
because it is regenerated from the repository each time.

Some documents should not live in a repository at all. A proposal written to get a decision, or the
slides for one meeting, are written once and read in a week, and their job is over when the decision
is made. Those are records of a moment rather than descriptions of the system, a distinction the next
section depends on, and writing them well is the subject of `architect-communication` lesson 2.
