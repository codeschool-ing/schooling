---
title: What an environment holds, for a data project
version: 1
---

**A notebook's answer depends on four things, and only one of them is in the notebook.** The code
is in the `.ipynb`. The data is in the folder, and lesson 2 said how to keep it honest. The Python
is the one `language_info` records. The fourth is the libraries, and a notebook records nothing at
all about them: open it with pandas 2 instead of pandas 3 and it runs, and some of its answers
change.

The `python` course built virtual environments for ordinary projects, in lessons 18 and 19:
`venv`, `pip`, `requirements.txt`, and then `uv` and `pyproject.toml`. That is assumed here. This
lesson is about what changes when the project is an analysis rather than a program:

- **The libraries are large and compiled.** NumPy and pandas are mostly C, shipped as wheels built
  for one operating system and one processor; `pydata/.venv` is 635 MB after one `pip install`.
  Rebuilding an environment is cheap in commands and not free in disk or time.
- **They change behaviour between versions, quietly.** A web framework that changes its API makes
  your program fail. pandas changing a default makes your notebook print a different number, which
  is worse, and lesson 11 and lesson 12 each have an example.
- **The person running it next is often you, months later**, on a different computer, wanting the
  same chart for the next quarter. The environment has to be rebuilt from something written down,
  because the one you have will not survive that long untouched.
- **Some tools outside Python are part of the stack.** A database driver, a geographic library, a
  GPU toolkit: none of those is a wheel `pip` can install everywhere, and that is the gap conda
  fills, four sections from here.

So a data project carries, beside its notebooks, **a file that says which libraries at which
versions**, and the discipline of rebuilding the environment from that file rather than from
memory. The rest of this lesson writes that file, proves it rebuilds, runs two environments side
by side in one JupyterLab, and then does the same with conda.
