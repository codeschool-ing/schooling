---
title: Default ACLs, for files that do not exist yet
version: 1
---

**An ACL on a file covers that file. The next file somebody creates in the same directory starts
with none.** João saves a new client's document:

```
ana@web:~$ sudo -u joao sh -c "umask 007; echo CPF 987.654.321-00 > /srv/clientes/costa.txt"; sudo getfacl -p --omit-header /srv/clientes/costa.txt
user::rw-
group::rw-
other::---

ana@web:~$ sudo -u auditoria cat /srv/clientes/costa.txt
cat: /srv/clientes/costa.txt: Permission denied
```

The first command shows the new file with the bits alone, no named entries, and the auditor is
refused, as she was before the last two sections. Every new file would need the same `setfacl` by
hand, and the first one somebody forgot would be the one the auditor asks for.

A **default ACL** on a directory is a template. It grants nothing on the directory itself; every file
and subdirectory created inside it is born with these entries. `setfacl -d` writes it, and `getfacl`
shows it as the lines starting `default:`. It is set here with the group's `rw` and nothing for
others, which also makes the shared directory independent of the umask of whoever saves a file.

Then Maria saves another document, and it arrives with the auditor and the portal already on it:

```
ana@web:~$ sudo setfacl -d -m u:auditoria:r,u:portal:r,g::rw,o::- /srv/clientes && sudo getfacl -p --omit-header /srv/clientes | grep default
default:user::rwx
default:user:portal:r--
default:user:auditoria:r--
default:group::rw-
default:mask::rw-
default:other::---
ana@web:~$ sudo -u maria sh -c "umask 007; echo CPF 111.222.333-96 > /srv/clientes/souza.txt"; sudo getfacl -p --omit-header /srv/clientes/souza.txt
user::rw-
user:portal:r--
user:auditoria:r--
group::rw-
mask::rw-
other::---

ana@web:~$ sudo -u auditoria cat /srv/clientes/souza.txt
CPF 111.222.333-96
```

`costa.txt`, created before the default existed, is unchanged and still needs fixing by hand. A
default applies at creation and never afterwards, so a directory full of old files is set once with
`setfacl -R -m` for what exists and once with `-d` for what will.

## What copies and moves do

Two habits break defaults in practice, and both are worth knowing before they happen:

- **A file moved in with `mv` keeps the ACL it had.** A move within one file system renames the file
  and creates nothing, so the default never applies; a document moved from somebody's home arrives
  with their home's access.
- **A file copied with `cp -p` or `rsync -A` keeps its own ACL** rather than taking the directory's,
  because those options exist to preserve what the file had.

`getfacl -R` over the directory, compared with what the defaults promise, is the check that finds both,
and it belongs in the baseline of lesson 2 for any directory that holds clients' data.
