from fig import Canvas


def sizes(T):
    c = Canvas(720, 250, T(
        "A bar chart of the compressed JavaScript each framework's production build sends for the same counter: "
        "Svelte 10.22 kB, Vue 24.63 kB, Angular 29.06 kB, React 68.68 kB. The Svelte bar is about a seventh as long "
        "as the React one.",
        "Um gráfico de barras do JavaScript comprimido que o build de produção de cada framework manda para o mesmo "
        "contador: Svelte 10,22 kB, Vue 24,63 kB, Angular 29,06 kB, React 68,68 kB. A barra do Svelte tem cerca de um "
        "sétimo do comprimento da do React."))
    rows = [("Svelte 5.57", 10.22), ("Vue 3.5", 24.63), ("Angular 21.2", 29.06), ("React 19.3", 68.68)]
    x0, scale = 150, 7.5
    for k, (name, kb) in enumerate(rows):
        y = 30 + k * 46
        c.text(x0 - 12, y + 15, name, size=10.5, anchor="end")
        c.rect(x0, y, kb * scale, 30, fill="var(--phosphor)" if k == 0 else "var(--paper-dim)",
               stroke="var(--phosphor)" if k == 0 else "var(--paper-dim)", rx=2)
        label = T(f"{kb:.2f} kB", f"{kb:.2f} kB".replace(".", ","))
        c.text(x0 + kb * scale + 8, y + 15, label, size=10, anchor="start")
    c.text(360, 232, T("gzip, one counter, a production build with each framework's usual tools",
                       "gzip, um contador, build de produção com as ferramentas de costume de cada framework"),
           size=10, fill="var(--paper-dim)")
    c.caption = T("Almost all of each bar is the framework's runtime, not the counter.",
                  "Quase toda barra é o runtime do framework, não o contador.")
    return c


def models(T):
    c = Canvas(720, 300, T(
        "Four rows, one per framework, showing what happens after minutes changes. Svelte: the signal runs the one "
        "effect that sets the paragraph's text. Vue: the ref marks the component that read it, the component's render "
        "function runs again, and its virtual DOM is compared to find the text. React: the whole component function "
        "runs again, and the new virtual DOM is compared with the old one to find the text. Angular: the signal marks "
        "the component that read it, and Angular checks that component's template and updates the text.",
        "Quatro linhas, uma por framework, mostrando o que acontece depois que minutes muda. Svelte: o signal roda o "
        "único efeito que define o texto do parágrafo. Vue: o ref marca o componente que o leu, a função de render do "
        "componente roda de novo, e o virtual DOM dela é comparado para achar o texto. React: a função do componente "
        "inteira roda de novo, e o virtual DOM novo é comparado com o antigo para achar o texto. Angular: o signal "
        "marca o componente que o leu, e o Angular confere o template desse componente e atualiza o texto."))
    rows = [
        ("Svelte", [T("signal", "signal"), T("the one effect", "o único efeito")]),
        ("Vue", [T("ref marks a component", "ref marca o componente"), T("render again", "render de novo"), T("compare vDOM", "comparar vDOM")]),
        ("React", [T("run the function again", "rodar a função de novo"), T("compare vDOM", "comparar vDOM")]),
        ("Angular", [T("signal marks a component", "signal marca o componente"), T("check its template", "conferir o template")]),
    ]
    for k, (name, steps) in enumerate(rows):
        y = 26 + k * 62
        c.text(20, y + 20, name, size=11, weight="600", anchor="start", fill="var(--amber)")
        c.text(110, y + 20, "minutes += 30", mono=True, size=9.5, anchor="start", fill="var(--paper-dim)")
        x = 220
        for i, step in enumerate(steps):
            c.rect(x, y, 122, 40, fill="var(--panel)", stroke="var(--wire)")
            c.text(x + 61, y + 20, step, size=9)
            c.line(x - 18, y + 20, x - 2, y + 20, stroke="var(--paper-dim)", arrow=True)
            x += 138
        c.rect(x, y, 60, 40, fill="var(--ink)", stroke="var(--phosphor)")
        c.text(x + 30, y + 20, "<p>", mono=True, size=10, fill="var(--phosphor)")
        c.line(x - 18, y + 20, x - 2, y + 20, stroke="var(--paper-dim)", arrow=True)
    c.text(360, 290, T("fewer steps is less work in the browser, and all four are fast enough for the planner",
                       "menos passos é menos trabalho no navegador, e os quatro são rápidos o bastante para o planner"),
           size=10, fill="var(--paper-dim)")
    c.caption = T("The same change, and the path each framework takes from it to the paragraph.",
                  "A mesma mudança, e o caminho que cada framework faz dela até o parágrafo.")
    return c


FIGURES = [("four-counters", sizes), ("how-they-update", models)]
