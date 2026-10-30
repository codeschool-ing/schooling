from fig import Canvas


def two_ways(T):
    c = Canvas(720, 250, T(
        "Two diagrams side by side. On the left, tracked reads, as Angular, Vue and Svelte do it: a tick "
        "changes the state, an arrow goes to the two derived values that read it, and from them to the one "
        "paragraph that reads those; the heading and the rest are untouched. On the right, React: a tick "
        "changes the state, the whole component function runs again, its result is compared with the last "
        "one, and the difference is written to the page.",
        "Dois diagramas lado a lado. À esquerda, leituras rastreadas, como fazem Angular, Vue e Svelte: uma "
        "marcação muda o estado, uma seta vai aos dois valores derivados que o leem, e deles ao único "
        "parágrafo que os lê; o título e o resto ficam intocados. À direita, o React: uma marcação muda o "
        "estado, a função inteira do componente roda de novo, o resultado é comparado com o anterior, e a "
        "diferença é escrita na página."))
    c.text(175, 22, T("Angular, Vue, Svelte: tracked reads", "Angular, Vue, Svelte: leituras rastreadas"), size=10.5)
    c.text(545, 22, T("React: run again, compare", "React: rodar de novo, comparar"), size=10.5)
    c.line(360, 14, 360, 236, dash="3 3")
    # left
    c.rect(115, 44, 120, 34, stroke="var(--amber)")
    c.text(175, 61, T("state", "estado"), size=10)
    for x, label in ((40, "planned"), (190, "done")):
        c.rect(x, 110, 120, 34, stroke="var(--phosphor)")
        c.text(x + 60, 127, label, size=10, mono=True)
    c.line(160, 80, 110, 106, arrow=True)
    c.line(190, 80, 240, 106, arrow=True)
    c.rect(100, 176, 150, 34, stroke="var(--phosphor)")
    c.text(175, 193, T("the paragraph", "o parágrafo"), size=10)
    c.line(100, 146, 150, 172, arrow=True)
    c.line(250, 146, 200, 172, arrow=True)
    c.text(175, 228, T("the heading is not touched", "o título não é tocado"), size=9.5, fill="var(--paper-dim)")
    # right
    steps = [(44, T("state", "estado"), "var(--amber)"),
             (98, T("the whole function runs", "a função inteira roda"), "var(--phosphor)"),
             (152, T("compared with the last result", "comparada com o resultado anterior"), "var(--phosphor)"),
             (206, T("the difference is written", "a diferença é escrita"), "var(--phosphor)")]
    for y, label, col in steps:
        c.rect(430, y, 230, 30, stroke=col)
        c.text(545, y + 15, label, size=10)
    for y in (74, 128, 182):
        c.line(545, y, 545, y + 22, arrow=True)
    c.caption = T("The same tick, two ways to find what changed: follow who read the value, or run the component again and compare.",
                  "A mesma marcação, dois jeitos de achar o que mudou: seguir quem leu o valor, ou rodar o componente de novo e comparar.")
    return c


FIGURES = [("what-runs-again", two_ways)]
