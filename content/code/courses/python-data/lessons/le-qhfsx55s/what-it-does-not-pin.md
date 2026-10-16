---
title: What a pinned file still leaves open
version: 1
---

**A lock file fixes the libraries; it does not fix everything a result depends on.** Knowing what
is left open is what lets you say, honestly, how far a notebook will reproduce on somebody else's
computer.

**The Python.** `requirements.txt` says nothing about which interpreter reads it. NumPy 2.5 refuses
anything older than 3.12, as lesson 1's failure showed, so this project's pins happen to enforce a
floor; another project's may not, and a newer Python can change a result too. Write the version
down where a person will read it: a line in the project's `README`, or `requires-python` in a
`pyproject.toml`, which the `python` course's lesson 19 sets. `environment.yml` does better, because
`python=3.12` is one of its lines and conda installs that Python.

**The operating system and the processor.** NumPy on an Intel laptop and on an Apple one runs
different compiled code underneath, built against different maths libraries. This course was
recorded on one machine, and was not run on another. Where a result is a long sum of
floating-point numbers, another machine can print a different last digit, because it may add them
in a different order; lesson 5 shows why the order of additions matters to a float.

**The data.** The pins say nothing about `trips.csv`. Lesson 2's rule, never overwrite your input,
and lesson 1's program that regenerates it are what cover that.

**Randomness.** A shuffle, a sample or a random split gives new numbers on every run unless it is
seeded, whatever the versions. Lesson 8 is about seeds.

**The packages themselves, byte for byte.** `numpy==2.5.3` names a version; it does not prove that
the file pip downloads is the one you tested. `pip install --require-hashes` with a hash beside each
line does, and tools like `uv` write those hashes for you. For an analysis on your own computer
that is more than you need. For a pipeline that runs unattended on a server, it is the difference
between a version number and a guarantee.

| left open | what closes it |
|---|---|
| the Python | a written version: `README`, `requires-python`, or `python=` in `environment.yml` |
| the operating system | nothing in the file; a virtual machine or a container, when it matters |
| the data | a program that makes it, or a copy that is never overwritten |
| randomness | a seed, lesson 8 |
| the packages' bytes | hashes in the lock file |
