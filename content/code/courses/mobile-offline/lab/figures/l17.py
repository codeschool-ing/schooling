"""Lesson 17: the life of a cached copy, after one download."""
from fig import Fig

T = {
    "en": dict(
        aria="A timeline of one cached copy, downloaded at second 0 with max-age=60 and stale-while-revalidate=300. From 0 to 60 the copy is fresh: it is shown and nothing is asked. From 60 to 360 it is stale: it is shown at once and checked in the background with If-None-Match. After 360 it is too old to show: the screen waits for the network, and a 304 costs no body. The client's runs at seconds 30 and 45 fall in the fresh band, 90 in the stale band.",
        fresh="fresh", fresh2="shown, nothing asked",
        stale="stale while revalidating", stale2="shown at once, checked behind it",
        old="too old", old2="the screen waits",
        t="seconds since the copy was downloaded",
        runs="runs of fetch.ts",
        cap="One download, three ways to answer the next read. Each 200 or 304 starts the timeline again from zero.",
    ),
    "pt": dict(
        aria="Uma linha do tempo de uma cópia em cache, baixada no segundo 0 com max-age=60 e stale-while-revalidate=300. De 0 a 60 a cópia está fresca: é mostrada e nada é perguntado. De 60 a 360 está velha: é mostrada na hora e conferida por trás com If-None-Match. Depois de 360 está velha demais para mostrar: a tela espera a rede, e um 304 não custa corpo. As execuções do cliente nos segundos 30 e 45 caem na faixa fresca, a de 90 na faixa velha.",
        fresh="fresca", fresh2="mostrada, nada perguntado",
        stale="velha, sendo revalidada", stale2="mostrada na hora, conferida por trás",
        old="velha demais", old2="a tela espera",
        t="segundos desde que a cópia foi baixada",
        runs="execuções do fetch.ts",
        cap="Um download, três jeitos de responder à próxima leitura. Cada 200 ou 304 recomeça a linha do tempo do zero.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l17-expiry", 720, 230, t["aria"])
    x0, scale = 40, 1.6   # px per second, up to 400 s
    def X(s): return x0 + s * scale
    f.rect(X(0), 60, 60 * scale, 60, stroke="phosphor", fill="panel")
    f.rect(X(60), 60, 300 * scale, 60, stroke="amber", fill="panel")
    f.rect(X(360), 60, 40 * scale + 20, 60, stroke="wire", fill="panel", dashed=True)
    f.text(X(30), 82, t["fresh"], bold=True, size=10, fill="phosphor")
    f.text(X(30), 98, "max-age", mono=True, size=9, fill="paper-dim")
    f.text(X(210), 82, t["stale"], bold=True, size=10, fill="amber")
    f.text(X(210), 98, t["stale2"], size=9.5, fill="paper")
    f.text(X(380) + 10, 82, t["old"], bold=True, size=10, fill="paper-dim")
    f.text(X(380) + 10, 98, t["old2"], size=9, fill="paper-dim", italic=True)
    f.text(X(30), 132, t["fresh2"], size=9, fill="paper-dim", italic=True)
    f.arrow([(X(0), 150), (X(400) + 24, 150)])
    for s in (0, 60, 360):
        f.arrow([(X(s), 145), (X(s), 155)], head=False)
        f.text(X(s), 168, str(s), mono=True, size=9, fill="paper-dim")
    f.text(X(200), 190, t["t"], size=9.5, fill="paper-dim")
    f.text(X(0), 30, t["runs"], anchor="start", size=9.5, fill="paper-dim")
    for s in (30, 45, 90):
        f.arrow([(X(s), 40), (X(s), 58)], color="paper")
        f.text(X(s) + (6 if s != 30 else -6), 48, str(s), anchor="start" if s != 30 else "end", mono=True, size=9, fill="paper")
    return {"l17-expiry": f.json(t["cap"])}
