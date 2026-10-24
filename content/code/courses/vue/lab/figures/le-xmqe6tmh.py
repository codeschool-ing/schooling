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


def kept(T):
    c = Canvas(720, 190, T(
        "The KeptAlive demo, two Draft components over three moments. When the page opens, statistics is mounted "
        "and activated, and verbs is typed into its note, 5 characters. Spanish does not exist yet. After the click "
        "on Spanish, statistics is deactivated, not unmounted, and spanish is mounted and activated. After the click "
        "on Statistics, spanish is deactivated and the same statistics component is activated again, with its 5 "
        "characters.",
        "A demo KeptAlive, dois componentes Draft em três momentos. Quando a página abre, statistics é montado e "
        "ativado, e verbs é digitado na nota dele, 5 caracteres. Spanish ainda não existe. Depois do clique em "
        "Spanish, statistics é desativado, não desmontado, e spanish é montado e ativado. Depois do clique em "
        "Statistics, spanish é desativado e o mesmo componente statistics é ativado de novo, com os seus 5 "
        "caracteres."))
    heads = [T("opens, verbs typed", "abre, verbs digitado"), "click #spanish", "click #stats"]
    for i, h in enumerate(heads):
        c.text(225 + i * 190, 22, h, size=10.5, mono=i > 0, fill="var(--amber)")
    c.text(20, 66, "statistics", mono=True, size=11, anchor="start", fill="var(--phosphor)")
    c.text(20, 136, "spanish", mono=True, size=11, anchor="start", fill="var(--phosphor)")
    rows = [
        (40, [("mounted · activated", T("5 characters", "5 caracteres"), True),
              ("deactivated", T("kept, not unmounted", "guardado, não desmontado"), False),
              ("activated", T("the same one, 5 characters", "o mesmo, 5 caracteres"), True)]),
        (110, [(None, T("not created yet", "ainda não criado"), False),
               ("mounted · activated", None, True),
               ("deactivated", T("kept, not unmounted", "guardado, não desmontado"), False)]),
    ]
    for y, cells in rows:
        for i, (hook, note, on) in enumerate(cells):
            x = 135 + i * 190
            c.rect(x, y, 180, 52, fill="var(--ink)",
                   stroke="var(--phosphor)" if on else "var(--wire)", dash=None if on else "4 3")
            if hook and note:
                c.text(x + 90, y + 18, hook, mono=True, size=10)
                c.text(x + 90, y + 36, note, size=9.5, fill="var(--paper)" if on else "var(--paper-dim)")
            elif hook:
                c.text(x + 90, y + 26, hook, mono=True, size=10)
            else:
                c.text(x + 90, y + 26, note, size=9.5, fill="var(--paper-dim)")
    c.text(420, 180, T("onUnmounted never ran: KeepAlive put each one away", "o onUnmounted nunca rodou: o KeepAlive guardou cada um"),
           size=9.5, fill="var(--paper-dim)")
    c.caption = T("Switching away deactivates a kept component; switching back activates the same instance.",
                  "Sair de um componente guardado o desativa; voltar ativa a mesma instância.")
    return c


FIGURES = [("order", order), ("keep-alive", kept)]
