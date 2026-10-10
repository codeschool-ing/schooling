"""Lesson 2: cells, execution order and hidden state."""
from draw import Fig

record = Fig(
    "record", 720, 250,
    ("Left, the page: two cells, the first marked 1 and the second marked 3 with the output 20 under it. "
     "Right, the kernel's history: run 1 sets total to 0, run 2 adds 10 and leaves 10, run 3 adds 10 again and leaves 20.",
     "À esquerda, a página: duas células, a primeira marcada 1 e a segunda marcada 3 com a saída 20 embaixo. "
     "À direita, o histórico do kernel: a execução 1 põe total em 0, a 2 soma 10 e deixa 10, a 3 soma 10 de novo e deixa 20."),
    ("The page keeps the last output of each cell. Only the kernel knows the second cell ran twice.",
     "A página guarda a última saída de cada célula. Só o kernel sabe que a segunda rodou duas vezes."))
f = record
f.text(150, 22, "the page", "a página", weight="600")
f.text(530, 22, "the kernel, run by run", "o kernel, execução a execução", weight="600")
f.box(40, 45, 260, 46, "total = 0", mono=True, weight=None)
f.text(24, 68, "[1]", mono=True, size=10, fill="paper-dim")
f.box(40, 110, 260, 46, "total = total + 10", mono=True, weight=None)
f.text(24, 133, "[3]", mono=True, size=10, fill="paper-dim")
f.text(170, 176, "20", mono=True, fill="amber")
f.text(170, 200, "only the last output is kept", "só a última saída fica", size=10, fill="paper-dim")
for i, (code, val) in enumerate([("total = 0", "0"), ("total + 10", "10"), ("total + 10", "20")]):
    y = 45 + i * 62
    f.box(400, y, 200, 46, code, mono=True, weight=None)
    f.text(388, y + 23, str(i + 1), mono=True, size=10, fill="paper-dim", anchor="end")
    f.text(640, y + 23, "total", mono=True, size=10, fill="paper-dim")
    f.text(690, y + 23, val, mono=True, fill="amber")
f.line(300, 68, 374, 68, arrow=True, stroke="wire")
f.line(300, 130, 374, 130, arrow=True, stroke="wire")
f.line(300, 145, 374, 186, arrow=True, stroke="wire")

order = Fig(
    "order", 720, 290,
    ("Page order on the left: the csv cell, the wet-days cell, the limit cell. Run order on the right: "
     "1 the csv cell, 2 the wet-days cell failing with NameError, 3 the limit cell, 4 the wet-days cell again giving 63. "
     "Run from the top, the wet-days cell comes before the limit and fails.",
     "Ordem da página à esquerda: a célula do csv, a dos dias chuvosos, a do limite. Ordem de execução à direita: "
     "1 a do csv, 2 a dos dias chuvosos falhando com NameError, 3 a do limite, 4 a dos dias chuvosos de novo dando 63. "
     "Rodada de cima, a célula dos dias chuvosos vem antes do limite e falha."),
    ("The page is in one order and the history in another. Restart and run all replays the page.",
     "A página está numa ordem e o histórico em outra. Reiniciar e rodar tudo repete a página."))
f = order
f.text(140, 20, "page order", "ordem da página", weight="600")
f.text(560, 20, "run order", "ordem de execução", weight="600")
page = [("days = …", "[1]"), ("wet = … > limit", "[4]"), ("limit = 10", "[3]")]
for i, (code, n) in enumerate(page):
    y = 40 + i * 70
    f.box(40, y, 200, 46, code, mono=True, weight=None)
    f.text(252, y + 23, n, mono=True, size=10, fill="paper-dim", anchor="start")
runs = [("days = …", None, "paper-dim"), ("wet = …", "NameError", "amber"), ("limit = 10", None, "paper-dim"), ("wet = …", "63", "amber")]
for i, (code, out, tone) in enumerate(runs):
    y = 40 + i * 58
    f.box(460, y, 170, 44, code, mono=True, weight=None)
    f.text(450, y + 22, str(i + 1), mono=True, size=10, fill="paper-dim", anchor="end")
    if out:
        f.text(640, y + 22, out, mono=True, size=10, fill=tone, anchor="start")
links = [(0, 0), (1, 1), (2, 2), (1, 3)]
for p, r in links:
    f.line(282, 63 + p * 70, 436, 62 + r * 58, arrow=True)
f.text(360, 278, "restart and run all: page order, and the second cell fails",
       "reiniciar e rodar tudo: ordem da página, e a segunda célula falha", size=10, fill="paper-dim")

FIGURES = [record, order]
