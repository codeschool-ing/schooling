"""Lesson 7: what an origin is made of."""
from fig import Fig

T = {
    "en": dict(
        aria="The address http://localhost:5173/api/plan?week=43 split into its parts. The scheme http, the host localhost and the port 5173 are bracketed together as the origin. The path /api/plan and the query ?week=43 are outside the bracket: they do not change the origin. Below, the API's address http://localhost:3000 has the same scheme and host and a different port, so it is a different origin.",
        scheme="scheme", host="host", port="port", path="path", query="query",
        origin="the origin: all three must match",
        rest="not part of the origin",
        other="another origin: only the port differs",
        cap="Two addresses on one computer, and two origins. The browser compares the three parts as written, so a port, a scheme or a spelling of the host makes a stranger.",
    ),
    "pt": dict(
        aria="O endereço http://localhost:5173/api/plan?week=43 dividido nas suas partes. O esquema http, o host localhost e a porta 5173 estão agrupados como a origem. O caminho /api/plan e a consulta ?week=43 ficam fora do grupo: eles não mudam a origem. Embaixo, o endereço da API, http://localhost:3000, tem o mesmo esquema e o mesmo host e outra porta, então é outra origem.",
        scheme="esquema", host="host", port="porta", path="caminho", query="consulta",
        origin="a origem: as três precisam bater",
        rest="não fazem parte da origem",
        other="outra origem: só a porta difere",
        cap="Dois endereços num computador, e duas origens. O navegador compara as três partes como estão escritas, então uma porta, um esquema ou uma grafia do host fazem um estranho.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l07-origin", 720, 190, t["aria"])
    parts = [("http://", 60, "phosphor", t["scheme"]), ("localhost", 90, "phosphor", t["host"]),
             (":5173", 60, "phosphor", t["port"]), ("/api/plan", 100, "wire", t["path"]),
             ("?week=43", 90, "wire", t["query"])]
    x = 60
    spans = []
    for text, w, stroke, label in parts:
        f.box(x, 50, w, 34, [text], mono=True, stroke=stroke, size=10)
        f.text(x + w / 2, 100, label, size=9, fill="paper-dim")
        spans.append((x, w))
        x += w + 6
    left, right = spans[0][0], spans[2][0] + spans[2][1]
    f.arrow([(left, 38), (left, 30), (right, 30), (right, 38)], head=False, color="amber")
    f.text((left + right) / 2, 20, t["origin"], size=9.5, fill="amber", bold=True)
    l2, r2 = spans[3][0], spans[4][0] + spans[4][1]
    f.text((l2 + r2) / 2, 30, t["rest"], size=9, fill="paper-dim", italic=True)
    y = 140
    x = 60
    for text, w, stroke in (("http://", 60, "phosphor"), ("localhost", 90, "phosphor"), (":3000", 60, "amber")):
        f.box(x, y, w, 34, [text], mono=True, stroke=stroke, size=10)
        x += w + 6
    f.text(x + 10, y + 17, t["other"], anchor="start", size=9.5, fill="amber")
    return {"l07-origin": f.json(t["cap"], same=["host"] if lang == "pt" else None)}
