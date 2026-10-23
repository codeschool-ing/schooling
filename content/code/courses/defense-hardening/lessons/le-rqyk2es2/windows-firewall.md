---
title: The Windows firewall, per program
version: 1
---

**Nothing in this section was run for this course.** The lab has no Windows machine, so what
follows is Microsoft's documented behaviour of Windows Defender Firewall, the firewall built into
every supported version of Windows, with no transcript and no screenshot.

## Three profiles

Windows keeps three sets of rules and applies one per network connection, by where the machine
thinks it is:

| profile | when it applies |
|---|---|
| **Domain** | the machine can reach a domain controller of the domain it belongs to: it is at work |
| **Private** | a network the user marked as trusted, such as a home network |
| **Public** | anything else, and the default for a network nobody classified: a café, an airport |

That is the laptop problem of the first section solved in configuration: the same machine is
tighter on a café's Wi-Fi than in the office, without anybody changing anything. The defaults are
the same in all three, **inbound blocked unless a rule allows it, outbound allowed unless a rule
blocks it**.

## Rules about a program

A Windows rule can name a **program**, by the path of its executable, or a **service**, by its
service name, as well as addresses and ports. That is the per-application rule of this lesson
without accounts or control groups: the firewall itself knows which program owns each connection.
A rule that blocks a program's outbound connections looks like this in PowerShell, from the
documentation of the `NetSecurity` module:

```
New-NetFirewallRule -DisplayName "Portal: no outbound" -Direction Outbound `
    -Program "C:\Portal\portal.exe" -Action Block -Profile Domain,Private,Public
```

**Two behaviours catch people out.** A block rule wins over an allow rule that matches the same
traffic, whatever order they were created in, so an exception is written by narrowing the block
rather than adding an allow. And the first time an unknown program listens for connections, Windows
may ask the user whether to allow it, which on a managed machine is a decision that should belong
to the administrator, not to whoever is in front of the screen; Group Policy can switch the
question off.

## Managed centrally

On a firm's machines nobody sets these rules by hand. They are pushed by **Group Policy**, under
*Computer Configuration, Windows Settings, Security Settings, Windows Defender Firewall with
Advanced Security*, or by a management service such as Intune, which lesson 3 describes, and
policy can stop local administrators from adding rules of their own. It is the same discipline as
the files of this lesson: the rule set is written once, in one place, reviewed there, and applied to
every machine that should have it.
