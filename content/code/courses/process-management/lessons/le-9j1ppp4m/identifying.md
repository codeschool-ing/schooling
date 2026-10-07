---
title: Finding the risks
version: 1
---

The risks a project manages are only the ones somebody noticed. Most techniques for identifying risks exist to get past the obstacles to noticing: optimism, the reluctance to say something discouraging in a meeting, and the narrow view of each person's own part.

## Ask the people who will do the work

The developers, testers and operators know where the work is uncertain, and they are rarely asked. A short session at the start of a project, and again at each planning point, with one question — *what could make this go differently from the plan?* — produces most of the risks that matter. Writing answers on cards before discussing them works for the same reason planning poker's hidden cards did in lesson 10: the first idea spoken aloud anchors the rest.

## Use checklists and the past

Every organisation that has run projects has a history of what went wrong. A checklist built from it — third-party integrations, data migrations, regulatory approvals, a single expert, a new technology — prompts people to consider categories they would not have thought of. **Assumptions** are a particularly rich source: every plan rests on them, and each one is a risk if it turns out false. "The provider's sandbox will be available from week one" is an assumption in lesson 9's estimate, and listing it makes it visible as a risk.

Some teams keep these together in a **RAID log**: risks, assumptions, issues and dependencies in one place, reviewed at the same meeting, because each kind tends to turn into another.

## The pre-mortem

The most effective single technique is the **pre-mortem**, described by Gary Klein in 2007. The team imagines that it is some months in the future and the project has **failed**. Each person then writes down, privately, the reasons it failed. The answers are collected and discussed.

It works because it changes the question from *what might go wrong?*, which invites reassurance, to *why did it go wrong?*, which invites explanation. Saying that a colleague's integration might be late is awkward; explaining why an imagined failure happened is not. The pre-mortem gives people permission to say what they were already worried about.

For the Agenda team's online booking, a pre-mortem produced the five risks of this lesson in twenty minutes, among them the one nobody had said aloud before: that only one developer understands the billing integration.

## Look at the architecture

Technical risks hide in the design, and an architect should look for them deliberately: the parts that are new to the team, the integrations with systems outside its control, the places where a quality requirement — response time, availability — is close to the limit of what the design can deliver. This lesson's eighth section comes back to those, because they are the risks an architect is best placed to find and to reduce.
