"""Lesson 15: a grow-only counter merged, and the module that holds it."""
import pathlib
from fig import Fig

SRC = (pathlib.Path(__file__).parent / "l15-crdt.ts").read_text().rstrip("\n").split("\n")


def chunk(a, b):
    return "\n".join(SRC[a - 1:b])


T = {
    "en": dict(
        aria="A grow-only counter of minutes studied. Both devices last synced phone 60 and tablet 40, a total of 100. Offline, the phone adds 30: its copy reads phone 90, tablet 40, total 130. The tablet adds 45: its copy reads phone 60, tablet 85, total 145. The merge keeps the larger count for each device: phone 90, tablet 85, total 175, whichever copy is merged into which.",
        synced="as both last synced", phone="the phone adds 30", tablet="the tablet adds 45",
        merged="merged: the larger count per device", total="total",
        cap="Each device only ever writes its own entry, so the merge has nothing to choose between: it keeps the larger count for each device, and the total is their sum.",
    ),
    "pt": dict(
        aria="Um contador só de crescimento de minutos estudados. Os dois aparelhos sincronizaram por último phone 60 e tablet 40, um total de 100. Offline, o celular soma 30: a cópia dele mostra phone 90, tablet 40, total 130. O tablet soma 45: a cópia dele mostra phone 60, tablet 85, total 145. A mescla guarda a maior contagem de cada aparelho: phone 90, tablet 85, total 175, qualquer que seja a cópia mesclada em qual.",
        synced="como os dois sincronizaram", phone="o celular soma 30", tablet="o tablet soma 45",
        merged="mesclado: a maior contagem por aparelho", total="total",
        cap="Cada aparelho só escreve a própria entrada, então a mescla não tem entre o que escolher: guarda a maior contagem de cada aparelho, e o total é a soma delas.",
    ),
}


def counter(f, x, y, title, p, t, tot, stroke, tl):
    f.text(x + 85, y - 12, title, size=9.5, italic=True, fill="paper-dim")
    f.rect(x, y, 170, 74, stroke=stroke, fill="panel")
    f.text(x + 14, y + 18, "phone", anchor="start", mono=True, size=10)
    f.text(x + 156, y + 18, str(p), anchor="end", mono=True, size=10)
    f.text(x + 14, y + 38, "tablet", anchor="start", mono=True, size=10)
    f.text(x + 156, y + 38, str(t), anchor="end", mono=True, size=10)
    f.text(x + 14, y + 60, tl, anchor="start", size=10, bold=True, fill="phosphor")
    f.text(x + 156, y + 60, str(tot), anchor="end", mono=True, size=10, bold=True, fill="phosphor")


def figures(lang):
    t = T[lang]
    f = Fig("l15-counter", 720, 250, t["aria"])
    counter(f, 20, 100, t["synced"], 60, 40, 100, "wire", t["total"])
    counter(f, 270, 30, t["phone"], 90, 40, 130, "amber", t["total"])
    counter(f, 270, 160, t["tablet"], 60, 85, 145, "amber", t["total"])
    counter(f, 530, 100, t["merged"], 90, 85, 175, "phosphor", t["total"])
    f.arrow([(190, 125), (270, 70)])
    f.arrow([(190, 150), (270, 200)])
    f.arrow([(440, 70), (530, 125)], color="phosphor")
    f.arrow([(440, 200), (530, 150)], color="phosphor")
    same = None if lang == "en" else ["total"]
    return {"l15-counter": f.json(t["cap"], same=same)}


EXAMPLES = {"counters-and-sets": [{
    "language": "typescript", "file": "crdt.ts",
    "parts": [
        (chunk(1, 2), None, None),
        (chunk(3, 6),
         "A grow-only counter is one count per device. `add` raises only the writing device's entry, and the total is the sum of them all.",
         "Um contador só de crescimento é uma contagem por aparelho. O `add` aumenta só a entrada do aparelho que escreve, e o total é a soma de todas."),
        (chunk(7, 12),
         "The merge keeps the larger count for each device. Taking a maximum is commutative, associative and idempotent, which is the whole guarantee.",
         "A mescla guarda a maior contagem de cada aparelho. Tirar um máximo é comutativo, associativo e idempotente, que é a garantia inteira."),
        (chunk(13, 21),
         "The observed-remove set. Each add records a tag beside the value; a remove marks as removed only the tags this copy holds, which are the adds it has seen.",
         "O conjunto com remoção observada. Cada adição registra uma etiqueta ao lado do valor; uma remoção marca como removidas só as etiquetas que esta cópia tem, que são as adições que ela viu."),
        (chunk(22, 24),
         "A value is in the set while at least one of its tags has not been removed.",
         "Um valor está no conjunto enquanto pelo menos uma das etiquetas dele não foi removida."),
        (chunk(25, 31),
         "The merge is a union of the adds and a union of the removes. Unions are commutative, associative and idempotent too, and `sort` keeps the stored order the same whatever came first.",
         "A mescla é uma união das adições e uma união das remoções. Uniões também são comutativas, associativas e idempotentes, e o `sort` mantém a ordem guardada igual, o que quer que tenha vindo primeiro."),
    ],
}]}
