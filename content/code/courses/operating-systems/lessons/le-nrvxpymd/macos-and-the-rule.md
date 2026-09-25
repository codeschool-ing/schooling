---
title: macOS, and the rule all three share
version: 1
---

A Mac has two kinds of account: **Administrator** and **Standard**, set in *System Settings > Users &
Groups*. Lesson 4's Setup Assistant made the first account an administrator.

When a Standard user, or an administrator, does something that needs more, a dialog asks for **an
administrator's name and password**. It is UAC's credential prompt, and there is no Yes-only version:
**on a Mac even an administrator types the password**, or uses Touch ID, which is closer to `sudo`
than to UAC.

In Terminal, `sudo` works as on Linux, and **only administrators may use it**. The accounts and the
admin group can be listed:

```sh
dscl . -list /Users | grep -v '^_'          # the accounts, without the system ones
dscl . -read /Groups/admin GroupMembership  # who is an administrator
id                                          # the same command as on Linux
```

**None of those were run for this lesson.** The `grep -v '^_'` hides the system accounts, whose names
start with an underscore on macOS; `_www` is the web server's, like Linux's `www-data`.

## The three side by side

| | Linux | Windows | macOS |
|---|---|---|---|
| the all-powerful account | `root`, locked on Ubuntu | *Administrator*, disabled | `root`, disabled |
| what makes a person an administrator | the `sudo` (or `wheel`) group | the Administrators group | the admin group |
| borrowing the power | `sudo`, per command | a UAC prompt, per program | a password dialog, per action |
| whose password | your own | Yes, or an administrator's | an administrator's |
| where it is recorded | the journal, per command | the Security log, if auditing is on | the unified log |

The rule under all of it is the **principle of least privilege**: every person and every program gets
the least access that lets it do its job. Accounts for people are standard; the power is borrowed, used,
and returned; and the record of each borrowing is what makes a shared machine accountable.
