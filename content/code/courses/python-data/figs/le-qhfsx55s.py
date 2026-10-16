"""Lesson 3: environments, requirements and conda."""
from draw import Fig

kernels = Fig(
    "kernels", 720, 250,
    ("One JupyterLab, started from pydata's environment, lists two kernels. The kernel python3 runs "
     "pydata/.venv/bin/python with pandas 3.0.6; the kernel oldpandas runs oldpandas/.venv/bin/python "
     "with pandas 2.2.3. The same notebook can be switched between them.",
     "Um JupyterLab, iniciado do ambiente de pydata, lista dois kernels. O kernel python3 roda "
     "pydata/.venv/bin/python com pandas 3.0.6; o kernel oldpandas roda oldpandas/.venv/bin/python "
     "com pandas 2.2.3. O mesmo notebook pode ser trocado entre os dois."),
    ("A kernel is a registered Python. Which one a notebook runs decides which pandas answers.",
     "Um kernel é um Python registrado. Qual deles roda o notebook decide qual pandas responde."))
f = kernels
f.box(20, 85, 170, 80, "JupyterLab", "JupyterLab", sub=("one server", "um servidor"))
f.box(275, 30, 170, 70, "python3", mono=True, sub=("kernel", "kernel"))
f.box(275, 150, 170, 70, "oldpandas", mono=True, sub=("kernel", "kernel"))
f.box(530, 30, 170, 70, "pydata/.venv", mono=True, sub=("pandas 3.0.6", "pandas 3.0.6"), sub_mono=True)
f.box(530, 150, 170, 70, "oldpandas/.venv", mono=True, sub=("pandas 2.2.3", "pandas 2.2.3"), sub_mono=True)
f.line(194, 112, 271, 70, arrow=True)
f.line(194, 138, 271, 180, arrow=True)
f.line(449, 65, 526, 65, arrow=True)
f.line(449, 185, 526, 185, arrow=True)
f.text(487, 52, "runs", "roda", size=10, fill="paper-dim")
f.text(487, 172, "runs", "roda", size=10, fill="paper-dim")

FIGURES = [kernels]
