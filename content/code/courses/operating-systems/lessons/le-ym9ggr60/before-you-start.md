---
title: Before you start: can this computer run it?
version: 1
---

**Windows 11 has hardware requirements that Windows 10 did not**, and they are the first thing to
check, because a computer that fails them cannot be upgraded the normal way.

| | minimum for Windows 11 |
|---|---|
| processor | 64-bit, 1 GHz or faster, 2 or more cores, on Microsoft's list of supported models |
| memory | 4 GB of RAM |
| storage | 64 GB |
| firmware | UEFI, capable of Secure Boot (lesson 1) |
| security chip | TPM 2.0 |
| graphics | DirectX 12 compatible |

Two rows cause almost every refusal. The **processor list**: many computers from before about 2018 run
fine but are not on it. And the **TPM**, the *Trusted Platform Module*, a small security chip (or a
feature of the processor) that stores encryption keys. It is often present but switched off in the
firmware settings.

Microsoft's **PC Health Check** app runs these checks and says which one failed. In an office, it is
the first thing to run on every machine before promising anybody an upgrade.

## Why it matters now

Windows 10 stopped receiving free security updates in **October 2025**. A computer that cannot run
Windows 11 can buy a limited period of paid updates, or move to another system, but it should not
simply carry on: a system without security updates is one discovered flaw away from being the way
into the office network.

## Three things to settle first

1. **The data.** Anything on the computer that matters is copied somewhere else first. A clean
   install erases the disk, and the installer asks only once.
2. **The licence.** Most computers sold with Windows carry a **digital licence** tied to the
   hardware, and a reinstall on the same machine activates by itself. Otherwise you need a 25-character
   **product key**.
3. **The edition.** Home, Pro or Enterprise. For an office, Pro at least; lesson 5 explains why.

Checking the version of a machine that is already running, before deciding anything, takes one of
these:

```sh
winver                          # a window with the version and build
systeminfo                      # OS name, version, install date, memory, updates
Get-ComputerInfo -Property OsName, OsVersion, OsBuildNumber   # the same, as PowerShell
```

**None of these were run for this lesson**; they are Windows commands, and the machine this course's
transcripts come from is Linux. `winver` opens a small window; the other two print text.
