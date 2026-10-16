"""Lesson 21: from notebook to script."""
from draw import Fig

refactor = Fig(
    "refactor", 720, 280,
    ("The notebook's four cells on the left become the script's parts on the right. The imports stay "
     "imports; reading the file becomes load; the station's counts become per_month, with the station "
     "as an argument; the chart cell becomes chart. A new main reads the command line and calls them "
     "in order.",
     "As quatro células do notebook, à esquerda, viram as partes do script, à direita. Os imports "
     "continuam imports; ler o arquivo vira load; as contagens da estação viram per_month, com a "
     "estação como argumento; a célula do gráfico vira chart. Um main novo lê a linha de comando e as "
     "chama em ordem."),
    ("Each cell becomes a function with its inputs named; main joins them, and argparse supplies what "
     "a cell used to hard-code.",
     "Cada célula vira uma função com as entradas nomeadas; o main as junta, e o argparse fornece o "
     "que uma célula deixava fixo no código."))
f = refactor
f.text(130, 20, "stations.ipynb", mono=True, size=12, weight="600")
f.text(560, 20, "station_report.py", mono=True, size=12, weight="600")
cells = ["import pandas …", "%time trips = …", "station = \"S05\" …", "fig, ax = …"]
funcs = ["import pandas …", "def load(path)", "def per_month(trips, station)", "def chart(counts, station, out)"]
for i, (c, fn) in enumerate(zip(cells, funcs)):
    y = 40 + i * 46
    f.text(20, y + 16, f"[{i + 1}]", mono=True, size=10, fill="paper-dim", anchor="start")
    f.box(50, y, 180, 32, c, mono=True, size=11, weight=None)
    f.line(234, y + 16, 396, y + 16, arrow=True)
    f.box(400, y, 300, 32, fn, mono=True, size=11, weight=None, stroke="phosphor")
f.box(400, 230, 300, 36, "def main(): argparse, then each in order", "def main(): argparse, e cada um em ordem",
      mono=True, size=11, weight=None, stroke="amber")
f.text(140, 248, "run in any order, by hand", "rodadas em qualquer ordem, à mão", size=10,
       fill="paper-dim")

FIGURES = [refactor]
