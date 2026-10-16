---
title: What goes with it, so it runs elsewhere
version: 1
---

**A script runs elsewhere when three things travel with it: the code, the versions of the libraries it
was written against, and a sentence saying how to run it.** The first is `station_report.py`. The
other two are short files, and leaving them out is what makes "it works on my machine" a sentence
people say.

The versions are lesson 3's `requirements.txt`, the pins this course installed:

```
(.venv) ana@lab:~/pydata$ cat requirements.txt
jupyterlab==4.6.4
numpy==2.5.3
pandas==3.0.6
matplotlib==3.11.2
seaborn==0.13.2
pyarrow==26.0.0
openpyxl==3.1.5
```

Somebody else builds the same environment from it with `pip install -r requirements.txt`, and their
pandas prints what yours printed. Without it they get whatever is newest that day, and lesson 11 showed
how much one major version of pandas can change.

The sentence is a `README.md` beside the script: a text file, written in Markdown because
GitHub and most editors draw it as a page, and for a script this size it is short. Create it in
JupyterLab with **Text File**, name it `README.md`, and write what someone needs to run the script
from nothing:

```
(.venv) ana@lab:~/pydata$ cat README.md
# Station report

Trips per month from one Maré Bikes station, as a table and a chart.

    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    python station_report.py S05

`--data` points at another trips file, `--out` names the chart, and
`python station_report.py -h` lists both.
```

The folder holds the project and what it made:

```
(.venv) ana@lab:~/pydata$ ls
README.md  __pycache__	 quiet.png	   station_report.py  stations.ipynb  trips.csv
S05.png    make_data.py  requirements.txt  stations.csv       stations.py     weather.csv
```

Four of those are the project: `station_report.py`, `requirements.txt`, `README.md`, and
`stations.ipynb`. The CSV files are the data, `make_data.py` makes them, and the two charts are output.
`__pycache__` is where Python keeps the compiled form of a module it imported, `station_report`
here, and it is rebuilt whenever it is missing, so it is left out of a repository with a line in
`.gitignore`. `stations.py`, the converted notebook, has done its job and can go.

`stations.ipynb` stays. It is where the question was first asked, and it is the right place to ask the
next one. **The notebook is for finding out; the script is for doing it again.** Each time an answer
found in the notebook has to be produced again, it moves into a function in the script, and the
notebook imports it from there.

That is the whole course in one habit: a notebook that runs top to bottom, types chosen on purpose,
joins and windows checked against their row counts, charts that say what they show, and the work that
must last moved into a file that runs without you.
