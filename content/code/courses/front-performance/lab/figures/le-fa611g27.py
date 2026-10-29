from fig import Canvas

# Read off this lesson's captures.
INP_RUNS = [(1888, 1, 1762, 125), (848, 3, 723, 123), (88, 1, 61, 25)]   # total, input, processing, presentation
LCP_RUNS = [(972, "0.031"), (956, "0.000"), (648, "0.000")]                  # the three phone runs


def inp_parts(T):
    c = Canvas(720, 170, T(
        "One interaction drawn as a bar along time, in three parts: input delay, from the tap until the handler "
        "starts; processing, while the handler runs; and presentation delay, until the next frame is painted. INP is "
        "the length of the whole bar.",
        "Uma interação desenhada como uma barra ao longo do tempo, em três partes: o input delay, do toque até o "
        "tratador começar; o processamento, enquanto o tratador roda; e o presentation delay, até o próximo quadro ser "
        "pintado. O INP é o comprimento da barra inteira."))
    x0 = 60
    parts = [(120, T("input delay", "input delay"), "var(--panel)", "var(--wire)"),
             (330, T("processing: the handlers", "processamento: os tratadores"), "var(--ink)", "var(--amber)"),
             (160, T("presentation", "apresentação"), "var(--panel)", "var(--phosphor)")]
    x = x0
    for w, label, fill, stroke in parts:
        c.rect(x, 60, w, 34, fill=fill, stroke=stroke, sw=1.6, rx=2)
        c.text(x + w / 2, 77, label, size=10.5, fill=stroke if stroke != "var(--wire)" else "var(--paper)")
        x += w
    c.line(x0, 50, x0, 104, stroke="var(--paper)")
    c.text(x0, 36, T("tap", "toque"), size=10.5)
    c.line(x, 50, x, 104, stroke="var(--phosphor)")
    c.text(x, 36, T("next paint", "próxima pintura"), size=10.5, fill="var(--phosphor)")
    c.line(x0, 124, x, 124, stroke="var(--paper-dim)")
    c.text((x0 + x) / 2, 140, T("INP: the whole of it, for the slowest interaction of the visit",
                                "INP: tudo isso, para a interação mais lenta da visita"), size=10, fill="var(--paper-dim)")
    c.caption = T("What a person waits for is the paint, not the end of the code.",
                  "O que a pessoa espera é a pintura, não o fim do código.")
    return c


def cls_windows(T):
    c = Canvas(720, 190, T(
        "Layout shifts along a timeline, each drawn as a bar whose height is its score. Shifts less than a second apart "
        "belong to the same window, and a window lasts five seconds at most. Two windows are drawn; CLS is the total of "
        "the worse one.",
        "Deslocamentos de layout ao longo de uma linha do tempo, cada um desenhado como uma barra cuja altura é a sua "
        "nota. Deslocamentos a menos de um segundo um do outro pertencem à mesma janela, e uma janela dura no máximo "
        "cinco segundos. Duas janelas estão desenhadas; o CLS é o total da pior."))
    base, x0, s = 140, 40, 60  # s pixels per second
    c.line(x0, base, x0 + 650, base, stroke="var(--paper-dim)", arrow=True)
    c.text(x0 + 650, base + 18, T("seconds", "segundos"), anchor="end", size=9.5, fill="var(--paper-dim)")
    shifts = [(0.6, 30), (1.1, 18), (1.8, 40), (6.4, 22), (7.0, 12)]
    for t, h in shifts:
        c.rect(x0 + t * s - 5, base - h, 10, h, fill="var(--amber)", stroke="var(--amber)", rx=1)
    c.rect(x0 + 0.4 * s, 40, 1.7 * s, 105, fill="none", stroke="var(--phosphor)", dash="4 3")
    c.text(x0 + 1.25 * s, 30, T("window 1: the worst", "janela 1: a pior"), size=10, fill="var(--phosphor)")
    c.rect(x0 + 6.2 * s, 60, 1.1 * s, 85, fill="none", stroke="var(--wire)", dash="4 3")
    c.text(x0 + 6.75 * s, 50, T("window 2", "janela 2"), size=10, fill="var(--paper-dim)")
    for sec in range(0, 11, 2):
        c.text(x0 + sec * s, base + 16, str(sec), size=9, mono=True, fill="var(--paper-dim)")
    c.text(x0 + 4 * s, 90, T("more than a second with no shift ends a window", "mais de um segundo sem deslocamento fecha uma janela"),
           size=9.5, fill="var(--paper-dim)")
    c.caption = T("CLS is the worst burst of movement, not the sum of every shift the page ever made.",
                  "O CLS é a pior rajada de movimento, não a soma de todo deslocamento que a página já fez.")
    return c


def notice_runs(T):
    c = Canvas(720, 220, T(
        f"Three measurements of the course page on a phone-sized window with every request 300 ms slower. As it was: "
        f"LCP {LCP_RUNS[0][0]} ms and CLS {LCP_RUNS[0][1]}. With room kept for the notice: LCP {LCP_RUNS[1][0]} ms and CLS "
        f"{LCP_RUNS[1][1]}. With the notice sent by the server: LCP {LCP_RUNS[2][0]} ms and CLS {LCP_RUNS[2][1]}.",
        f"Três medidas da página de curso numa janela do tamanho de um celular, com cada requisição 300 ms mais lenta. "
        f"Como estava: LCP {LCP_RUNS[0][0]} ms e CLS {LCP_RUNS[0][1]}. Com espaço guardado para o aviso: LCP "
        f"{LCP_RUNS[1][0]} ms e CLS {LCP_RUNS[1][1]}. Com o aviso mandado pelo servidor: LCP {LCP_RUNS[2][0]} ms e CLS "
        f"{LCP_RUNS[2][1]}."))
    labels = [T("as it was", "como estava"), T("room kept", "espaço guardado"), T("sent by the server", "mandado pelo servidor")]
    x0, scale = 200, 330 / 1000
    for i, ((lcp, cls), label) in enumerate(zip(LCP_RUNS, labels)):
        y = 40 + i * 56
        c.text(x0 - 12, y + 12, label, anchor="end", size=11)
        good = i == 2
        c.rect(x0, y, lcp * scale, 24, fill="var(--ink)", stroke="var(--phosphor)" if good else "var(--amber)", rx=2)
        c.text(x0 + lcp * scale + 8, y + 12, f"LCP {lcp} ms · CLS {cls}", anchor="start", size=10, mono=True,
               fill="var(--paper)")
    c.text(x0, 205, T("LCP, the bar; CLS beside it", "LCP, a barra; CLS ao lado"), anchor="start", size=10, fill="var(--paper-dim)")
    c.caption = T("Keeping room stopped the movement; sending the notice with the page brought it forward.",
                  "Guardar espaço parou o movimento; mandar o aviso com a página o trouxe para a frente.")
    return c


def inp_runs(T):
    c = Canvas(720, 230, T(
        f"Three measurements of the same click on All courses, with five thousand courses and the processor four times "
        f"slower. As it was: INP {INP_RUNS[0][0]} ms, of which {INP_RUNS[0][2]} processing. Counting once: "
        f"{INP_RUNS[1][0]} ms, {INP_RUNS[1][2]} processing. Drawing a hundred courses: {INP_RUNS[2][0]} ms.",
        f"Três medidas do mesmo clique em All courses, com cinco mil cursos e o processador quatro vezes mais lento. Como "
        f"estava: INP {INP_RUNS[0][0]} ms, dos quais {INP_RUNS[0][2]} de processamento. Contando uma vez: "
        f"{INP_RUNS[1][0]} ms, {INP_RUNS[1][2]} de processamento. Desenhando cem cursos: {INP_RUNS[2][0]} ms."))
    labels = [T("as it was", "como estava"), T("count once", "contar uma vez"), T("draw a hundred", "desenhar cem")]
    x0, scale = 160, 460 / 2000
    for i, ((total, inp, proc, pres), label) in enumerate(zip(INP_RUNS, labels)):
        y = 40 + i * 52
        c.text(x0 - 12, y + 12, label, anchor="end", size=11)
        x = x0
        for w, fill, stroke in ((inp, "var(--panel)", "var(--wire)"), (proc, "var(--ink)", "var(--amber)"),
                                (pres, "var(--panel)", "var(--phosphor)")):
            if w * scale >= 1:
                c.rect(x, y, w * scale, 24, fill=fill, stroke=stroke, rx=1)
            x += w * scale
        c.text(x0 + total * scale + 8, y + 12, f"{total} ms", anchor="start", size=10.5, mono=True)
    c.line(x0 + 200 * scale, 30, x0 + 200 * scale, 186, stroke="var(--phosphor)", dash="3 3")
    c.text(x0 + 200 * scale + 4, 200, T("200 ms: good", "200 ms: bom"), anchor="start", size=10, fill="var(--phosphor)")
    c.rect(x0 + 260, 194, 12, 12, fill="var(--ink)", stroke="var(--amber)")
    c.text(x0 + 278, 200, T("processing", "processamento"), anchor="start", size=10, fill="var(--amber)")
    c.rect(x0 + 380, 194, 12, 12, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(x0 + 398, 200, T("presentation", "apresentação"), anchor="start", size=10, fill="var(--phosphor)")
    c.caption = T("The first fix removed work nobody needed; the second, work nobody would have seen.",
                  "A primeira correção tirou trabalho de que ninguém precisava; a segunda, trabalho que ninguém veria.")
    return c


FIGURES = [
    ("inp", inp_parts),
    ("cls", cls_windows),
    ("a-layout-shift", notice_runs),
    ("a-slow-interaction", inp_runs),
]
