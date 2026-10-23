---
title: A hash that refuses a file
version: 1
---

A version pin says **which release** to install: `blinker==1.9.0`. It does not say **which bytes**.
If the file served under that name changes, because an index was compromised, a mirror served
something else, or a maintainer's account published over a release, the pin is still satisfied and
the installer still installs. Codecov's script and the xz tarballs were both files whose name was
right and whose content was not.

A hash pins the bytes. **pip's `--require-hashes` mode installs a file only if its SHA-256 is one
the requirements file lists**, and refuses anything else before a line of it runs. Lesson 15 turns
linkbox's requirements into a lock with a hash for every file; this section shows the mechanism on
one package, in a scratch directory, so you can see the refusal for yourself.

### A pin with a hash

Work in a directory of its own, with a virtual environment that has pip in it (`--seed` puts it
there):

```
ana@vm:~$ mkdir ~/supply && cd ~/supply
ana@vm:~/supply$ uv venv --seed -q && . .venv/bin/activate
(supply) ana@vm:~/supply$ pip --version
pip 26.2.2 from /home/ana/supply/.venv/lib/python3.13/site-packages/pip (python 3.13)
```

`pip download` fetches a file without installing it, and `pip hash` prints the line a requirements
file needs:

```
(supply) ana@vm:~/supply$ pip download -q --no-deps -d wheels blinker==1.9.0
(supply) ana@vm:~/supply$ ls wheels
blinker-1.9.0-py3-none-any.whl
(supply) ana@vm:~/supply$ pip hash wheels/blinker-1.9.0-py3-none-any.whl
wheels/blinker-1.9.0-py3-none-any.whl:
--hash=sha256:ba0efaa9080b619ff2f3459d1d500c57bddea4a6b424b60a91141db6fd2f08bc
```

That hash is a fact about this one file. The same wheel downloaded on any machine, from any mirror,
has the same SHA-256, and a file with a single byte changed has a completely different one. Put the
line into a requirements file and install with the mode on:

```
(supply) ana@vm:~/supply$ echo "blinker==1.9.0 $(pip hash wheels/*.whl | tail -n 1)" > requirements.txt
(supply) ana@vm:~/supply$ cat requirements.txt
blinker==1.9.0 --hash=sha256:ba0efaa9080b619ff2f3459d1d500c57bddea4a6b424b60a91141db6fd2f08bc
(supply) ana@vm:~/supply$ pip install --require-hashes --no-deps -r requirements.txt
Collecting blinker==1.9.0 (from -r requirements.txt (line 1))
  Using cached blinker-1.9.0-py3-none-any.whl (8.5 kB)
Installing collected packages: blinker
Successfully installed blinker-1.9.0
(supply) ana@vm:~/supply$ pip uninstall -q -y blinker
```

It installed: the file, fetched from PyPI by the download a moment earlier and reused from pip's cache, has exactly the hash the requirements file names. **The hash came from your own download, which is the step that deserves care**: a hash
copied from a file that was already tampered with pins the tampered file. Lesson 15 takes the hashes
from the index's own records with a resolver, and on a date, for that reason.

### The mode is all or nothing

With `--require-hashes`, a requirement without a hash is refused too, and pip prints the hash it
would have accepted:

```
(supply) ana@vm:~/supply$ pip install --require-hashes blinker==1.9.0
Collecting blinker==1.9.0
  Using cached blinker-1.9.0-py3-none-any.whl (8.5 kB)
ERROR: Hashes are required in --require-hashes mode, but they are missing from some requirements. Here is a list of those requirements along with the hashes their downloaded archives actually had. Add lines like these to your requirements files to prevent tampering. (If you did not enable --require-hashes manually, note that it turns on automatically when any package has a hash.)
    blinker==1.9.0 --hash=sha256:ba0efaa9080b619ff2f3459d1d500c57bddea4a6b424b60a91141db6fd2f08bc
```

That strictness is the point. A lock where most files are hashed and one is not is a lock with one door open, and pip does not let you have it. The last sentence of the message says something else worth knowing: the mode turns itself on as soon as any line of a requirements file carries a hash.

### A file that changed

Now make an index that serves a different file under the same name. Copy the wheel into a directory
laid out as an index, add one byte to it, the smallest change there is, and serve the directory with
`python3 -m http.server 8081 --bind 127.0.0.1 --directory mirror` in a second terminal. Then install
the same requirements file from that index:

```
(supply) ana@vm:~/supply$ mkdir -p mirror/simple/blinker
(supply) ana@vm:~/supply$ cp wheels/blinker-1.9.0-py3-none-any.whl mirror/simple/blinker/
(supply) ana@vm:~/supply$ printf "x" >> mirror/simple/blinker/blinker-1.9.0-py3-none-any.whl
(supply) ana@vm:~/supply$ pip install --require-hashes --no-deps --index-url http://127.0.0.1:8081/simple/ -r requirements.txt
Looking in indexes: http://127.0.0.1:8081/simple/
Collecting blinker==1.9.0 (from -r requirements.txt (line 1))
  Downloading blinker-1.9.0-py3-none-any.whl (8.5 kB)
ERROR: THESE PACKAGES DO NOT MATCH THE HASHES FROM THE REQUIREMENTS FILE. If you have updated the package versions, please update the hashes. Otherwise, examine the package contents carefully; someone may have tampered with them.
    blinker==1.9.0 from http://127.0.0.1:8081/simple/blinker/blinker-1.9.0-py3-none-any.whl (from -r requirements.txt (line 1)):
        Expected sha256 ba0efaa9080b619ff2f3459d1d500c57bddea4a6b424b60a91141db6fd2f08bc
             Got        15cc4b75d6aec4b6e546a4efaa1e60ef06aac0191d77e4cc95db00ed1066e421
```

**pip downloaded the file and refused it.** The name was right, the version was right, the index
answered normally, and the installation stopped at the one check that looks at the content. Read the
message: `Expected` is the hash you pinned, `Got` is the hash of what arrived. Nothing was unpacked
and nothing ran.

### What a hash does not do

- **It does not judge the first file.** If the release you pinned was malicious on the day you
  hashed it, as ua-parser-js's three versions were for the hours they were up, the hash pins the
  malicious file faithfully. A cooling-off period before adopting a new release is the defence for
  that, and lesson 15 adds it.
- **It does not cover what is not in the file.** A base image, a script fetched with `curl` in a
  Dockerfile, a GitHub Action: each needs its own pin by digest or commit, which lessons 15 and 16
  add.
- **It does not say who made the file.** A hash proves this is the file you reviewed; a signature
  and provenance, in lesson 14, say who built it and from what.

Codecov is the case where a hash alone was enough. The customer who found it compared the script
they downloaded with the SHA-256 published beside it, and that comparison is exactly what pip did
above.
