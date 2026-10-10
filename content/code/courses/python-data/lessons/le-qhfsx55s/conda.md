---
title: conda, and the environment that is not only Python
version: 1
---

**conda manages environments like `venv` does, and installs packages like `pip` does, but its
packages are not limited to Python.** A conda package can be a C library, a compiler, a database
client or a whole Python interpreter, built for your system and installed beside the rest. That is
why so much of data science uses it: GDAL for maps, CUDA for a graphics card, a specific BLAS for
linear algebra. pip can only install what is published as a Python wheel, and for those it is not
always possible.

For the libraries in this course, every one of them is a wheel and `venv` with pip is all you need.
This section installs conda anyway, because you will meet projects that use it, and because it
shows a failure every data scientist meets in their first month.

## Installing it

**Miniforge** is the small installer from the conda-forge community: conda itself, a Python to run
it, and conda-forge as the only channel, which is the free, community-built repository of conda
packages. On Linux:

```
ana@lab:~$ curl -LO https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
ana@lab:~$ bash Miniforge3-Linux-x86_64.sh -b
Transaction finished

installation finished.
ana@lab:~$ source ~/miniforge3/bin/activate
(base) ana@lab:~$ conda --version
conda 26.7.2
```

`curl` prints nothing when it succeeds. The installer, run without `-b`, asks you to read a licence
and confirm where to install; `-b` accepts the defaults, which put everything in `~/miniforge3` and
change nothing outside it. `source ~/miniforge3/bin/activate` starts conda in this terminal, and the
prompt shows `(base)`, the environment conda itself lives in. **Install nothing into `base`**: it
is conda's own environment, and breaking it breaks conda.

On Windows and macOS, Miniforge has a graphical installer on its download page; neither was run for
this course.

## Creating an environment, and the version that is not there

conda creates environments by name, in `~/miniforge3/envs`, and installs into them in the same
command. The same seven libraries, at the same versions, from conda-forge:

```
(base) ana@lab:~$ conda create -y -q -n bikes -c conda-forge python=3.12 numpy=2.5.3 pandas=3.0.6 matplotlib=3.11.2 seaborn=0.13.2 pyarrow=26.0.0 openpyxl=3.1.5 jupyterlab=4.6.4
Channels:
 - conda-forge
Platform: linux-64
Collecting package metadata (repodata.json): ...working... done
Solving environment: ...working... failed
Channels:
 - conda-forge
Platform: linux-64
Collecting package metadata (repodata.json): ...working... done
Solving environment: ...working... failed

PackagesNotFoundInChannelsError: The following packages are not available from current channels:

  - pyarrow=26.0.0

Current channels:

  - https://conda.anaconda.org/conda-forge

To search for alternate channels that may provide the conda package you're
looking for, navigate to

    https://anaconda.org

and use the search bar at the top of the page.


```

**`pyarrow=26.0.0` is not on conda-forge**, though pip installed it in lesson 1. The two
repositories are built by different people on different schedules, and a version can exist on PyPI
for weeks before conda-forge has it, or the other way round. The fix that keeps the versions is to
take everything else from conda and that one package from pip, **in that order**:

```
(base) ana@lab:~$ conda create -y -q -n bikes -c conda-forge python=3.12 numpy=2.5.3 pandas=3.0.6 matplotlib=3.11.2 seaborn=0.13.2 openpyxl=3.1.5 jupyterlab=4.6.4 > /dev/null && echo done
WARNING conda.conda_pypi.main:notify_externally_managed_future(156): 
  Did you know? You can install many PyPI packages with conda
  using the conda-pypi beta. Get started:
    https://docs.conda.io/projects/conda/en/stable/new-features.html

done
(base) ana@lab:~$ conda activate bikes
(bikes) ana@lab:~$ pip install -q pyarrow==26.0.0
(bikes) ana@lab:~$ conda list "^(numpy|pandas|pyarrow)$"
# packages in environment at /home/ana/miniforge3/envs/bikes:
#
# Name                     Version          Build               Channel
numpy                      2.5.3            py312he827f4e_0     conda-forge
pandas                     3.0.6            np2py312h91ec553_0  conda-forge
pyarrow                    26.0.0           pypi_0              pypi
```

`conda list` shows where each package came from in its last column. `pypi` marks the one pip put
there. The rule is conda first and pip last: pip knows nothing of conda's packages, and a conda
install run after pip may replace what pip installed without telling it.

## Writing it down

conda's equivalent of `requirements.txt` is `environment.yml`. `conda env export --from-history`
writes one from what you asked for, rather than the hundreds of packages that came with it:

```
(bikes) ana@lab:~/pydata$ conda env export --from-history
/home/ana/miniforge3/lib/python3.14/site-packages/conda/cli/main_export.py:295: CondaExportWarning: The exported environment contains 3rd party Python packages.

Your environment contains 1 package installed via pip. Conda cannot reliably lock these packages for reproducible environments.

Detected packages:
  - pyarrow==26.0.0

Learn more: https://docs.conda.io/projects/conda/en/stable/user-guide/configuration/pip-interoperability.html
  warnings.warn(warning, CondaExportWarning)
name: bikes
channels:
  - conda-forge
dependencies:
  - openpyxl=3.1.5
  - python=3.12
  - matplotlib=3.11.2
  - numpy=2.5.3
  - jupyterlab=4.6.4
  - seaborn=0.13.2
  - pandas=3.0.6
prefix: /home/ana/miniforge3/envs/bikes
```

The warning names the problem: **`pyarrow` is missing from the list**, because conda wrote down
only what conda installed. An environment rebuilt from this file would have no pyarrow at all. So
the file is finished by hand, with a `pip:` section, and that is the version to keep in the
project:

```yaml
name: bikes
channels:
  - conda-forge
dependencies:
  - python=3.12
  - numpy=2.5.3
  - pandas=3.0.6
  - matplotlib=3.11.2
  - seaborn=0.13.2
  - openpyxl=3.1.5
  - jupyterlab=4.6.4
  - pip
  - pip:
      - pyarrow==26.0.0
```

The proof is the same as for `requirements.txt`: build from the file, under another name, and ask
what came out:

```
(base) ana@lab:~/pydata$ conda env create -q -n bikes2 -f environment.yml > /dev/null && echo done
WARNING conda.conda_pypi.main:notify_externally_managed_future(156): 
  Did you know? You can install many PyPI packages with conda
  using the conda-pypi beta. Get started:
    https://docs.conda.io/projects/conda/en/stable/new-features.html

done
(base) ana@lab:~/pydata$ conda run -n bikes2 python -c "import numpy, pandas, pyarrow; print(numpy.__version__, pandas.__version__, pyarrow.__version__)"
2.5.3 3.0.6 26.0.0
```

## What it costs

```
(base) ana@lab:~$ du -sh miniforge3/envs/bikes pydata/.venv
1.9G	miniforge3/envs/bikes
635M	pydata/.venv
(base) ana@lab:~$ du -sh --exclude=envs --exclude=pkgs miniforge3
430M	miniforge3
(base) ana@lab:~$ du -sh miniforge3/pkgs
2.5G	miniforge3/pkgs
```

**The conda environment is three times the size of the `venv` one**, for the same seven libraries,
because it brings its own Python and its own copies of the C libraries underneath them, where the
`venv` borrows Ubuntu's Python. conda itself is another 430 MB, and `pkgs` is its cache of every
package it downloaded, kept so that the next environment needing one does not download it again;
`conda clean --all` empties it when the disk matters more.

That is the price of not depending on the system, and it is why this course recommends `venv` for its own work and conda for the projects that need something pip
cannot install.

Remove what you made here when you are done with it: `conda env remove -n bikes2` deletes one
environment, and deleting `~/miniforge3` removes conda entirely.
