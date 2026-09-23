---
title: Targets, and the machine that will not come up
version: 2
---

A **target** is a named group of units. Nothing more: it runs no program and has no `ExecStart=`.
It exists so that "bring the machine to this state" is one name.

You met one in section 09 without being told what it was:

```
Created symlink …/etc/systemd/system/multi-user.target.wants/hello.service → /etc/systemd/system/hello.service.
```

`multi-user.target` is the state *the machine is up, the network works, services are running, and
nobody is expected at a graphical screen*. Enabling a service put it in that target's `wants`
directory — so reaching the target starts it.

## Targets replaced runlevels

SysV had **runlevels**, numbered 0 to 6, and you will still meet the numbers in old documentation
and in muscle memory:

| runlevel | target | is |
|---|---|---|
| 0 | `poweroff.target` | off |
| 1 | `rescue.target` | single-user, root only, minimal services |
| 3 | `multi-user.target` | **the normal state of a server** |
| 5 | `graphical.target` | the same plus a desktop |
| 6 | `reboot.target` | restarting |

The numbers were a total order — level 5 implied everything in level 3 — which was tidy and could
not express *this particular set*. Targets are units with dependencies, so they compose, and a
machine can have as many as somebody defines.

```
systemctl get-default                       # what it boots into
sudo systemctl set-default multi-user       # boot without a desktop from now on
systemctl isolate rescue.target             # go there now
systemctl list-units --type=target          # what is active
```

**`set-default` is one symlink**, exactly like section 09's: `/etc/systemd/system/default.target`
pointing at the one you chose. Everything in systemd is a symlink somewhere, and once you see that
the design stops being mysterious.

**`isolate` is not `start`.** It starts that target and **stops everything not in it**, which on a
running server means dropping services out from under whoever is using them. Useful in a rescue
console; alarming over ssh.

## The ones worth recognising

Beyond the runlevel equivalents, four targets turn up in unit files constantly:

| | reached when |
|---|---|
| `network.target` | the network stack is **configured**, which is not the same as reachable |
| `network-online.target` | something has actually come up — and only if a `wait-online` service is enabled |
| `local-fs.target` | everything in `/etc/fstab` is mounted — lesson 3 section 12 |
| `sysinit.target` | the early, low-level setup is done |

**`After=network.target` does not mean the network works.** That is the single most common wrong
assumption in a hand-written unit: the service starts, tries to bind an address or resolve a name,
and fails once at boot and works every time you start it by hand. `After=network-online.target`
plus `Wants=network-online.target` is the honest version, and it requires the `wait-online` service
to be enabled or it silently means nothing again.

## Why the boot is faster, and how to see where it went

Section 08 said systemd starts things in parallel by resolving dependencies rather than running a
numbered list. You can watch the result:

```
systemd-analyze                     # how long the boot took, split into kernel and userspace
systemd-analyze blame               # every unit, slowest first
systemd-analyze critical-chain      # the chain that actually determined the total
```

**`blame` and `critical-chain` answer different questions, and people reach for the wrong one.**
`blame` lists what took longest; `critical-chain` lists what the total was *waiting on*. A unit can
take thirty seconds and cost nothing, because nothing was waiting for it. Fix the chain.

## The machine that will not come up

This is the section's real subject, and the sequence is worth having before you need it.

**A boot stops somewhere.** Either it hangs, or it drops you into an emergency shell, and in both
cases the useful information is already on the screen or in the journal.

| symptom | what it usually is |
|---|---|
| hangs on a job, with a countdown | a unit waiting for something that will not arrive — the countdown is its timeout |
| `Give root password for maintenance` | a filesystem in `/etc/fstab` could not be mounted |
| emergency shell, nothing mounted | the root filesystem itself, or a badly wrong `fstab` |
| boots, but a service is missing | section 09: started once by hand, never enabled |

**The `fstab` one is the most common by far**, and lesson 3 section 12 told you the defence:
`sudo mount -a` after editing, and confirm it is silent before you reboot. `nofail` in the options
column is the belt-and-braces version — it lets the boot continue when that mount fails, which is
right for a data disk and wrong for the root.

Once you are at a prompt, whatever kind:

```
journalctl -b -p err        # what failed this boot
systemctl --failed          # and what is still failing
systemctl list-jobs         # what is stuck waiting, right now
```

`list-jobs` is the one for a hang: it prints the units systemd is currently waiting on, which is
exactly the question.

## Two ways in when there is no prompt at all

**The kernel command line**, edited in the bootloader at startup, takes systemd arguments:

| add | gets you |
|---|---|
| `systemd.unit=rescue.target` | single user, root shell, minimal services |
| `systemd.unit=emergency.target` | less than that — root filesystem read-only, almost nothing |
| `init=/bin/bash` | no init at all. The last resort |

**A rescue or live image** is the other way, and the one for a root filesystem that will not mount.
Boot it, mount the real root somewhere, and fix the file. Lesson 3 section 12's `mount` is all you
need.

Both of these are worth reading now and trying once on a machine you can afford to break. The
afternoon you need them is not the afternoon to learn them.
