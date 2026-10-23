---
title: The landscape of process automation
version: 1
---

Every product in this section is sold with the word *automation*, and most of them show a diagram of
boxes and arrows on the first page of their site. So the common mistake is to treat them as one
market, line the vendors up and compare prices. **They automate different things, and the first
question is what the problem needs automated: a screen, a short hop between two applications, or a
process with people in it that lasts for days.** The vendor comes after that.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l06-landscape\" aria-label=\"A map of process automation tools on two axes. Across: what is automated, from a screen, through a task between applications, to a process with people that lasts days. Down: who builds it, from a business user at the top to a professional developer at the bottom. RPA tools such as UiPath and Power Automate desktop flows sit at the screen, built by both. Low-code flows, Power Automate cloud flows, sit at a task between applications, built by business users. Integration code and the ESB sit at a task between applications, built by developers. BPM suites such as IBM Business Automation Workflow, Pega and Appian sit at the long process, built by specialists in the product. Open engines such as Camunda, Flowable and jBPM sit at the long process, built by developers.\"><path d=\"M110.0 270.0 L705.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M110.0 40.0 L110.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"210.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a screen</text><text x=\"410.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a task between apps</text><text x=\"610.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a process with people, days</text><text x=\"407.5\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">what is automated →</text><text x=\"55.0\" y=\"53.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">business</text><text x=\"55.0\" y=\"66.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">user</text><text x=\"55.0\" y=\"243.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">professional</text><text x=\"55.0\" y=\"256.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">developer</text><text x=\"55.0\" y=\"147.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">built</text><text x=\"55.0\" y=\"162.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">by ↕</text><rect x=\"118.0\" y=\"125.0\" width=\"184.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">RPA</text><text x=\"210.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">UiPath, Automation Anywhere,</text><text x=\"210.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Power Automate desktop</text><rect x=\"318.0\" y=\"45.0\" width=\"184.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">low-code flows</text><text x=\"410.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Power Automate cloud</text><text x=\"410.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">flows (lesson 3)</text><rect x=\"318.0\" y=\"195.0\" width=\"184.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">integration code</text><text x=\"410.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the ESB (lesson 8),</text><text x=\"410.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">services you write</text><rect x=\"518.0\" y=\"90.0\" width=\"184.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">BPM suites</text><text x=\"610.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">IBM Business Automation</text><text x=\"610.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Workflow, Pega, Appian</text><rect x=\"518.0\" y=\"195.0\" width=\"184.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">open engines</text><text x=\"610.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Camunda, Flowable, jBPM</text><text x=\"610.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in your own code</text></svg>", "caption": "The question is what the tool automates before it is who sells it. RPA drives a screen; a BPM suite or an engine keeps a long process with people in it."}
```

## BPM suites

A suite is what the previous section took apart: modeller, engine, task list, forms, integration and
monitoring in one product, under one licence, with one vendor to call. IBM's Business Automation
Workflow is one. Pega and Appian are the other two names an architect meets most often in large
companies. Pega built its name on business rules and case management; Appian sells itself first as a
low-code platform with processes inside it. All three are bought through an enterprise contract, as
IBM's is.

What a suite gives you is speed for the first process and one supplier answerable for all of it. The forms, the
inbox, the roles and the reports come with it, and a team that knows the product can put a new
approval process in front of users in weeks. What it costs is the subject of section 05 of this
lesson. In short: **the process lives in the vendor's format, and the people who can change it are
the people who know that product.**

## Open engines

Camunda, Flowable and jBPM are engines rather than suites. They are libraries or servers that your
own developers run, and their processes are BPMN 2.0 files that live in your repository beside the
code. jBPM is the oldest of the three. Camunda and Flowable both began as forks of Activiti, an
engine started by the author of jBPM. The family tree matters less than what they share: the model
is a standard XML file, and the behaviour behind each step is code your team writes in an ordinary
language, tested and deployed like the rest of your software.

The engine still does the hard part. It stores instances, wakes them up, runs timers and keeps the
history. What you write yourself is everything a suite would have handed over: the forms, the inbox
if users need one, the reports. The vendors behind Camunda and Flowable sell enterprise editions with
more of that tooling. The licence terms have also changed between major versions, so **read the
licence of the exact version you would run, not the one a blog post describes.**

This is the family that fits a process the company changes often and considers its own. It needs
developers who are comfortable owning a long-running system, which Serra Alta's product teams are.

## Low-code flows

Power Automate, which lesson 3 met spreading through Serra Alta's departments, is the example every
employee already has. A cloud flow starts on an event (an e-mail arrives, a row is added to a list,
a form is submitted), runs a few steps across applications through connectors, and finishes.
Approvals are available as a step, so a flow can ask a manager to say yes.

That makes low-code flows look like a light BPM suite, and for a two-step approval that is over in a
day they are a good one. The difference shows when the process gets long. **A flow is built to run
for minutes or hours; a process instance is built to live for a month.** Flows have documented limits
on how long one run may last, and a run's history is kept for a limited period rather than as the
permanent record an engine keeps. Before trusting a flow with a
process that waits for a quality visit or a signed contract, look up the run duration limit for your
plan and compare it with the slowest instance you have ever had.

The governance question lesson 3 raised applies here too: a flow belongs to whoever built it, and
Serra Alta found flows whose author had left the company.

## Robotic process automation

RPA tools such as UiPath, Automation Anywhere and Power Automate's desktop flows drive a user
interface. A software robot opens the application, reads what is on the screen, clicks, types and
copies values from one window to another, exactly as a person would. **RPA automates a screen, not a
process.** What it replaces is a person's hands, and it knows nothing about the business step those
hands were doing.

That makes it honest in one situation and fragile in another.

It is honest when there is no other way in. Serra Alta's farm onboarding ends with a clerk retyping
the new farm into Coleta, the milk collection system on IBM i: 23 fields on a green screen, copied
from the BPM form, about 220 times a year. Coleta has no API, and nobody is going to give it one,
because lesson 13 is about retiring it. A robot that types those 23 fields is a reasonable piece of
engineering for the years Coleta has left, as long as everybody calls it what it is: a temporary
bridge to a system without an interface.

It is fragile because the screen is not a contract. When a field moves, a label changes or a
confirmation pop-up appears, a robot either stops, which is the good case, or types a value into the
wrong field and carries on, which is the bad one. **An API changes by announcement; a screen changes
because somebody improved it.** Coleta's screen has hardly changed in twenty years, which is the
unusual circumstance that makes a robot safe there. A robot on a SaaS screen that the vendor redesigns
twice a year is a maintenance contract with yourself.

A robot also hides the problem it solves. Once the retyping is automated, nobody feels the cost of a
system with no interface, and the pressure to fix it goes away. Use RPA as a bridge with a date on it.

## Integration code is not process automation

One more family appears on the map because it gets confused with the others. A flow on Serra Alta's
integration bus that turns a sales order into an EDI message, or the nightly file from Coleta to SAP,
moves data between systems. It has no people, no inbox and nothing that waits for weeks. That is
integration, and lessons 8 to 11 are about it. The confusion runs in both directions. One team puts a two-second message transformation into a BPM
suite because the suite is what it knows; another builds a month-long approval out of messages and
database flags because it has never seen an engine.

## Telling which one a problem needs

The questions are short, and they work best asked in this order.

| question | if the answer is yes |
| --- | --- |
| Is there a person deciding something, and can the case stay open for days? | a process engine: a suite or an open engine |
| Does the company change this process often and consider it its own? | lean towards an open engine in your own code |
| Is it a few steps between applications that finish within hours? | a low-code flow, under somebody's governance |
| Is it data moving between systems with nobody involved? | integration (lessons 8 to 11), not a process tool |
| Is the only way into a system its screen? | RPA, as a bridge with an end date |

Run Serra Alta's own needs through it and they land in different places. Credit approval has people
deciding and cases open for days, so it needs an engine. The retyping into Coleta is a screen with no
interface, so a robot is honest there until Coleta goes. Sending a customer the certificate of
analysis when a batch is released is a few steps between SAP, Documentum and e-mail, finished in
minutes, so a flow or an integration fits. None of the three answers is "the tool we already pay
for", which is the answer most companies give first.
