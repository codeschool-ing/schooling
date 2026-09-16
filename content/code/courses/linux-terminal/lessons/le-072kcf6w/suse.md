---
title: SUSE, the third family
version: 1
---

Smaller than the other two, older than Ubuntu, and the one you will meet in specific places rather
than generally: manufacturing, German-speaking Europe, and almost anywhere running SAP.

Worth a short section rather than a long one — **because if you can drive Red Hat you can mostly
drive this**, and the differences are nameable.

## The three names

| | what it is |
|---|---|
| **SLE** | SUSE Linux Enterprise. The paid product, with long support — Server is `SLES`, Desktop is `SLED` |
| **openSUSE Leap** | free, built from the same sources as SLE, and version-aligned with it |
| **openSUSE Tumbleweed** | free, **rolling** — always current, never a version upgrade. Section 08 |

Leap and SLE being built from the same sources is the useful part: it is the same relationship
Rocky has with RHEL, arranged deliberately by SUSE rather than reconstructed by volunteers.

## What you type

`.rpm` packages, like Red Hat, and a different tool in front of them:

| | |
|---|---|
| install | `sudo zypper install nginx` |
| update everything | `sudo zypper update` |
| apply patches only | `sudo zypper patch` |
| search | `zypper search nginx` |
| refresh the index | `sudo zypper refresh` |

**`zypper patch` is the one with no equivalent elsewhere.** `update` moves packages to newer
versions; `patch` applies only the issued fixes — security and bug — and leaves everything else
where it is. On a production machine that is a genuinely different operation, and it is the kind
of distinction an enterprise distribution exists to make.

## The two things SUSE is actually known for

**YaST**, a configuration tool that covers the whole machine — users, network, services,
partitions — in one interface, with a text mode that works over SSH. Nothing in the other families
is quite like it. People who like it miss it elsewhere; people who prefer editing `/etc` by hand
find it in the way.

**Btrfs with snapshots by default.** SUSE installs with a filesystem that can take snapshots, and
wires it to the package manager: an update takes a snapshot first, and a machine that will not
boot afterwards can be rolled back from the boot menu. That is a real answer to a real fear, and
it is not the default anywhere else.

## And AppArmor, not SELinux

SUSE uses **AppArmor**, the same framework as the Debian side, rather than Red Hat's SELinux.
Which is the one cross-family fact worth carrying: **the security framework does not follow the
package format.** SUSE and Red Hat both use `.rpm` and disagree here.

## Where you will actually meet it

If you never work with SAP or European manufacturing, possibly nowhere. If you do, you will meet
nothing else. That is a reasonable thing to know about a tool — not every family is one you have
to be ready for, and recognising the name and the package manager is enough until the day it is
not.
