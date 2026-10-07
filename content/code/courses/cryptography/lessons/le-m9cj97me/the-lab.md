---
title: Your lab, and three ways to build it
version: 1
---

**Every lesson in this course is run, and you should run it too.** Reading that a changed byte
makes GCM refuse a file is one thing; changing the byte yourself and watching it refuse is what
makes the idea stick. Nothing here runs on a machine we host. You build the lab on your own
computer, and this section builds it.

The lab is one Linux machine with three things on it:

- **the OpenSSL command line**, which most transcripts use, and which every Linux already has;
- **Python 3 with two libraries**, `cryptography` and `bcrypt`, in a virtual environment of its
  own, for what the command line does not show;
- **`~/lab`**, a directory of keys, data and small programs. The programs answer to one command,
  `vcrypt`, and you type every line of them yourself: each is shown whole in the lesson that first
  uses it, so nothing in this course runs that you have not read.

Some later lessons install a package or two of their own: OpenSSH and an LDAP server in lesson 12,
BIND's DNSSEC tools in lesson 13, `cryptsetup` and PostgreSQL in lesson 14, `wpa_supplicant` in
lesson 15, FreeRADIUS in lesson 16. Each says so at the point it needs them.

## Three ways to have one

| | what it is | what it costs your computer |
|---|---|---|
| **a virtual machine** (recommended) | Ubuntu Server 24.04 LTS in a hypervisor | 2 GB of memory while it runs, about 10 GB of disk |
| installed | the same packages on a computer that already runs Ubuntu 24.04 | under 50 MB for the first lessons, and the servers of lessons 12, 14 and 16 installed for good |
| online | a small Ubuntu 24.04 machine rented from a cloud provider | nothing on your computer; money, by the hour |

**The virtual machine is the recommended path**, and the reason is lessons 12 to 16. They start an
SSH server, an LDAP directory, a database and two RADIUS servers, add a user called `ana`, and put
names in `/etc/hosts`: the kind of change you do not want on the computer you work on. In a virtual
machine a mistake costs a snapshot, and when the course is over you delete it.

Any hypervisor works: VirtualBox on Windows or Linux, UTM on a Mac with an Apple processor, Hyper-V
on Windows Pro, GNOME Boxes on Linux. Download the Ubuntu Server 24.04 LTS installer from
ubuntu.com, create a machine with 2 GB of memory and a 10 GB disk, start it from the installer and
accept the defaults. When the installer asks for a name, call the machine `lab` if you like: every
transcript here prints `ana@lab`, where `ana` is the person and `lab` the machine, and yours will
print your own. Creating the machine was not recorded for this course; everything from the first
`apt-get` below was.

**Installed** is fine on a computer that already runs Ubuntu 24.04, with the same commands. On
Windows, WSL with Ubuntu 24.04 gives you the same commands too, and lessons 1 to 11 need nothing
more. On macOS the OpenSSL and Python commands exist, but `sha256sum`, `date` and `apt-get` do not
behave the same, and the server lessons will not work as printed. Neither was run here.

**Online**, any provider's smallest Ubuntu 24.04 machine is enough, and some providers have a free
allowance. It was not run for this course, and no lesson depends on one company's terms. A machine
on the internet is found by scanners within minutes, so keep its firewall closed except for SSH.

## The packages and the Python

Everything from here is typed in a terminal on the machine you chose. First the programs, from
Ubuntu's own archive:

```sh
sudo apt-get update
sudo apt-get install -y openssl xxd python3-venv
```

Then the lab's directory, and a **virtual environment** inside it: a Python of its own, in
`~/lab/venv`, with its own libraries, so that nothing here touches the Python Ubuntu itself runs on.
The versions are pinned, because a different one could print something differently from the
transcripts. The last command adds three lines to `~/.bashrc`, so that every new terminal finds
`vcrypt` and that Python without being told:

```sh
mkdir -p ~/lab/bin ~/lab/tools ~/lab/keys ~/lab/data
python3 -m venv ~/lab/venv
~/lab/venv/bin/pip install cryptography==50.0.2 bcrypt==5.0.0
cat >> ~/.bashrc <<'EOF'
# cryptography course
export PATH="$HOME/lab/bin:$PATH"
source "$HOME/lab/venv/bin/activate"
EOF
```

Close the terminal and open a new one, or type `source ~/.bashrc`, so that those lines take effect.

## `vcrypt` and the first two programs

`vcrypt` is not a program you install. It is five lines of shell that run a Python file:
`vcrypt seal ...` runs `~/lab/tools/seal.py` with the lab's Python. Each lesson adds the files it
needs to `~/lab/tools`, so by lesson 17 there are about twenty of them, every one shown.

To make a file, open it in an editor, paste the whole block, and save: `nano ~/lab/bin/vcrypt`,
paste, then `Ctrl+O`, `Enter` to save and `Ctrl+X` to leave. The first line of each block is the
file's path, as a comment.

```sh
#!/usr/bin/env bash
# ~/lab/bin/vcrypt
# vcrypt NAME ARGS... runs ~/lab/tools/NAME.py with the lab's own Python.
lab=$(cd "$(dirname "$0")/.." && pwd)
name=${1:?usage: vcrypt NAME [ARGS...]}
shift
exec "$lab/venv/bin/python" "$lab/tools/$name.py" "$@"
```

The next file is where every key in the lab comes from, and it **cheats on purpose**. A real key is
random bytes from the operating system, different every time. Then your keys would differ from the
ones printed here, and so would every ciphertext, signature and certificate in seventeen lessons.
So the lab derives each key from a public label instead, and yours come out identical to the
lesson's. Anybody who reads this file can rebuild every key in the lab, which makes them worthless
as secrets. Lesson 17 shows how that same mistake looks in real code.

```py
# ~/lab/tools/drbg.py
"""Bytes that look random and are not: every key in ~/lab comes from here.

stream(label, n) is HMAC-SHA256 of the label under a seed printed below, so
the same label gives the same bytes on every machine, and your keys are the
keys in the lessons. That is what a course needs and exactly what a real key
must never have: anybody who reads this file can rebuild every key in the
lab. Lesson 17 says why. No key from here belongs anywhere but ~/lab.
"""
import hashlib
import hmac

SEED = b"cryptography course lab, not a secret"


def stream(label: str, n: int) -> bytes:
    out, counter = b"", 0
    while len(out) < n:
        out += hmac.new(SEED, label.encode() + counter.to_bytes(4, "big"), hashlib.sha256).digest()
        counter += 1
    return out[:n]


def integer(label: str, bits: int) -> int:
    return int.from_bytes(stream(label, (bits + 7) // 8), "big") >> ((-bits) % 8)
```

The HMAC in it is lesson 6's subject; for now it is a machine that turns a label into bytes. The
second program prints those bytes:

```py
# ~/lab/tools/derive.py
"""vcrypt derive LABEL N: N bytes from drbg.py, as hex on one line.
With --raw, the bytes themselves, for a file that stands in for data."""
import sys

import drbg

raw = "--raw" in sys.argv
label, n = [a for a in sys.argv[1:] if a != "--raw"]
data = drbg.stream(label, int(n))
if raw:
    sys.stdout.buffer.write(data)
else:
    print(data.hex())
```

## This lesson's keys and data

Four keys: two AES-256 keys of 32 bytes, and two 16-byte initialisation vectors, which section 07
explains. Then a referral letter, and Monday's appointment file: 32 quarter-hour slots from 08:00 to
16:45, skipping lunch, each one a record of exactly sixteen bytes, which section 05 says why.

```sh
cd ~/lab
chmod +x bin/vcrypt
vcrypt derive aes-256 32 > keys/aes-256.hex
vcrypt derive aes-256-b 32 > keys/aes-256-b.hex
vcrypt derive iv-a 16 > keys/iv-a.hex
vcrypt derive iv-b 16 > keys/iv-b.hex
cat > data/referral.txt <<'EOF'
Referral 2026-0417. Patient: Marina Duarte, 41.
Lower back pain after lifting, eight weeks. Eight sessions of physiotherapy.
Dr. Paulo Nogueira, CRM-SP 000000 (invented)
EOF
for h in 08 09 10 11 13 14 15 16; do
  for m in 00 15 30 45; do
    case $h$m in
      0815|0900|0930|1000|1100|1330|1345|1500|1600|1630) printf 'room1 BOOKED   \n' ;;
      *) printf 'room1 free     \n' ;;
    esac
  done
done > data/slots.dat
```

`chmod +x` makes `vcrypt` something the shell can run. Vereda, its patients and its doctor are
invented, and so is every name in this course.

## Checking it

In a new terminal, the versions should be these:

```
ana@lab:~$ openssl version
OpenSSL 3.0.13 30 Jan 2024 (Library: OpenSSL 3.0.13 30 Jan 2024)
ana@lab:~$ python3 --version
Python 3.12.3
ana@lab:~$ python3 -c 'import cryptography, bcrypt; print(cryptography.__version__, bcrypt.__version__)'
50.0.2 5.0.0
```

`python3` is 3.12 and finds both libraries because the line in `~/.bashrc` put the lab's Python
first. And the files should be exactly these bytes. A SHA-256 digest, lesson 4's subject, changes
completely if one byte of the file does, so comparing the first few characters of each line is
enough:

```
ana@lab:~$ cd ~/lab
ana@lab:~/lab$ sha256sum keys/* data/*
e3c71c1722537cedf7d918f3a3d2ccb44c1ab732f98a679debbacfe6498d4c28  keys/aes-256-b.hex
50ca6e257529c4a3daaf38397347d105c4a618599cb53106d7c0c165485506e8  keys/aes-256.hex
afa184b52da6b03f4a26305a8e5adb1301a24c5c5436ac664e9ff8033141c32e  keys/iv-a.hex
467a7750f8816d8e9820633cecaac16e0ef07479c5d1f1331af4059f4298a409  keys/iv-b.hex
7c55ba550e02c3e33d50f2e4627f5e855b6cc9692e91eb72d15e5905f32abc4c  data/referral.txt
5e832af18cbeab6bd7bb6d2931668e0296498d2e5837980aee5e5d49ae3f8750  data/slots.dat
```

All of it, the Python libraries included, costs this much disk:

```
ana@lab:~/lab$ du -sh ~/lab
34M	/home/ana/lab
```

Almost all of that is the virtual environment; the keys and the data are a few kilobytes.

If a line differs, or a command did not do what this section says, the next section is for you.
