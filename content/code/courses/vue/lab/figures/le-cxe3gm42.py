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


FIGURES = [("choosing", timelines)]
