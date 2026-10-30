"""Lesson 16: four runs of a sync that can stop at any step."""
import re
from fig import Fig

T = {
    "en": dict(
        aria="Four runs of the sync, one row each, every box a step. Run 1, four steps: send k1, k2, k3, k4, then time is up. Run 2, three steps: send k5; during the second step k6 reaches the server and the process is killed before the outbox marks it sent. Run 3: send k6 again, which the server ignores, then pull c1 and c2, c3 and c4, c5, and find nothing left. Run 4: nothing left to do, in one step. A checkpoint follows every completed step.",
        runs=["run 1", "run 2", "run 3", "run 4"],
        up="time is up", killed="killed", ignored="k6, ignored", nothing="nothing left",
        legend="every completed step is saved before the next begins",
        cap="Being stopped costs at most one step: the one in flight when the kill came, sent again and ignored by the server's idempotency key.",
    ),
    "pt": dict(
        aria="Quatro execuções da sincronização, uma por linha, cada caixa um passo. Execução 1, quatro passos: manda k1, k2, k3, k4, e o tempo acaba. Execução 2, três passos: manda k5; durante o segundo passo k6 chega ao servidor e o processo é morto antes de a caixa de saída marcá-lo como enviado. Execução 3: manda k6 de novo, que o servidor ignora, depois puxa c1 e c2, c3 e c4, c5, e não acha mais nada. Execução 4: nada a fazer, em um passo. Um ponto de salvamento segue cada passo concluído.",
        runs=["execução 1", "execução 2", "execução 3", "execução 4"],
        up="tempo acabou", killed="morto", ignored="k6, ignorado", nothing="nada a fazer",
        legend="cada passo concluído é salvo antes de o próximo começar",
        cap="Ser parado custa no máximo um passo: o que estava em andamento quando veio a morte, mandado de novo e ignorado pela chave de idempotência do servidor.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l16-runs", 720, 230, t["aria"])
    rows = [
        [("k1", "wire"), ("k2", "wire"), ("k3", "wire"), ("k4", "wire"), (t["up"], "end")],
        [("k5", "wire"), ("k6", "kill"), (t["killed"], "x")],
        [(t["ignored"], "amber"), ("c1, c2", "phosphor"), ("c3, c4", "phosphor"), ("c5", "phosphor"), (t["nothing"], "wire")],
        [(t["nothing"], "wire")],
    ]
    for i, row in enumerate(rows):
        y = 20 + i * 44
        f.text(20, y + 15, t["runs"][i], anchor="start", bold=True, size=10)
        x = 110
        for label, kind in row:
            if kind == "end":
                f.text(x + 4, y + 15, label, anchor="start", size=9.5, italic=True, fill="paper-dim")
                continue
            if kind == "x":
                f.text(x + 4, y + 15, label, anchor="start", size=9.5, bold=True, fill="amber")
                continue
            w = 96
            stroke = {"kill": "amber", "amber": "amber", "phosphor": "phosphor"}.get(kind, "wire")
            f.box(x, y, w, 30, [label], stroke=stroke, dashed=(kind == "kill"), mono=bool(re.fullmatch(r"[kc]\d(, [kc]\d)?", label)), size=9.5)
            x += w + 14
    f.text(110, 208, t["legend"], anchor="start", size=9.5, italic=True, fill="paper-dim")
    return {"l16-runs": f.json(t["cap"])}
