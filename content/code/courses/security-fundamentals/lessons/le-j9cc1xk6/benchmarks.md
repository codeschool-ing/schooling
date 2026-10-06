---
title: Benchmarks: a checklist per product
version: 1
---

The CIS Controls say "securely configure every system" (control 4) without saying how, because the how
depends on the system. That is the job of a second CIS publication with a confusingly similar name: the
**CIS Benchmarks**.

A **CIS Benchmark** is a detailed configuration guide for one product: one for Ubuntu Linux, one for
Windows Server, one for a particular database, a web server, a browser, a cloud provider's account
settings. Each is a long list of recommendations, and each recommendation states:

- the **setting** and the value to use;
- the **rationale**: what attack or mistake it prevents;
- how to **audit** it: the command or screen that shows the current value;
- how to **remediate** it: the change that sets the right value;
- the **impact**: what the change might break.

They are written and revised by volunteers and vendors working together, which is why they are called
consensus benchmarks, and they are free to download for non-commercial use.

### Two levels

Most benchmarks split their recommendations into two **profiles**:

| profile | intent |
|---|---|
| **Level 1** | the practical baseline: settings that improve security with little impact on how the system is used |
| **Level 2** | defence in depth for high-security environments: stricter settings that may break some functionality |

Level 1 is where everybody starts. Level 2 is chosen deliberately, item by item, where the risk
justifies the cost to usability: lesson 1's tension between confidentiality and availability, again.

### Why a checklist at all

A server installed from scratch is configured for **convenience**, not security. That is not
carelessness by the vendor: a default has to work for everyone, and the most compatible choice is often
the most permissive. Lesson 2 called this a configuration vulnerability, the kind that needs no bug at
all. A benchmark is the list of every place where the convenient default and the secure setting differ,
written down once by people who studied the product, so that each administrator does not have to
rediscover them.

The most valuable property of a benchmark, though, is that **each item can be checked by a machine.**
"Root may not log in over SSH" becomes a command that prints the current value, and a check becomes a
script that runs every night. The next section writes four such checks for the shop's SSH server, in
the style of a benchmark rather than copying one: the real CIS Benchmark for Ubuntu has hundreds of
recommendations, and its text is CIS's to publish. `defense-hardening` lesson 2 applies the benchmarks
properly, with the tools that check them at scale.
