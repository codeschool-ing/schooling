---
title: AgentKit, the hosted half
version: 1
---

OpenAI presented **AgentKit** in October 2025 as a set of hosted products for building agents on its platform, with the **Agents SDK**, an open-source Python library, underneath. The two are easy to confuse because they share the agent vocabulary, and they are different kinds of thing: one runs on OpenAI's servers and is used through a browser and an API; the other runs in your program.

As OpenAI described them at launch, the hosted pieces were:

| piece | what it is for |
|---|---|
| **Agent Builder** | a visual canvas for laying out an agent workflow as connected nodes (agents, tools, conditions, guardrails), testing it with previews and publishing versions; a workflow can be exported as Agents SDK code |
| **ChatKit** | an embeddable chat interface, so a product can put an agent in front of its users without building the front end |
| **Connector Registry** | an administrator's list of the data sources and MCP servers that agents in an organisation may connect to |
| **Evals** additions | datasets, grading of whole traces and prompt optimisation, for measuring an agent rather than a single reply |

**None of this could be run for this course.** The lab reaches no provider (lesson 1 section 07), and these products are only on OpenAI's platform, behind an account and a bill. So this section describes them and the rest of the lesson does not mention them again. The products also change on the platform's schedule, not the library's: names, what is in beta and what is generally available have all moved since launch, and this course cannot tell you which have moved since it was written. **Read OpenAI's current documentation before relying on any detail in the table.**

## What carries over

What does not age is the shape. A visual builder draws the same graph lesson 6 drew in code: an agent hands off to another, a node decides a branch, a guardrail stands in front of a step. A workflow exported from a builder is Agents SDK code, so the library is the part worth knowing well, and it is the part that runs here.

The trade between the two is the one lesson 7 discussed for frameworks in general. A hosted builder is quick to start, easy to show to people who do not write code, and ties the agent to one vendor's platform, pricing and data handling. The library keeps the loop in your process and your repository, where it can be tested like lesson 7's, reviewed in a pull request and moved.
