---
title: Accounts on Windows
version: 1
---

A Windows PC can have three kinds of account, and lesson 2 chose among them at setup:

| kind | signs in with | where it lives |
|---|---|---|
| **local account** | a name and password on this PC | only on this PC |
| **Microsoft account** | an e-mail address | Microsoft, synced to the PC |
| **work or school account** | the organisation's address | Entra ID or the office's Active Directory |

Whatever the kind, **two groups decide what it may do**: **Administrators** and **Users**. A member of
Users is a **standard user**, who can run programs and change their own settings but cannot install for
everybody, change system settings or read other people's files.

Windows also has a built-in account named **Administrator**, **disabled by default** since Windows
Vista. Like Ubuntu's root, it is there and nobody signs in as it.

```sh
net user                                   # the local accounts
net localgroup Administrators              # who is an administrator here
Get-LocalUser | Select-Object Name, Enabled, LastLogon
Get-LocalGroupMember -Group Administrators
New-LocalUser -Name "reception" -NoPassword
Add-LocalGroupMember -Group Users -Member "reception"
whoami /groups                             # which groups this session carries
```

**None of those were run for this lesson.** `whoami /groups` is worth remembering: it lists the groups
the *current session* carries, which is what decides access, and after somebody is added to a group it
shows whether their session has caught up. Lesson 9's rule was the same: **group changes arrive at the
next sign-in**.

*Settings > Accounts > Other users* does the same with windows and buttons; **`lusrmgr.msc`**, *Local
Users and Groups*, is the fuller tool, on Pro and above.
