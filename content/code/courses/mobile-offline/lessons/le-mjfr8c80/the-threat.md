---
title: What encryption on the device protects against, and what it does not
version: 1
---

**Encrypting data at rest protects it from somebody who has the storage and not the unlocked
phone, and from nobody else.** That sentence decides every choice in this lesson, so it comes first.
The common picture is that encryption makes data safe, full stop. It makes data safe from a
particular person in a particular situation, and an app that encrypts against the wrong one spends
effort and buys nothing.

Write the situations down and the answer for each becomes plain:

| who has what | does encryption at rest help? |
|---|---|
| a thief with a **lost phone**, locked | yes: the storage is unreadable without the key the lock protects |
| somebody with a **backup** of the phone, on a computer or in the cloud | yes, if the data or the backup is encrypted with a key that is not in it |
| a **forensic copy** of the storage, taken from a phone that has been powered off | yes, and it is the case the platforms design for |
| **malware running as your app**, or code you shipped by mistake | no: it asks for the data the way your code does, and gets it decrypted |
| a **rooted or jailbroken phone**, unlocked, with a debugger attached | no: the keys are in memory while the app runs |
| the **person who owns the phone**, signed in | no, and it should not: it is their data |

**The last three are not failures of encryption.** Code that runs as the app is the app, as far as
the system can tell. Defending against it is a different job: keeping dependencies few and
reviewed, never loading code from a server, and lesson 20's rule of not keeping on the device what
does not need to be there.

## What the planner holds, against that table

The planner keeps courses, sessions and their dates. For most people that is not sensitive, and
the platform's own protection, the next section, is enough. Two things change the answer:

- **A planner for therapy sessions, or for a medical course with patient notes**, holds health data,
  which the law in Brazil (LGPD) and in Europe (GDPR) treats as a special category. Losing an
  unlocked phone is still out of reach; losing a locked one, or a backup, must not expose it.
- **A token that signs the person in** is a key to everything on the server. Lesson 20 keeps it in
  the Keystore or the Keychain and nowhere else.

So the lesson builds three layers, and each one answers a row of the table. The platform encrypts
the whole disk under the lock screen (the next section). The app can add its own encryption with a
key the hardware guards, for data a backup must not expose (the section after). And a biometric can
release that key only to the person in front of the phone (the last section).

**None of it replaces asking whether the data needs to be on the device at all.** That question is
lesson 20's, and it is the cheaper one: data that is not there cannot leak from a lost phone, a
backup, or malware.
