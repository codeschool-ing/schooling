---
title: Two environments, one JupyterLab
version: 1
---

**A pinned version is not pedantry: the same line of pandas gives a different answer in a different
version, and runs without complaint in both.** The quickest way to believe it is to see it. Here is
a four-line script, `check.py`, saved in `pydata`:

```py
import sys
import pandas as pd

plans = pd.Series(["annual", "day", "annual"])
print(sys.version.split()[0], pd.__version__, plans.dtype)
```

It prints the Python, the pandas, and the type pandas gives a column of text. Now a second
project, `oldpandas`, with the pandas that was current before this course's:

```
ana@lab:~$ mkdir oldpandas && cd oldpandas
ana@lab:~/oldpandas$ python3 -m venv .venv && source .venv/bin/activate
(.venv) ana@lab:~/oldpandas$ pip install -q pandas==2.2.3 ipykernel
(.venv) ana@lab:~/oldpandas$ python ~/pydata/check.py
3.12.3 2.2.3 object
(.venv) ana@lab:~/pydata$ python check.py
3.12.3 3.0.6 str
```

**Same Python, same three words, two different types.** pandas 2 stores text in a column of
general Python objects, `object`; pandas 3 gives text a type of its own, `str`. Code that tests
`dtype == object` to find the text columns, which was common and correct for years, finds none of
them in pandas 3, and nothing raises an error. Lesson 12 is about types in pandas, and this
difference is the first thing in it.

## Choosing the environment from the notebook

Each environment can run JupyterLab, but you do not need a JupyterLab per project. JupyterLab finds
**kernels**, and an environment with `ipykernel` installed can register itself as one:

```
(.venv) ana@lab:~/oldpandas$ python -m ipykernel install --user --name oldpandas --display-name "Python (pandas 2.2)"
Installed kernelspec oldpandas in /home/ana/.local/share/jupyter/kernels/oldpandas
(.venv) ana@lab:~/pydata$ jupyter kernelspec list
Available kernels:
  python3      /home/ana/pydata/.venv/share/jupyter/kernels/python3
  oldpandas    /home/ana/.local/share/jupyter/kernels/oldpandas
```

`--user` puts the registration in your home folder, where every JupyterLab you start can see it;
`--name` is the folder it gets and `--display-name` is what the launcher shows. Now the launcher in
`pydata`'s JupyterLab has two Python cards, `Python 3 (ipykernel)` and `Python (pandas 2.2)`, and
**Kernel, Change Kernel…** switches an open notebook between them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"One JupyterLab, started from pydata&#x27;s environment, lists two kernels. The kernel python3 runs pydata/.venv/bin/python with pandas 3.0.6; the kernel oldpandas runs oldpandas/.venv/bin/python with pandas 2.2.3. The same notebook can be switched between them.\" data-fig=\"kernels\"><defs><marker id=\"kernels-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"85\" width=\"170\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">JupyterLab</text><text x=\"105.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one server</text><rect x=\"275\" y=\"30\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">python3</text><text x=\"360.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kernel</text><rect x=\"275\" y=\"150\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">oldpandas</text><text x=\"360.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kernel</text><rect x=\"530\" y=\"30\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">pydata/.venv</text><text x=\"615.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pandas 3.0.6</text><rect x=\"530\" y=\"150\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">oldpandas/.venv</text><text x=\"615.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pandas 2.2.3</text><line x1=\"194\" y1=\"112\" x2=\"271\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#kernels-ah)\"></line><line x1=\"194\" y1=\"138\" x2=\"271\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#kernels-ah)\"></line><line x1=\"449\" y1=\"65\" x2=\"526\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#kernels-ah)\"></line><line x1=\"449\" y1=\"185\" x2=\"526\" y2=\"185\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#kernels-ah)\"></line><text x=\"487\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">runs</text><text x=\"487\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">runs</text></svg>", "caption": "A kernel is a registered Python. Which one a notebook runs decides which pandas answers."}
```

A notebook records its choice in `kernelspec`, the metadata lesson 1 showed, so it opens on the same kernel next time.

The registration is a small folder holding the path to `oldpandas/.venv/bin/python`. Delete the
environment and the card stays, pointing at nothing; remove it with
`jupyter kernelspec remove oldpandas`.

Two habits keep this from becoming a source of confusion instead of a tool:

- **Ask the kernel, not the launcher.** The second cell of lesson 1's notebook, `sys.executable`,
  says which environment a notebook is really running in. A card's name is only a label somebody
  typed.
- **Install into an environment from its own terminal.** Inside a notebook, `%pip install` installs
  into the kernel's environment, which is what you meant; a bare `!pip install` runs whatever `pip`
  the shell finds first, which may be another environment's. Better still, add the line to
  `requirements.txt` and install from the file, so that the file stays the truth.
