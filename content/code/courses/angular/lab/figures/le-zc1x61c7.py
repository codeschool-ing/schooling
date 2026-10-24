from fig import Canvas


def flow(T):
    c = Canvas(720, 290, T(
        "The course page at the top holds the data. An arrow labelled sessions goes down to the session list, and "
        "an arrow labelled session goes down from the list to each row. From a row, an arrow labelled toggled, "
        "carrying true, goes up to the list, and from the list an arrow labelled toggled, carrying the id and done, "
        "goes up to the page, which updates its data. The new data then flows down again.",
        "A página do curso, no topo, guarda os dados. Uma seta chamada sessions desce até a lista de sessões, e uma "
        "seta chamada session desce da lista até cada linha. De uma linha, uma seta chamada toggled, levando true, "
        "sobe até a lista, e da lista uma seta chamada toggled, levando o id e o done, sobe até a página, que "
        "atualiza os seus dados. Os dados novos então descem de novo."))
    def box(x, y, w, name, sub, col):
        c.rect(x, y, w, 46, fill="var(--panel)", stroke=col)
        c.text(x + w / 2, y + 16, name, mono=True, size=11)
        c.text(x + w / 2, y + 33, sub, size=9, fill="var(--paper-dim)")
    box(250, 20, 220, "CoursePage", T("owns the data", "dono dos dados"), "var(--amber)")
    box(250, 120, 220, "SessionList", T("passes it on", "repassa"), "var(--wire)")
    box(250, 220, 220, "SessionRow", T("one per session", "uma por sessão"), "var(--wire)")
    # down: inputs
    c.line(300, 66, 300, 118, stroke="var(--phosphor)", arrow=True)
    c.text(292, 92, "[sessions]", mono=True, size=10, anchor="end", fill="var(--phosphor)")
    c.line(300, 166, 300, 218, stroke="var(--phosphor)", arrow=True)
    c.text(292, 192, "[session]", mono=True, size=10, anchor="end", fill="var(--phosphor)")
    c.text(120, 140, T("data goes down,", "os dados descem,"), size=10.5, fill="var(--phosphor)")
    c.text(120, 156, T("through inputs", "pelos inputs"), size=10.5, fill="var(--phosphor)")
    # up: outputs
    c.line(420, 218, 420, 168, stroke="var(--amber)", arrow=True)
    c.text(428, 192, "(toggled) true", mono=True, size=10, anchor="start", fill="var(--amber)")
    c.line(420, 118, 420, 68, stroke="var(--amber)", arrow=True)
    c.text(428, 92, "(toggled) { id, done }", mono=True, size=10, anchor="start", fill="var(--amber)")
    c.text(620, 140, T("news goes up,", "as notícias sobem,"), size=10.5, fill="var(--amber)")
    c.text(620, 156, T("through outputs", "pelos outputs"), size=10.5, fill="var(--amber)")
    c.text(360, 280, T("the owner updates its data, and the new value flows down again",
                       "o dono atualiza os dados, e o valor novo desce de novo"), size=9.5, fill="var(--paper-dim)")
    c.caption = T("Inputs carry data down; outputs carry news up; only the owner changes the data.",
                  "Inputs levam dados para baixo; outputs levam notícias para cima; só o dono muda os dados.")
    return c


FIGURES = [("outputs", flow)]
