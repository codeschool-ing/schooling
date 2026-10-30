"""Lesson 11: one history, a cursor per device."""
from fig import Fig

T = {
    "en": dict(
        aria="The server's history of writes as a row of numbered boxes: 1 s1, 2 s2, and so on to 2006 h2000, then 2007 s7. Phone A's cursor sits after 2006, so asking for changes after 2006 returns one row, s7, and the new cursor 2007. Phone B's cursor sits after 6, so the same question from B returns 2001 rows. One history serves both, each from its own place.",
        hist="the server's history: every write, numbered in the order it arrived",
        a="phone A: cursor 2006", b="phone B: cursor 6",
        ra="after=2006 → 1 row, cursor 2007", rb="after=6 → 2001 rows, cursor 2007",
        cap="The device keeps its place in one history the server writes. The cost of a pull follows how far it has to read, not how much there is.",
    ),
    "pt": dict(
        aria="O histórico de escritas do servidor como uma fileira de caixas numeradas: 1 s1, 2 s2, e assim por diante até 2006 h2000, depois 2007 s7. O cursor do celular A fica depois de 2006, então pedir as mudanças depois de 2006 devolve uma linha, s7, e o cursor novo 2007. O cursor do celular B fica depois de 6, então a mesma pergunta feita por B devolve 2001 linhas. Um histórico serve os dois, cada um a partir do próprio lugar.",
        hist="o histórico do servidor: toda escrita, numerada na ordem em que chegou",
        a="celular A: cursor 2006", b="celular B: cursor 6",
        ra="after=2006 → 1 linha, cursor 2007", rb="after=6 → 2001 linhas, cursor 2007",
        cap="O aparelho guarda o seu lugar num histórico que o servidor escreve. O custo de uma busca acompanha o quanto ela precisa ler, não o quanto existe.",
    ),
}

BOXES = [("1", "s1"), ("2", "s2"), ("…", ""), ("6", "s6"), ("7", "h1"), ("…", ""), ("2006", "h2000"), ("2007", "s7")]


def figures(lang):
    t = T[lang]
    f = Fig("l11-cursor", 720, 230, t["aria"])
    f.text(20, 22, t["hist"], anchor="start", bold=True, size=10.5, fill="phosphor")
    x = 20
    pos = {}
    for n, (num, sid) in enumerate(BOXES):
        w = 40 if num == "…" else 76
        f.box(x, 40, w, 44, [num, sid] if sid else [num], stroke="phosphor" if num == "2007" else "wire", mono=True, size=9.5)
        pos[num] = (x, w)
        x += w + 8
    xa = pos["2007"][0] - 4
    xb = pos["7"][0] - 4
    f.arrow([(xa, 34), (xa, 128)], head=False, color="amber", width=2)
    f.text(xa, 142, t["a"], size=9.5, fill="amber")
    f.text(xa, 160, t["ra"], size=9.5, fill="paper-dim", italic=True)
    f.arrow([(xb, 34), (xb, 178)], head=False, color="phosphor", width=2)
    f.text(xb + 6, 192, t["b"], anchor="start", size=9.5, fill="phosphor")
    f.text(xb + 6, 210, t["rb"], anchor="start", size=9.5, fill="paper-dim", italic=True)
    return {"l11-cursor": f.json(t["cap"])}
