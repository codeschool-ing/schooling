---
title: A server has no desktop
version: 1
---

The office server needs no screen: nobody sits in front of it. For that job there is **Ubuntu Server**,
and it is different in three ways worth knowing before you choose it.

**The installer is text.** Same questions as the desktop one (language, keyboard, network, disk,
account), answered with the arrow keys and Enter. It looks old-fashioned and it is quicker.

**It offers to install the SSH server.** SSH is how you reach a Linux machine from another computer and
type commands on it as if you were sitting there; the networks course uses it throughout. Tick it during
installation, and the server can go back in its cupboard with no keyboard or monitor attached.

**There is no graphical interface afterwards.** You sign in to a prompt like the ones in this course's
transcripts, and everything is done with commands. That is a feature: nothing to update that nobody uses,
less memory spent, fewer ways in for an attacker.

## Desktop or server?

| | Desktop | Server |
|---|---|---|
| used by | a person, in front of it | other computers, over the network |
| interface | graphical | text, reached over SSH |
| typical office job | the reception PC | shared files, backups, the printer queue |

Both are the same Ubuntu underneath: the same `apt`, the same `sudo`, the same tree of folders. A
server can gain a desktop later with one package, and a desktop can run server programs. The choice is
about what the machine is for, not what it can do.

## In the cloud

Most Linux servers today are not in a cupboard at all: they are virtual machines rented from a cloud
provider. Those are not installed from an ISO. They start from a ready-made **image**, and the first-hour
steps of section 05, updates and a user with `sudo`, are the part that stays the same. The virtualization
course picks up from here.
