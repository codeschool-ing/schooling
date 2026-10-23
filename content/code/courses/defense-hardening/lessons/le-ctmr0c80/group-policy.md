---
title: Group Policy, as Microsoft documents it
version: 1
---

**Nothing in this section was run for this course.** The lab has no Windows machine and no Active
Directory domain, so what follows is Microsoft's documented behaviour, with no transcript and no
screenshot. The names are the ones you will meet on the screen of the Group Policy Management
Console.

**A Group Policy Object** (GPO) is a named collection of settings. It has two halves:
**Computer Configuration**, applied to a machine when it starts and on a schedule after that, and
**User Configuration**, applied to a person when they log on, on whichever machine that is. Inside
each half are Policies (settings the system enforces, greyed out for the user) and Preferences
(settings it writes, which a user may still change between refreshes). A security baseline is almost all Computer
Configuration Policies: password rules, which services run, who may log on locally, firewall rules,
audit settings.

A GPO does nothing until it is **linked** to a container in the directory: a **site**, the
**domain**, or an **organisational unit** (OU), which is a folder of computer and user accounts.
Linking it to an OU applies it to every computer and every user inside that OU and inside the OUs
below it. The same GPO can be linked in several places, which is how one baseline reaches several
departments.

## When it applies

A domain member applies Computer Configuration when it starts and User Configuration when somebody
logs on. After that it refreshes in the background, **every 90 minutes plus a random offset of up
to 30 minutes**, so that thousands of machines do not ask the domain controllers at the same
moment. Domain controllers refresh every 5 minutes. Security settings are reapplied every 16 hours
even when nothing changed, which is what undoes a local change to one of them.

An administrator can ask for a refresh at once with `gpupdate /force` on the machine, and can ask
what was applied, and from which GPO, with `gpresult /r`, or `gpresult /h report.html` for the full
report. That report, the **resultant set of policy**, is the Windows equivalent of `sshd -T` from
lesson 1: not what any one GPO says, but what the machine ended up with.

## Who gets it

By default a GPO applies to every computer and user in the containers it is linked to, because the
group **Authenticated Users** holds the permission to apply it. Two filters narrow that:

- **security filtering** replaces Authenticated Users with a particular group, so a GPO linked to
  the whole domain applies only to the members of, say, "Finance laptops";
- **WMI filtering** attaches a query about the machine, such as its Windows version, and the GPO
  applies only where the query is true.

Both are easy to get wrong in the direction that matters: a filter that matches nobody leaves the
baseline unapplied and raises no error. `gpresult` lists the GPOs a machine **denied**, with the
reason, and that list is the first place to look when a setting is missing.

## Where baselines come from

Microsoft publishes its own **security baselines** for each Windows release, as GPOs ready to
import, in the Security Compliance Toolkit, and CIS publishes its Windows Benchmarks with the
Group Policy path of every setting. Either is the starting point lesson 2 described: measure, adopt
what fits, and write down why for what does not.
