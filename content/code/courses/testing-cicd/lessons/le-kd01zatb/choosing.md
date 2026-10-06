---
title: Choosing a strategy
version: 1
---

Five ways of putting a release in front of customers, and what each one buys:

| | gap in service | two versions at once | way back | how much a bug reaches | extra cost |
| --- | --- | --- | --- | --- | --- |
| recreate | yes | never | redeploy the old one | everyone | none |
| rolling | no | during the rollout | another rollout | grows as it rolls | a spare instance, maybe |
| blue-green | no | only at the switch | flip the switch | everyone, until the flip back | a second production |
| canary | no | for the whole canary | set the share to 0 | the canary's share | per-version metrics |
| feature flag | no | the code holds both | turn the flag off | the flag's share | code and tests for both paths |

They combine. A common arrangement is blue-green or rolling for the release, so deploys are fast and
safe to undo, and flags for the features inside it, so each feature reaches customers on its own
schedule. A canary sits on top when the traffic is large enough to judge, in the sense of section 08.

## Questions that decide it

- **Can two versions run at once?** If not, for this release, recreate is honest and the others are
  not. Better still, split the change so that they can, which is lesson 11's subject.
- **How quickly must a bad release be undone?** Seconds point to blue-green or a flag; minutes allow
  a rollout in reverse.
- **Is there enough traffic to measure?** A service with a hundred requests a day cannot run a
  meaningful canary; it can still use blue-green and flags.
- **Who decides when customers see a feature?** If it is not the person deploying, a flag.

None of these strategies replaces the tests of the first six lessons. They limit how far a bug
travels once it is past them, and how long it stays. The release above carried a bug no test caught;
blue-green took it out of service in three milliseconds, the canary kept it to two requests, and the flag
would have withdrawn the feature without touching the release.
