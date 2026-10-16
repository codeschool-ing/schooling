---
title: Writing the environment down, and proving it rebuilds
version: 1
---

**The environment you have is an accident of the day you built it; the file you write is the
environment you can have again.** Lesson 1 installed seven libraries with one `pip install`, and
pip brought in everything they need. Ask it what is there now:

```
(.venv) ana@lab:~/pydata$ pip freeze | wc -l
103
(.venv) ana@lab:~/pydata$ pip freeze | grep -E "^(numpy|pandas|python-dateutil|pytz|tzdata)=="
numpy==2.5.3
pandas==3.0.6
python-dateutil==2.9.0.post0
tzdata==2026.5
```

A hundred and three packages, from seven requests. Most of them you never chose: `tzdata` is the
time-zone database pandas reads, `python-dateutil` parses dates for it, and a long tail is
JupyterLab's. There are two honest ways to write this down, and a data project wants both.

## The direct requirements, by hand

`requirements.txt` in `pydata`, holding what you asked for and nothing else:

```
jupyterlab==4.6.4
numpy==2.5.3
pandas==3.0.6
matplotlib==3.11.2
seaborn==0.13.2
pyarrow==26.0.0
openpyxl==3.1.5
```

It is short enough to read, and each line is a decision: **this** project uses pandas, at
**this** version. The test of the file is to build an environment from it somewhere else and see
whether it is the same one. A second folder on the same machine, made from nothing but the file:

```
ana@lab:~$ mkdir rebuilt && cd rebuilt
ana@lab:~/rebuilt$ python3 -m venv .venv && source .venv/bin/activate
(.venv) ana@lab:~/rebuilt$ pip install -q -r ../pydata/requirements.txt
(.venv) ana@lab:~/rebuilt$ pip freeze | wc -l
103
(.venv) ana@lab:~/rebuilt$ pip check
No broken requirements found.
```

`-q` keeps pip quiet. The new environment has the same hundred and three packages, and `pip check`
confirms that every package's own requirements are satisfied by the versions next to it.

## The full list, by machine

The direct file pins seven packages and leaves ninety-six to pip's judgement on the day it runs.
Today pip chose what it chose in lesson 1; next month a dependency of JupyterLab will publish a new
version, and the same file will build a slightly different environment. For a notebook whose
numbers matter, write down the whole state as well:

```
(.venv) ana@lab:~/pydata$ pip freeze > requirements-lock.txt
(.venv) ana@lab:~/pydata$ diff <(pip freeze) <(cd ~/rebuilt && .venv/bin/pip freeze) && echo same
same
```

`pip freeze` lists every installed package with its exact version, in the same `name==version`
form `pip install -r` reads. The `diff` compares the two environments' lists and finds nothing, so
`echo same` runs: the file built an identical environment, today. `requirements-lock.txt` is what
makes "today" any day.

Keep both, and know which to use:

| file | written by | holds | rebuild with it when |
|---|---|---|---|
| `requirements.txt` | you | what the project needs, pinned | you are upgrading on purpose, and want pip to choose the rest again |
| `requirements-lock.txt` | `pip freeze` | everything, exactly | you want the same environment, and the same numbers |

The `python` course, lesson 19, does the same thing with `uv` and `pyproject.toml`, where one
command keeps both lists for you; for a project that is becoming a package, that is the better
tool. Two plain text files are enough for an analysis, and they work with nothing installed but
pip.

**Both go into version control beside the notebooks; `.venv` never does.** The folder is
reproduced in minutes from either file, and the files are the part worth keeping.
