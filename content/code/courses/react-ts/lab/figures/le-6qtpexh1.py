from fig import Fig

m = Fig("modes", 720, 230,
        {"en": "Three rows, one per rendering mode, against two moments: build time and request time. Static: the "
               "whole page is made at build time and the same file is sent on every request. Partial prerender: the "
               "shell is made at build time, and the parts inside Suspense are rendered per request and streamed into "
               "it. Dynamic: nothing at build time; the whole page is made per request.",
         "pt": "Três linhas, uma por modo de renderização, contra dois momentos: o build e a requisição. Estático: a "
               "página inteira é feita no build e o mesmo arquivo é mandado a cada requisição. Prerender parcial: a "
               "casca é feita no build, e as partes dentro do Suspense são renderizadas por requisição e transmitidas "
               "para dentro dela. Dinâmico: nada no build; a página inteira é feita por requisição."},
        {"en": "The question is how much of the page can be known before anybody asks for it.",
         "pt": "A pergunta é quanto da página pode ser conhecido antes de alguém pedi-la."})
m.text(285, 22, {"en": "at build time", "pt": "no build"}, anchor="middle", tone="dim", size=11)
m.text(560, 22, {"en": "per request", "pt": "por requisição"}, anchor="middle", tone="dim", size=11)
m.line(420, 30, 420, 210, tone="wire", dashed=True)
rows = [("○", {"en": "static", "pt": "estático"}, (170, 230), None),
        ("◐", {"en": "partial", "pt": "parcial"}, (170, 230), (440, 240)),
        ("ƒ", {"en": "dynamic", "pt": "dinâmico"}, None, (440, 240))]
for i, (mark, name, build, req) in enumerate(rows):
    y = 44 + i * 58
    m.text(24, y + 22, mark, tone="phosphor", size=13)
    m.text(46, y + 22, name, tone="paper", size=11)
    if build:
        label = {"en": "the whole page", "pt": "a página inteira"} if not req else {"en": "the shell", "pt": "a casca"}
        m.box(build[0], y, build[1], 40, label, tone="phosphor", size=10.5)
    if req:
        label = {"en": "the whole page", "pt": "a página inteira"} if not build else {"en": "what is inside Suspense", "pt": "o que está dentro do Suspense"}
        m.box(req[0], y, req[1], 40, label, tone="amber", size=10.5)
    if build and not req:
        m.text(560, y + 22, {"en": "the same file, every time", "pt": "o mesmo arquivo, toda vez"}, anchor="middle", tone="dim", size=10.5)

FIGS = [m]
