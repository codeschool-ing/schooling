"""Lesson 8: one drain past a poison operation."""
from fig import Fig

T = {
    "en": dict(
        aria="The outbox holds three operations in order: number 9, create s11 at 300 minutes; number 10, update s11 to 200 minutes; number 11, create s12. The drain sends number 9 and the server answers 422, so it moves to the dead table. Number 10 is held, because it updates a session the server never created. Number 11 belongs to another session and is sent, and the server answers 201.",
        title="the outbox, oldest first", server="the server", dead="dead",
        r9="422: moved to dead", r10="held: same session", r11="201: sent",
        cap="A refused operation leaves the queue so the rest can pass, and the operations on the same row wait behind it.",
    ),
    "pt": dict(
        aria="A caixa de saída guarda três operações em ordem: a número 9, create s11 com 300 minutos; a número 10, update s11 para 200 minutos; a número 11, create s12. A drenagem envia a número 9 e o servidor responde 422, então ela vai para a tabela dead. A número 10 fica retida, porque atualiza uma sessão que o servidor nunca criou. A número 11 é de outra sessão e é enviada, e o servidor responde 201.",
        title="a caixa de saída, da mais antiga", server="o servidor", dead="dead",
        r9="422: vai para dead", r10="retida: mesma sessão", r11="201: enviada",
        cap="Uma operação recusada sai da fila para as outras passarem, e as operações da mesma linha esperam atrás dela.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l08-poison", 720, 250, t["aria"])
    f.text(20, 22, t["title"], anchor="start", bold=True, size=10.5, fill="phosphor")
    ops = [("#9  create s11  300 min", "amber", t["r9"]), ("#10 update s11  200 min", "wire", t["r10"]),
           ("#11 create s12   30 min", "phosphor", t["r11"])]
    for n, (label, stroke, result) in enumerate(ops):
        y = 40 + n * 62
        f.box(20, y, 220, 40, [label], stroke=stroke, mono=True, anchor="start", dashed=(n == 1))
        f.text(270, y + (20 if n == 1 else 10), result, anchor="start", size=10, fill="amber" if n == 0 else ("paper-dim" if n == 1 else "phosphor"),
               italic=(n == 1))
    f.box(560, 162, 140, 40, [t["server"]], stroke="phosphor")
    f.arrow([(240, 192), (556, 192)], color="phosphor")
    f.box(560, 38, 140, 44, [t["dead"]], stroke="amber", mono=True)
    f.arrow([(240, 68), (556, 68)], color="amber")
    return {"l08-poison": f.json(t["cap"], same=None)}
