---
title: The key, and the backup nobody can open
version: 1
---

An encrypted backup is exactly as recoverable as its passphrase. Lesson 1 listed "encrypted with a
key nobody kept" among the ways a backup fails silently, and this is how it happens: the
passphrase is in the configuration file of the database server, the database server is the thing
that was lost, and nobody wrote it down anywhere else.

Here is the second repository as seen by a configuration whose passphrase is wrong by one character,
which is the same as seen by a new server whose configuration was rebuilt from memory:

```
ana@vm:~$ sudo sed 's/^repo2-cipher-pass=./repo2-cipher-pass=X/' /etc/pgbackrest.conf | sudo tee /tmp/wrong.conf > /dev/null
ana@vm:~$ sudo chown postgres /tmp/wrong.conf
ana@vm:~$ sudo -u postgres pgbackrest --config=/tmp/wrong.conf --stanza=main --repo=2 info | grep -v 'outside of section'
stanza: main
    status: error (other)
            [FormatError] unable to load info file '/srv/offsite/pgbackrest/backup/main/backup.info' or '/srv/offsite/pgbackrest/backup/main/backup.info.copy':
            HINT: backup.info cannot be opened and is required to perform a backup.
            HINT: has a stanza-create been performed?
    cipher: aes-256-cbc
ana@vm:~$ sudo rm /tmp/wrong.conf
```

pgBackRest cannot even read the list of backups. **Every byte is there and none of it is usable**,
and no tool, support contract or amount of effort changes that: AES with a long random passphrase is
not broken by trying.

So the passphrase is part of the backup, and it is kept the way the most important secrets are kept:

- **somewhere that survives the loss of the database server**, and of the backup storage too: a
  password manager or vault the organisation already trusts, with access by more than one person;
- **with the procedure that uses it**, so that whoever restores knows where to find it (lesson 24);
- **tested**, by the drill: a drill that restores from the encrypted repository on a machine
  configured from the written-down passphrase, and not from a copy of the old configuration, is the
  only proof the passphrase that was written down is the right one.

Changing the passphrase of an existing repository is not possible in place; a new one means a new
repository, backed up into from scratch, with the old one kept until its backups age out. That is
one more reason to generate it properly the first time.
