---
title: Active Directory and Entra ID are not the same thing
version: 1
---

**The name invites the wrong picture.** Microsoft Entra ID was called Azure Active Directory until
2023, and many people still assume it is the office's Active Directory moved into the cloud. It is
not. They are two different directories, built for two different worlds, and a company that has
both has to decide how one person can be the same person in each.

| | Active Directory Domain Services | Microsoft Entra ID |
|---|---|---|
| where it runs | on domain controllers, servers the company owns | in Microsoft's cloud, as a service |
| what it was built for | computers on one network: logging in to Windows, file shares, printers | applications on the internet: Azure, Microsoft 365, any app that speaks the web's protocols |
| how it proves identity | Kerberos and NTLM, on the local network | OAuth 2.0, OpenID Connect and SAML, over HTTPS |
| how it is organised | domains, forests and organisational units, with group policy | a flat tenant, with groups and administrative units |
| who joins it | Windows machines on the company network | devices anywhere, and applications |

Neither replaces the other in a company that runs both. The office's file server still asks
Active Directory; Azure's portal asks Entra ID. **The question this lesson answers is how a person
with an account in the first gets one in the second without anybody typing it twice**, and how they
then prove who they are to the second.

## Where an account is born

Every user in a hybrid company has a **source of authority**: the one directory where the account is
created, changed and disabled. For most companies that already run Active Directory, it is Active
Directory. HR's process creates the account there, a leaver is disabled there, and Entra ID receives
a copy.

That makes one rule non-negotiable: **change a synchronised account in its source, never in its
copy.** A name corrected in Entra ID is overwritten at the next synchronisation; a user disabled only
in Entra ID can still log in to the office's machines. The emergency accounts of lesson 11 are the
deliberate exception, born in the cloud so that they depend on nothing on the ground.

## What travels, and in which direction

Synchronisation copies from Active Directory to Entra ID: users, groups and their memberships,
contacts, and, if the company chooses, a hash of each password, which the last section of this
lesson weighs. A few things can travel back, called **writeback**: a password changed in the cloud,
so that a person who resets theirs through Entra ID's self-service page can then log in to the office
too.

**Everything in this lesson is read, not run.** Synchronisation needs an Active Directory and a
tenant, and a lab with neither cannot show it. One question about the result is public, though, and
the last section asks it of Entra ID itself.
