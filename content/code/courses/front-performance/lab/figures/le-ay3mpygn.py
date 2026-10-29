from fig import Canvas

# The build after the split, as Vite printed it, in kilobytes.
FILES = [("index", 19.85), ("planner", 0.52), ("chart", 132.39)]


def split(T):
    c = Canvas(720, 210, T(
        f"The three files of the split build and which page loads them. index, {FILES[0][1]} kilobytes, and planner, "
        f"{FILES[1][1]}, are loaded by every page. chart, {FILES[2][1]} kilobytes, is loaded only by the stats page, "
        "when its code asks for it.",
        f"Os três arquivos do build dividido e que página carrega cada um. O index, {FILES[0][1]} kilobytes, e o "
        f"planner, {FILES[1][1]}, são carregados por toda página. O chart, {FILES[2][1]} kilobytes, só é carregado "
        "pela página de estatísticas, quando o código dela o pede."))
    scale = 3.2
    x = 40
    spots = {}
    for name, kb in FILES:
        w = max(kb * scale, 34)
        lazy = name == "chart"
        c.rect(x, 40, w, 40, fill="var(--ink)" if lazy else "var(--panel)", stroke="var(--amber)" if lazy else "var(--phosphor)",
               rx=2, dash="4 3" if lazy else None)
        c.text(x + w / 2, 30, f"{name} · {kb} kB", size=10, mono=True, fill="var(--amber)" if lazy else "var(--paper)")
        spots[name] = x + w / 2
        x += w + 14
    c.text(150, 128, T("every page: the course page, the home page", "toda página: a de curso, a inicial"), size=10.5)
    c.line(spots["index"], 82, 150, 116, stroke="var(--phosphor)")
    c.line(spots["planner"], 82, 150, 116, stroke="var(--phosphor)")
    c.text(spots["chart"], 128, T("only /stats, after its import()", "só /stats, depois do import() dela"), size=10.5,
           fill="var(--amber)")
    c.line(spots["chart"], 82, spots["chart"], 116, stroke="var(--amber)", dash="4 3")
    c.text(360, 176, T("Before the split, all of it was one file, and every page loaded the chart.",
                       "Antes da divisão, tudo isso era um arquivo, e toda página carregava o gráfico."),
           size=10, fill="var(--paper-dim)")
    c.caption = T("The code a page does not use is no longer the page's to download.",
                  "O código que uma página não usa não é mais dela para baixar.")
    return c


FIGURES = [
    ("import-on-demand", split),
]
