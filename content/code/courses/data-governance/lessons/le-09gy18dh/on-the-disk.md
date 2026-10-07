---
title: What is on the disk
version: 1
---

Everything so far protected the data in motion. Now the files. PostgreSQL stores each table in
plain files under its data directory, and **nothing in PostgreSQL encrypts them**. The server
can say which file holds the customers:

```
ana@lab:~/gov$ sudo -u postgres psql -c "CHECKPOINT"
CHECKPOINT
ana@lab:~/gov$ sudo -u postgres psql -Atc "SELECT pg_relation_filepath('sales.customers')"
base/16384/16389
ana@lab:~/gov$ sudo grep -a -o -m 1 "paula.cavalcanti@example.com" /var/lib/postgresql/16/gov/base/16384/16389
paula.cavalcanti@example.com
```

`CHECKPOINT` first, because a page changed in memory reaches its file only at the next checkpoint;
then the file path; then a plain `grep` for one customer's e-mail address, run against the raw
bytes of the table. **It is there, in clear, in the file.** Anybody holding a copy of that
directory — a stolen disk, a decommissioned server, a snapshot of a cloud volume shared to the
wrong account — reads every customer with tools that ship with every operating system.

## Encrypting the volume

The standard answer on Linux is to encrypt the whole block device the data directory lives on,
with **LUKS**, so that what is written to the disk is ciphertext and what the operating system
reads after unlocking it is plaintext. The format is easiest to see on a small file standing in
for a disk:

```
ana@lab:~/gov$ truncate -s 32M volume.img
ana@lab:~/gov$ cryptsetup luksFormat --batch-mode volume.img
ana@lab:~/gov$ cryptsetup luksDump volume.img
LUKS header information
Version:       	2
Epoch:         	3
Metadata area: 	16384 [bytes]
Keyslots area: 	16744448 [bytes]
UUID:          	a0619260-7cae-4f3e-a8df-68dd2d67437e
Label:         	(no label)
Subsystem:     	(no subsystem)
Flags:       	(no flags)

Data segments:
  0: crypt
	offset: 16777216 [bytes]
	length: (whole device)
	cipher: aes-xts-plain64
	sector: 4096 [bytes]

Keyslots:
  0: luks2
	Key:        512 bits
	Priority:   normal
	Cipher:     aes-xts-plain64
	Cipher key: 512 bits
	PBKDF:      argon2id
	Time cost:  6
	Memory:     1048576
	Threads:    4
	Salt:       fa 54 9f 6a 55 25 07 16 4a c1 39 04 9c a8 de b4 
	            63 ef 65 b5 0a 89 28 72 ab 58 25 2a 0b d1 cd 11 
	AF stripes: 4000
	AF hash:    sha256
	Area offset:32768 [bytes]
	Area length:258048 [bytes]
	Digest ID:  0
Tokens:
Digests:
  0: pbkdf2
	Hash:       sha256
	Iterations: 218818
	Salt:       4a 4b 51 15 f5 c0 78 b3 3d 26 c1 50 66 04 43 b4 
	            f5 e1 d0 39 7f 72 bf a5 d7 63 3a 97 af 0e 63 6b 
	Digest:     98 c5 3b 9c c2 79 cf 5b df 2a 03 25 91 d6 8f 16 
	            24 b0 d6 0b 89 e4 51 86 0d 43 db 57 1e 40 53 73 
```

`luksFormat` wrote a header and nothing else; the passphrase was given on standard input by the
capture script, where a person types it twice at a prompt. The header is the interesting part:

- **`cipher: aes-xts-plain64`** — AES in XTS mode, the mode designed for disks, with a 512-bit key
  (two 256-bit halves, one of them for XTS's tweak);
- **a keyslot with `PBKDF: argon2id`** — the passphrase is not the key. It unlocks a slot holding
  the real volume key, through a derivation that is deliberately slow and memory-hungry, the same
  idea as the SCRAM iterations of lesson 1;
- **room for more slots**, so a volume can be opened by several passphrases or key files, and one
  can be removed without re-encrypting the disk.

The next steps open the volume, put a file system on it and mount it where PostgreSQL keeps its
data. **They were not run here**: opening a LUKS volume needs the kernel's device-mapper, which the
machine this course was recorded on does not offer. In the virtual machine lesson 1 recommends,
they are:

```sh
sudo cryptsetup open volume.img ipe-data
sudo mkfs.ext4 /dev/mapper/ipe-data
sudo mount /dev/mapper/ipe-data /var/lib/postgresql
```

In a cloud, the same protection is a property of the volume — an encrypted EBS volume, a Google
Cloud persistent disk, which Google encrypts by default — and the key that matters is the one in
the provider's key-management service, which is lesson 4's subject.

## What it protects against

**A disk that leaves the building.** That is a real threat and the only one: stolen hardware,
disks sent for repair, drives decommissioned without being wiped, a snapshot copied out. Against
those, volume encryption is complete and cheap. The next section is about everything it does not
protect against, which is most of what this course is about.
