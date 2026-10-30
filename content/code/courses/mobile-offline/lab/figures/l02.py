"""Lesson 2: the torn write, in place and by rename."""
from fig import Fig

T = {
    "en": dict(
        aria="Two ways to save settings, each in three moments. Written in place: before, torn.json holds the old settings; the process is killed halfway, and torn.json holds 31 of 62 bytes; the next launch cannot parse it. Written beside it and renamed: before, torn.json holds the old settings; killed halfway, torn.json.tmp holds 31 bytes and torn.json is untouched; the next launch reads the old settings, whole.",
        c1="before the save", c2="killed halfway", c3="the next launch",
        r1="in place", r2="beside it, then renamed",
        old="old settings, whole", half="31 of 62 bytes", untouched="old settings, untouched",
        fail="cannot be parsed", ok="reads the old settings",
        cap="Opening a file for writing empties it. Written in place, a kill leaves the only copy half written; written beside it, a kill leaves a file nothing reads.",
    ),
    "pt": dict(
        aria="Dois jeitos de salvar configurações, cada um em três momentos. Gravado no lugar: antes, torn.json guarda as configurações antigas; o processo é morto no meio, e torn.json guarda 31 de 62 bytes; a próxima abertura não consegue interpretá-lo. Gravado ao lado e renomeado: antes, torn.json guarda as configurações antigas; morto no meio, torn.json.tmp guarda 31 bytes e torn.json está intacto; a próxima abertura lê as configurações antigas, inteiras.",
        c1="antes de salvar", c2="morto no meio", c3="a próxima abertura",
        r1="no lugar", r2="ao lado, depois renomeado",
        old="configurações antigas", half="31 de 62 bytes", untouched="antigas, intactas",
        fail="não se interpreta", ok="lê as antigas",
        cap="Abrir um arquivo para gravar o esvazia. Gravado no lugar, uma morte deixa a única cópia pela metade; gravado ao lado, deixa um arquivo que ninguém lê.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l02-torn", 720, 280, t["aria"])
    xs = [170, 350, 530]
    for x, c in zip(xs, [t["c1"], t["c2"], t["c3"]]):
        f.text(x + 80, 24, c, size=10, bold=True, fill="paper-dim")
    # row 1: in place
    f.text(20, 82, t["r1"], anchor="start", bold=True, size=10.5, fill="amber")
    f.box(xs[0], 52, 160, 60, ["torn.json", t["old"]], stroke="wire", size=9.5)
    f.box(xs[1], 52, 160, 60, ["torn.json", t["half"]], stroke="amber", size=9.5, dashed=True)
    f.box(xs[2], 52, 160, 60, [t["fail"]], stroke="amber", size=10, fill="amber")
    # row 2: rename
    f.text(20, 192, t["r2"], anchor="start", bold=True, size=10.5, fill="phosphor")
    f.box(xs[0], 162, 160, 60, ["torn.json", t["old"]], stroke="wire", size=9.5)
    f.box(xs[1], 146, 160, 40, ["torn.json.tmp", t["half"]], stroke="wire", size=9, dashed=True)
    f.box(xs[1], 196, 160, 40, ["torn.json", t["untouched"]], stroke="phosphor", size=9)
    f.box(xs[2], 162, 160, 60, [t["ok"]], stroke="phosphor", size=10, fill="phosphor")
    for y in (82, 192):
        f.arrow([(330, y), (350, y)])
        f.arrow([(510, y), (530, y)])
    same = None if lang == "en" else ["torn.json", "torn.json.tmp"]
    return {"l02-torn": f.json(t["cap"], same=same)}
