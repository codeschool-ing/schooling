"""Lesson 1: Jupyter and JupyterLab."""
from draw import Fig

three = Fig(
    "three", 720, 250,
    ("Three programs. The browser holds the page of cells and sends code to the Jupyter server, "
     "which passes it to the kernel, a Python process that holds the state; results travel back "
     "the same way. The server also saves the notebook to disk as first.ipynb.",
     "Três programas. O navegador tem a página de células e manda código ao servidor Jupyter, que o "
     "repassa ao kernel, um processo Python que guarda o estado; os resultados voltam pelo mesmo "
     "caminho. O servidor também grava o notebook em disco como first.ipynb."),
    ("The page shows what the kernel said when each cell ran. The kernel holds what is true now.",
     "A página mostra o que o kernel disse quando cada célula rodou. O kernel guarda o que vale agora."))
f = three
f.box(20, 50, 170, 90, "your browser", "seu navegador", sub=("the page: cells, outputs", "a página: células, saídas"))
f.box(275, 50, 170, 90, "Jupyter server", "servidor Jupyter", sub=("started in the terminal", "iniciado no terminal"))
f.box(530, 50, 170, 90, "kernel", "kernel", sub=("Python, and its variables", "o Python e suas variáveis"))
f.box(275, 185, 170, 50, "first.ipynb", mono=True, size=12, sub=("on disk", "em disco"))
for x1, x2 in ((190, 275), (445, 530)):
    f.line(x1 + 4, 80, x2 - 4, 80, arrow=True)
    f.line(x2 - 4, 110, x1 + 4, 110, arrow=True)
f.text(232, 68, "code", "código", size=10, fill="paper-dim")
f.text(232, 124, "outputs", "saídas", size=10, fill="paper-dim")
f.text(487, 68, "code", "código", size=10, fill="paper-dim")
f.text(487, 124, "results", "resultados", size=10, fill="paper-dim")
f.line(360, 144, 360, 181, arrow=True)
f.text(388, 162, "save", "grava", size=10, fill="paper-dim")

FIGURES = [three]
