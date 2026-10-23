from fig import Canvas


def skip(T):
    c = Canvas(720, 240, T(
        "Two trees of the same three levels. On the left, prop drilling: the parent passes unit to the middle "
        "component as a prop, and the middle passes it on to each leaf, though it never uses it. On the right, "
        "provide and inject: the parent provides unit under a key, the middle component is not involved, and "
        "each leaf injects the value directly.",
        "Duas árvores com os mesmos três níveis. À esquerda, prop drilling: o pai passa unit ao componente do "
        "meio como prop, e o do meio repassa a cada folha, embora nunca o use. À direita, provide e inject: o "
        "pai provê unit sob uma chave, o componente do meio não participa, e cada folha injeta o valor "
        "diretamente."))

    def tree(x0, provide):
        c.rect(x0 + 90, 30, 140, 34, fill="var(--ink)", stroke="var(--amber)")
        c.text(x0 + 160, 47, T("parent", "pai"), size=11, fill="var(--amber)")
        c.rect(x0 + 90, 105, 140, 34, fill="var(--panel)", stroke="var(--wire)", dash=None if not provide else "4 3")
        c.text(x0 + 160, 122, T("middle", "meio"), size=11, fill="var(--paper-dim)" if provide else "var(--paper)")
        for i, lx in enumerate((x0 + 20, x0 + 190)):
            c.rect(lx, 180, 120, 34, fill="var(--ink)", stroke="var(--phosphor)")
            c.text(lx + 60, 197, T("leaf", "folha"), size=11, fill="var(--phosphor)")
        c.line(x0 + 160, 66, x0 + 160, 103, stroke="var(--wire)")
        c.line(x0 + 160, 141, x0 + 80, 178, stroke="var(--wire)")
        c.line(x0 + 160, 141, x0 + 250, 178, stroke="var(--wire)")
        if not provide:
            c.text(x0 + 168, 86, ":unit", mono=True, size=10, fill="var(--amber)", anchor="start")
            c.text(x0 + 70, 158, ":unit", mono=True, size=10, fill="var(--amber)", anchor="end")
            c.text(x0 + 252, 158, ":unit", mono=True, size=10, fill="var(--amber)", anchor="start")
        else:
            c.path(f"M{x0 + 88},50 C{x0 - 10},90 {x0 + 20},150 {x0 + 60},178", stroke="var(--amber)", dash="5 3")
            c.path(f"M{x0 + 232},50 C{x0 + 330},90 {x0 + 300},150 {x0 + 260},178", stroke="var(--amber)", dash="5 3")
            c.text(x0 + 160, 16, "provide(unitKey, 'hours')", mono=True, size=10, fill="var(--amber)")
            c.text(x0 + 160, 230, "inject(unitKey)", mono=True, size=10, fill="var(--phosphor)")
    c.text(180, 16, T("props, level by level", "props, nível por nível"), size=11, weight="600")
    tree(20, False)
    tree(380, True)
    c.caption = T("With provide, the middle component no longer carries a value it does not use. It also no longer "
                  "shows, anywhere, that its children need one.",
                  "Com provide, o componente do meio deixa de carregar um valor que não usa. Ele também deixa de "
                  "mostrar, em qualquer lugar, que os filhos precisam de um.")
    return c


FIGURES = [("provide-inject", skip)]
