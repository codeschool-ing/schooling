from fig import Canvas


def path(T):
    c = Canvas(720, 250, T(
        "Requests along time, as a page loads. The HTML comes first. The stylesheet is requested once the HTML names it, "
        "and the first paint waits for it. The font is requested only after the stylesheet has arrived, and the text "
        "that uses it waits for the font. The module script and the picture are requested alongside the stylesheet, "
        "and the first paint does not wait for either.",
        "Requisições ao longo do tempo, enquanto uma página carrega. O HTML vem primeiro. A folha de estilo é pedida "
        "quando o HTML a cita, e a primeira pintura espera por ela. A fonte só é pedida depois que a folha de estilo "
        "chegou, e o texto que a usa espera pela fonte. O script módulo e a imagem são pedidos junto com a folha de "
        "estilo, e a primeira pintura não espera por nenhum dos dois."))
    x0, step = 170, 150
    rows = [(T("the HTML", "o HTML"), 0, 1, True), (T("stylesheet", "folha de estilo"), 1, 2, True),
            (T("font", "fonte"), 2, 3, True), (T("module script", "script módulo"), 1, 2.3, False),
            (T("picture", "imagem"), 1, 2.6, False)]
    for i, (label, a, b, on) in enumerate(rows):
        y = 30 + i * 32
        c.text(x0 - 12, y + 10, label, anchor="end", size=10.5, fill="var(--paper)" if on else "var(--paper-dim)")
        c.rect(x0 + a * step, y, (b - a) * step, 20, fill="var(--ink)" if on else "var(--panel)",
               stroke="var(--amber)" if on else "var(--wire)", rx=2, dash=None if on else "4 3")
    c.line(x0 + 2 * step, 22, x0 + 2 * step, 196, stroke="var(--phosphor)", sw=1.6)
    c.text(x0 + 2 * step, 212, T("first paint", "primeira pintura"), size=10.5, fill="var(--phosphor)")
    c.line(x0 + 3 * step, 22, x0 + 3 * step, 196, stroke="var(--phosphor)", dash="3 3")
    c.text(x0 + 3 * step, 212, T("text in its font", "texto na sua fonte"), size=10.5, fill="var(--phosphor)")
    c.rect(x0, 228, 12, 12, fill="var(--ink)", stroke="var(--amber)")
    c.text(x0 + 18, 234, T("on the critical path", "no caminho crítico"), anchor="start", size=10, fill="var(--amber)")
    c.rect(x0 + 200, 228, 12, 12, fill="var(--panel)", stroke="var(--wire)", dash="4 3")
    c.text(x0 + 218, 234, T("off it", "fora dele"), anchor="start", size=10, fill="var(--paper-dim)")
    c.caption = T("Each step on the path is a round trip the person waits through with nothing to see.",
                  "Cada degrau do caminho é uma ida e volta que a pessoa espera sem ver nada.")
    return c


FIGURES = [
    ("the-critical-path", path),
]
