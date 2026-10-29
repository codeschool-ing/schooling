from fig import Canvas


def two_ways(T):
    c = Canvas(720, 290, T(
        "Two ways one press of the button reaches the page. Above, React: setMinutes asks React to call Counter again, "
        "which returns a new description of the button and the paragraph; React compares it with the previous "
        "description, finds one text that differs, and patches that text on the page. Below, Svelte: the click sets "
        "the signal minutes, the signal tells the one effect that read it, and the effect sets the text of the "
        "paragraph. Both end with one text node changed; only React built and compared two descriptions to get there.",
        "Dois caminhos pelos quais um clique no botão chega à página. Em cima, o React: setMinutes pede ao React para "
        "chamar Counter de novo, que devolve uma descrição nova do botão e do parágrafo; o React a compara com a "
        "descrição anterior, acha um texto diferente e aplica essa mudança na página. Embaixo, o Svelte: o clique "
        "define o signal minutes, o signal avisa o único efeito que o leu, e o efeito define o texto do parágrafo. Os "
        "dois terminam com um nó de texto mudado; só o React montou e comparou duas descrições para chegar lá."))
    c.text(20, 20, "React", size=12, weight="600", anchor="start")
    steps = [("setMinutes(30)", True), (T("Counter() again", "Counter() de novo"), False),
             (T("new description", "descrição nova"), False), (T("diff with the old", "diff com a antiga"), False),
             (T("patch 1 text", "aplica 1 texto"), False)]
    x = 20
    for i, (s, mono) in enumerate(steps):
        c.rect(x, 36, 124, 44, fill="var(--panel)", stroke="var(--wire)")
        c.text(x + 62, 58, s, mono=mono or i == 1, size=10)
        if i < len(steps) - 1:
            c.line(x + 124, 58, x + 140, 58, stroke="var(--paper-dim)", arrow=True)
        x += 140
    c.rect(160, 92, 404, 30, fill="var(--ink)", stroke="var(--amber)", dash="4 3")
    c.text(362, 107, T("work done in the browser to find the change", "trabalho feito no navegador para achar a mudança"),
           size=10, fill="var(--amber)")
    c.text(20, 160, "Svelte", size=12, weight="600", anchor="start")
    steps2 = [("minutes += 30", True), (T("signal minutes", "signal minutes"), False),
              (T("its one reader", "o seu único leitor"), False), (T("set 1 text", "define 1 texto"), False)]
    x = 20
    for i, (s, mono) in enumerate(steps2):
        c.rect(x, 176, 124, 44, fill="var(--panel)", stroke="var(--phosphor)" if i else "var(--wire)")
        c.text(x + 62, 198, s, mono=mono or i == 1, size=10)
        if i < len(steps2) - 1:
            c.line(x + 124, 198, x + 140, 198, stroke="var(--paper-dim)", arrow=True)
        x += 140
    c.rect(580, 176, 124, 44, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(642, 198, "<p>30 …</p>", mono=True, size=10, fill="var(--phosphor)")
    c.line(564, 198, 578, 198, stroke="var(--phosphor)", arrow=True)
    c.line(642, 80, 642, 174, stroke="var(--phosphor)", dash="3 3")
    c.text(362, 252, T("worked out once, by the compiler, before anybody visited",
                       "descoberto uma vez, pelo compilador, antes de qualquer visita"), size=10, fill="var(--phosphor)")
    c.caption = T("Both reach the same single change. React compares two descriptions to find it; Svelte's effect already knew.",
                  "Os dois chegam à mesma mudança única. O React compara duas descrições para achá-la; o efeito do Svelte já sabia.")
    return c


def readers(T):
    c = Canvas(720, 250, T(
        "The counter's signals and their readers. The signal minutes has two readers: the template effect that sets the "
        "first paragraph, and the effect that logs. The signal goal has one reader: the template effect that sets the "
        "second paragraph. Pressing Raise the goal reaches only goal's reader; pressing Add 30 minutes reaches only "
        "minutes's two readers.",
        "Os signals do contador e os seus leitores. O signal minutes tem dois leitores: o template effect que define o "
        "primeiro parágrafo e o efeito que escreve no console. O signal goal tem um leitor: o template effect que define "
        "o segundo parágrafo. Apertar Raise the goal chega só ao leitor de goal; apertar Add 30 minutes chega só aos dois "
        "leitores de minutes."))
    c.rect(40, 50, 150, 50, fill="var(--ink)", stroke="var(--amber)")
    c.text(115, 75, "minutes", mono=True, size=11, fill="var(--amber)")
    c.rect(40, 160, 150, 50, fill="var(--ink)", stroke="var(--amber)")
    c.text(115, 185, "goal", mono=True, size=11, fill="var(--amber)")
    c.text(115, 28, T("signals", "signals"), size=10, fill="var(--paper-dim)")
    c.text(560, 28, T("their readers", "os seus leitores"), size=10, fill="var(--paper-dim)")
    r = [(30, T("sets the first paragraph", "define o primeiro parágrafo")),
         (100, T("the effect that logs", "o efeito que escreve no console")),
         (175, T("sets the second paragraph", "define o segundo parágrafo"))]
    for y, s in r:
        c.rect(440, y + 10, 240, 40, fill="var(--panel)", stroke="var(--phosphor)")
        c.text(560, y + 30, s, size=10.5)
    c.line(190, 70, 438, 50, stroke="var(--phosphor)", arrow=True)
    c.line(190, 80, 438, 120, stroke="var(--phosphor)", arrow=True)
    c.line(190, 185, 438, 195, stroke="var(--phosphor)", arrow=True)
    c.text(300, 140, T("a change goes down its signal's list, and nowhere else",
                       "uma mudança percorre a lista do seu signal, e mais nada"), size=10, fill="var(--paper-dim)")
    c.caption = T("Each signal keeps the list of what read it. Raising the goal reaches one reader; adding minutes reaches two.",
                  "Cada signal guarda a lista de quem o leu. Subir a meta chega a um leitor; somar minutos chega a dois.")
    return c


FIGURES = [("the-virtual-dom", two_ways), ("signals", readers)]
