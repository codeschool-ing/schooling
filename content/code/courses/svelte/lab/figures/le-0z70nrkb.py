from fig import Canvas


def where(T):
    c = Canvas(720, 330, T(
        "Two rows, each split between the server on the left and the browser on the right. First visit: on the server, "
        "the layout's server load runs, then the page's universal load, then the page is rendered to HTML; the HTML "
        "goes to the browser with the data written into it, and the browser runs the universal load again while "
        "hydrating. A click on a link: everything happens in the browser, where the universal load runs and the page "
        "renders; the server is asked for the server load's data at __data.json only if that data is out of date.",
        "Duas linhas, cada uma dividida entre o servidor à esquerda e o navegador à direita. Primeira visita: no "
        "servidor, roda o load de servidor do layout, depois o load universal da página, depois a página é renderizada "
        "em HTML; o HTML vai para o navegador com os dados escritos nele, e o navegador roda o load universal de novo "
        "durante a hidratação. Um clique num link: tudo acontece no navegador, onde o load universal roda e a página "
        "renderiza; o servidor só é consultado em __data.json se os dados do load de servidor estiverem desatualizados."))
    c.text(185, 18, T("server", "servidor"), size=11, weight="600", fill="var(--amber)")
    c.text(545, 18, T("browser", "navegador"), size=11, weight="600", fill="var(--phosphor)")
    c.line(360, 30, 360, 300, stroke="var(--wire)", dash="3 4")
    for row, (label, y) in enumerate([(T("first visit", "primeira visita"), 40), (T("a click on a link", "um clique num link"), 180)]):
        c.text(20, y + 6, label, size=10.5, weight="600", anchor="start")
    # row 1 server
    boxes1 = [(40, "+layout.server.js", "load"), (145, "+page.js", "load"), (250, T("render", "renderiza"), "HTML")]
    for x, a, b in boxes1:
        x0, w = (22, 115) if x == 40 else (x, 95)
        c.rect(x0, 60, w, 46, fill="var(--panel)", stroke="var(--amber)")
        c.text(x0 + w / 2, 77, a, mono=a.startswith("+"), size=9.5)
        c.text(x0 + w / 2, 94, b, mono=True, size=9.5, fill="var(--paper-dim)")
    c.line(137, 83, 143, 83, stroke="var(--paper-dim)", arrow=True)
    c.line(240, 83, 248, 83, stroke="var(--paper-dim)", arrow=True)
    c.line(345, 83, 398, 83, stroke="var(--paper-dim)", arrow=True)
    c.text(372, 120, T("HTML + data", "HTML + dados"), size=9.5, fill="var(--paper-dim)")
    c.rect(400, 60, 130, 46, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(465, 77, "+page.js", mono=True, size=9.5)
    c.text(465, 94, T("load, again", "load, de novo"), size=9.5, fill="var(--phosphor)")
    c.line(530, 83, 568, 83, stroke="var(--paper-dim)", arrow=True)
    c.rect(570, 60, 130, 46, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(635, 77, T("hydration", "hidratação"), size=9.5)
    c.text(635, 94, T("the page comes alive", "a página ganha vida"), size=9, fill="var(--paper-dim)")
    # row 2
    c.rect(400, 200, 130, 46, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(465, 217, "+page.js", mono=True, size=9.5)
    c.text(465, 234, "load", mono=True, size=9.5, fill="var(--paper-dim)")
    c.line(530, 223, 568, 223, stroke="var(--paper-dim)", arrow=True)
    c.rect(570, 200, 130, 46, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(635, 217, T("render", "renderiza"), size=9.5)
    c.text(635, 234, T("the new page", "a página nova"), size=9, fill="var(--paper-dim)")
    c.rect(40, 200, 200, 46, fill="var(--panel)", stroke="var(--amber)", dash="4 3")
    c.text(140, 217, "+layout.server.js", mono=True, size=9.5)
    c.text(140, 234, T("only if its data is out of date", "só se os dados estiverem velhos"), size=9, fill="var(--paper-dim)")
    c.line(240, 223, 398, 223, stroke="var(--paper-dim)", dash="4 3", arrow=True)
    c.text(320, 212, "__data.json", mono=True, size=9.5, fill="var(--paper-dim)")
    c.text(360, 290, T("the universal load runs on both sides; the server load only ever on the left",
                       "o load universal roda dos dois lados; o de servidor, só do lado esquerdo"),
           size=10, fill="var(--paper-dim)")
    c.caption = T("A universal load runs on the server for the first page, again in the browser to hydrate it, and "
                  "only in the browser after that. A server load never leaves the server.",
                  "Um load universal roda no servidor para a primeira página, de novo no navegador para hidratá-la, e só "
                  "no navegador depois disso. Um load de servidor nunca sai do servidor.")
    return c


FIGURES = [("where-it-runs", where)]
