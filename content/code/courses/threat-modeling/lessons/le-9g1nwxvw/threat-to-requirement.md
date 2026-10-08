---
title: From threat to requirement
version: 1
---

A list of threats answers the second of the four questions. Nothing on it protects anybody until
the third question is answered: **what are we going to do about it?** The answer comes in two
steps, and teams that skip the first write requirements for threats they should have removed,
accepted or handed elsewhere.

**First, a decision.** `security-fundamentals` (lesson 3) introduced the four ways of treating a
risk, and a threat model uses the same four:

| decision | what it means | example at Vereda |
|---|---|---|
| **mitigate** | build or change something so the threat is less likely or less harmful | verify the webhook's signature (T01) |
| **eliminate** | remove what makes the threat possible | stop sending the CPF to the gateway, so it cannot be linked (lesson 5) |
| **transfer** | make somebody else carry it, by contract or insurance | the gateway's contract makes it liable for card data it stores |
| **accept** | decide, on the record, to live with it | T14, until the console's viewer is replaced |

**Second, for the first two decisions, a requirement**: a statement of what the system must do,
written so somebody can check it. Transfer ends in a contract and acceptance in a signed record;
both are lesson 12's subject. This lesson is about the requirement.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l08-chain\" aria-label=\"The chain from a threat to evidence, using T07. The threat: a patient changes the exam number and downloads somebody else’s report. The decision: mitigate. The requirement, R10: the portal returns an exam only to the patient it belongs to, and answers any other request as if it did not exist. The verification: a test that asks for another patient’s exam and expects the same answer as for a missing one. Below the chain, the other three decisions: eliminate, transfer, accept, each of which ends somewhere else.\"><defs><marker id=\"l08-chain-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"97.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">threat</text><rect x=\"20.0\" y=\"38.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">T07</text><text x=\"97.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a patient downloads</text><text x=\"97.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">another’s report</text><path d=\"M175.0 73.0 L195.0 73.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-chain-tm-ah-paper-dim)\"></path><text x=\"272.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">decision</text><rect x=\"195.0\" y=\"38.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"272.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mitigate</text><path d=\"M350.0 73.0 L370.0 73.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-chain-tm-ah-paper-dim)\"></path><text x=\"447.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">requirement</text><rect x=\"370.0\" y=\"38.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">R10</text><text x=\"447.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">exams only to</text><text x=\"447.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">their owner</text><path d=\"M525.0 73.0 L545.0 73.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-chain-tm-ah-paper-dim)\"></path><text x=\"622.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">verification</text><rect x=\"545.0\" y=\"38.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"622.0\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a test asks for</text><text x=\"622.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">another’s exam</text><text x=\"20.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">the other decisions end elsewhere:</text><rect x=\"20.0\" y=\"160.0\" width=\"220.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">eliminate</text><text x=\"130.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">remove the feature or the data</text><rect x=\"252.0\" y=\"160.0\" width=\"220.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"362.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">transfer</text><text x=\"362.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a contract or insurance carries it</text><rect x=\"484.0\" y=\"160.0\" width=\"220.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"594.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">accept</text><text x=\"594.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a signed decision, with a date</text><text x=\"362.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lesson 12</text><text x=\"594.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lesson 12</text></svg>", "caption": "A threat is dealt with when the chain reaches evidence. A requirement nobody verifies is a wish written in the imperative."}
```

### Mitigations are written as behaviour

The common mistake is writing the mitigation as a technology: "use a WAF", "add MFA", "encrypt the
database". Each names something to buy or switch on, and none says what the system will then do.
**A requirement names the behaviour, and leaves the mechanism to whoever builds it**, unless the
mechanism is the point:

| mitigation as a technology | as a requirement |
|---|---|
| "add MFA for staff" | staff sign-in requires a second factor every time |
| "fix the IDOR" | the portal returns an exam only to the patient it belongs to |
| "use a WAF" | (no requirement: which threat was it for?) |

The last row is common and worth catching. A control proposed with no threat beside it is either
answering a threat nobody wrote down, which should be written down, or answering nothing.

### One threat, several requirements, and the reverse

T01 needs two requirements: the signature check, and the amount check that lesson 6 found a
signature cannot replace. One requirement can also cover two threats, as the e-mail about a new
sign-in covers both T16 and T17. Neither is a problem. What matters is that the join is written
down, which is the section on traceability.
