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


def owner(T):
    c = Canvas(720, 250, T(
        "The ReactiveProvide demo. On the left, the provider owns total, a ref that starts at 75. In the middle, "
        "what it provides under plannerKey: readonly of total, and the function addFive. On the right, TotalBadge "
        "injects both and shows Total: 80 minutes. Clicking Add five calls addFive, and the provider changes its own "
        "ref, from 75 to 80, which both show. Writing total.value equals 999 from the badge is refused, because what "
        "it holds is a read-only view of the ref.",
        "A demo ReactiveProvide. À esquerda, o provider é dono de total, um ref que começa em 75. No meio, o que ele "
        "fornece sob plannerKey: readonly de total, e a função addFive. À direita, o TotalBadge injeta os dois e "
        "mostra Total: 80 minutes. Clicar em Add five chama addFive, e o provider muda o próprio ref, de 75 para 80, "
        "que os dois mostram. Escrever total.value igual a 999 a partir do badge é recusado, porque o que ele tem é "
        "uma visão somente leitura do ref."))
    c.rect(20, 50, 180, 90, fill="var(--ink)", stroke="var(--amber)")
    c.text(110, 68, "ReactiveProvide.vue", mono=True, size=10, fill="var(--amber)")
    c.text(110, 96, "total = ref(75)", mono=True, size=10.5)
    c.text(110, 120, T("75, then 80", "75, depois 80"), size=10, fill="var(--phosphor)")
    c.rect(270, 40, 180, 116, fill="var(--panel)", stroke="var(--wire)", dash="4 3")
    c.text(360, 56, "plannerKey", mono=True, size=10, fill="var(--paper-dim)")
    c.rect(285, 70, 150, 32, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(360, 86, "readonly(total)", mono=True, size=10.5, fill="var(--phosphor)")
    c.rect(285, 112, 150, 32, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(360, 128, "addFive", mono=True, size=10.5, fill="var(--phosphor)")
    c.rect(520, 50, 180, 90, fill="var(--ink)", stroke="var(--wire)")
    c.text(610, 68, "TotalBadge.vue", mono=True, size=10, fill="var(--amber)")
    c.text(610, 100, "Total: 80 minutes", mono=True, size=10.5)
    c.line(202, 96, 266, 96, stroke="var(--wire)", arrow=True)
    c.text(234, 84, "provide", mono=True, size=9.5, fill="var(--paper-dim)")
    c.line(452, 96, 516, 96, stroke="var(--wire)", arrow=True)
    c.text(484, 84, "inject", mono=True, size=9.5, fill="var(--paper-dim)")
    c.path("M 570 142 V 196 H 110", stroke="var(--phosphor)")
    c.line(110, 196, 110, 144, stroke="var(--phosphor)", arrow=True)
    c.text(340, 186, T("Add five: the owner changes its own ref", "Add five: o dono muda o próprio ref"), size=10,
           fill="var(--phosphor)")
    c.text(620, 214, "total.value = 999", mono=True, size=10, fill="var(--amber)")
    c.text(620, 232, T("refused: a read-only view", "recusado: uma visão somente leitura"), size=9.5,
           fill="var(--amber)")
    c.caption = T("Provide the state read-only and the ways to change it as functions.",
                  "Forneça o estado como somente leitura e as formas de mudá-lo como funções.")
    return c


FIGURES = [("provide-inject", skip), ("reactive-provide", owner)]
