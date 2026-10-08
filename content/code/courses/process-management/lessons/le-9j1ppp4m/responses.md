---
title: Planning a response
version: 1
---

For each risk worth managing, somebody decides what to do about it. The PMBOK Guide lists the options as a short vocabulary, and using it makes risk discussions faster, because everybody knows what each word commits to.

## For threats

- **Avoid**: change the plan so the risk cannot happen. If the payment provider's API is unstable, use a different provider, or leave payment out of the first release. Avoiding a risk usually costs scope or money; it removes the risk entirely.
- **Transfer**: move the impact to somebody else, usually by contract or insurance. A fixed-price contract with a supplier transfers cost overrun on that part to the supplier, at a price. Transferring does not make the risk less likely; it changes who pays.
- **Mitigate**: reduce the probability, the impact, or both. Sampling and cleaning two clinics' data in the first Sprint reduces both for risk C; pairing a second developer on billing reduces the impact of risk B.
- **Accept**: decide to do nothing in advance, either **passively** — deal with it if it happens — or **actively**, by setting aside a reserve of time or money. Accepting is the right answer for risks whose responses would cost more than they save, such as D, the app store rejection.
- **Escalate**: when the risk is outside the project's authority — a company-wide hiring freeze, a regulatory change — pass it to the level that owns it, as PRINCE2's exceptions did in lesson 7.

## For opportunities

The vocabulary has a mirror for good news:

- **Exploit**: make sure the opportunity happens. Assign a developer to test the calendar library in the first week.
- **Share**: work with a partner who is better placed to capture it.
- **Enhance**: increase its probability or its benefit.
- **Accept**: take it if it comes, without effort.

## Matching the response to the risk

The four Agenda threats get four different responses, and the reasons are instructive:

| risk | response | why |
|---|---|---|
| A — API changes | mitigate: wrap the provider behind the team's own interface | cheap, and limits the impact to one module |
| B — billing developer leaves | mitigate: pair a second developer on billing for two Sprints | the impact is large, and knowledge can be spread |
| C — dirty clinic data | mitigate: sample two clinics in Sprint 1 | the probability is high and testing it is cheap |
| D — app store rejection | accept, actively: one day in the plan for a resubmission | a response would cost more than the risk |

Every response is itself a small piece of work with a cost, and it goes into the backlog like any other work. Lesson 12 shows how to weigh that cost against features when deciding what comes first.

## Secondary risks

A response can create new risks. Wrapping the payment provider behind the team's own interface adds code that can have its own defects; transferring work to a supplier adds the risk that the supplier fails. A response is finished when its own risks have been looked at.
