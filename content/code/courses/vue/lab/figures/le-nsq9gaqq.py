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


def queue(T):
    c = Canvas(720, 245, T(
        "One click on Add three, in time order from left to right, on three rows. On the first row, the click's "
        "code: count.value++ three times, then the log saying count is 3 and the page still says 0, then await "
        "nextTick. On the second row, Vue's queue: the three writes queued one render, and it runs once, with count "
        "equal to 3, when the click's code has paused at the await. Then the code resumes and the page says 3. On "
        "the third row, the output element: it says 0 until that one render, and 3 after it.",
        "Um clique em Add three, em ordem de tempo da esquerda para a direita, em três linhas. Na primeira, o código "
        "do clique: count.value++ três vezes, depois o log dizendo que count é 3 e a página ainda diz 0, depois "
        "await nextTick. Na segunda, a fila do Vue: as três escritas puseram na fila um redesenho só, e ele roda uma "
        "vez, com count igual a 3, quando o código do clique parou no await. Então o código continua e a página diz "
        "3. Na terceira, o elemento output: diz 0 até esse redesenho, e 3 depois dele."))
    c.text(20, 55, "addThree()", mono=True, size=10.5, anchor="start", fill="var(--amber)")
    c.text(20, 125, T("queue", "fila"), size=10.5, anchor="start", fill="var(--phosphor)")
    c.text(20, 190, "<output>", mono=True, size=10.5, anchor="start")
    for i in range(3):
        c.rect(110 + i * 40, 40, 34, 30, fill="var(--panel)", stroke="var(--amber)")
        c.text(127 + i * 40, 55, "++", mono=True, size=11, fill="var(--amber)")
        c.line(127 + i * 40, 72, 150, 106, stroke="var(--wire)", dash="3 3")
    c.rect(100, 108, 120, 32, fill="var(--ink)", stroke="var(--phosphor)", dash="4 3")
    c.text(160, 124, T("1 render queued", "1 redesenho na fila"), size=10, fill="var(--phosphor)")
    c.rect(230, 40, 160, 30, fill="var(--panel)", stroke="var(--wire)")
    c.text(310, 55, T("logs: the page still says 0", "log: a página ainda diz 0"), size=9.5)
    c.rect(400, 40, 100, 30, fill="var(--panel)", stroke="var(--amber)")
    c.text(450, 55, "await nextTick()", mono=True, size=9.5, fill="var(--amber)")
    c.line(502, 62, 525, 106, stroke="var(--phosphor)", dash="3 3", arrow=True)
    c.rect(505, 108, 120, 32, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(565, 124, "render with count = 3", mono=True, size=9, fill="var(--phosphor)")
    c.line(627, 110, 640, 74, stroke="var(--phosphor)", arrow=True)
    c.rect(628, 40, 84, 30, fill="var(--panel)", stroke="var(--amber)")
    c.text(670, 55, T("the page says 3", "a página diz 3"), size=9.5)
    c.rect(100, 176, 523, 28, fill="var(--panel)", stroke="var(--wire)")
    c.text(361, 190, "0", mono=True, size=11)
    c.rect(627, 176, 83, 28, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(668, 190, "3", mono=True, size=11)
    c.line(100, 226, 710, 226, stroke="var(--wire)", arrow=True)
    c.text(405, 238, T("one click, in time order", "um clique, em ordem de tempo"), size=10, fill="var(--paper-dim)")
    c.caption = T("Three writes queue one render; nextTick waits for it.",
                  "Três escritas põem um redesenho na fila; o nextTick espera por ele.")
    return c


FIGURES = [("two-models", two_models), ("the-update-queue", queue)]
