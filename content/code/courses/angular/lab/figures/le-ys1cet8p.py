from fig import Canvas


def marbles(T):
    c = Canvas(720, 250, T(
        "A marble diagram with four lines, time running left to right. interval(100) emits 0, 1, 2, 3 and 4, "
        "one every tenth of a second. After map(n => n * 10): 0, 10, 20, 30, 40, at the same moments. After "
        "filter(n => n % 20 === 0): 0, 20 and 40; 10 and 30 are gone. After take(3): 0, 20 and 40, and a bar "
        "where the chain completes, at the moment 40 arrives.",
        "Um diagrama de bolinhas com quatro linhas, o tempo correndo da esquerda para a direita. interval(100) "
        "emite 0, 1, 2, 3 e 4, um a cada décimo de segundo. Depois de map(n => n * 10): 0, 10, 20, 30, 40, nos "
        "mesmos momentos. Depois de filter(n => n % 20 === 0): 0, 20 e 40; o 10 e o 30 somem. Depois de "
        "take(3): 0, 20 e 40, e uma barra onde a cadeia termina, no momento em que o 40 chega."))
    rows = [("interval(100)", [0, 1, 2, 3, 4], False, "var(--wire)"),
            ("map(n => n * 10)", [0, 10, 20, 30, 40], False, "var(--wire)"),
            ("filter(n => n % 20 === 0)", [0, None, 20, None, 40], False, "var(--wire)"),
            ("take(3)", [0, None, 20, None, 40], True, "var(--phosphor)")]
    x0, dx = 330, 70
    for r, (label, vals, done, col) in enumerate(rows):
        y = 40 + r * 52
        c.text(20, y, label, size=10, mono=True, anchor="start")
        end = x0 + 4 * dx + 60 if not done else x0 + 4 * dx
        c.line(x0 - 30, y, end, y, stroke="var(--paper-dim)", arrow=not done)
        if done:
            c.line(x0 + 4 * dx + 18, y - 12, x0 + 4 * dx + 18, y + 12, stroke="var(--phosphor)", sw=2)
        for i, v in enumerate(vals):
            if v is None:
                continue
            x = x0 + i * dx
            c.rect(x - 14, y - 12, 28, 24, rx=12, fill="var(--panel)", stroke=col)
            c.text(x, y, str(v), size=10, mono=True)
    c.text(x0 + 4 * dx + 30, 40 + 3 * 52 + 22, T("complete", "fim"), size=9, anchor="start", fill="var(--phosphor)")
    c.text(x0 + 2 * dx, 232, T("time →", "tempo →"), size=9.5, fill="var(--paper-dim)")
    c.caption = T("Each line is what one stage lets through; take(3) ends the chain at the third value, which stops interval too.",
                  "Cada linha é o que uma etapa deixa passar; o take(3) termina a cadeia no terceiro valor, o que para o interval também.")
    return c


FIGURES = [("operators", marbles)]
