from fig import Canvas


def track(T):
    c = Canvas(720, 300, T(
        "Two lists of three rows, before and after the list is reversed. Each row is a piece of DOM with a field; "
        "the Git row's field holds 25. Tracked by id, the Git row's DOM moves to the top, with its 25. Tracked by "
        "position, every row's DOM stays where it was and only its text changes, so the 25 stays in the third row, "
        "which now says HTML and CSS.",
        "Duas listas de três linhas, antes e depois de a lista ser invertida. Cada linha é um pedaço de DOM com um "
        "campo; o campo da linha do Git tem 25. Rastreado por id, o DOM da linha do Git vai para o topo, com o seu 25. "
        "Rastreado por posição, o DOM de cada linha fica onde estava e só o texto muda, então o 25 fica na terceira "
        "linha, que agora diz HTML and CSS."))
    names = ["HTML and CSS", "JavaScript", "Git"]
    def rows(x, y, labels, values, hi):
        for i, (n, v) in enumerate(zip(labels, values)):
            yy = y + i * 34
            c.rect(x, yy, 200, 28, fill="var(--panel)", stroke="var(--amber)" if i == hi else "var(--wire)")
            c.text(x + 10, yy + 14, n, anchor="start", size=10, mono=True)
            c.rect(x + 140, yy + 5, 50, 18, fill="var(--ink)", stroke="var(--wire)", rx=2)
            if v:
                c.text(x + 165, yy + 14, v, size=10, mono=True, fill="var(--amber)")
    for k, (title, y0) in enumerate(((T("tracked by id", "rastreado por id"), 40), (T("tracked by position", "rastreado por posição"), 180))):
        c.text(20, y0 - 18, title, anchor="start", size=11, weight="600")
        c.text(130, y0 - 4, T("before", "antes"), size=9.5, fill="var(--paper-dim)")
        c.text(590, y0 - 4, T("after Reverse", "depois do Reverse"), size=9.5, fill="var(--paper-dim)")
        rows(30, y0 + 2, names, ["", "", "25"], 2)
        if k == 0:
            rows(490, y0 + 2, list(reversed(names)), ["25", "", ""], 0)
            c.path(f"M232 {y0+86} C 360 {y0+86}, 360 {y0+16}, 486 {y0+16}", stroke="var(--amber)")
            c.line(480, y0 + 16, 486, y0 + 16, stroke="var(--amber)", arrow=True)
            c.text(360, y0 + 92, T("the Git row moves, field and all", "a linha do Git se move, com o campo"), size=9.5, fill="var(--amber)")
        else:
            rows(490, y0 + 2, list(reversed(names)), ["", "", "25"], 2)
            for i in range(3):
                c.line(232, y0 + 16 + i * 34, 486, y0 + 16 + i * 34, stroke="var(--wire)", dash="3 3", arrow=True)
            c.text(360, y0 + 108, T("each row stays; only its text changes", "cada linha fica; só o texto muda"), size=9.5, fill="var(--paper-dim)")
    c.caption = T("The key decides what counts as the same row. By position, the 25 ends up next to the wrong course.",
                  "A chave decide o que conta como a mesma linha. Por posição, o 25 vai parar ao lado do curso errado.")
    return c


FIGURES = [("tracking", track)]
