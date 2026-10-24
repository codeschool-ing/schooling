from fig import Canvas


def timelines(T):
    c = Canvas(720, 250, T(
        "Three timelines of one visit, left to right. Client-side rendering: the HTML arrives empty, the "
        "script is downloaded and runs, the data is fetched, and only then is the page drawn and usable. "
        "Server-side rendering: the server renders the page for the request, the HTML arrives drawn and is "
        "readable at once, then the script downloads and hydrates it, and only after that does it answer a "
        "click. Static generation: the page was rendered once at build time; the request is answered with "
        "the file, readable at once, and hydrated when the script has run.",
        "Três linhas do tempo de uma visita, da esquerda para a direita. Renderização no cliente: o HTML chega "
        "vazio, o script é baixado e roda, os dados são buscados, e só então a página é desenhada e pode ser "
        "usada. Renderização no servidor: o servidor renderiza a página para a requisição, o HTML chega "
        "desenhado e pode ser lido na hora, depois o script baixa e a hidrata, e só depois disso ela responde "
        "a um clique. Geração estática: a página foi renderizada uma vez, no build; a requisição é respondida "
        "com o arquivo, legível na hora, e hidratada quando o script rodou."))
    rows = [
        ("CSR", 40, [(T("empty HTML", "HTML vazio"), 110, "var(--panel)"), (T("script", "script"), 90, "var(--panel)"),
                     (T("data", "dados"), 80, "var(--panel)"), (T("drawn, usable", "desenhada, usável"), 150, "var(--phosphor-dim)")]),
        ("SSR", 110, [(T("server renders", "servidor renderiza"), 120, "var(--panel)"),
                      (T("drawn, readable", "desenhada, legível"), 150, "var(--scan)"),
                      (T("hydrated, usable", "hidratada, usável"), 160, "var(--phosphor-dim)")]),
        ("SSG", 180, [(T("file", "arquivo"), 70, "var(--panel)"),
                      (T("drawn, readable", "desenhada, legível"), 150, "var(--scan)"),
                      (T("hydrated, usable", "hidratada, usável"), 160, "var(--phosphor-dim)")]),
    ]
    for name, y, parts in rows:
        c.text(40, y + 16, name, mono=True, size=12, weight="600", fill="var(--amber)")
        x = 80
        for label, w, fill in parts:
            c.rect(x, y, w, 32, fill=fill, stroke="var(--wire)")
            c.text(x + w / 2, y + 16, label, size=10)
            x += w + 4
    c.line(80, 228, 690, 228, stroke="var(--wire)", arrow=True)
    c.text(385, 242, T("time since the click on the link", "tempo desde o clique no link"), size=10)
    c.caption = T("The server's modes put words on the screen sooner; the page answers a click only after "
                  "hydration in all of them.",
                  "Os modos do servidor põem palavras na tela mais cedo; em todos eles a página só responde a "
                  "um clique depois da hidratação.")
    return c


def two_clocks(T):
    c = Canvas(720, 255, T(
        "The same line, today equals isoDate of new Date, read on two clocks at the same moment. The server, in "
        "UTC, reads 02:30 on 22 October, so today is 2026-10-22 and it draws the highlight on the 22nd. The "
        "browser, in São Paulo, three hours behind, reads 23:30 on 21 October, so today is 2026-10-21 and it "
        "expects (today) on the 21st. Below, the page in production: Vue makes the missing element, so the 21st, "
        "Statistics, 60 minutes, says (today); and leaves the attribute alone, so the 22nd, Guitar, 20 minutes, "
        "keeps the server's highlight. Two todays.",
        "A mesma linha, today igual a isoDate de new Date, lida em dois relógios no mesmo instante. O servidor, em "
        "UTC, lê 02:30 de 22 de outubro, então today é 2026-10-22 e ele desenha o destaque no dia 22. O navegador, "
        "em São Paulo, três horas atrás, lê 23:30 de 21 de outubro, então today é 2026-10-21 e ele espera (today) no "
        "dia 21. Embaixo, a página em produção: o Vue cria o elemento que falta, então o dia 21, Statistics, 60 "
        "minutes, diz (today); e deixa o atributo como está, então o dia 22, Guitar, 20 minutes, fica com o destaque "
        "do servidor. Dois hojes."))
    sides = [(20, "var(--amber)", T("the server, in UTC", "o servidor, em UTC"), T("02:30 on 22 October", "02:30 de 22 de outubro"),
              "today = '2026-10-22'", T("highlights the 22nd", "destaca o dia 22")),
             (380, "var(--phosphor)", T("the browser, in São Paulo", "o navegador, em São Paulo"),
              T("23:30 on 21 October", "23:30 de 21 de outubro"), "today = '2026-10-21'",
              T("expects (today) on the 21st", "espera (today) no dia 21"))]
    for x, col, who, when, today, does in sides:
        c.rect(x, 20, 320, 100, fill="var(--ink)", stroke=col)
        c.text(x + 160, 38, who, size=11, weight="600", fill=col)
        c.text(x + 160, 60, when, size=10.5)
        c.text(x + 160, 82, today, mono=True, size=10.5, fill=col)
        c.text(x + 160, 104, does, size=10)
    c.text(360, 146, T("the page in production, at the same moment", "a página em produção, no mesmo instante"),
           size=10.5, fill="var(--paper-dim)")
    c.rect(20, 162, 370, 30, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(205, 177, "21 October 2026, Statistics, 60 minutes (today)", mono=True, size=9.5)
    c.text(402, 177, T("(today) made by the browser", "(today) criado pelo navegador"), size=10, anchor="start",
           fill="var(--phosphor)")
    c.rect(20, 204, 370, 30, fill="var(--scan)", stroke="var(--amber)")
    c.text(205, 219, "22 October 2026, Guitar, 20 minutes", mono=True, size=9.5)
    c.text(402, 219, T("highlight left by the server", "destaque deixado pelo servidor"), size=10, anchor="start",
           fill="var(--amber)")
    c.caption = T("Each side reads its own clock; in production the page keeps a piece of each answer.",
                  "Cada lado lê o próprio relógio; em produção a página fica com um pedaço de cada resposta.")
    return c


FIGURES = [("choosing", timelines), ("hydration-mismatch", two_clocks)]
