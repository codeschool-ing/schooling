---
title: Why configuration moves to one place
version: 1
---

**At one machine, hardening is a list of commands. At fifty, it is a question of who decides and
where the decision lives.** Lesson 2 wrote the portal's baseline as a check and a playbook for one
server. A firm the size of Jatobá has a few servers and a few dozen workstations, and each of them
drifts in its own way: a setting changed for a printer that was then replaced, a rule relaxed for
one afternoon, a laptop that was off the network when everything else was updated.

The wrong picture is that a fleet is many copies of the same machine, so the same commands typed on
each will keep them the same. They do not stay the same, and nobody types the commands on the
fortieth machine on the same day as the first. What keeps a fleet consistent is **desired state**:
one description of how every machine should be, held centrally, and a mechanism that compares each
machine with it and puts back what differs, on a schedule, without anybody remembering to.

Three things follow from moving configuration to one place, and each is a security property in
its own right.

**The rule is readable.** "Every workstation refuses root over SSH" is one line somebody can review,
instead of a fact true on whichever machines somebody visited. An auditor asks for the rule, not for
forty screenshots.

**The differences are declared.** Not every machine should be the same. A workstation and a server
need different settings, and one machine may need an exception. Central configuration makes each
difference a written statement attached to a group or a machine, which is the only form in which a
difference can be reviewed. An undeclared difference is drift.

**Drift is corrected without being noticed first.** A setting changed by hand is put back at the
next run, whether or not anybody saw it change. That is a defence on its own: an intruder who
relaxes a setting to stay in has it tightened again within the hour, and the change shows in the
log of the run that undid it.

## Two families of tools

On Windows networks joined to an Active Directory domain, the mechanism is **Group Policy**, built
into the operating system, and the next two sections explain it. On machines that are not domain
members, laptops managed over the internet among them, Microsoft's answer is **Intune**, a mobile
device management service that pushes configuration profiles to enrolled devices. Neither was run
for this course, because the lab has no Windows machine; they are taught from Microsoft's documented
behaviour.

On Linux the mechanism is a **configuration management tool**: Ansible, Puppet, Chef or Salt. The
last three sections of this lesson build the Linux half in the lab with Ansible, for three machines
with different jobs, and run it on a timer. The ideas carry from one family to the other almost
unchanged, and so do the mistakes.
