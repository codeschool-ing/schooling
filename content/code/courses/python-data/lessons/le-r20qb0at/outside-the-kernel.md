---
title: State outside the kernel, in modules and files
version: 1
---

**Restarting the kernel clears its memory and nothing else.** Two kinds of state live outside it
and survive a restart, and both make a notebook answer differently from one day to the next with
no cell changed.

## A module you edit

Sooner or later a function is worth keeping in a file of its own, so that two notebooks can share
it. A cell can write that file: the `%%writefile` magic saves the rest of the cell under the name
it is given, instead of running it.

```python
%%writefile bikes.py
def label(minutes):
    return "short" if minutes < 15 else "long"
```

```
Writing bikes.py
```

```python
import bikes
bikes.label(20)
```

```
'long'
```

Now change your mind about the limit and save the file again, as you would in JupyterLab's
editor:

```python
%%writefile bikes.py
def label(minutes):
    return "short" if minutes < 30 else "long"
```

```
Overwriting bikes.py
```

```python
import bikes
bikes.label(20)
```

```
'long'
```

**Still `long`**, with the file now saying 30. Python imports a module once per process and keeps
it; a second `import` finds it already loaded and does nothing. The kernel is running the version
of `bikes.py` it read the first time, and the page gives no sign of it. Ask for a fresh read:

```python
import importlib
importlib.reload(bikes)
bikes.label(20)
```

```
'long'
```

`importlib.reload` reads the file again. Restarting the kernel does the same for every module at
once. IPython also has an extension that reloads edited modules before each cell, turned on with
two lines, `%load_ext autoreload` and `%autoreload 2`; it is convenient while a module is changing
every few minutes, and it is also one more thing that differs between your session and somebody
else's run of the notebook.

## A file that changes underneath

The notebook reads `weather.csv` from the folder, and the folder is not part of the notebook. If
the file changes, the same cells give different answers, and nothing in the `.ipynb` says which
file it read. Two habits cover most of it:

- **Read the data in the first cells, with its path written there**, so that what the notebook
  depends on is on its first screen and nowhere else.
- **Never overwrite your input.** A cleaned file gets a new name. A notebook that reads
  `trips.csv` and writes `trips.csv` gives a different answer the second time it runs, because
  the second run reads the first run's output.

Lesson 3 adds the third piece outside the kernel, the libraries themselves, and how to write their
versions down beside the notebook.
