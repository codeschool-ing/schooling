from fig import Canvas


def update(T):
    c = Canvas(720, 200, T(
        "Two versions of the worker along time. Version 1 controls the open tabs. Version 2 is found, installs, and "
        "then waits while any tab controlled by version 1 is open. When the last one closes, version 2 activates, "
        "deletes version 1's cache, and controls the pages opened after.",
        "Duas versões do worker ao longo do tempo. A versão 1 controla as abas abertas. A versão 2 é achada, instala, "
        "e espera enquanto houver alguma aba controlada pela versão 1 aberta. Quando a última fecha, a versão 2 ativa, "
        "apaga o cache da versão 1, e controla as páginas abertas depois."))
    x0 = 120
    c.text(x0 - 12, 62, T("version 1", "versão 1"), anchor="end", size=10.5)
    c.rect(x0, 50, 380, 24, fill="var(--ink)", stroke="var(--phosphor)", rx=2)
    c.text(x0 + 190, 62, T("controls the open tabs", "controla as abas abertas"), size=10, fill="var(--phosphor)")
    c.text(x0 - 12, 112, T("version 2", "versão 2"), anchor="end", size=10.5)
    for a, b, label, fill, stroke, dash in ((120, 80, "install", "var(--panel)", "var(--wire)", None),
                                            (200, 300, T("waiting", "esperando"), "var(--panel)", "var(--amber)", "4 3"),
                                            (500, 90, "activate", "var(--ink)", "var(--phosphor)", None)):
        c.rect(x0 + a, 100, b, 24, fill=fill, stroke=stroke, rx=2, dash=dash)
        c.text(x0 + a + b / 2, 112, label, size=10, mono=label in ("install", "activate"),
               fill=stroke if stroke != "var(--wire)" else "var(--paper)")
    c.line(x0 + 120, 40, x0 + 120, 150, stroke="var(--paper-dim)", dash="3 3")
    c.text(x0 + 120, 166, T("/sw.js differs", "o /sw.js mudou"), size=10, fill="var(--paper-dim)")
    c.line(x0 + 500, 40, x0 + 500, 150, stroke="var(--paper-dim)", dash="3 3")
    c.text(x0 + 500, 166, T("the last tab closes", "a última aba fecha"), size=10, fill="var(--paper-dim)")
    c.text(x0 + 545, 186, T("planner-v1 deleted", "planner-v1 apagado"), size=9.5, mono=False, fill="var(--paper-dim)")
    c.caption = T("A new worker waits for the old one's pages to go.",
                  "Um worker novo espera as páginas do antigo irem embora.")
    return c


FIGURES = [
    ("a-new-version", update),
]
