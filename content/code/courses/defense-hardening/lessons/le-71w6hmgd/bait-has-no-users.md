---
title: Bait has no users
version: 1
---

**A honeypot is something that has no legitimate use, put where an intruder would find it.** A
machine nobody's work needs, a file nobody's job opens, an account nobody logs in as. Because none
of them has a user, **any touch is a finding**, and that turns the usual problem of detection
upside down.

Every other detector in this course faces the same difficulty: telling the unusual from the
merely uncommon, across thousands of events that are almost all normal. Lesson 8's rules had to
know what the portal does; lesson 9's scanner had to argue with order numbers; lesson 11 spent a
section on tuning. A honeypot needs none of that. It does not have to recognise an attack, because
it is not looking at anybody's work. It only has to notice that somebody arrived.

The common picture of a honeypot is an elaborate trap that lures attackers in and studies them for
weeks. That kind exists, and researchers run them on the internet. **Inside a firm the useful kind
is small and dull**, and its job is not to study anyone. It is an alarm wire in the place an
intruder walks through after the first machine, when they look around to see what else is there.
That is the stage where nothing else in this course is very good at noticing them, because looking
around uses ordinary tools in ordinary ways.

## Three kinds of bait

| bait | what it is | what a touch means |
|---|---|---|
| **a honeypot** | a machine, or ports on one, that offers services nobody uses | somebody is exploring the network |
| **a honeytoken** | a file, a credential or a record that nothing legitimate reads | somebody is going through files they had no reason to open |
| **a honey account** | an account name that exists nowhere, written where it would be found | somebody is trying names they found |

This lesson builds one of each in the lab: a honeypot on `trap`, a bait file on `web`, and a
username planted in that file that no system knows.

**What a honeypot costs is mostly care.** It must look worth touching, it must never be the thing
that gets the firm into trouble, and the alerts must reach somebody. The section on placement says
where that care goes. Start the lab with the machines this lesson uses:

```sh
sudo bash hostlab.sh up trap desk web
```
