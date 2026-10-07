---
title: Full-disk encryption, inside a LUKS header
version: 1
---

**A full-disk encryption system encrypts every sector of a volume with one random key, the volume
key, and stores that key in a header, encrypted under each passphrase allowed to unlock it.** LUKS,
the Linux standard, makes that structure easy to see; BitLocker and FileVault are built the same way.
Vereda's laptops run Linux, and the lab formats a 32 MiB file in place of a laptop's disk.

## This lesson's packages and files

Two programs, from Ubuntu's packages: `cryptsetup`, the LUKS tool, for this section, and PostgreSQL,
the database of sections 04 and 05. Installing PostgreSQL also starts it.

```sh
sudo apt-get install -y cryptsetup-bin postgresql
```

The two passphrases go in files, so that the commands below run without stopping to ask; a real one
is typed at the prompt and never written down. Then the database: a role `ana` with a password the
lab made up, a database `vereda` she owns, and the `pgcrypto` extension section 05 uses. `sudo -iu
postgres` runs `psql` as PostgreSQL's own administrator, the only role there is on a fresh install:

```sh
cd ~/lab
printf 'correct horse battery staple' > disk.pass
printf 'recovery-7KQ2-M9XD-4TPA' > recovery.pass
sudo -iu postgres psql -q <<'EOF'
CREATE ROLE ana LOGIN PASSWORD 'lab-only-db-password';
CREATE DATABASE vereda OWNER ana;
\c vereda
CREATE EXTENSION pgcrypto;
GRANT pg_checkpoint TO ana;
EOF
```

`GRANT pg_checkpoint` lets `ana` run the `CHECKPOINT` of section 04, which normally only an
administrator may. Last, the line that tells `psql` where to connect and as whom, so that every
command in this lesson can be a plain `psql -c`. Type it in each new terminal while you work on this
lesson:

```sh
export PGHOST=127.0.0.1 PGUSER=ana PGDATABASE=vereda PGPASSWORD=lab-only-db-password
```

## Formatting, and a second way in

```
ana@lab:~/lab$ truncate -s 32M disk.img
ana@lab:~/lab$ cryptsetup luksFormat -q --type luks2 --cipher aes-xts-plain64 --key-size 512 --pbkdf argon2id --pbkdf-force-iterations 4 --pbkdf-memory 65536 --pbkdf-parallel 1 --uuid 6d2f4a1e-0b7c-4c3e-9a51-2f6e8c1d0a37 --key-file disk.pass disk.img
ana@lab:~/lab$ cryptsetup luksAddKey -q --pbkdf argon2id --pbkdf-force-iterations 4 --pbkdf-memory 65536 --pbkdf-parallel 1 --key-file disk.pass disk.img recovery.pass
```

The first command created the volume and its random 512-bit volume key, protected by the
physiotherapist's passphrase. The second added a **recovery passphrase** in a second slot, the one IT
keeps in its vault for the day somebody forgets theirs. Neither passphrase encrypts the disk. Each
only unlocks a copy of the volume key.

## Reading the header

```
ana@lab:~/lab$ cryptsetup luksDump disk.img | grep -E '^(Version|UUID)|^  [0-9]: |cipher:|Cipher key|PBKDF|Time cost|Memory'
Version:       	2
UUID:          	6d2f4a1e-0b7c-4c3e-9a51-2f6e8c1d0a37
  0: crypt
	cipher: aes-xts-plain64
  0: luks2
	Cipher key: 512 bits
	PBKDF:      argon2id
	Time cost:  4
	Memory:     65536
  1: luks2
	Cipher key: 512 bits
	PBKDF:      argon2id
	Time cost:  4
	Memory:     65536
  0: pbkdf2
```

The header says, in public:

- the data is encrypted with **AES in XTS mode** (`aes-xts-plain64`), with a 512-bit key, which is two
  AES-256 keys. XTS is a mode built for disks: each sector is encrypted with its own position mixed in,
  so equal sectors do not look equal (lesson 1's ECB problem) and any sector can be read or written on
  its own. It has no authentication tag, because a sector has no room for one; that is a known
  limitation of disk encryption;
- two **keyslots**, 0 and 1, each holding the volume key encrypted under a key derived from one
  passphrase with **Argon2id**, time cost 4, 64 MiB of memory: lesson 5's slow, memory-hard function,
  doing the job it was built for. Whoever steals the laptop has to guess the passphrase at Argon2id's
  speed, offline, for as long as they like. That is why the passphrase's strength is the whole of the
  protection.

## Unlocking, with either passphrase

The recovery passphrase recovers the volume key:

```
ana@lab:~/lab$ cryptsetup open --test-passphrase --key-file recovery.pass disk.img && echo "recovery passphrase unlocks the volume key"
recovery passphrase unlocks the volume key
```

A passphrase that differs by one capital letter does not:

```
ana@lab:~/lab$ printf 'Correct horse battery staple' > typo.pass; cryptsetup open --test-passphrase --key-file typo.pass disk.img; echo "exit status $?"
No key available with this passphrase.
exit status 2
```

(The lab checks passphrases with `--test-passphrase`, which unlocks the volume key and stops. Mapping
the volume as a disk needs the kernel's device mapper, which the machine that recorded this lesson
does not offer, so the volume is never mounted here.)

## What the structure buys

Because the passphrases only wrap the volume key, changing a passphrase rewrites a few hundred bytes
of header and **never re-encrypts the disk**. Removing an employee's slot revokes their access without
touching the data. And destroying the header destroys the volume key, which makes the whole disk
unreadable at once: **crypto-erase**, how encrypted disks and phones are wiped in a second. A copy of
the header taken before a slot was removed still opens with the old passphrase, which is why headers
are backed up deliberately and old copies destroyed.

On a laptop with a TPM, the volume key can also be sealed to the TPM so that the machine unlocks only
if its boot chain is unchanged; BitLocker does this by default, usually with a PIN as well. What it
protects remains the same: the powered-off device.
