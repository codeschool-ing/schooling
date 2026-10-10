---
title: Restart and run all, before you trust it
version: 1
---

**The habit is one menu item: Kernel, Restart Kernel and Run All Cells…** It throws away the
kernel's memory, starts a new one, and runs every cell in page order. If the notebook still gives
the same answers, the page and the kernel agree, and the notebook is a document rather than a
souvenir of a session. If it stops with an error, you found the out-of-order cell or the hidden
variable now, instead of somebody else finding it later.

Do it at three moments: **before you save a notebook you will share**, **before you believe a
result enough to act on it**, and **whenever you have just deleted or moved a cell**. It costs the
time the notebook takes to run, which for everything in this course is seconds.

Ana's notebook from two sections ago, fixed. The setting moved to the top, with the other things
the notebook depends on:

```py
import csv
limit = 10
```

```py
with open("weather.csv") as f:
    days = list(csv.DictReader(f))
```

```py
wet = [d for d in days if float(d["rain_mm"] or 0) > limit]
len(wet)
```

## The same check, from the terminal

A notebook can be run top to bottom with no browser at all, which is how you check one somebody
sent you before opening it, and how a machine checks one for you. `jupyter execute` starts a fresh
kernel, runs every cell in order and stops at the first error:

```
(.venv) ana@lab:~/pydata$ jupyter execute fixed.ipynb
[NbClientApp] Executing fixed.ipynb
[IPKernelApp] WARNING | Kernel is running over TCP without encryption. All communication (including code and outputs) is sent in plain text and is susceptible to eavesdropping. Use IPC transport or launch with kernel manager-provisioned CurveZMQ keys to enable transport encryption.
[NbClientApp] Executing notebook with kernel: python3
```

Log lines and no error: every cell ran, in a kernel that had never seen any of them. The `WARNING`
is about how the kernel talks to the program that started it, over a network port on your own
computer rather than an encrypted channel. On a computer only you use it changes nothing; on a
server other people log in to, it is a question for whoever runs that server.

Run on the broken notebook, the same command stops where `nbconvert` stopped in the earlier section, at the
`NameError`. `jupyter execute` does not save what it ran; `jupyter nbconvert --to notebook
--execute --inplace` runs the notebook the same way and writes the outputs back into the file, so
that the saved counts read `1`, `2`, `3`:

```
(.venv) ana@lab:~/pydata$ jupyter nbconvert --to notebook --execute --inplace fixed.ipynb
[NbConvertApp] Converting notebook fixed.ipynb to notebook
[IPKernelApp] WARNING | Kernel is running over TCP without encryption. All communication (including code and outputs) is sent in plain text and is susceptible to eavesdropping. Use IPC transport or launch with kernel manager-provisioned CurveZMQ keys to enable transport encryption.
[NbConvertApp] Writing 2014 bytes to fixed.ipynb
(.venv) ana@lab:~/pydata$ python -c 'import json; nb = json.load(open("fixed.ipynb")); print(*[(c["execution_count"], c["source"][-1], c["outputs"][-1]["data"]["text/plain"] if c["outputs"] else []) for c in nb["cells"]], sep="\n")'
(1, 'limit = 10', [])
(2, '    days = list(csv.DictReader(f))', [])
(3, 'len(wet)', ['63'])
```

**A notebook whose counts run `1` to `n` without a gap was run once, from the top, in one
kernel.** That is the notebook to hand to somebody, and it is the only kind lesson 21 turns into a
script.

## What restarting does not fix

It does not fix a file that changed underneath, or a library that was upgraded: those are outside
the kernel, and a restart reads them as they are now. It does not fix randomness either. A notebook
that draws random numbers without a seed gives new numbers on every run, top to bottom or not;
lesson 8 is about that. Restart and run all proves the page is self-consistent, which is necessary
and is not the same as reproducible.
