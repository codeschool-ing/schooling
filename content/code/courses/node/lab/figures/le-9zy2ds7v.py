from fig import Canvas


def decides(T):
    c = Canvas(720, 250, T(
        "How Node decides what a file is. A .mjs file is an ES module and a .cjs file is CommonJS. "
        "For a .js file, Node finds the nearest package.json: \"type\": \"module\" makes it an ES module; "
        "any other package.json makes it CommonJS; with no package.json at all, Node detects the syntax.",
        "Como o Node decide o que um arquivo é. Um arquivo .mjs é ES module e um .cjs é CommonJS. "
        "Para um .js, o Node procura o package.json mais próximo: \"type\": \"module\" faz dele um ES module; "
        "qualquer outro package.json faz dele CommonJS; sem package.json nenhum, o Node detecta a sintaxe."))
    def box(x, y, w, h, lines, stroke="var(--wire)", fill="var(--panel)"):
        c.rect(x, y, w, h, fill=fill, stroke=stroke)
        n = len(lines)
        for i, (t, mono, col) in enumerate(lines):
            c.text(x + w / 2, y + h / 2 + (i - (n - 1) / 2) * 16, t, mono=mono, size=10.5, fill=col)
    box(20, 95, 110, 50, [(T("the file", "o arquivo"), False, "var(--paper)")])
    box(180, 20, 140, 40, [(".mjs", True, "var(--paper)")])
    box(180, 100, 140, 40, [(".js", True, "var(--paper)")])
    box(180, 180, 140, 40, [(".cjs", True, "var(--paper)")])
    for y in (40, 120, 200):
        c.line(130, 120, 178, y, stroke="var(--paper-dim)", arrow=True)
    box(380, 85, 150, 70, [(T("nearest", "package.json"), False, "var(--paper)"), ("package.json", True, "var(--paper)")])
    c.line(320, 120, 378, 120, stroke="var(--paper-dim)", arrow=True)
    box(580, 14, 120, 52, [(T("ES module", "ES module"), False, "var(--phosphor)")], stroke="var(--phosphor)", fill="var(--ink)")
    box(580, 176, 120, 52, [("CommonJS", False, "var(--amber)")], stroke="var(--amber)", fill="var(--ink)")
    c.line(320, 40, 578, 40, stroke="var(--phosphor)", arrow=True)
    c.line(320, 200, 578, 200, stroke="var(--amber)", arrow=True)
    c.line(530, 100, 578, 52, stroke="var(--phosphor)", arrow=True)
    c.text(562, 92, '"type": "module"', mono=True, size=9.5, fill="var(--phosphor)", anchor="start")
    c.line(530, 140, 578, 188, stroke="var(--amber)", arrow=True)
    c.text(562, 150, T("anything else", "qualquer outro"), size=9.5, fill="var(--amber)", anchor="start")
    c.text(455, 172, T("none at all: detect the syntax", "nenhum: detecta a sintaxe"), size=9.5, fill="var(--paper-dim)")
    c.caption = T("The extension wins. Only a plain .js asks the package.json, and every project in this course says \"type\": \"module\".",
                  "A extensão vence. Só um .js comum pergunta ao package.json, e todo projeto deste curso diz \"type\": \"module\".")
    return c


def walk(T):
    c = Canvas(720, 260, T(
        "Nested folders, from / down to /home/ana/server/modules/pkg, which holds the file that calls require(\"tidy\"). "
        "Node looks for a node_modules folder in pkg first, then in each parent in turn, up to /, and stops at the first one that has tidy.",
        "Pastas aninhadas, de / até /home/ana/server/modules/pkg, onde está o arquivo que chama require(\"tidy\"). "
        "O Node procura uma pasta node_modules primeiro em pkg, depois em cada pasta acima, até /, e para na primeira que tiver tidy."))
    names = ["/", "/home", "/home/ana", "/home/ana/server", "~/server/modules", "~/server/modules/pkg"]
    for i, n in enumerate(names):
        x, y = 20 + i * 22, 14 + i * 34
        w, h = 680 - i * 44, 232 - i * 34
        c.rect(x, y, w, h, fill="var(--panel)" if i % 2 == 0 else "var(--ink)", stroke="var(--wire)")
        c.text(x + 10, y + 13, n, mono=True, size=10, anchor="start", fill="var(--paper-dim)")
    x0, y0 = 20 + 5 * 22, 14 + 5 * 34
    c.rect(x0 + 16, y0 + 26, 150, 24, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(x0 + 91, y0 + 38, 'require("tidy")', mono=True, size=10, fill="var(--phosphor)")
    for i in range(6):
        y = 14 + (5 - i) * 34 + 13
        c.text(560 - 0, y, f"{i + 1}. node_modules/tidy ?", mono=True, size=9.5, anchor="end", fill="var(--amber)" if i == 0 else "var(--paper-dim)")
    c.caption = T("One folder at a time, from the file outwards. The first node_modules that has the package wins.",
                  "Uma pasta de cada vez, do arquivo para fora. A primeira node_modules que tiver o pacote vence.")
    return c


FIGURES = [("how-node-decides", decides), ("finding-a-module", walk)]
