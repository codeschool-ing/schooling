from fig import Canvas


def two_models(T):
    c = Canvas(720, 250, T(
        "Two rows, each showing a component over three clicks. In React, every click runs the whole component "
        "function again, then compares the new description with the old one and patches the page. In Vue, the "
        "setup runs once at the start; every click writes a ref, and only the render that read it runs again "
        "and patches the page.",
        "Duas linhas, cada uma mostrando um componente ao longo de três cliques. No React, cada clique roda de "
        "novo a função inteira do componente, compara a nova descrição com a antiga e corrige a página. No Vue, "
        "o setup roda uma vez no começo; cada clique escreve num ref, e só a renderização que o leu roda de novo "
        "e corrige a página."))
    rows = [(60, "React", T("the whole function", "a função inteira"), True),
            (170, "Vue", T("the render that read it", "a renderização que o leu"), False)]
    for y, name, label, react in rows:
        c.text(20, y, name, anchor="start", size=13, weight="600")
        x = 100
        if not react:
            c.rect(x, y - 16, 70, 32, fill="var(--ink)", stroke="var(--amber)")
            c.text(x + 35, y, "setup", mono=True, size=10.5, fill="var(--amber)")
            x += 80
        for i in range(4):
            w = 110 if react else 76
            if react:
                c.rect(x, y - 16, w, 32, fill="var(--ink)", stroke="var(--phosphor)")
                c.text(x + w / 2, y - 3, T("component()", "component()"), mono=True, size=10, fill="var(--phosphor)")
                c.text(x + w / 2, y + 10, T("+ compare", "+ comparação"), size=9, fill="var(--paper-dim)")
            else:
                c.rect(x, y - 16, w, 32, fill="var(--ink)", stroke="var(--phosphor)")
                c.text(x + w / 2, y, "render()", mono=True, size=10, fill="var(--phosphor)")
            if i < 3:
                cx = x + w + (20 if react else 25)
                c.line(cx, y - 30, cx, y + 26, stroke="var(--wire)", dash="2 3")
                c.text(cx, y - 38, T("click", "clique"), size=9, fill="var(--paper-dim)")
            x += w + (40 if react else 50)
        c.text(100, y + 40, T(f"runs again on a change: {label}", f"roda de novo a cada mudança: {label}"), anchor="start", size=10.5, fill="var(--paper-dim)")
    c.caption = T("React finds out what changed by running everything again. Vue already knows, because every read of a "
                  "ref was recorded.",
                  "O React descobre o que mudou rodando tudo de novo. O Vue já sabe, porque cada leitura de um ref "
                  "foi registrada.")
    return c


FIGURES = [("two-models", two_models)]
