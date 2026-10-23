from fig import Canvas


def keys(T):
    c = Canvas(720, 270, T(
        "The same sort, with and without a key. On the left, without a key: the two list elements stay where they are and "
        "are given new data, so the first element, which holds the note read chapter 3, now shows the 24th. On the right, "
        "with a key: the elements move with their sessions, so the element holding the note moves down with the 19th.",
        "A mesma ordenação, com e sem chave. À esquerda, sem chave: os dois elementos da lista ficam onde estão e recebem "
        "dados novos, então o primeiro elemento, que guarda a nota read chapter 3, agora mostra o dia 24. À direita, com "
        "chave: os elementos se movem com as suas sessões, então o elemento que guarda a nota desce junto com o dia 19."))
    for col, (title, keyed) in enumerate([(T("without a key", "sem chave"), False), (T("with (session.id)", "com (session.id)"), True)]):
        x0 = 20 + col * 360
        c.text(x0 + 160, 20, title, size=11.5, weight="600", fill="var(--amber)" if not keyed else "var(--phosphor)")
        c.text(x0 + 60, 44, T("before", "antes"), size=10, fill="var(--paper-dim)")
        c.text(x0 + 250, 44, T("after the sort", "depois de ordenar"), size=10, fill="var(--paper-dim)")
        before = [("19 Oct, 90 min", "read chapter 3"), ("24 Oct, 60 min", "")]
        if keyed:
            after = [("24 Oct, 60 min", ""), ("19 Oct, 90 min", "read chapter 3")]
        else:
            after = [("24 Oct, 60 min", "read chapter 3"), ("19 Oct, 90 min", "")]
        for i, (d, n) in enumerate(before):
            y = 60 + i * 90
            c.rect(x0, y, 130, 70, fill="var(--panel)", stroke="var(--wire)")
            c.text(x0 + 65, y + 20, d, size=10)
            c.rect(x0 + 10, y + 34, 110, 24, fill="var(--ink)", stroke="var(--wire)")
            c.text(x0 + 16, y + 46, n, mono=True, size=9, anchor="start")
        for i, (d, n) in enumerate(after):
            y = 60 + i * 90
            wrong = (not keyed) and i == 0
            c.rect(x0 + 190, y, 130, 70, fill="var(--panel)", stroke="var(--amber)" if wrong else "var(--wire)")
            c.text(x0 + 255, y + 20, d, size=10)
            c.rect(x0 + 200, y + 34, 110, 24, fill="var(--ink)", stroke="var(--amber)" if wrong else "var(--wire)")
            c.text(x0 + 206, y + 46, n, mono=True, size=9, anchor="start", fill="var(--amber)" if wrong else "var(--paper)")
        if keyed:
            c.line(x0 + 132, 95, x0 + 188, 180, stroke="var(--phosphor)", arrow=True)
            c.line(x0 + 132, 185, x0 + 188, 100, stroke="var(--phosphor)", arrow=True)
        else:
            c.line(x0 + 132, 95, x0 + 188, 95, stroke="var(--amber)", arrow=True)
            c.line(x0 + 132, 185, x0 + 188, 185, stroke="var(--amber)", arrow=True)
    c.text(180, 255, T("elements stay; data moves", "os elementos ficam; os dados mudam"), size=10, fill="var(--amber)")
    c.text(540, 255, T("elements move with their data", "os elementos vão com os seus dados"), size=10, fill="var(--phosphor)")
    c.caption = T("Without a key the note belongs to a position; with one it belongs to a session.",
                  "Sem chave a nota pertence a uma posição; com chave, a uma sessão.")
    return c


FIGURES = [("keyed-each", keys)]
