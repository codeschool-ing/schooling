---
title: More than one user and one group
version: 1
---

**An access control list adds entries for named users and named groups to a file's nine bits.**
The bits stay; the list adds to them. On Linux the list is a POSIX ACL, read with `getfacl` and
written with `setfacl`, and Ubuntu's file systems support it without any setup.

Build the case first. The accountants are a group, `contabil`, with Maria and João in it; the
auditor is an account of her own, `auditoria`. The client directory belongs to the group, with the
set-group-id bit on the directory so that files created inside it belong to the group too:

```
ana@web:~$ sudo groupadd contabil && for u in maria joao auditoria; do sudo useradd -M -s /usr/sbin/nologin $u; done; sudo usermod -aG contabil maria; sudo usermod -aG contabil joao; id maria; id auditoria
uid=1002(maria) gid=1003(maria) groups=1003(maria),1002(contabil)
uid=1004(auditoria) gid=1005(auditoria) groups=1005(auditoria)
ana@web:~$ sudo install -d -o root -g contabil -m 2770 /srv/clientes && ls -ld /srv/clientes
drwxrws--- 2 root contabil 4096 Oct 23 09:35 /srv/clientes
ana@web:~$ sudo -u maria sh -c "umask 007; echo CPF 123.456.789-09, IRPF 2025 > /srv/clientes/silva.txt"; sudo ls -l /srv/clientes
total 4
-rw-rw---- 1 maria contabil 30 Oct 23 09:35 silva.txt
```

`2770` is the set-group-id bit, then full access for the owner and the group and nothing for anybody
else. Maria creates a file with the umask a shared directory needs, `007`, which leaves nothing for
others, and the file comes out as the bits intend: readable and writable by the accountants, closed to
everybody else.

Including the two who need to read it:

```
ana@web:~$ sudo -u auditoria cat /srv/clientes/silva.txt
cat: /srv/clientes/silva.txt: Permission denied
ana@web:~$ sudo -u portal cat /srv/clientes/silva.txt
cat: /srv/clientes/silva.txt: Permission denied
```

The bits have no way to say "this one person may read". Making the file readable by others would
give it to every account on the machine; putting the auditor in `contabil` would give her write
access too. That is the moment an ACL exists for.

## Named entries

```
ana@web:~$ sudo setfacl -m u:auditoria:rx,u:portal:rx /srv/clientes && sudo setfacl -m u:auditoria:r,u:portal:r /srv/clientes/silva.txt
ana@web:~$ ls -ld /srv/clientes; sudo ls -l /srv/clientes
drwxrws---+ 2 root contabil 4096 Oct 23 09:35 /srv/clientes
total 4
-rw-rw----+ 1 maria contabil 30 Oct 23 09:35 silva.txt
ana@web:~$ sudo getfacl -p /srv/clientes/silva.txt
# file: /srv/clientes/silva.txt
# owner: maria
# group: contabil
user::rw-
user:portal:r--
user:auditoria:r--
group::rw-
mask::rw-
other::---
```

Two commands: one for the directory, which needs `x` to be entered and `r` to be listed, and one for
the file. `ls` marks both with a `+` after the bits, the only sign in a normal listing that more
access exists than the bits show. `getfacl` prints the whole list: the owner, the two named users,
the owning group, a **mask**, and others. The mask is the next section's subject.

Then the test that matters, from each side:

```
ana@web:~$ sudo -u auditoria cat /srv/clientes/silva.txt
CPF 123.456.789-09, IRPF 2025
ana@web:~$ echo "edited" | sudo -u auditoria tee -a /srv/clientes/silva.txt
tee: /srv/clientes/silva.txt: Permission denied
edited
ana@web:~$ echo "edited" | sudo -u joao tee -a /srv/clientes/silva.txt
edited
```

The auditor reads the file and cannot write it, and João, as an accountant, can. `tee` prints what
it was given whatever happens, so the word `edited` appears under the refusal too: the
`Permission denied` line is the answer. **Each kind of access is now exactly what the job needs**,
and the files of the other clients stay closed to everybody outside the list.
