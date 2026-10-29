from fig import Canvas


def layers(T):
    c = Canvas(720, 230, T(
        "Three columns. Primitives: green-600 and green-300, grey-0 and grey-900. Semantic tokens in two themes: in "
        "light, accent is green-600 and surface is grey-0; in dark, accent is green-300 and surface is grey-900. "
        "Usage: the stylesheet gives a button the accent token as its background, and never names a primitive.",
        "Três colunas. Primitivos: green-600 e green-300, grey-0 e grey-900. Tokens semânticos em dois temas: no "
        "claro, accent é green-600 e surface é grey-0; no escuro, accent é green-300 e surface é grey-900. Uso: a "
        "folha de estilo dá a um botão o token accent como fundo, e nunca cita um primitivo."))
    c.text(20, 20, T("primitives", "primitivos"), anchor="start", size=10.5, weight="600")
    prims = [("green-600", "#2f6f4e"), ("green-300", "#7fbf9a"), ("grey-0", "#ffffff"), ("grey-900", "#16191d")]
    for i, (n, h) in enumerate(prims):
        y = 44 + i * 40
        c.rect(20, y - 14, 180, 28, fill="var(--panel)")
        c.text(32, y, n, mono=True, size=10, anchor="start")
        c.text(190, y, h, mono=True, size=9.5, anchor="end", fill="var(--paper-dim)")
    c.text(260, 20, T("semantic, per theme", "semânticos, por tema"), anchor="start", size=10.5, weight="600")
    sem = [(T("light", "claro"), [("accent", 0), ("surface", 2)], 30), (T("dark", "escuro"), [("accent", 1), ("surface", 3)], 120)]
    for title, rows, y0 in sem:
        c.rect(260, y0, 200, 80, fill="var(--ink)", stroke="var(--phosphor)")
        c.text(270, y0 + 14, title, anchor="start", size=9.5, fill="var(--paper-dim)")
        for j, (name, k) in enumerate(rows):
            y = y0 + 36 + j * 24
            c.text(272, y, name, mono=True, size=10, anchor="start", fill="var(--phosphor)")
            c.line(258, y, 202, 44 + k * 40, stroke="var(--wire)", dash="3 3")
    c.text(520, 20, T("the stylesheet", "a folha de estilo"), anchor="start", size=10.5, weight="600")
    c.rect(520, 60, 180, 100, fill="var(--panel)")
    c.text(532, 84, "button {", mono=True, size=10, anchor="start")
    c.text(544, 106, "background:", mono=True, size=10, anchor="start")
    # Drawn in two pieces, so the label is not read as a colour the figure asks for.
    c.text(556, 126, "var(", mono=True, size=10, anchor="start", fill="var(--phosphor)")
    c.text(580, 126, "--accent);", mono=True, size=10, anchor="start", fill="var(--phosphor)")
    c.text(532, 146, "}", mono=True, size=10, anchor="start")
    c.line(518, 110, 462, 70, stroke="var(--paper-dim)", arrow=True)
    c.line(518, 116, 462, 156, stroke="var(--paper-dim)", arrow=True)
    c.text(520, 196, T("names a meaning, never a paint", "cita um significado, nunca uma tinta"), anchor="start", size=10, fill="var(--paper-dim)")
    c.caption = T("Code names the semantic token; each theme decides which primitive that name points at.",
                  "O código cita o token semântico; cada tema decide para qual primitivo esse nome aponta.")
    return c


def scale(T):
    c = Canvas(720, 160, T(
        "The planner's five font sizes drawn side by side, each the one before it times 1.25: 1, 1.25, 1.563, 1.953 "
        "and 2.441 rem.",
        "Os cinco tamanhos de fonte do planner desenhados lado a lado, cada um o anterior vezes 1,25: 1, 1,25, "
        "1,563, 1,953 e 2,441 rem."))
    x = 30
    sizes = [1, 1.25, 1.563, 1.953, 2.441]
    for i, s in enumerate(sizes):
        px = 16 * s * 1.4
        c.text(x, 92, "Aa", size=round(px, 1), anchor="start")
        c.text(x, 128, f"--font-size-{i}", mono=True, size=9.5, anchor="start", fill="var(--paper-dim)")
        c.text(x, 146, f"{s} rem", mono=True, size=9.5, anchor="start", fill="var(--phosphor)")
        x += max(110, px * 1.6 + 30)
    c.text(30, 20, T("each step is the one before it × 1.25", "cada passo é o anterior × 1,25"), anchor="start", size=10.5, fill="var(--paper-dim)")
    c.caption = T("A type scale is a rule, not a list: change the ratio and every size moves in proportion.",
                  "Uma escala tipográfica é uma regra, não uma lista: mude a razão e todo tamanho se move na proporção.")
    return c


FIGURES = [("tokens", layers), ("a-type-scale", scale)]
