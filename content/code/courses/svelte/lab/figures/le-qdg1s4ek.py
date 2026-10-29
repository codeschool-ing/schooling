from fig import Canvas


def flipfig(T):
    c = Canvas(720, 250, T(
        "The four steps of FLIP for the 24th when a session on the 21st is added above it. First: the 24th's row is "
        "measured in the second place. Last: the list is updated, the 21st is inserted, and the 24th is measured again "
        "in the third place. Invert: a transform draws the 24th back where it was. Play: the transform is animated "
        "away, and the row glides down into its new place.",
        "Os quatro passos do FLIP para o dia 24 quando uma sessão do dia 21 é acrescentada acima dele. First: a linha do "
        "24 é medida no segundo lugar. Last: a lista é atualizada, o 21 é inserido, e o 24 é medido de novo no terceiro "
        "lugar. Invert: um transform desenha o 24 de volta onde estava. Play: o transform é animado até sumir, e a linha "
        "desliza para o seu lugar novo."))
    steps = [("First", T("measure", "medir"), [("19", 0), ("24", 1)], None),
             ("Last", T("update, measure", "atualizar, medir"), [("19", 0), ("21", 1), ("24", 2)], None),
             ("Invert", T("draw it back", "desenhar de volta"), [("19", 0), ("24", 1)], "up"),
             ("Play", T("animate to place", "animar até o lugar"), [("19", 0), ("21", 1), ("24", 2)], "down")]
    for i, (name, sub, rows, arrow) in enumerate(steps):
        x = 20 + i * 175
        c.text(x + 75, 22, name, mono=True, size=11.5, weight="600", fill="var(--amber)")
        c.text(x + 75, 42, sub, size=10, fill="var(--paper-dim)")
        for label, slot in rows:
            y = 60 + slot * 46
            hl = label == "24"
            c.rect(x, y, 150, 36, fill="var(--ink)" if hl else "var(--panel)",
                   stroke="var(--phosphor)" if hl else "var(--wire)", dash="4 3" if (hl and arrow == "up") else None)
            c.text(x + 75, y + 18, f"{label} Oct", size=10.5, fill="var(--phosphor)" if hl else "var(--paper)")
        if arrow == "down":
            c.line(x + 160, 120, x + 160, 158, stroke="var(--phosphor)", arrow=True)
        if arrow == "up":
            c.text(x + 75, 160, "translateY(-46px)", mono=True, size=9.5, fill="var(--phosphor)")
            c.text(x + 75, 182, T("over the 21st, sliding in", "sobre o 21, que entra"), size=9.5, fill="var(--paper-dim)")
    c.text(360, 232, T("the DOM changes once; only the drawing travels", "o DOM muda uma vez; só o desenho viaja"),
           size=10, fill="var(--paper-dim)")
    c.caption = T("FLIP: measure, change, draw it back where it was, then let it go.",
                  "FLIP: medir, mudar, desenhar de volta onde estava, e soltar.")
    return c


def easing(T):
    c = Canvas(720, 260, T(
        "Three easing curves, plotted as progress against time from 0 to 1. linear is a straight diagonal. cubicOut rises "
        "steeply at first and flattens as it reaches 1, arriving gently. cubicIn starts flat and rises steeply at the end, "
        "leaving abruptly.",
        "Três curvas de easing, desenhadas como progresso contra tempo, de 0 a 1. linear é uma diagonal reta. cubicOut sobe "
        "rápido no começo e se achata ao chegar a 1, chegando suave. cubicIn começa plano e sobe rápido no fim, saindo "
        "de repente."))
    curves = [("linear", lambda t: t, "var(--paper-dim)"),
              ("cubicOut", lambda t: 1 - (1 - t) ** 3, "var(--phosphor)"),
              ("cubicIn", lambda t: t ** 3, "var(--amber)")]
    for i, (name, f, col) in enumerate(curves):
        x0, y0, w, h = 40 + i * 225, 30, 180, 180
        c.rect(x0, y0, w, h, fill="var(--panel)", stroke="var(--wire)")
        pts = " ".join(f"{'M' if k == 0 else 'L'}{x0 + w * k / 40:.1f} {y0 + h - h * f(k / 40):.1f}" for k in range(41))
        c.path(pts, stroke=col, sw=2)
        c.text(x0 + w / 2, y0 + h + 20, name, mono=True, size=11, fill=col)
        c.text(x0 - 8, y0 + h, "0", mono=True, size=9, anchor="end", fill="var(--paper-dim)")
        c.text(x0 - 8, y0, "1", mono=True, size=9, anchor="end", fill="var(--paper-dim)")
    c.text(360, 252, T("across: time; up: how far the animation has got", "na horizontal: tempo; na vertical: quanto a animação avançou"),
           size=10, fill="var(--paper-dim)")
    c.caption = T("The same duration, three ways of spending it.", "A mesma duração, três jeitos de gastá-la.")
    return c


FIGURES = [("flip", flipfig), ("custom-transition", easing)]
