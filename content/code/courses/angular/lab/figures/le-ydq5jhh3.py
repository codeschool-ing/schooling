from fig import Canvas


def levels(T):
    rows = [
        (T("a plain function", "uma função simples"), "planner.spec.ts", 115),
        (T("a service, fake server", "um serviço, servidor falso"), "planner-store.spec.ts", 185),
        (T("a component, its page", "um componente, a página"), "course-sessions.spec.ts", 250),
        (T("a component, harnesses", "um componente, harnesses"), "MatCheckboxHarness", 300),
        (T("the application, a browser", "a aplicação, um navegador"), "look", 400),
    ]
    c = Canvas(720, 270, T(
        "Five levels of test, one per row, from a plain function at the top to the whole application in a "
        "browser at the bottom. Each row has a bar whose length is the price of a test at that level, "
        "growing from short to long, and names the planner's file at that level. An arrow down the side "
        "says that a failure means more, and points at less, further down.",
        "Cinco níveis de teste, um por linha, de uma função simples no topo à aplicação inteira num "
        "navegador embaixo. Cada linha tem uma barra cujo comprimento é o preço de um teste naquele nível, "
        "crescendo de curta a longa, e dá o nome do arquivo do planner naquele nível. Uma seta descendo ao "
        "lado diz que, mais para baixo, uma falha cobre mais e aponta menos."))
    for k, (name, file, w) in enumerate(rows):
        y = 34 + k * 44
        c.text(20, y + 12, name, size=10.5, anchor="start")
        c.rect(230, y, w, 24, stroke="var(--phosphor)" if k < 4 else "var(--amber)")
        c.text(238, y + 12, file, size=9.5, mono=True, anchor="start", fill="var(--paper-dim)")
    c.text(230, 18, T("price of one test", "preço de um teste"), size=9.5, anchor="start", fill="var(--paper-dim)")
    c.line(680, 40, 680, 238, arrow=True)
    c.text(672, 246, T("covers more, points at less", "cobre mais, aponta menos"), size=9.5, anchor="end",
           fill="var(--paper-dim)")
    c.caption = T("Each rule goes to the cheapest level that can see it; the levels below the top cost more and say less about where the fault is.",
                  "Cada regra vai para o nível mais barato que consegue vê-la; os níveis abaixo do topo custam mais e dizem menos sobre onde está o defeito.")
    return c


FIGURES = [("what-goes-where", levels)]
