"""Lesson 3 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-90xpvn2v"

f = Fig("l03-frames", 720, 250,
        "Four frames along a time line. Frame 1: the body runs and reads title and minutes. Then minutes changes, which the body read, so frame 2 runs the body. Then notes changes, which the body never read, so frame 3 runs nothing. Then title and minutes both change before frame 4, which runs the body once.",
        "Quatro quadros ao longo de uma linha do tempo. Quadro 1: o body roda e lê title e minutes. Depois minutes muda, que o body leu, então o quadro 2 roda o body. Depois notes muda, que o body nunca leu, então o quadro 3 não roda nada. Depois title e minutes mudam antes do quadro 4, que roda o body uma vez.")
f.line(30, 200, 700, 200, color="wire")
f.text(690, 220, "time", "tempo", size=10, fill="paper-dim", anchor="end")
frames = [(70, "frame 1", "quadro 1", True, "body run 1", "body roda (1)"),
          (250, "frame 2", "quadro 2", True, "body run 2", "body roda (2)"),
          (430, "frame 3", "quadro 3", False, "nothing to redo", "nada a refazer"),
          (610, "frame 4", "quadro 4", True, "body run 3", "body roda (3)")]
for x, en, pt, ran, ren, rpt in frames:
    f.box(x - 60, 150, 120, 36, stroke="phosphor" if ran else "wire", dashed=not ran)
    f.text(x, 160, en, pt, size=10, fill="paper-dim")
    f.text(x, 176, ren, rpt, size=10, fill="phosphor" if ran else "paper-dim")
    f.line(x, 186, x, 198, color="wire", arrow=False)
changes = [(160, "minutes = 60", True), (340, "notes = …", False), (520, "title, minutes", True)]
for x, label, read in changes:
    f.box(x - 70, 40, 140, 30, stroke="amber" if read else "wire")
    f.text(x, 55, label, mono=True, size=10, fill="amber" if read else "paper-dim")
    f.line(x, 70, x, 196, color="amber" if read else "wire", dashed=not read)
f.text(166, 110, "read by the body", "lido pelo body", size=10, fill="amber", anchor="start")
f.text(346, 110, "never read", "nunca lido", size=10, fill="paper-dim", anchor="start")
f.text(526, 110, "two changes, one run", "duas mudanças, uma execução", size=10, fill="amber", anchor="start")
f.write(lesson(L, "counting-bodies"),
        "A change marks the screen dirty only if the body read what changed, and any number of changes between frames cost one run.",
        "Uma mudança só suja a tela se o body leu o que mudou, e quantas mudanças houver entre quadros custam uma execução.")

g = Fig("l03-branches", 720, 250,
        "The type Pair<Text, Either<Image, Text>> drawn as a tree. Pair has two slots: the first holds Text, the title; the second holds Either, which has two branches, first holding Image, the checkmark, and second holding Text, the minutes. When done is true the first branch is filled; when it is false the second. The title is in the same slot either way.",
        "O tipo Pair<Text, Either<Image, Text>> desenhado como árvore. Pair tem duas vagas: a primeira guarda Text, o título; a segunda guarda Either, que tem dois ramos, first com Image, o sinal de concluído, e second com Text, os minutos. Quando done é verdadeiro o primeiro ramo é preenchido; quando é falso, o segundo. O título fica na mesma vaga nos dois casos.")
g.box(280, 20, 160, 34, stroke="wire")
g.text(360, 37, "Pair", mono=True, size=12, fill="paper", weight="600")
g.box(110, 100, 180, 44, stroke="phosphor")
g.text(200, 114, "Text", mono=True, size=11, fill="phosphor", weight="600")
g.text(200, 132, "the title, always here", "o título, sempre aqui", size=10, fill="paper-dim")
g.box(430, 100, 160, 34, stroke="amber")
g.text(510, 117, "Either", mono=True, size=11, fill="amber", weight="600")
g.line(330, 54, 220, 98, color="wire")
g.line(390, 54, 490, 98, color="wire")
g.box(340, 180, 160, 50, stroke="wire")
g.text(420, 196, ".first: Image", mono=True, size=10, fill="paper")
g.text(420, 216, "when done is true", "quando done é verdadeiro", size=10, fill="paper-dim")
g.box(530, 180, 170, 50, stroke="wire")
g.text(615, 196, ".second: Text", mono=True, size=10, fill="paper")
g.text(615, 216, "when done is false", "quando done é falso", size=10, fill="paper-dim")
g.line(490, 134, 430, 178, color="amber")
g.line(530, 134, 600, 178, color="amber")
g.write(lesson(L, "conditional-views"),
        "Both values have this one type. Flipping done moves the second slot from one branch to the other, and the view in it is a different view.",
        "Os dois valores têm este tipo único. Virar done leva a segunda vaga de um ramo para o outro, e a view ali é outra view.")
