---
title: The lab, and three ways to build it
version: 1
---

**A model is fitted, not described.** Every lesson in this course runs something: a split, a fit,
a score, a curve. You will understand a confusion matrix a good deal better after your own
program has printed one that disagrees with what you expected, so the course is built to be run,
on a computer you set up yourself. This section sets it up. The next one makes the data.

The lab is one folder, `~/ml`, with three things in it:

- **Python 3.12 or newer**, in a **virtual environment** of its own, `~/ml/.venv`, so nothing
  installed here touches the Python your system or your other courses use;
- **the libraries**: scikit-learn for almost everything, pandas and NumPy underneath it,
  XGBoost and LightGBM for lesson 8, UMAP for lesson 17, SHAP for lesson 19, and FastAPI with
  Uvicorn for lesson 21, which puts a model behind an address;
- **the data**, in `~/ml/data`, written by one program you paste in the next section.

Nothing in this course needs a graphics card. **A processor is enough**, which is the line between
this course and `deep-learning`, and the largest fit here takes seconds rather than hours.

## Three ways to have one

| path | what it costs your computer | the transcripts |
|---|---|---|
| **installed, in a virtual environment** (recommended) | about 710 MB of disk inside one folder, and nothing outside it | match as printed on Ubuntu 24.04; close elsewhere |
| **in a virtual machine** | an Ubuntu 24.04 machine: about 25 GB of disk, and the memory and processors you lend it | match as printed |
| **online** | nothing on your computer; an account with somebody, on their terms | close, not exact |

**Installing is the recommended path for this course.** Most of what a lesson does is
arithmetic, and a virtual machine takes processors and memory away from it. A virtual
environment changes nothing outside its own folder, so deleting `~/ml` removes the whole lab. If
you built a virtual machine for `data-cleaning`, it works just as well here; its lesson 1 builds
the same kind of machine.

**In a virtual machine**, `virtualization` lesson 4 builds one in VirtualBox. Give it at least
4 GB of memory and two processors. On Windows, WSL running Ubuntu 24.04 is a virtual machine too,
and the commands below work there unchanged.

**Online**, Google Colab gives you a notebook with Python in the browser, and GitHub Codespaces
gives you a Linux machine with a terminal. Both cost your computer nothing, and both belong to a
company that sets the allowance and can change it, so neither is a path this course depends on.
Neither was used to record anything here. On either one, install the same `requirements.txt`
below before you start, because the versions they come with are not the versions these lessons
print.

The transcripts were recorded on Ubuntu 24.04, where the prompt reads `ana@lab:~/ml$`: `ana` is
the person, `lab` the machine and `~/ml` the folder. Yours prints your own name.

## Building it

Open a terminal and make the folder:

```sh
mkdir ~/ml
cd ~/ml
```

Then a file that names every library and its exact version. **The versions are pinned on
purpose**: a newer scikit-learn can change a default, and a changed default changes a score,
which is part of lesson 15. Save this as `~/ml/requirements.txt`. Any editor will do; `nano
requirements.txt` opens one in the terminal, saves with Ctrl+O and quits with Ctrl+X.

```
# requirements.txt
scikit-learn==1.9.1
pandas==3.0.6
numpy==2.5.3
scipy==1.18.1
matplotlib==3.11.2
xgboost-cpu==3.4.1
lightgbm==4.7.0
shap==0.53.0
umap-learn==0.5.12
fastapi==0.143.0
uvicorn==0.54.0
```

`xgboost-cpu` is XGBoost without the code for graphics cards, which on Linux is a difference of
some 300 MB for nothing this course uses. Now the environment, and the libraries inside it:

```
ana@lab:~/ml$ python3 --version
Python 3.12.3
ana@lab:~/ml$ python3 -m venv .venv
ana@lab:~/ml$ source .venv/bin/activate
ana@lab:~/ml$ pip install --quiet -r requirements.txt
```

`--quiet` keeps pip from printing every file it downloads, so **silence is success here**.

Last, five lines at the end of `~/.bashrc`, so that every new terminal starts the same way:

```sh
cat >> ~/.bashrc <<'EOF'
# machine-learning
export TZ=America/Sao_Paulo
export VIRTUAL_ENV_DISABLE_PROMPT=1
source ~/ml/.venv/bin/activate
EOF
```

`TZ` puts the machine on the company's clock. The last line **activates** the environment: from
then on, `python` and `pip` are the ones in `~/ml/.venv`. Activating normally adds `(.venv)` to the
front of the prompt, and the line before it turns that off, so your prompt looks like the
transcripts. Open a new terminal, `cd ~/ml`, and check:

```
ana@lab:~/ml$ which python
/home/ana/ml/.venv/bin/python
ana@lab:~/ml$ python --version
Python 3.12.3
ana@lab:~/ml$ python -c "import sklearn, pandas, numpy; print(sklearn.__version__, pandas.__version__, numpy.__version__)"
1.9.1 3.0.6 2.5.3
```

That is the whole lab. It takes this much disk:

```
ana@lab:~/ml$ du -sh .venv
711M	.venv
```

## Off Linux

Two things change, and neither was recorded here.

- **On Windows**, outside WSL, install Python 3.12 from `python.org` and tick *Add python.exe to
  PATH*. The environment's programs live in `.venv\Scripts\` rather than `.venv/bin/`, so
  activating it is `.venv\Scripts\activate`, and there is no `~/.bashrc`: you activate it in each
  new terminal.
- **On macOS**, the commands are the same. In `requirements.txt` write `xgboost==3.4.1` where it
  says `xgboost-cpu==3.4.1`, because the second is not published for macOS. LightGBM's own
  documentation asks for OpenMP on macOS, which Homebrew installs with `brew install libomp`.

If you would rather work in a notebook, as `python-data` did, install JupyterLab into the same
environment with `pip install jupyterlab` and open one in `~/ml`. The course shows programs saved
as files and run whole, for the reason `python-data` gave in its last lesson: a file runs top to
bottom every time, and a notebook runs in whatever order its cells were last clicked.
