---
title: Long-term containment
version: 1
---

Short-term containment is a tourniquet: it holds, and nobody wants to live with it. **Long-term
containment** is the set of temporary measures that let the business work normally again while eradication
and recovery are prepared, which can take days. The systems stay in service, under conditions.

For Thursday's incident, the conditions could read like this:

| measure | why it can stay for a while |
|---|---|
| `files` reaches the internet only through the egress rule, backup allowed | the office only ever needed the backup; the rule turns out to be the policy it should always have had |
| bruno works with a **new password and a new key**, and the old key is gone from every host in scope | the account is back in service and the stolen credentials are not |
| `gw` accepts **keys only**, no passwords, once every user has a key | Thursday began with a guessed password; nothing to guess is the fix for that |
| a **Sigma rule** alerts on any connection from `files` to a destination other than the backup | if the rule is ever removed by mistake, or something tries anyway, somebody hears about it |
| `gw` is **watched more closely** for two weeks: every login reviewed the next morning | the key was found; whether it was the only thing left behind is not yet known |
| a **rebuild of `gw`** is planned for lesson 14 | a host an intruder controlled cannot be fully trusted again; the date is set now so it does not slide |

Two things about the list. **Some of it should never be undone.** The egress rule and the keys-only setting
were containment on Thursday and are simply better configuration afterwards; lesson 15 is where that kind of
finding becomes a change to the standard build, so the next server starts with it. And **some of it has a
date on it**: closer monitoring that never ends is a queue nobody reads after the first month, which is
lesson 6's alert fatigue arriving through a different door.

Long-term containment also has a precondition that is easy to skip: **the backups are checked before
eradication starts.** Rebuilding `gw` assumes there is a known-good copy of its configuration from before
Thursday. If the only copy is the one the intruder could edit, the rebuild restores their work.
