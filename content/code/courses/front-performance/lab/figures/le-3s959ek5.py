from fig import Canvas


def three_answers(T):
    c = Canvas(720, 300, T(
        "Three rows, one per way of rendering, each a timeline from left to right. Client-side: the browser receives an "
        "empty page, fetches the script, the script fetches the data, and only then is the page drawn. Server-side: the "
        "server reads the data and draws the page when the request arrives, and the browser shows it as soon as it is "
        "received. Build time: the page was drawn before anybody asked, and the server only hands out the file.",
        "Três linhas, uma por jeito de renderizar, cada uma uma linha do tempo da esquerda para a direita. No cliente: o "
        "navegador recebe uma página vazia, busca o script, o script busca os dados, e só então a página é desenhada. No "
        "servidor: o servidor lê os dados e desenha a página quando a requisição chega, e o navegador a mostra assim que a "
        "recebe. No build: a página foi desenhada antes de alguém pedir, e o servidor só entrega o arquivo."))
    rows = [
        (T("client-side", "no cliente"), 60, [
            (150, 120, T("empty HTML", "HTML vazio"), False),
            (280, 110, T("script", "script"), False),
            (400, 110, T("data", "dados"), False),
            (520, 160, T("page drawn", "página desenhada"), True)]),
        (T("server-side", "no servidor"), 145, [
            (150, 230, T("server reads data, draws page", "servidor lê dados, desenha"), False),
            (390, 160, T("page shown", "página exibida"), True),
            (560, 120, T("script", "script"), False)]),
        (T("build time", "no build"), 230, [
            (150, 120, T("file", "arquivo"), False),
            (280, 160, T("page shown", "página exibida"), True),
            (450, 120, T("script", "script"), False)]),
    ]
    for label, y, boxes in rows:
        c.text(20, y, label, anchor="start", size=11, weight="600")
        for x, w, s, shown in boxes:
            c.rect(x, y - 16, w - 8, 32, fill="var(--ink)" if shown else "var(--panel)",
                   stroke="var(--phosphor)" if shown else "var(--wire)", sw=1.6 if shown else 1.2)
            c.text(x + (w - 8) / 2, y, s, size=10, fill="var(--phosphor)" if shown else "var(--paper)")
    c.text(150, 270, T("drawn earlier, on your computer or in CI", "desenhada antes, no seu computador ou na CI"),
           anchor="start", size=9.5, fill="var(--paper-dim)")
    c.line(140, 285, 700, 285, stroke="var(--paper-dim)", arrow=True)
    c.text(700, 272, T("time", "tempo"), anchor="end", size=9.5, fill="var(--paper-dim)")
    c.caption = T("The same page, made in three places. What moves is the moment the person first sees it.",
                  "A mesma página, feita em três lugares. O que muda é o momento em que a pessoa a vê pela primeira vez.")
    return c


def discovery(T):
    c = Canvas(720, 230, T(
        "The chain of a client-rendered page. The HTML names a script and a stylesheet; the script, once it runs, asks for "
        "courses.json; only when that arrives is anything drawn into the empty main. Each arrow is a request the browser "
        "could not have made before the previous response arrived.",
        "A cadeia de uma página renderizada no cliente. O HTML nomeia um script e uma folha de estilo; o script, quando roda, "
        "pede o courses.json; só quando ele chega algo é desenhado no main vazio. Cada seta é uma requisição que o navegador "
        "não poderia ter feito antes de a resposta anterior chegar."))
    c.rect(20, 40, 150, 60, fill="var(--panel)", stroke="var(--wire)")
    c.text(95, 60, "/", mono=True, size=11)
    c.text(95, 80, '<main id="app">', mono=True, size=9.5, fill="var(--paper-dim)")
    c.rect(230, 25, 180, 40, fill="var(--panel)", stroke="var(--wire)")
    c.text(320, 45, "/assets/index-….js", mono=True, size=10)
    c.rect(230, 80, 180, 40, fill="var(--panel)", stroke="var(--wire)")
    c.text(320, 100, "/assets/index-….css", mono=True, size=10)
    c.line(170, 60, 228, 45, stroke="var(--paper-dim)", arrow=True)
    c.line(170, 80, 228, 100, stroke="var(--paper-dim)", arrow=True)
    c.rect(470, 25, 120, 40, fill="var(--panel)", stroke="var(--wire)")
    c.text(530, 45, "/courses.json", mono=True, size=10)
    c.line(410, 45, 468, 45, stroke="var(--paper-dim)", arrow=True)
    c.rect(470, 140, 230, 50, fill="var(--ink)", stroke="var(--phosphor)", sw=1.6)
    c.text(585, 158, T("the list is drawn", "a lista é desenhada"), size=10.5, fill="var(--phosphor)")
    c.text(585, 176, T("first contentful paint", "primeira pintura com conteúdo"), size=9.5, fill="var(--paper-dim)")
    c.line(530, 65, 560, 138, stroke="var(--phosphor)", arrow=True)
    c.text(95, 130, T("1st response", "1ª resposta"), size=9.5, fill="var(--paper-dim)")
    c.text(320, 140, T("2nd", "2ª"), size=9.5, fill="var(--paper-dim)")
    c.text(530, 90, T("3rd", "3ª"), size=9.5, fill="var(--paper-dim)")
    c.text(20, 215, T("Without JavaScript the chain stops after the stylesheet, and nothing is drawn.",
                      "Sem JavaScript a cadeia para depois da folha de estilo, e nada é desenhado."),
           anchor="start", size=10, fill="var(--amber)")
    c.caption = T("Three responses in a row, each needed before the next request can even be made.",
                  "Três respostas em sequência, cada uma necessária antes de a próxima requisição sequer poder ser feita.")
    return c


def takeover(T):
    c = Canvas(720, 210, T(
        "A hybrid session. The first page is requested from the server, which draws it. Then two clicks, to the Git course "
        "and back to the list, are drawn by the script in the browser, and no request for a page goes to the server. A "
        "reload sends the request to the server again.",
        "Uma sessão híbrida. A primeira página é pedida ao servidor, que a desenha. Depois dois cliques, para o curso de Git "
        "e de volta à lista, são desenhados pelo script no navegador, e nenhuma requisição de página vai ao servidor. Um "
        "recarregamento manda a requisição ao servidor de novo."))
    c.text(20, 50, T("server", "servidor"), anchor="start", size=11, weight="600")
    c.text(20, 140, T("browser", "navegador"), anchor="start", size=11, weight="600")
    c.line(100, 50, 700, 50, stroke="var(--wire)", dash="2 3")
    c.line(100, 140, 700, 140, stroke="var(--wire)", dash="2 3")
    steps = [(120, T("GET /", "GET /"), True), (270, T("click Git", "clique em Git"), False),
             (420, T("click All courses", "clique em All courses"), False), (580, T("reload", "recarregar"), True)]
    for x, label, server in steps:
        if server:
            c.rect(x, 34, 110, 32, fill="var(--ink)", stroke="var(--amber)")
            c.text(x + 55, 50, T("draws page", "desenha"), size=10, fill="var(--amber)")
            c.line(x + 55, 66, x + 55, 122, stroke="var(--amber)", arrow=True)
        c.rect(x, 124, 110, 32, fill="var(--ink)" if not server else "var(--panel)",
               stroke="var(--phosphor)" if not server else "var(--wire)")
        c.text(x + 55, 140, T("draws page", "desenha") if not server else T("shows it", "mostra"), size=10,
               fill="var(--phosphor)" if not server else "var(--paper)")
        c.text(x + 55, 175, label, size=9.5, fill="var(--paper-dim)")
    c.caption = T("The server draws the first page and every reload; the browser draws everything in between.",
                  "O servidor desenha a primeira página e cada recarregamento; o navegador desenha tudo no meio.")
    return c


def waterfall(T):
    c = Canvas(720, 290, T(
        "Two request waterfalls with 300 milliseconds added to every request. Client-side: the HTML, then the script and "
        "stylesheet, then the data, three waits in a row, and the first paint at 948 milliseconds. Server-side: the HTML, "
        "then the stylesheet, and the first paint at 640 milliseconds, while the script and the data arrive after it.",
        "Duas cascatas de requisições com 300 milissegundos somados a cada uma. No cliente: o HTML, depois o script e a "
        "folha de estilo, depois os dados, três esperas seguidas, e a primeira pintura aos 948 milissegundos. No servidor: o "
        "HTML, depois a folha de estilo, e a primeira pintura aos 640 milissegundos, enquanto o script e os dados chegam "
        "depois dela."))
    x0, scale = 150, 0.5
    def bar(y, start, label):
        c.rect(x0 + start * scale, y - 9, 300 * scale - 4, 18, fill="var(--panel)", stroke="var(--wire)")
        c.text(x0 + start * scale + 6, y, label, anchor="start", size=9, mono=True)
    c.text(20, 30, T("client-side", "no cliente"), anchor="start", size=11, weight="600")
    bar(55, 0, "/")
    bar(78, 310, "index-….js")
    bar(101, 310, "index-….css")
    bar(124, 620, "/courses.json")
    c.line(x0 + 948 * scale, 40, x0 + 948 * scale, 135, stroke="var(--phosphor)", sw=1.6)
    c.text(x0 + 948 * scale - 6, 40, T("paint 948 ms", "pintura 948 ms"), anchor="end", size=10, fill="var(--phosphor)")
    c.text(20, 160, T("server-side", "no servidor"), anchor="start", size=11, weight="600")
    bar(185, 0, "/")
    bar(208, 310, "index-….css")
    bar(231, 310, "index-….js")
    bar(254, 620, "/courses.json")
    c.line(x0 + 640 * scale, 170, x0 + 640 * scale, 268, stroke="var(--phosphor)", sw=1.6)
    c.text(x0 + 640 * scale + 6, 170, T("paint 640 ms", "pintura 640 ms"), anchor="start", size=10, fill="var(--phosphor)")
    c.caption = T("Both pages made the same requests. Only the client-rendered one had to wait for the third before "
                  "it could draw. The bars are drawn 300 ms long; the two paints are the measured ones.",
                  "As duas páginas fizeram as mesmas requisições. Só a renderizada no cliente teve de esperar a terceira "
                  "para poder desenhar. As barras têm 300 ms de desenho; as duas pinturas são as medidas.")
    return c


FIGURES = [
    ("where-html-is-made", three_answers),
    ("client-side", discovery),
    ("hybrid", takeover),
    ("what-each-costs", waterfall),
]
