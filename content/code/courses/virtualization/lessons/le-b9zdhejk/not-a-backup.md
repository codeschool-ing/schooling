---
title: A snapshot is not a backup
version: 1
---

Everything in this lesson lived on the same disk as the guest: inside `vm1.qcow2`, or in a file next to
it that cannot be read without it. So a snapshot protects against **your own changes**, and against
nothing that happens to the disk:

| what goes wrong | does a snapshot save you? |
|---|---|
| an update breaks the system | yes: revert |
| a setting you tried makes things worse | yes: revert |
| the host's disk fails | no: the snapshot was on it |
| the guest's file is deleted or corrupted | no: the snapshot was in it, or depends on it |
| ransomware encrypts the host's files | no |

A **backup** is a copy somewhere else: another disk, another server, another building. The usual rule
is three copies, on two kinds of media, one of them away from the office, and Proxmox's `vzdump` and
lesson 6's backup server exist for exactly this. A snapshot is often *part* of taking one, because it
gives the backup a disk that stops changing while it is copied, and the snapshot is merged away
afterwards.

When a customer says "we have snapshots, so we have backups", the table above is the conversation to
have.
