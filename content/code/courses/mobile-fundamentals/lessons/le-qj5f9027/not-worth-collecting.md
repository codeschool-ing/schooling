---
title: The data not worth collecting
version: 1
---

**Every piece of data an app collects is something it then has to declare, protect, keep, and delete
on request, so the cheapest data to hold is the data never collected.** The habit most teams start
with runs the other way: collect what might be useful, decide later what it is for. On a phone that
habit is expensive twice. The store forms make the collection public, and the person reading the label
on the product page decides whether to install on the strength of it.

## What the planner does not need

**The planner needs no account, no location, no contacts, and no identifier for the device.** Go
through the list a typical app collects and ask, for each one, what the student would lose without it.

| data | what it would buy the planner | what the student loses without it |
|---|---|---|
| an account with an email address | a plan on two phones | nothing today: the plan is on the phone, and lesson 16 keeps it there |
| location | nothing; a study session has no place | nothing |
| contacts | inviting a friend to study | one share sheet, which the system offers without the permission |
| a device identifier for analytics | counting how many people open each screen | nothing they can see |
| crash logs sent to a third party | finding crashes sooner | nothing they can see, until a crash goes unfixed |

**Only the last row is a real trade, and it has a cheaper answer.** Both stores' consoles show crash
reports and performance data the system itself gathers, with no SDK in the app. `mobile-delivery`
lesson 12 is about crash-reporting libraries, and its lesson 15 about what is measured in the field. Starting from the system's own reports keeps the planner's form empty for as long as they
are enough.

**"Not worth collecting" is a judgement about the person, not about storage.** A device identifier
costs a few bytes. What it costs the student is that every screen they open becomes a record tied to
their phone, held by somebody they did not choose, under a policy they did not read. Apple's page on
privacy details lists data from which identifiers have been stripped as an example of data *not*
linked to the user; removing what links data to a person is something an app can do before
collection, and cannot undo after.

## Analytics that are not surveillance

**Measuring how an app is used is not the problem; measuring who is using it, screen by screen, is.**
There is a version of analytics that answers the questions a team actually has, such as which screens
are used and where people give up, from counts that identify nobody: no device identifier, no account,
nothing that lets one person's sessions be put back together. `mobile-delivery` lesson 16 is about
building exactly that, events and funnels with measurement that is not surveillance, and it starts from
the inventory this lesson wrote.

**The tags on a link are the same question in miniature.** Lesson 11's parser ignored the
`?from=email` on a link to the week. A tag like that says where a person came from, which is what
makes it useful to a marketing team and also what makes it data about the person. The planner reads
it for nothing and sends it nowhere, so it does not appear in the inventory, and the store forms never
ask about it. If the planner ever started counting where installs come from, through the referrer of
lesson 11's deferred links, that would be a new line in the inventory, with a `why` somebody has to be
willing to write.

## The order of the questions

**Ask whether to collect before asking how to declare.** The inventory of the previous section makes
the order mechanical: an entry cannot exist without a reason, and its reason has to survive being
read by the person it is about. When the reason is "it might be useful", the entry does not go in, and
the form has one line fewer. When the reason is real, the entry says where the data goes, and the
form's answers follow from it.

This lesson's figure had three boxes, and the planner keeps everything in the first. That is the shape
worth aiming for in any app: data in the box on the left by default, and every move to the right a
decision someone wrote down.
