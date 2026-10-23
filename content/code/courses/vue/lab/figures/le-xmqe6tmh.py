from fig import Canvas


def order(T):
    c = Canvas(720, 250, T(
        "Time runs left to right. Three rows: parent, first child, second child. The parent's setup and "
        "beforeMount come first; then each child's setup and beforeMount; then the first child's mounted, the "
        "second child's mounted, and last the parent's mounted. Creation goes down the tree and mounting comes "
        "back up.",
        "O tempo corre da esquerda para a direita. Três linhas: o pai, o primeiro filho, o segundo filho. O "
        "setup e o beforeMount do pai vêm primeiro; depois o setup e o beforeMount de cada filho; depois o "
        "mounted do primeiro filho, o do segundo e, por último, o mounted do pai. A criação desce a árvore e a "
        "montagem volta subindo."))
    rows = [(T("parent", "pai"), 50), (T("first child", "primeiro filho"), 110), (T("second child", "segundo filho"), 170)]
    for name, y in rows:
        c.text(20, y, name, anchor="start", size=11)
        c.line(130, y, 705, y, stroke="var(--wire)", dash="2 4")
    steps = [(0, "setup"), (0, "beforeMount"), (1, "setup"), (1, "beforeMount"), (2, "setup"), (2, "beforeMount"),
             (1, "mounted"), (2, "mounted"), (0, "mounted")]
    x = 135
    prev = None
    for i, (r, label) in enumerate(steps):
        y = rows[r][1]
        mounted = label == "mounted"
        w = 58
        c.rect(x, y - 13, w, 26, fill="var(--ink)", stroke="var(--phosphor)" if mounted else "var(--amber)")
        c.text(x + w / 2, y, label if label != "beforeMount" else "before…", mono=True, size=9, fill="var(--phosphor)" if mounted else "var(--amber)")
        if prev:
            c.line(prev[0], prev[1], x, y, stroke="var(--paper-dim)", sw=0.8)
        prev = (x + w, y)
        x += 63
    c.text(260, 222, T("created, going down", "criados, descendo"), size=10.5, fill="var(--amber)")
    c.text(600, 222, T("mounted, coming back up", "montados, voltando"), size=10.5, fill="var(--phosphor)")
    c.caption = T("A parent is mounted last, so its onMounted can count on every child being on the page.",
                  "O pai é montado por último, então o onMounted dele pode contar com todos os filhos já na página.")
    return c


FIGURES = [("order", order)]
