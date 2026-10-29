from fig import Canvas


def swr(T):
    c = Canvas(720, 250, T(
        "A timeline of one page under incremental regeneration with an age of ten seconds. The build makes copy 1. "
        "Requests in the first ten seconds get copy 1. The data changes. The first request after ten seconds still "
        "gets copy 1 and starts a render in the background, which produces copy 2. The request after that gets copy 2.",
        "Uma linha do tempo de uma página sob regeneração incremental com idade de dez segundos. O build faz a cópia "
        "1. As requisições nos primeiros dez segundos recebem a cópia 1. Os dados mudam. A primeira requisição depois "
        "de dez segundos ainda recebe a cópia 1 e inicia uma renderização em segundo plano, que produz a cópia 2. A "
        "requisição seguinte recebe a cópia 2."))
    x0 = 60
    c.line(x0, 150, 690, 150, stroke="var(--paper-dim)", arrow=True)
    c.text(690, 168, T("time", "tempo"), anchor="end", size=9.5, fill="var(--paper-dim)")
    c.rect(x0, 120, 330, 24, fill="var(--panel)", stroke="var(--wire)")
    c.text(x0 + 165, 132, T("copy 1, fresh for 10 s", "cópia 1, fresca por 10 s"), size=10)
    c.rect(x0 + 330, 120, 120, 24, fill="var(--ink)", stroke="var(--amber)", dash="4 3")
    c.text(x0 + 390, 132, T("copy 1, stale", "cópia 1, velha"), size=10, fill="var(--amber)")
    c.rect(x0 + 450, 120, 180, 24, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(x0 + 540, 132, T("copy 2, fresh", "cópia 2, fresca"), size=10, fill="var(--phosphor)")
    c.line(x0 + 200, 40, x0 + 200, 116, stroke="var(--amber)", dash="3 3")
    c.text(x0 + 200, 30, T("the data changes", "os dados mudam"), size=10, fill="var(--amber)")
    for x, label, colour in ((x0 + 60, T("request: copy 1", "requisição: cópia 1"), "var(--paper)"),
                             (x0 + 260, T("request: copy 1", "requisição: cópia 1"), "var(--paper)"),
                             (x0 + 360, T("request: copy 1, starts a render", "requisição: cópia 1, inicia render"), "var(--amber)"),
                             (x0 + 560, T("request: copy 2", "requisição: cópia 2"), "var(--phosphor)")):
        c.line(x, 196, x, 152, stroke=colour, arrow=True)
    c.text(x0 + 60, 206, T("request: copy 1", "requisição: cópia 1"), size=9.5, fill="var(--paper)")
    c.text(x0 + 245, 206, T("request: copy 1", "requisição: cópia 1"), size=9.5, fill="var(--paper)")
    c.text(x0 + 375, 222, T("request: copy 1, starts a render", "requisição: cópia 1, inicia render"), size=9.5,
           fill="var(--amber)")
    c.text(x0 + 560, 206, T("request: copy 2", "requisição: cópia 2"), size=9.5, fill="var(--phosphor)")
    c.path(f"M {x0 + 370} 118 C {x0 + 400} 80, {x0 + 430} 80, {x0 + 450} 118", stroke="var(--phosphor)", dash="3 3")
    c.text(x0 + 410, 74, T("render in the background", "render em segundo plano"), size=9.5, fill="var(--phosphor)")
    c.caption = T("Nobody waits for a render, and the request that starts one is the last to see the old page.",
                  "Ninguém espera uma renderização, e a requisição que inicia uma é a última a ver a página velha.")
    return c


def build_time(T):
    data = [(100, 0.207, "0.207", "0,207"), (1000, 1.108, "1.108", "1,108"), (5000, 4.773, "4.773", "4,773")]
    c = Canvas(720, 200, T(
        "A bar chart of how long prerender.ts took for three sizes of site: 100 courses in "
        f"{data[0][2]} seconds, 1000 in {data[1][2]}, and 5000 in {data[2][2]}.",
        "Um gráfico de barras de quanto o prerender.ts levou para três tamanhos de site: 100 cursos em "
        f"{data[0][3]} segundo, 1000 em {data[1][3]}, e 5000 em {data[2][3]}."))
    x0, scale = 140, 480 / data[-1][1]
    for i, (n, s, en, pt) in enumerate(data):
        y = 30 + i * 44
        c.text(x0 - 10, y + 13, T(f"{n} courses", f"{n} cursos"), anchor="end", size=11)
        c.rect(x0, y, max(s * scale, 3), 26, fill="var(--ink)", stroke="var(--phosphor)", rx=2)
        c.text(x0 + max(s * scale, 3) + 8, y + 13, T(en + " s", pt + " s"), anchor="start", size=10.5,
               fill="var(--paper-dim)")
    c.line(x0, 170, x0 + 490, 170, stroke="var(--wire)")
    c.text(x0, 186, T("time to prerender every page, this computer", "tempo para pré-renderizar todas as páginas, neste computador"),
           anchor="start", size=10, fill="var(--paper-dim)")
    c.caption = T("Every page, every build: the time follows the number of pages, whatever changed.",
                  "Toda página, todo build: o tempo segue o número de páginas, mude o que mudar.")
    return c


FIGURES = [
    ("regeneration", swr),
    ("what-goes-stale", build_time),
]
