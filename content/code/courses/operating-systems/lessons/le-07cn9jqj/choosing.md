---
title: Choosing one for a job
version: 1
---

The three answers Ana was given were each right for somebody. The way to choose is to start from the
**job** and let it rule distributions out.

| the job | a good fit | why |
|---|---|---|
| the office file server | **Ubuntu LTS** or **Debian stable** | years of fixes, nothing changes under it |
| software certified on RHEL | **RHEL**, or **Rocky** / **AlmaLinux** | what the vendor tests; the real thing if support demands it |
| an office desktop | **Ubuntu LTS** or **Linux Mint** | long support, drivers, and help easy to find |
| a developer's laptop | **Fedora**, or a rolling one | new tools early, one person affected by a break |
| inside a container | **Alpine** or **Debian slim** | small, and replaced rather than upgraded |

And four questions that settle most of the rest:

1. **How many years must it run?** Rule out everything whose support ends sooner.
2. **Does anything on it need a certified platform?** Then the vendor's list decides.
3. **Who will look after it?** A team that knows `apt` works faster on Ubuntu than on the best
   distribution it has never used. For an office where Ana is the whole IT department, that counts.
4. **Can someone be paid to help?** Canonical sells support for Ubuntu, Red Hat for RHEL and SUSE for
   SLES. Debian, Fedora and Arch have excellent communities and nobody to call.

For the cupboard, the answer comes out as **Ubuntu 26.04 LTS**: years of support, the family the
server already uses, and the accounting software is not on it. If the accounting software moved onto
that server, the vendor's list would decide instead, and the answer would be Rocky or AlmaLinux.

## What does not decide it

**Which one looks nicest.** The desktop's appearance is a setting, and servers have none. **Which one
is fastest.** With the same kernel the differences are small next to what the hardware decides.
**Which one is popular on a forum this year.** Popularity helps when searching for answers; it does not
keep a server patched.
