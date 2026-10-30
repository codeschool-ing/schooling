"""Lesson 19 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-bj93ayfx"
f = Fig("l19-grouping", 720, 330,
        "One session row, drawn at the top: the course title, the minutes, the unit and a tick. Below it, the three ways to group it for VoiceOver. With ignore, the row is one stop that says the label and value the app gave it. With combine, the row is one stop that reads the children's own labels joined. With contain, the children stay separate stops inside one container that VoiceOver can enter and leave.",
        "Uma linha de sessão, desenhada em cima: o título do curso, os minutos, a unidade e um visto. Abaixo, as três formas de agrupá-la para o VoiceOver. Com ignore, a linha é uma parada que diz o rótulo e o valor que o app deu. Com combine, a linha é uma parada que lê as palavras dos próprios filhos juntas. Com contain, os filhos continuam paradas separadas dentro de um contêiner em que o VoiceOver entra e de onde sai.")
f.box(160, 18, 400, 44, stroke="wire")
f.text(240, 40, "SQL Databases", mono=True, size=11)
f.text(420, 40, "50 min", mono=True, size=11, fill="paper-dim")
f.text(520, 40, "✓", mono=True, size=13, fill="phosphor")
f.text(360, 82, "the same row, three ways", "a mesma linha, de três jeitos", size=10, fill="paper-dim")
cols = [(20, ".ignore", "one stop", "uma parada", "the label you wrote:", "o rótulo que você escreveu:", "SQL Databases, 50 minutes,", "Monday 19 October · done"),
        (255, ".combine", "one stop", "uma parada", "the children, joined:", "os filhos, juntos:", "SQL Databases, 50 min,", "and the image's name"),
        (490, ".contain", "four stops", "quatro paradas", "each child on its own,", "cada filho sozinho,", "inside one container", None)]
for x, name, en, pt, l1e, l1p, l2, l3 in cols:
    f.box(x, 100, 210, 210, stroke="phosphor" if name == ".ignore" else "wire", fill="ink")
    f.text(x + 105, 122, name, mono=True, size=12, fill="amber", weight="600")
    f.text(x + 105, 144, en, pt, size=11, fill="paper", weight="600")
    f.text(x + 105, 170, l1e, l1p, size=10, fill="paper-dim")
    f.line(360, 62, x + 105, 98, color="wire")
for x in (20, 255):
    f.box(x + 15, 190, 180, 60, stroke="phosphor" if x == 20 else "wire")
f.text(125, 210, "SQL Databases, 50 minutes,", mono=True, size=9, fill="phosphor")
f.text(125, 230, "Monday 19 October · done", mono=True, size=9, fill="phosphor")
f.text(360, 210, "SQL Databases, 50 min,", mono=True, size=9, fill="paper")
f.text(360, 230, "and the tick's own label", "e o rótulo do próprio visto", size=9, fill="paper")
f.text(595, 186, "inside one container", "dentro de um contêiner", size=10, fill="paper-dim")
for i, w in enumerate(["SQL Databases", "50", "min", "✓"]):
    f.box(510, 200 + i * 26, 170, 22, stroke="wire", dashed=True)
    f.text(595, 211 + i * 26, w, mono=True, size=9, fill="paper")
f.write(lesson(L, "grouping"),
        "Grouping decides how many stops a row makes. The planner's session row is ignore with its own label, because the sentence it needs is not its children's words in order.",
        "O agrupamento decide quantas paradas uma linha faz. A linha de sessão do planner é ignore com rótulo próprio, porque a frase de que ela precisa não é a das palavras dos filhos em ordem.")
