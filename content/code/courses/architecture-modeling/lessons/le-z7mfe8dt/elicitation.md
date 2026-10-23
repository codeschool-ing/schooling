---
title: Elicitation: asking, watching and confirming
version: 1
---

**Elicitation is drawing information out of stakeholders and other sources**, and BABOK chose the
word deliberately: requirements are not lying around to be *gathered*. People hold them partly,
inconsistently and often without knowing they hold them. Getting them out takes technique, and the
technique has to fit the person and the question.

## Techniques, and what each is good for

BABOK describes fifty techniques. A handful do most of the elicitation work:

| technique | good for | its blind spot |
| --- | --- | --- |
| **interview** | one person's knowledge, goals and worries, in depth | people describe what they think they do |
| **observation** | how the work is really done | slow; people work differently when watched |
| **workshop** | agreement across several stakeholders, quickly | the loudest voice wins unless it is facilitated |
| **document analysis** | rules, formats and history that nobody remembers | documents are out of date |
| **prototyping** | reactions to something concrete | people react to the look rather than the behaviour |
| **survey** | the views of many people, cheaply | only answers the questions you thought to ask |

## Observation found what interviews did not

Tainá and Joana started with an interview, and Joana described the reconciliation precisely: download
the gateway's file, export Carcará's payments, match them by transaction id, investigate the rest.
The interview took an hour and missed three things that a morning of **observation** found:

- Joana matches **refunds** in a separate pass, because the gateway reports them on the day they are
  settled, not the day they are made. A match by date alone fails for every refund.
- She keeps a **spreadsheet of known exceptions**: transactions that will never match, with a note
  on each. It has 214 rows and is the most valuable artefact in the process.
- Cash refunds at the counter show up as **mismatches she explains by phoning the station**. That is
  how the agents became stakeholders.

None of these is a secret. They were invisible to Joana because she does them every month without
thinking. **People are poor witnesses of their own routines**, which is why the technique matters.

## Confirming, every time

BABOK makes **confirming the elicitation results** a task of its own: writing down what you
understood and checking it with the source before anybody builds on it. Tainá sent Joana a one-page
summary of the morning, with the three findings and the questions they raised, and asked one question
at the end: *what did I get wrong?* Joana corrected one thing, the refund timing, which is settled two
days later rather than one. A wrong day in the requirement would have made every refund a mismatch.

## Preparing

Elicitation goes better when the analyst arrives with: the question to answer, what is already known
(the core concepts page from earlier in this lesson), the sources to consult and a way to record what
comes out. Ten minutes of preparation is the difference between an interview and a chat.
