---
title: A failover you did not run
version: 1
---

A managed service's failover is lesson 16's, run by the provider: a standby in another data centre,
something that decides the primary is gone, a promotion, and the **DNS name** the application connects
to repointed at the new primary. Each piece has a lesson in this course:

- **It takes time**, typically a minute or two from the failure to a name that answers again,
  because detection waits out a timeout (lesson 16's `ttl`) and DNS answers are cached (lesson 19).
  The provider's documentation gives a figure; the honest one is the one you measure.
- **Every connection breaks.** The application reconnects and retries, exactly as lesson 19's
  `orders.sh` needed to, and a driver or a pool (lesson 18) that caches the old address keeps
  connecting to a server that is not the primary.
- **The standby is usually synchronous inside the region**, so a failover loses no confirmed commit,
  and commits pay the round trip (lesson 12). Read whether yours is, because "high availability" on a
  product page does not say.
- **Read replicas are separate** from the standby that fails over, and asynchronous: lesson 13's stale
  reads apply unchanged.

Most providers let you **force a failover**, often as an option of a reboot. That is lesson 23's
rehearsal on somebody else's servers, and the only way to learn what your application does during
those minutes, before a real one shows you.
