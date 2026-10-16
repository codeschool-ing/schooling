"""Lesson 4: ndarray, dtype and memory."""
from draw import Fig

strides = Fig(
    "strides", 720, 270,
    ("Top: the array hours as a table of 4 rows and 6 columns, 0 to 23. Bottom: the same 24 numbers "
     "as one flat block of memory, row after row, 8 bytes each. One step along a row moves 8 bytes; "
     "one step down a column moves 48 bytes, a whole row.",
     "Em cima: o array hours como uma tabela de 4 linhas e 6 colunas, de 0 a 23. Embaixo: os mesmos "
     "24 números como um bloco plano de memória, linha após linha, 8 bytes cada. Um passo ao longo da "
     "linha anda 8 bytes; um passo coluna abaixo anda 48 bytes, uma linha inteira."),
    ("Strides (48, 8): the shape is a way of reading a flat block.",
     "Strides (48, 8): o formato é um jeito de ler um bloco plano."))
f = strides
f.text(20, 18, "hours, shape (4, 6)", "hours, formato (4, 6)", anchor="start", weight="600")
for r in range(4):
    for c in range(6):
        x, y = 20 + c * 40, 32 + r * 30
        f.rect(x, y, 40, 30, fill="panel", stroke="wire", rx=0, width=1)
        f.text(x + 20, y + 15, str(r * 6 + c), mono=True, size=11)
f.line(30, 160, 100, 160, arrow=True, stroke="amber")
f.text(110, 160, "+8 bytes", mono=True, size=10, fill="amber", anchor="start")
f.line(290, 47, 290, 120, arrow=True, stroke="amber")
f.text(300, 84, "+48 bytes", mono=True, size=10, fill="amber", anchor="start")
f.text(400, 60, "a table is only a way", "uma tabela é só um jeito", anchor="start", size=11, fill="paper-dim")
f.text(400, 78, "of reading the block below", "de ler o bloco abaixo", anchor="start", size=11, fill="paper-dim")
f.text(20, 192, "the same bytes in memory", "os mesmos bytes na memória", anchor="start", weight="600")
for i in range(24):
    x = 20 + i * 28
    f.rect(x, 206, 28, 26, fill="scan" if (i // 6) % 2 else "panel", stroke="wire", rx=0, width=1)
    f.text(x + 14, 219, str(i), mono=True, size=10)
for r in range(4):
    f.text(20 + r * 168 + 84, 248, f"row {r}", f"linha {r}", size=10, fill="paper-dim")

FIGURES = [strides]
