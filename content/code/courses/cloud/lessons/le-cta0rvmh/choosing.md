---
title: Choosing, and the bucket somebody made public
version: 1
---

Choose by how the program reaches the data first, and by price second. **A program that needs a
path cannot use a key, and one that needs a disk cannot use either**, whatever the bar chart says.

| the data | where it goes | why |
|---|---|---|
| a database's data files, PostgreSQL on one instance | a block volume | many small writes at scattered places, one writer, and a database that expects a disk it controls |
| the operating system of a virtual machine | a block volume | only a block device can be booted from |
| images users upload, read by many web servers and browsers | objects in a bucket | written once, read many times by name; the cheapest gigabyte, and a browser can fetch one straight from the store |
| the same images, when the application only knows how to write to a directory | a file share | the application wants a path; it costs more and changes no code |
| application logs and backups | objects, with a lifecycle rule | written once, rarely read, kept for months; the classes and the expiry do the housekeeping |
| a legacy application exchanging files with another through a shared directory | a file share | both sides agree on a path, and changing either program is not on the table |

**Three mistakes turn up often enough to name.** A database on a file share, where every write pays a
network round trip and the database's own locking meets the filesystem's. An object store mounted as
though it were a filesystem, with one of the tools that do that: reading works, and renaming a
directory or appending to a file turns into the copies and rewrites the object section described.
And a large empty volume created "for later", which bills from the first day: 1,000 GB of `gp3` in
`sa-east-1` is 1,000 × 0.1520 = 152.00 USD a month for space nobody has written to.

## The bucket that was public

Every few months a news story reports records found in a storage bucket anybody could read. **Buckets
are private by default, and somebody made those public.** Somebody wrote a policy that grants reading
to everyone, or changed a setting to share one file quickly, and the store did exactly what it was
told, for every object under it.

On S3 the defaults have tightened over the years. Since April 2023 a new bucket has Block Public
Access switched on and object ACLs disabled, so making one public now takes two deliberate changes
rather than one careless one. That lowers the odds and does not remove them, because anybody with
permission to change the setting can still switch it off.

Reading a policy and seeing who it grants what is lesson 7's subject. Finding every public bucket
across an account, encrypting with keys you control and watching for drift is `cloud-security`'s,
which is where this lesson hands it on.
