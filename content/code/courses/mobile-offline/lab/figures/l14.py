"""Lesson 14: a three-way merge, field by field, and the sync that uses it."""
import pathlib
from fig import Fig

SRC = (pathlib.Path(__file__).parent / "l14-sync.ts").read_text().rstrip("\n").split("\n")


def chunk(a, b):
    return "\n".join(SRC[a - 1:b])


T = {
    "en": dict(
        aria="A three-way merge of session s3, field by field. Columns: base, the version both devices started from; the phone's copy; the tablet's copy; the merge. minutes: base 20, phone 30, tablet 20, merged 30, taken from the phone. done: base false, phone false, tablet true, merged true, taken from the tablet. course: guitar on all three, kept. Below, the other case: minutes base 20, phone 30, tablet 25: both changed it, so it is a conflict and both values are kept for the person.",
        h=["base", "phone", "tablet", "merged"],
        n1="only the phone changed it", n2="only the tablet changed it", n3="nobody changed it",
        other="the other case: the same field on both sides",
        conflict="conflict: keep both", n4="both changed it, differently",
        cap="A field still at its base value is a field that side did not touch. Only a field both sides changed, to different values, is a real conflict.",
    ),
    "pt": dict(
        aria="Uma mescla de três vias da sessão s3, campo a campo. Colunas: base, a versão de que os dois aparelhos partiram; a cópia do celular; a cópia do tablet; a mescla. minutes: base 20, celular 30, tablet 20, mescla 30, tirado do celular. done: base false, celular false, tablet true, mescla true, tirado do tablet. course: guitar nos três, mantido. Embaixo, o outro caso: minutes base 20, celular 30, tablet 25: os dois mudaram, então é um conflito e os dois valores ficam guardados para a pessoa.",
        h=["base", "celular", "tablet", "mescla"],
        n1="só o celular mudou", n2="só o tablet mudou", n3="ninguém mudou",
        other="o outro caso: o mesmo campo dos dois lados",
        conflict="conflito: guardar os dois", n4="os dois mudaram, diferente",
        cap="Um campo ainda no valor da base é um campo que aquele lado não mexeu. Só um campo que os dois lados mudaram, para valores diferentes, é um conflito de verdade.",
    ),
}

ROWS = [("minutes", "20", "30", "20", "30", 1, "n1"), ("done", "false", "false", "true", "true", 2, "n2"),
        ("course", "guitar", "guitar", "guitar", "guitar", 0, "n3")]


def figures(lang):
    t = T[lang]
    f = Fig("l14-merge", 720, 250, t["aria"])
    xs = [110, 210, 310, 410]
    for x, h in zip(xs, t["h"]):
        f.text(x + 40, 26, h, bold=True, size=10, fill="phosphor" if h in ("merged", "mescla") else "paper")
    for i, (field, *vals, src, note) in enumerate(ROWS):
        y = 42 + i * 40
        f.text(20, y + 15, field, anchor="start", mono=True, size=10)
        for j, (x, v) in enumerate(zip(xs, vals)):
            changed = (j == src) or (j == 3 and src)
            f.box(x, y, 80, 30, [v], mono=True, size=10,
                  stroke="amber" if j == src and src else ("phosphor" if j == 3 else "wire"))
        f.text(505, y + 15, t[note], anchor="start", size=9.5, italic=True, fill="paper-dim")
    f.text(20, 186, t["other"], anchor="start", bold=True, size=10, fill="amber")
    y = 204
    f.text(20, y + 15, "minutes", anchor="start", mono=True, size=10)
    for x, v, s in zip(xs[:3], ["20", "30", "25"], ["wire", "amber", "amber"]):
        f.box(x, y, 80, 30, [v], mono=True, size=10, stroke=s)
    f.box(xs[3], y, 180, 30, [t["conflict"]], size=9.5, stroke="amber", dashed=True)
    f.text(xs[3] + 190, y + 15, t["n4"], anchor="start", size=9.5, italic=True, fill="paper-dim")
    same = None if lang == "en" else ["base", "tablet"]
    return {"l14-merge": f.json(t["cap"], same=same)}


EXAMPLES = {"field-by-field": [{
    "language": "typescript", "file": "sync.ts",
    "parts": [
        (chunk(1, 6),
         "The fields that make up a session, and a helper that keeps only those from a row the server sent, which also carries `id` and `version`.",
         "Os campos que formam uma sessão, e uma função que guarda só eles de uma linha que o servidor mandou, que também traz `id` e `version`."),
        (chunk(7, 15),
         "The two copies the device keeps: `base`, as the server last sent it at version 1, and `mine`, the person's edit on top of it. The arguments say what was edited, as `minutes=30`.",
         "As duas cópias que o aparelho guarda: `base`, como o servidor mandou da última vez na versão 1, e `mine`, a edição da pessoa por cima dela. Os argumentos dizem o que foi editado, como `minutes=30`."),
        (chunk(16, 26),
         "Send the edit with the version it was made from. A 200 means nobody wrote in between, and the reply is the saved row.",
         "Manda a edição com a versão de que ela partiu. Um 200 quer dizer que ninguém escreveu no meio, e a resposta é a linha salva."),
        (chunk(27, 34),
         "A 409 carries the server's current row. Merge it against the base; if a field changed on both sides, stop and keep both copies.",
         "Um 409 traz a linha atual do servidor. Mescla contra a base; se um campo mudou dos dois lados, para e guarda as duas cópias."),
        (chunk(35, 37),
         "Otherwise the merge becomes the new edit, the server's row becomes the new base, and the next attempt names the server's version.",
         "Se não, a mescla vira a nova edição, a linha do servidor vira a nova base, e a próxima tentativa cita a versão do servidor."),
    ],
}]}
