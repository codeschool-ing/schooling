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
UUID:          	1ac389d5-712f-476d-8ddf-3a3d6138a33b
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
	Time cost:  5
	Memory:     1048576
	Threads:    4
	Salt:       26 b8 a9 e7 22 8d 34 31 f3 fb 86 2c 0f 68 0b ec 
	            99 b1 3a f5 45 71 41 90 cc e8 4e d9 a2 a7 a1 6f 
	AF stripes: 4000
	AF hash:    sha256
	Area offset:32768 [bytes]
	Area length:258048 [bytes]
	Digest ID:  0
Tokens:
Digests:
  0: pbkdf2
	Hash:       sha256
	Iterations: 219919
	Salt:       20 d6 60 ff c2 28 bd 5c 7f 73 bd 35 ad 35 87 a7 
	            88 81 81 b2 50 a5 fe 62 54 4c 55 e0 df 99 92 5c 
	Digest:     12 65 5f bc ec d8 5a fd 5b 2d 9e 82 5f a0 10 81 
	            ef fd bb 9b 15 a2 81 f4 41 4e 77 37 20 59 23 ac 
```

`luksFormat` wrote a header and nothing else; you type the passphrase at its prompt, and
nothing is echoed. The header is the interesting part:

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
