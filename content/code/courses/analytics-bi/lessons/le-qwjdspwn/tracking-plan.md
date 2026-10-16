---
title: A tracking plan is a contract
version: 1
---

Events are written by developers, in many places, over years, and nothing in the browser stops a new
release from naming an event `addToCart` where the old one said `add_to_cart`. Every funnel built on the
old name silently stops counting that step. The defence is a **tracking plan**: the list of events the
company has agreed to send, with what each one means and which properties it carries, written down
before the code.

A plan does two things. It is documentation, so the analyst knows what `checkout` means. And it can be
**checked**: every event that arrives is compared with the plan, and one that is not in it is a
violation.

Segment's version is called **Protocols**. A tracking plan is attached to a source, every event is
validated against it, and a mismatch is a violation. Matching is strict: the documentation says the
name has to match exactly, casing and spacing included. For events that are not in the plan, a source
can be set to **block** them, so they never reach a destination, and for properties not in the plan, to
**omit** them. Protocols is sold as an add-on to Segment's Business plan.

Blocking is the strong setting, and Segment's documentation gives the warning that goes with it: a
blocked event that is not forwarded somewhere else is discarded for good. The safe order is to
**watch the violations first, fix them, and only then block**, because the first day a plan blocks
anything it usually blocks something nobody knew was being sent.

You do not need Protocols to have a tracking plan. It is a table, and the check is a query, which is what
the next section builds on Lantern's events.
