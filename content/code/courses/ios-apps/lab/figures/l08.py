"""Lesson 8 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-mydx2e68"
f = Fig("l08-identity", 720, 290,
        "Two columns of rows. Before: position 0 is s1, SQL joins; position 1 is s2, Mobile lifecycle, with its notes open; position 2 is s3, SQL indexes. After deleting the first row: position 0 is s2 and position 1 is s3. Solid arrows join each row by id to the same row after the delete, so the open notes stay on s2. A dashed arrow follows position 1 instead, and lands on s3, a row the person never opened.",
        "Duas colunas de linhas. Antes: a posição 0 é s1, SQL joins; a posição 1 é s2, Mobile lifecycle, com as notas abertas; a posição 2 é s3, SQL indexes. Depois de apagar a primeira linha: a posição 0 é s2 e a posição 1 é s3. Setas cheias ligam cada linha pelo id à mesma linha depois de apagar, então as notas abertas ficam em s2. Uma seta tracejada segue a posição 1 em vez disso, e cai em s3, uma linha que a pessoa nunca abriu.")
f.text(140, 22, "before", "antes", size=12, fill="paper", weight="600")
f.text(560, 22, "after the first row is deleted", "depois de apagar a primeira linha", size=12, fill="paper", weight="600")
rows_b = [("0", "s1", "SQL, joins", False), ("1", "s2", "Mobile, lifecycle", True), ("2", "s3", "SQL, indexes", False)]
for i, (pos, sid, title, open_) in enumerate(rows_b):
    y = 44 + i * 70
    f.box(40, y, 220, 50, stroke="amber" if open_ else "wire")
    f.text(56, y + 25, pos, mono=True, size=11, fill="paper-dim", anchor="start")
    f.text(150, y + 18, sid, mono=True, size=11, fill="paper", weight="600")
    f.text(150, y + 36, title, mono=True, size=10, fill="paper-dim")
rows_a = [("0", "s2", "Mobile, lifecycle", True), ("1", "s3", "SQL, indexes", False)]
for i, (pos, sid, title, open_) in enumerate(rows_a):
    y = 44 + i * 70
    f.box(460, y, 220, 50, stroke="amber" if open_ else "wire")
    f.text(476, y + 25, pos, mono=True, size=11, fill="paper-dim", anchor="start")
    f.text(570, y + 18, sid, mono=True, size=11, fill="paper", weight="600")
    f.text(570, y + 36, title, mono=True, size=10, fill="paper-dim")
f.line(260, 139, 456, 69, color="phosphor")
f.line(260, 209, 456, 139, color="phosphor")
f.path("M260 150 C 340 150, 380 150, 456 150", color="amber", dashed=True)
f.text(360, 88, "by id", "pelo id", size=10, fill="phosphor")
f.text(360, 166, "by position 1", "pela posição 1", size=10, fill="amber")
f.box(40, 252, 14, 14, stroke="amber", fill="panel")
f.text(62, 259, "notes open", "notas abertas", size=10, fill="paper-dim", anchor="start")
f.write(lesson(L, "ids-not-indices"),
        "Kept by id, the open notes stay with the session the person opened. Kept by position, they stay at position 1, and position 1 is now a different session.",
        "Guardadas pelo id, as notas abertas ficam com a sessão que a pessoa abriu. Guardadas pela posição, ficam na posição 1, e a posição 1 agora é outra sessão.")
