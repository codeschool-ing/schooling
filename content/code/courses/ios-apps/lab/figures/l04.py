"""Lesson 4 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-6va6ty5a"

f = Fig("l04-steps", 720, 240,
        "Three steps between a parent and a child. Step 1, the parent proposes a size: 360 wide. Step 2, the child chooses its size, 104 wide, and reports it. Step 3, the parent places the child at a position in its own space. The child's chosen width is kept; the parent decides only where it goes.",
        "Três passos entre um pai e um filho. Passo 1, o pai propõe um tamanho: 360 de largura. Passo 2, o filho escolhe o seu tamanho, 104 de largura, e o informa. Passo 3, o pai posiciona o filho num ponto do seu próprio espaço. A largura escolhida pelo filho é mantida; o pai decide só onde ele fica.")
f.box(30, 30, 180, 50, stroke="phosphor")
f.text(120, 48, "parent", "pai", size=11, fill="phosphor", weight="600")
f.text(120, 66, "HStack", mono=True, size=10, fill="paper-dim")
f.box(510, 30, 180, 50, stroke="amber")
f.text(600, 48, "child", "filho", size=11, fill="amber", weight="600")
f.text(600, 66, "Text", mono=True, size=10, fill="paper-dim")
f.line(212, 44, 506, 44, color="phosphor")
f.text(360, 34, "1  proposes: 360 wide", "1  propõe: 360 de largura", size=11, fill="phosphor")
f.line(506, 70, 214, 70, color="amber")
f.text(360, 90, "2  chooses and reports: 104 wide", "2  escolhe e informa: 104 de largura", size=11, fill="amber")
f.box(30, 130, 660, 80, stroke="wire", fill="ink")
f.text(360, 146, "3  the parent places the child; the width stays 104", "3  o pai posiciona o filho; a largura continua 104", size=11, fill="paper")
f.box(50, 162, 104, 34, stroke="amber")
f.text(102, 179, "SQL Databases", mono=True, size=9, fill="paper")
f.text(420, 180, "the rest of the 360 is the parent's to share out", "o resto dos 360 é do pai para repartir", size=10, fill="paper-dim")
f.write(lesson(L, "propose-and-report"),
        "The parent offers, the child decides, and the parent only chooses where the child goes.",
        "O pai oferece, o filho decide, e o pai só escolhe onde o filho fica.")
