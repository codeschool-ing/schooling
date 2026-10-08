---
title: Actions that get done
version: 1
---

A review produces **actions**, and an action that is not tracked is a wish. Each one needs four things:

| action | owner | due | done when |
|---|---|---|---|
| a standard build for servers, with keys-only SSH and `keyaudit.sh` scheduled | diego | 30 Oct | a new server built from it passes `sshd -T` and the audit with no changes |
| critical alerts page the person on call, at any hour | ana | 16 Oct | a test alert at 03:00 reaches a phone, and the page is in the alert's record |
| every server's internet egress declared in the firewall's source, default deny | diego | 13 Nov | the firewall's configuration has no rule that allows any server to reach anywhere |
| rate-limit SSH attempts at `fw` | diego | 23 Oct | 20 attempts in a minute from one address are dropped, in the lab first |
| the Sigma rule for `files` egress, and one for logins by keys not in the inventory | ana | 23 Oct | each rule fires on a test event and appears in the SIEM |
| the on-call rota, and what it is paid | managing partner | 16 Oct | the rota is published and the first week is covered |

Look at the last column. **"Done when" is a check somebody can run**, not a description of effort. "Improve
monitoring" cannot be done; "a test alert at 03:00 reaches a phone" either happens or it does not.

Two habits keep the list honest. The actions go into the **same tracker as other work**, not into the review
document where nobody looks again. And somebody, usually the incident lead, **checks the list on the due dates**
and reports what slipped: a review whose actions quietly expire was a meeting, which is what the figure at the
start of this lesson warns about.

Not every factor gets an action, and that is allowed. The review may decide that a risk is accepted, for a
reason, written down. What is not allowed is a factor that nobody decided anything about.
