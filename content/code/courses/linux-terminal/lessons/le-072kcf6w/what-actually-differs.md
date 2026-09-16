---
title: The six things that actually differ
version: 1
---

This is the section the lesson was built to reach. Everything before it was orientation; this is
the list you will use.

**Six differences.** Almost every "that command does not work here" moment is one of them.

## The table

| | Debian, Ubuntu | RHEL, Rocky, Alma | SUSE | Alpine |
|---|---|---|---|---|
| **package manager** | `apt` | `dnf` | `zypper` | `apk` |
| **package format** | `.deb` | `.rpm` | `.rpm` | `.apk` |
| **web server package** | `apache2` | `httpd` | `apache2` | `apache2` |
| **its config lives in** | `/etc/apache2` | `/etc/httpd` | `/etc/apache2` | `/etc/apache2` |
| **firewall front end** | `ufw` | `firewalld` | `firewalld` | `iptables` directly |
| **security framework** | AppArmor | **SELinux** | AppArmor | neither, by default |

Two rows in there are the ones that will actually catch you.

## 1 · Apache is called two different things

`sudo systemctl restart apache2` on a Rocky machine answers that there is no such service, and the
service is running. It is called `httpd` there, its configuration is in `/etc/httpd`, and the
package is `httpd` too.

This is the clearest example of what a family buys you: **the software is identical, and the name
of the thing you type is not.** Nginx, by contrast, is `nginx` everywhere, which is why nobody
warns you about Apache until it happens.

## 2 · SELinux is on, and it is above the permissions you know

On the Red Hat side SELinux is enabled in enforcing mode by default. Lesson 4 teaches nine
permission bits; SELinux is a second system on top of them, and the two disagree in one direction
only — **SELinux can deny what the bits allow, and never the reverse.**

What that produces is the most confusing refusal a beginner meets:

> `ls -l` says the file is readable by everyone. The web server cannot read it. Nothing about the
> permissions explains why.

Every forum answer will tell you to disable SELinux. Do not learn that habit. Lesson 4 gives it a
section; for now, recognise the shape and know there is a log that names the denial.

## What does not differ, which is more of it

The list above is short, and that is the useful fact. All of these are the same everywhere:

- the shell, and everything in lessons 3, 6, 8 and 9
- the filesystem layout of lesson 1 section 13
- users, groups and the permission bits of lesson 4
- `systemd`, `systemctl` and `journalctl` — lesson 5, and the same on every family except Alpine
- processes, signals, `ps`, `top` — lesson 6
- `grep`, `sed`, `awk`, pipes and redirection — lesson 8
- SSH, and everything about reaching a machine

**Alpine is the exception that proves the rule**: it differs in the userland and the init system as
well, which is why section 07 gives it a section of its own rather than a column.

## Translating a command you were given

The practical skill is taking an instruction written for one family and running it on another:

| you were given | on Red Hat | on SUSE |
|---|---|---|
| `apt update && apt install nginx` | `dnf install nginx` | `zypper install nginx` |
| `apt remove nginx` | `dnf remove nginx` | `zypper remove nginx` |
| `apt search nginx` | `dnf search nginx` | `zypper search nginx` |
| `ufw allow 80` | `firewall-cmd --add-service=http` | `firewall-cmd --add-service=http` |
| `systemctl restart apache2` | `systemctl restart httpd` | `systemctl restart apache2` |

Notice how much of each line survives. The verb is the same, the package name is usually the same,
and what changed is the first word — which is exactly what the next section's one command tells
you.
