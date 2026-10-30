from fig import Canvas

# Read off this lesson's captures.
WEIGHTS = [("TBT", 30), ("LCP", 25), ("CLS", 25), ("FCP", 10), ("SI", 10)]   # report.ts, every run
REAL = {"html": 4026, "css": 1198, "js": 1372, "lcp": 1300}                   # the last devtools run
MODEL_LCP = 4300                                                              # every simulate run
TASKS = [(49, 64, "other"), (241, 83, "Evaluate module"), (1225, 79, "Evaluate script"), (1381, 102, "Event (click)")]


def weights(T):
    c = Canvas(720, 150, T(
        "The performance score drawn as one bar of a hundred, split by weight: TBT 30, LCP 25, CLS 25, FCP 10 "
        "and SI 10. The first three, which stand for the Core Web Vitals, make seventy of the hundred.",
        "A nota de desempenho desenhada como uma barra de cem, dividida pelo peso: TBT 30, LCP 25, CLS 25, FCP 10 "
        "e SI 10. As três primeiras, que representam as Core Web Vitals, fazem setenta dos cem."))
    x0, scale = 40, 6.4
    x = x0
    for name, w in WEIGHTS:
        vital = name in ("TBT", "LCP", "CLS")
        c.rect(x, 40, w * scale, 40, fill="var(--ink)" if vital else "var(--panel)",
               stroke="var(--phosphor)" if vital else "var(--wire)", rx=2)
        c.text(x + w * scale / 2, 60, f"{name} {w}", size=11, mono=True)
        x += w * scale
    c.line(x0, 96, x0 + 70 * scale, 96, stroke="var(--phosphor)")
    c.text(x0 + 35 * scale, 112, T("70: the Core Web Vitals, or the lab's stand-in", "70: as Core Web Vitals, ou o substituto de laboratório"),
           size=10, fill="var(--phosphor)")
    c.caption = T("Seventy points of the hundred come from the three things a person feels.",
                  "Setenta dos cem pontos vêm das três coisas que a pessoa sente.")
    return c


def model(T):
    c = Canvas(720, 210, T(
        f"A timeline of the heavy home page on the slowed browser. The HTML took until {REAL['html']} ms to arrive. "
        f"The stylesheet arrived at {REAL['css']} ms and the script at {REAL['js']} ms, and the page painted its "
        f"largest content at about {REAL['lcp']} ms, while the HTML was still arriving. Lighthouse's model put the "
        f"same paint at about {MODEL_LCP} ms, after the whole document.",
        f"Uma linha do tempo da página inicial pesada no navegador desacelerado. O HTML levou até {REAL['html']} ms "
        f"para chegar. A folha de estilo chegou aos {REAL['css']} ms e o script aos {REAL['js']} ms, e a página "
        f"pintou o maior conteúdo por volta dos {REAL['lcp']} ms, com o HTML ainda chegando. O modelo do Lighthouse "
        f"pôs a mesma pintura por volta dos {MODEL_LCP} ms, depois do documento inteiro."))
    x0, scale = 120, 560 / 4800
    X = lambda ms: x0 + ms * scale
    rows = [(T("the HTML", "o HTML"), 0, REAL["html"]), (T("stylesheet", "folha de estilo"), 611, REAL["css"]),
            (T("script", "script"), 611, REAL["js"])]
    for i, (label, a, b) in enumerate(rows):
        y = 34 + i * 30
        c.text(x0 - 10, y + 9, label, anchor="end", size=10.5)
        c.rect(X(a), y, X(b) - X(a), 18, fill="var(--panel)", stroke="var(--wire)", rx=2)
    c.line(X(REAL["lcp"]), 26, X(REAL["lcp"]), 140, stroke="var(--phosphor)", sw=1.6)
    c.text(X(REAL["lcp"]), 156, T(f"painted, really · {REAL['lcp']} ms", f"pintou, de verdade · {REAL['lcp']} ms"),
           size=10, fill="var(--phosphor)")
    c.line(X(MODEL_LCP), 26, X(MODEL_LCP), 140, stroke="var(--amber)", sw=1.6, dash="4 3")
    c.text(X(MODEL_LCP), 176, T(f"painted, in the model · {MODEL_LCP} ms", f"pintou, no modelo · {MODEL_LCP} ms"),
           size=10, fill="var(--amber)")
    c.line(x0, 196, x0 + 560, 196, stroke="var(--paper-dim)", arrow=True)
    c.text(x0 + 560, 186, "ms", anchor="end", size=9.5, mono=True, fill="var(--paper-dim)")
    c.caption = T("The browser drew the top of the page while the bottom was still on its way.",
                  "O navegador desenhou o alto da página enquanto o resto ainda vinha.")
    return c


def tasks(T):
    c = Canvas(720, 200, T(
        "The long tasks of the traced click, along time. " + " ".join(
            f"At {s} ms, {d} ms: {n}." for s, d, n in TASKS) +
        " The first is the browser's own, the third is Playwright finding the element, and the second and the "
        "fourth are the planner's.",
        "As tarefas longas do clique registrado, ao longo do tempo. " + " ".join(
            f"Aos {s} ms, {d} ms: {n}." for s, d, n in TASKS) +
        " A primeira é do próprio navegador, a terceira é o Playwright achando o elemento, e a segunda e a quarta "
        "são do planner."))
    x0, scale = 40, 640 / 1600
    X = lambda ms: x0 + ms * scale
    owners = [T("the browser", "o navegador"), T("the planner", "o planner"), T("Playwright", "Playwright"),
              T("the planner", "o planner")]
    for i, ((s, d, n), who) in enumerate(zip(TASKS, owners)):
        mine = who == owners[1]
        y = 50 if i % 2 == 0 else 100
        c.rect(X(s), 120, max(d * scale, 4), 30, fill="var(--ink)", stroke="var(--amber)" if mine else "var(--wire)", rx=1)
        c.line(X(s) + d * scale / 2, y + 18, X(s) + d * scale / 2, 118, stroke="var(--paper-dim)")
        c.text(X(s) + d * scale / 2, y, n if n != "other" else T("nothing named", "nada com nome"), size=10, mono=n != "other")
        c.text(X(s) + d * scale / 2, y + 12, f"{d} ms · {who}", size=9.5,
               fill="var(--amber)" if mine else "var(--paper-dim)")
    c.line(x0, 166, x0 + 640, 166, stroke="var(--paper-dim)", arrow=True)
    for t in range(0, 1601, 400):
        c.text(X(t), 182, str(t), size=9, mono=True, fill="var(--paper-dim)")
    c.caption = T("Two of the four long tasks are not the page's.",
                  "Duas das quatro tarefas longas não são da página.")
    return c


FIGURES = [
    ("how-it-scores", weights),
    ("simulated-or-real", model),
    ("reading-a-trace", tasks),
]
