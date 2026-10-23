---
title: Mandatory access control, confining a program
version: 1
---

**Nothing in this section was run for this course.** Mandatory access control is enforced by the
kernel, and the kernel these containers share does not offer it to them; what follows is taken from
the AppArmor and SELinux documentation.

## Permissions say who; confinement says what

The permissions of lesson 6 answer one question: may this **account** read this file? A program
inherits every right its account has. The portal runs as `portal`, so anything that makes the
portal misbehave gets everything `portal` may do, which on most servers is far more than the portal
needs.

**Mandatory access control adds a second question that the account cannot answer away: may this
program do this, at all?** A policy written for the portal lists what it may touch, its own files,
its port, the Python libraries, and the kernel refuses everything else, to the portal, whatever its
account, and to root running the portal too. It is *mandatory* because the owner of a file cannot
grant an exception, the way they can with permissions.

## AppArmor and SELinux

Linux has two common implementations, and a distribution ships one:

| | AppArmor | SELinux |
|---|---|---|
| default on | Ubuntu, Debian, SUSE | Red Hat, Fedora, Rocky, Alma |
| a rule names | paths: `/opt/portal/** r,` | labels on files and processes, matched by type |
| writing a profile | readable, per program, often generated in learning mode | harder to read, very fine-grained, mostly shipped by the distribution |
| two modes | `complain` logs what it would refuse; `enforce` refuses | `permissive` logs; `enforcing` refuses |

An AppArmor profile for the portal would read much like this, a sketch from the documented syntax
rather than a tested file:

```
/opt/portal/portal.py {
  #include <abstractions/base>
  #include <abstractions/python>
  /opt/portal/** r,
  network inet stream,
  deny /home/** rw,
}
```

The usual way to write one is the same as for every rule in this course: run the program in
**complain** mode while it does its normal job, read what it touched, write that down as the
profile, and only then switch to **enforce**. `aa-status` lists the profiles and their modes, and
`aa-genprof` and `aa-logprof` help build a profile from the log.

## Why the lab cannot show it

AppArmor and SELinux live in the kernel's security layer, which is shared by every container on the
machine, and only the host can load a policy into it. The lab's image does not even install AppArmor's tools, because inside a
container there would be nothing for them to manage. In your own Ubuntu virtual machine, outside the containers, AppArmor is present
and enforcing: `sudo aa-status` there lists the profiles that Ubuntu's own packages install. That is the place to try the ideas of this section, on a program of your own.

Lesson 12 does run one form of confinement in the lab: the sandboxing options systemd offers each
service, which build a smaller world for a program out of namespaces rather than a kernel policy.
