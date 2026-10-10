---
title: A policy, two frameworks, and a calendar
version: 1
---

The register and the review are the machinery. Around them sit three things that are mostly words,
and that matter because they decide who is allowed to say no.

## A policy that fits on a page

An AI policy nobody reads protects nobody. Tarefa's fits on one page and every line can be checked
against something this course built:

1. **every system that calls a model is in the register**, with an owner on the staff; `register.py`
   holds it;
2. **a change that adds reach is reviewed before it ships**, by the owner and by somebody who is not
   the author; `review.py` holds it;
3. **personal data reaches a model only with a legal basis written down**, and only what the purpose
   needs; lessons 11 and 12;
4. **credentials are per component, narrowed and rotated**, never in a prompt or a repository; lesson
   17;
5. **files that decide what the assistant says are versioned and approved by name**; lesson 20;
6. **every alert has a runbook, and every incident a timeline**; lessons 22 and 24;
7. **whoever finds a problem may stop the system** that has it, without asking first.

The last line is the one that needs a policy rather than a program. The person on call at three in
the morning, or the engineer who notices the classifier answering in the wrong format, must know that
switching a feature off is within their authority. Without it written down, people wait for
permission, and lesson 24 showed what waiting costs.

## NIST AI RMF and ISO/IEC 42001

Two documents come up whenever a client, an auditor or an investor asks how a company manages AI
risk, and it helps to know what each is.

The **NIST AI Risk Management Framework** (AI RMF 1.0, published in January 2023) is voluntary and
free. It organises the work into four functions, and the generative AI profile NIST published in
July 2024 (NIST AI 600-1) applies them to systems like Tarefa's. The course's lessons fall into them
naturally:

| function | what it asks | where this course did it |
|---|---|---|
| Govern | policies, roles, accountability, a culture that reports problems | lessons 8, 20, 25 |
| Map | the context, what the system is for, and what can go wrong | lessons 1, 4, 12, 13 |
| Measure | testing and tracking the risks that were mapped | lessons 2, 3, 22, 23 |
| Manage | treating the risks, and responding when one happens | lessons 5 to 7, 9 to 11, 14 to 19, 21, 24 |

**ISO/IEC 42001**, published in December 2023, is a management system standard for AI, built like
ISO/IEC 27001 is for information security: requirements for an AI policy, roles, risk assessment, an
impact assessment for each AI system, and a set of reference controls in its Annex A, with a cycle
of internal audits and improvement. Unlike the NIST framework, **it can be certified** by an external
auditor, which is why it appears in contracts and tenders.

Neither one tells you how to stop a prompt from leaking a key. They ask whether you have a way of
deciding, recording and checking such things, and whether it runs. A company that has done this
course's work has most of the evidence either one asks for; what the frameworks add is the habit of
showing it, every year, to somebody from outside.

## The calendar

Governance that happens once is a project. Most of what this course built has a rhythm, and writing
the rhythm down is what makes it happen when nobody remembers:

| how often | what | lesson |
|---|---|---|
| every pull request | the suite | 23 |
| every night | the rate of what is deployed, against its ceiling | 23 |
| every month | the alert list, with what fired | 22 |
| every 90 days | key rotation | 17 |
| every quarter | the register against the providers' bills | 25 |
| every year | each system's review, the threat register, the policy itself | 13, 25 |
| after every incident | the review, and its actions in the suite | 24 |

That is the end of the course. The controls in it are not exotic; most are a few dozen lines of
Python and a JSON file. What makes them work is the same thing every lesson came back to: **each one
runs on its own, says what it found, and exits with a status somebody else's program reads.**
