---
title: When the setup fails
version: 1
---

**Four failures account for nearly all of it, and each one prints its own name.** Read the last
lines a command printed before anything else: the first error is the one that matters, and what
follows it is usually its consequences.

## `jupyter: command not found`

A new terminal, and the environment line was forgotten:

```
ana@lab:~$ cd pydata
ana@lab:~/pydata$ jupyter lab
bash: jupyter: command not found
```

`jupyter` is installed inside `.venv`, and only a terminal that ran `source .venv/bin/activate`
knows to look there. The prompt says which kind of terminal this is: no `(.venv)` in front of it,
no environment. Run the line, from inside `pydata`, and try again. On a desktop Ubuntu the same
mistake may instead print a suggestion to install a `jupyter` package with `apt`; that was not
recorded here, and the answer is the same. **Do not install it.** A second JupyterLab outside the
environment would start, and its notebooks would run on a Python without your libraries.

## `externally-managed-environment`

`pip` ran outside the environment, against the Python Ubuntu itself depends on:

```
ana@lab:~/pydata$ python3 -m pip install pandas==3.0.6
error: externally-managed-environment

× This environment is externally managed
```

Ubuntu refuses, on purpose: a library installed there can break a program of the operating
system's that expected a different version. The message goes on to suggest a virtual environment,
which is what `.venv` is. Activate it and the same `pip install` goes to the right place. If
`python3 -m venv .venv` itself fails, complaining that `ensurepip` is not available, the package
`python3-venv` from the first `apt-get` line is missing.

## `Could not find a version that satisfies the requirement`

The Python is too old for the pins. This was recorded in a second folder, `oldpy`, with a Python
3.11 that a fresh Ubuntu 24.04 does not have; on another system it is the Python that came with it:

```
(.venv) ana@lab:~/oldpy$ python --version
Python 3.11.17
(.venv) ana@lab:~/oldpy$ pip install numpy==2.5.3
ERROR: Ignored the following yanked versions: 2.4.0
ERROR: Ignored the following versions that require a different python version: 1.21.2 Requires-Python >=3.7,<3.11; 1.21.3 Requires-Python >=3.7,<3.11; 1.21.4 Requires-Python >=3.7,<3.11; 1.21.5 Requires-Python >=3.7,<3.11; 1.21.6 Requires-Python >=3.7,<3.11; 2.5.0 Requires-Python >=3.12; 2.5.0rc1 Requires-Python >=3.12; 2.5.1 Requires-Python >=3.12; 2.5.2 Requires-Python >=3.12; 2.5.3 Requires-Python >=3.12
ERROR: Could not find a version that satisfies the requirement numpy==2.5.3 (from versions: 1.3.0, 1.4.1, 1.5.0, 1.5.1, 1.6.0, 1.6.1, 1.6.2, 1.7.0, 1.7.1, 1.7.2, 1.8.0, 1.8.1, 1.8.2, 1.9.0, 1.9.1, 1.9.2, 1.9.3, 1.10.0.post2, 1.10.1, 1.10.2, 1.10.4, 1.11.0, 1.11.1, 1.11.2, 1.11.3, 1.12.0, 1.12.1, 1.13.0, 1.13.1, 1.13.3, 1.14.0, 1.14.1, 1.14.2, 1.14.3, 1.14.4, 1.14.5, 1.14.6, 1.15.0, 1.15.1, 1.15.2, 1.15.3, 1.15.4, 1.16.0, 1.16.1, 1.16.2, 1.16.3, 1.16.4, 1.16.5, 1.16.6, 1.17.0, 1.17.1, 1.17.2, 1.17.3, 1.17.4, 1.17.5, 1.18.0, 1.18.1, 1.18.2, 1.18.3, 1.18.4, 1.18.5, 1.19.0, 1.19.1, 1.19.2, 1.19.3, 1.19.4, 1.19.5, 1.20.0, 1.20.1, 1.20.2, 1.20.3, 1.21.0, 1.21.1, 1.22.0, 1.22.1, 1.22.2, 1.22.3, 1.22.4, 1.23.0, 1.23.1, 1.23.2, 1.23.3, 1.23.4, 1.23.5, 1.24.0, 1.24.1, 1.24.2, 1.24.3, 1.24.4, 1.25.0, 1.25.1, 1.25.2, 1.26.0, 1.26.1, 1.26.2, 1.26.3, 1.26.4, 2.0.0, 2.0.1, 2.0.2, 2.1.0, 2.1.1, 2.1.2, 2.1.3, 2.2.0, 2.2.1, 2.2.2, 2.2.3, 2.2.4, 2.2.5, 2.2.6, 2.3.0, 2.3.1, 2.3.2, 2.3.3, 2.3.4, 2.3.5, 2.4.0rc1, 2.4.1, 2.4.2, 2.4.3, 2.4.4, 2.4.5, 2.4.6)
ERROR: No matching distribution found for numpy==2.5.3
```

The useful line is the second one, near its end: `2.5.3 Requires-Python >=3.12`. pip found the
version and refused it, because this NumPy is built for 3.12 and newer. Install a newer Python,
delete the folder's `.venv`, and make it again with the new interpreter: an environment is tied
to the Python that made it and cannot be upgraded in place.

## Port 8888 is busy

A second `jupyter lab` while the first is still running somewhere, often in a terminal you forgot
about. These are the lines of the second one's log that say so:

```
[I 2026-10-10 04:06:19.655 ServerApp] The port 8888 is already in use, trying another port.
[I 2026-10-10 04:06:19.655 ServerApp] Jupyter Server 2.21.1 is running at:
[I 2026-10-10 04:06:19.656 ServerApp] http://localhost:8889/lab?token=20d69fcf11ddafde11d7f86434cbd4047ec8b7ad5bb0f3f3
```

Nothing is broken: the second server found `8888` taken and moved to `8889`. But you now have two
servers, each with its own kernels, and a notebook opened in one does not see what runs in the
other. Find the first terminal and stop it with Control-C, twice, or keep it and close the second.
The command `jupyter server list` prints every server running for your user, with its address.

## The notebook runs, and `import pandas` fails

That is the kernel running a Python other than the environment's, which happens when JupyterLab
itself was started from outside it. The second cell of the first notebook is the check:
`sys.executable` must end in `pydata/.venv/bin/python`. If it does not, stop JupyterLab, activate
the environment in that terminal, and start it again.

If something fails that is not here, start from scratch rather than repairing: delete `.venv`,
make it again with the commands of the lab section, and run `pip install` once more. Everything in
it is reproducible from those lines, which is the point of keeping them, and lesson 3 turns them
into a file.
