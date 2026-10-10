---
title: When the setup fails
version: 1
---

Most people who give up on a course like this give up here, on an error from a machine they have
only just built. These are the failures that actually happen, roughly in the order you would meet
them. Where the machine this course was recorded on produced one, it is shown as that machine
printed it.

**`python3 -m venv .venv` says *ensurepip is not available*.** The `python3-venv` package is
missing, and the message names the package to install. Run the `apt-get install` line again, delete
the half-made `.venv` with `rm -rf .venv`, and create it again.

**A new terminal cannot find PyTorch.**

```
ana@vm:~/dl$ python3 -c "import torch"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'torch'
```

The library is inside `~/dl/.venv`, and this terminal never activated it: the `~/.bashrc` lines were
skipped, or the terminal was opened before they were added. `. ~/dl/.venv/bin/activate` fixes the
terminal you are in, and `which python` should then answer `/home/ana/dl/.venv/bin/python` with your
own user name.

**`pip` is not found, or refuses with *externally-managed-environment*.** This is the same
mistake from the other side: the command ran outside the environment. Ubuntu 24.04 protects the
Python the system itself runs on and refuses a `pip install` aimed at it; the message suggests
`--break-system-packages`, and that advice is wrong here. Activate the environment, and the same
command installs into it. The course's machine never ran `pip` outside one, so this is described
rather than shown.

**The installation stops with *No space left on device*.** The libraries take about 6 GB once
unpacked, and `pip` needs room for the downloads as well. A VM made with a smaller disk than the
30 GB above runs out here. `multipass stop vm`, then `multipass set local.vm.disk=30G` to grow it,
or install the processor-only build the previous section names, which leaves NVIDIA's libraries out.
This one did not happen on the machine the course was recorded on, so it is described rather than
shown.

**`pip` says no version of `torch` matches.** PyTorch publishes ready-built packages for a range of
Python versions, and a Python newer than that range finds none. The versions in `requirements.txt`
were recorded on Python 3.12, the one Ubuntu 24.04 ships; use Ubuntu 24.04 in the VM, which is the
reason the VM is the recommended path.

**A training run ends with the single word `Killed`.** The system ran out of memory and ended the
process. Nothing in this course needs more than a fraction of 8 GB, so the usual cause is a VM made
with less, or another program holding the memory. `free -h` says how much is free. This did not
happen on the course's machine either.

**Your numbers are not the lesson's numbers.** That is not a failure. A network starts from random
weights, and the programs here fix the seed so that one machine repeats itself. A different
processor can add the same numbers in a different order and round differently in the last digit,
and over thousands of steps that becomes a different second decimal. What a lesson draws from a run
is a shape — the loss falling, the accuracy against the baseline, one setting beating another —
and the shape is what to check in yours.
