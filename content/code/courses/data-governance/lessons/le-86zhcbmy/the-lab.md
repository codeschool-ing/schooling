---
title: Your lab, and three ways to build it
version: 1
---

**Nobody learns access control by reading a grant.** You learn it when a query you expected to
work answers `permission denied`, or when one you expected to fail returns six thousand rows. So
every lesson here is run, on a machine you build yourself. The platform gives you no machine: the
lab is yours, and the next three sections build it from nothing, with every command and every
file on the page.

It is one Linux machine with:

- **PostgreSQL 16**, in a cluster of its own called `gov` on port 5433, holding Ipê's database,
  `ipe`: three schemas — `sales`, `health` and `support` — and seven tables, loaded with 6,012
  customers and seven years of orders. Section 4 builds the cluster and section 5 the data.
- **A small certificate authority** of the lab's own, which lesson 3 makes so that the database
  has a certificate a client can check.
- **OpenBao**, a key-management server, which lesson 4 installs and starts.

All of it runs on **Ubuntu 24.04**. Every transcript in this course was recorded there, and the
commands assume its package names and its paths. Another Linux works if you translate the
package names; the paths in the transcripts will then differ.

## Three ways to run it

**In a virtual machine — recommended.** An Ubuntu 24.04 virtual machine with 2 GB of memory and
10 GB of free disk is enough, in VirtualBox, UTM on a Mac, Hyper-V or any hypervisor you already
have. The lab adds a user, a database server, a key-management server, a sudoers file and two
lines in `/etc/hosts`: exactly the kind of change you do not want on the computer you work on, and
in a virtual machine a mistake costs a snapshot. `virtualization` lesson 4 builds one in
VirtualBox if you have never made one. **Cost to your computer**: the memory and disk above while
it runs, and nothing after you delete it.

**Installed on a Linux computer of your own.** Possible, if it runs Ubuntu 24.04 — or Windows,
through WSL with an Ubuntu 24.04 distribution. Read section 4 before running it: it writes
`/etc/hosts`, `/etc/postgresql-common/user_clusters` and a sudoers file, and if any of those is a
file you care about, use the virtual machine. One part of lesson 3, opening an encrypted volume,
needs the kernel's device-mapper, which WSL does not offer; that lesson says so where it matters.
**Cost**: about 300 MB of packages, and changes to system files you have to undo by hand.

**Online, on somebody else's machine.** A small cloud virtual machine running Ubuntu 24.04, with
1 vCPU and 2 GB of memory, reached by SSH — from a terminal or from the provider's page in a
browser. Any provider will do; the course depends on none of them, and free tiers come and go.
**Cost**: nothing on your computer, an account with a provider, and money or a free allowance for
the hours it runs. Every row in this lab is invented, so nothing real is sent anywhere, but switch
the machine off when you are not studying.

Whichever you choose, the commands in the rest of the course are the same.
