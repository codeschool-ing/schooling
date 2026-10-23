from fig import Canvas


def keys(T):
    c = Canvas(720, 220, T(
        "Two lists of three course rows, before and after statistics is removed. Keyed by index, the rows had "
        "keys 0, 1 and 2; afterwards keys 0 and 1 remain, so the component with key 0 is kept with its star and "
        "now shows Spanish, and key 2 is removed. Keyed by course, the rows had keys statistics, spanish and "
        "guitar; afterwards the statistics component is removed with its star, and the other two are kept.",
        "Duas listas de três linhas de curso, antes e depois de statistics ser removido. Com a chave pelo índice, "
        "as linhas tinham as chaves 0, 1 e 2; depois restam 0 e 1, então o componente de chave 0 é mantido com a "
        "estrela e passa a mostrar Spanish, e a chave 2 é removida. Com a chave pelo curso, as linhas tinham as "
        "chaves statistics, spanish e guitar; depois o componente de statistics sai com a estrela, e os outros "
        "dois são mantidos."))

    def row(x, y, key, text, star=False, gone=False):
        c.rect(x, y, 140, 30, fill="none" if gone else "var(--ink)",
               stroke="var(--amber)" if gone else "var(--phosphor)", dash="4 3" if gone else None)
        c.text(x + 8, y + 15, key, mono=True, size=10, anchor="start", fill="var(--paper-dim)")
        c.text(x + 132, y + 15, text + (" *" if star else ""), mono=True, size=10.5, anchor="end",
               fill="var(--amber)" if gone else "var(--paper)")

    for i, (title, x) in enumerate([(T("key = index", "chave = índice"), 20), (T("key = the course", "chave = o curso"), 380)]):
        c.text(x + 160, 18, title, size=12, weight="600")
        c.text(x + 70, 42, T("before", "antes"), size=10, fill="var(--paper-dim)")
        c.text(x + 250, 42, T("after", "depois"), size=10, fill="var(--paper-dim)")
        names = ["statistics", "spanish", "guitar"]
        for j, n in enumerate(names):
            k = str(j) if i == 0 else n[:4] + "…"
            row(x, 55 + j * 40, k, n, star=(j == 0))
        if i == 0:
            row(x + 180, 55, "0", "spanish", star=True)
            row(x + 180, 95, "1", "guitar")
            row(x + 180, 135, "2", T("removed", "removido"), gone=True)
            for j in range(2):
                c.line(x + 142, 70 + j * 40, x + 178, 70 + j * 40, stroke="var(--wire)", arrow=True)
        else:
            row(x + 180, 55, "stat…", T("removed *", "removido *"), gone=True)
            row(x + 180, 95, "span…", "spanish")
            row(x + 180, 135, "guit…", "guitar")
            for j in range(3):
                c.line(x + 142, 70 + j * 40, x + 178, 70 + j * 40, stroke="var(--wire)", arrow=True)
    c.text(200, 205, T("the star stays at position 0", "a estrela fica na posição 0"), size=10.5, fill="var(--amber)")
    c.text(560, 205, T("the star leaves with its course", "a estrela sai com o seu curso"), size=10.5, fill="var(--phosphor)")
    c.caption = T("Vue keeps the components whose keys still exist. With an index, the key that survives is a "
                  "position, and the state goes with the position.",
                  "O Vue mantém os componentes cujas chaves ainda existem. Com um índice, a chave que sobrevive é "
                  "uma posição, e o estado vai junto com a posição.")
    return c


FIGURES = [("the-key", keys)]
