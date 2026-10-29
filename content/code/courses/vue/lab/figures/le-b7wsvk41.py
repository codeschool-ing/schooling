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


def lives(T):
    c = Canvas(720, 200, T(
        "The two Noisy components of the IfAndShow demo over three clicks on Toggle, in four columns: the page "
        "opening with open true, the first click with open false, the second with open true, the third with open "
        "false. The one with v-if is created and put on the page, removed and replaced by a v-if comment, created "
        "and put on the page again, and removed again: created twice, removed twice. The one with v-show is created "
        "and put on the page once, and then only switches between display none and shown.",
        "Os dois componentes Noisy da demo IfAndShow ao longo de três cliques em Toggle, em quatro colunas: a "
        "página abrindo com open true, o primeiro clique com open false, o segundo com open true, o terceiro com "
        "open false. O que tem v-if é criado e posto na página, removido e trocado por um comentário v-if, criado e "
        "posto na página de novo, e removido de novo: criado duas vezes, removido duas vezes. O que tem v-show é "
        "criado e posto na página uma vez, e depois só alterna entre display none e visível."))
    heads = [(T("page opens", "a página abre"), "open = true"), (T("click 1", "clique 1"), "open = false"),
             (T("click 2", "clique 2"), "open = true"), (T("click 3", "clique 3"), "open = false")]
    for i, (h, v) in enumerate(heads):
        x = 110 + i * 150
        c.text(x + 70, 20, h, size=10.5, fill="var(--amber)")
        c.text(x + 70, 38, v, mono=True, size=9.5, fill="var(--paper-dim)")
    c.text(20, 82, "v-if", mono=True, size=11, anchor="start", fill="var(--phosphor)")
    c.text(20, 152, "v-show", mono=True, size=11, anchor="start", fill="var(--phosphor)")
    on = T("created, on the page", "criado, na página")
    for i in range(4):
        x = 110 + i * 150
        if i % 2 == 0:
            c.rect(x, 60, 140, 44, fill="var(--ink)", stroke="var(--phosphor)")
            c.text(x + 70, 82, on, size=10)
        else:
            c.rect(x, 60, 140, 44, fill="var(--ink)", stroke="var(--wire)", dash="4 3")
            c.text(x + 70, 74, T("removed", "removido"), size=10)
            c.text(x + 70, 92, "<!--v-if-->", mono=True, size=9.5, fill="var(--paper-dim)")
    cells = [(on, False), ("display: none", True), (T("shown again", "visível de novo"), False), ("display: none", True)]
    for i, (s, mono) in enumerate(cells):
        x = 110 + i * 150
        c.rect(x, 130, 140, 44, fill="var(--panel)" if mono else "var(--ink)",
               stroke="var(--wire)" if mono else "var(--phosphor)")
        c.text(x + 70, 152, s, size=10, mono=mono, fill="var(--paper-dim)" if mono else "var(--paper)")
    c.text(410, 192, T("the v-show paragraph is the same element throughout", "o parágrafo do v-show é o mesmo elemento o tempo todo"),
           size=9.5, fill="var(--paper-dim)")
    c.caption = T("v-if builds and destroys the component; v-show builds it once and changes one style.",
                  "O v-if constrói e destrói o componente; o v-show o constrói uma vez e muda um estilo.")
    return c


FIGURES = [("the-key", keys), ("v-if-and-v-show", lives)]
