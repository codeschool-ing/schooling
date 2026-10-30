"""Lesson 16 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-jfpa995y"
f = Fig("l16-runs", 720, 300,
        "Three background runs drawn as rows on a time line, each one second long. In each, two posts of 400 milliseconds complete, each followed by a save, and a third post starts and is cut off when the second ends and the task is cancelled. Beside each row, the sessions waiting: six before the first run, four after it, two after the second, none after the third. Between the rows, the note that on a phone the runs may be hours apart.",
        "Três execuções em segundo plano desenhadas como linhas numa linha do tempo, cada uma de um segundo. Em cada uma, dois envios de 400 milissegundos terminam, cada um seguido de um salvamento, e um terceiro envio começa e é cortado quando o segundo acaba e a tarefa é cancelada. Ao lado de cada linha, as sessões esperando: seis antes da primeira execução, quatro depois dela, duas depois da segunda, nenhuma depois da terceira. Entre as linhas, a nota de que num telefone as execuções podem estar a horas de distância.")
x0, sec = 120, 480                               # one second is 480 units wide
f.text(x0, 22, "0 s", mono=True, size=10, fill="paper-dim")
f.text(x0 + sec, 22, "1.0 s", mono=True, size=10, fill="paper-dim")
f.text(670, 22, "waiting", "esperando", size=10, fill="paper-dim")
for r, (before, after, names) in enumerate([(6, 4, ("b1", "b2", "b3")), (4, 2, ("b3", "b4", "b5")), (2, 0, ("b5", "b6", None))]):
    y = 48 + r * 82
    f.text(60, y + 16, f"run {r + 1}", f"execução {r + 1}", size=11, fill="paper")
    for i in range(2):
        bx = x0 + i * 0.4 * sec
        f.box(bx, y, 0.4 * sec - 6, 32, stroke="phosphor")
        f.text(bx + (0.4 * sec - 6) / 2, y + 16, f"post {names[i]}, saved", f"envio {names[i]}, salvo", size=10, fill="phosphor")
    bx = x0 + 0.8 * sec
    if names[2]:
        f.box(bx, y, 0.2 * sec, 32, stroke="amber", dashed=True)
        f.text(bx + 0.1 * sec, y + 16, names[2], mono=True, size=10, fill="amber")
    f.line(x0 + sec, y - 6, x0 + sec, y + 38, color="amber", arrow=False, sw=1.6)
    f.text(670, y + 16, f"{before} → {after}", mono=True, size=11, fill="paper")
    if r < 2:
        f.text(x0 + sec / 2, y + 56, "on a phone, perhaps hours later", "num telefone, talvez horas depois", size=10, fill="paper-dim")
f.text(x0 + sec, 284, "cancelled", "cancelada", size=10, fill="amber")
f.write(lesson(L, "expiration"),
        "Every success is saved the moment it happens, so wherever the cancellation falls, the cut post stays waiting and goes first next time.",
        "Todo sucesso é salvo no momento em que acontece, então onde quer que o cancelamento caia, o envio cortado continua esperando e vai primeiro da próxima vez.")
