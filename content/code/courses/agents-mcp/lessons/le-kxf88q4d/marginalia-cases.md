---
title: Five proposals at Marginalia
version: 1
---

Five ideas reach ana's team in the same week. Here is each one run through section 03's four questions, with the decision and the reason that settled it.

**"An agent that answers password questions."** The path is one help article, `h26`, every time. A search and a template answer it, or a link on the sign-in page. **Not an agent**: the first question fails, and anything more adds requests to a problem with a fixed answer.

**"Tell customers where their order is."** One lookup by order id, one sentence built from the status. The only judgement is reading the id out of a message, which a regular expression or one model call does. **A workflow**, the router of section 05 with a better template.

**"Handle the messages the router passes to a person."** These are, by construction, the cases no branch covers: complaints, mixed problems, odd requests. The path depends on what each lookup returns, and the answer can be checked against the order and the help centre. **An agent, with read-only tools**, whose output a person reviews before it is sent. Draft first; act later, once there is evidence about how often the drafts are right.

**"Let the agent issue refunds for damaged books."** The policy is clear (`h12`: photographs within 14 days, replacement at no cost), so most of the path can be written. The action costs money to reverse. **A workflow for the check, and the refund behind a person's confirmation**, which is lesson 17's design. Giving an agent the refund tool so that it can decide, by itself, whether a photo shows damage puts the most expensive mistake in the least checkable place.

**"Write the nightly stock report."** A query, a table, an email to two people. No reading of free text at all. **Automation**: a model adds nothing here except a way for the numbers to come out wrong.

## What the five have in common

Only one of the five became an agent, and it is the one that exists because the others were built first. **The router's "other" branch is where an agent's work comes from**: it collects, every day, the messages a fixed path could not handle, and its size is the honest measure of how much an agent is needed. Lesson 7 builds that agent properly, and lessons 8 to 10 rebuild it with three vendors' kits.
