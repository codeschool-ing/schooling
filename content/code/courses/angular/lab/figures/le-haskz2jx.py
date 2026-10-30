from fig import Canvas


def timeline(T):
    c = Canvas(720, 250, T(
        "A request rendered on the server, in two lanes, time running left to right. In the server's lane, the "
        "server renders the page and asks the API for the data. An arrow carries the HTML and the ng-state "
        "script down to the browser's lane, where three boxes follow: the browser shows the HTML, runs the "
        "scripts, and hydrates the page, attaching the listeners. A bracket over the first two browser boxes "
        "says that a click made then is recorded and replayed. A note under the last box says the first "
        "GET of the data is answered from ng-state.",
        "Uma requisição renderizada no servidor, em duas faixas, o tempo correndo da esquerda para a direita. "
        "Na faixa do servidor, o servidor renderiza a página e pede os dados à API. Uma seta leva o HTML e o "
        "script ng-state para a faixa do navegador, onde vêm três caixas: o navegador mostra o HTML, roda os "
        "scripts e hidrata a página, ligando os listeners. Um colchete sobre as duas primeiras caixas do "
        "navegador diz que um clique feito nesse intervalo é gravado e reproduzido. Uma nota sob a última "
        "caixa diz que o primeiro GET dos dados é respondido pelo ng-state."))
    c.text(20, 72, T("server", "servidor"), size=10.5, anchor="start", fill="var(--paper-dim)")
    c.text(20, 172, T("browser", "navegador"), size=10.5, anchor="start", fill="var(--paper-dim)")
    c.line(100, 30, 100, 220, stroke="var(--wire)", dash="3 3")
    c.rect(110, 50, 180, 44, stroke="var(--amber)")
    c.text(200, 64, T("renders the page", "renderiza a página"), size=10.5)
    c.text(200, 81, "GET /api/planner", size=9.5, mono=True, fill="var(--paper-dim)")
    c.line(290, 94, 318, 146, arrow=True, stroke="var(--amber)")
    c.text(312, 112, "HTML + ng-state", size=9.5, mono=True, anchor="start", fill="var(--amber)")
    boxes = [(320, T("shows the HTML", "mostra o HTML"), T("text, no listeners", "texto, sem listeners")),
             (455, T("runs the scripts", "roda os scripts"), "main.js"),
             (590, T("hydrates", "hidrata"), T("listeners attached", "listeners ligados"))]
    for x, title, sub in boxes:
        c.rect(x, 150, 120, 44, stroke="var(--phosphor)")
        c.text(x + 60, 164, title, size=10.5)
        c.text(x + 60, 181, sub, size=9.5, mono=(sub == "main.js"), fill="var(--paper-dim)")
    c.line(440, 172, 452, 172, arrow=True)
    c.line(575, 172, 587, 172, arrow=True)
    c.path("M 320 140 L 320 134 L 575 134 L 575 140", stroke="var(--amber)", dash="4 3")
    c.text(447, 125, T("a click now is recorded, then replayed", "um clique agora é gravado e reproduzido depois"),
           size=9.5, fill="var(--amber)")
    c.text(650, 212, T("the first GET is answered", "o primeiro GET é respondido"), size=9.5, fill="var(--paper-dim)")
    c.text(650, 228, T("from ng-state", "pelo ng-state"), size=9.5, fill="var(--paper-dim)")
    c.caption = T("The server sends a finished page and the data it used; the browser shows it at once, and takes it over when the scripts have run.",
                  "O servidor manda uma página pronta e os dados que usou; o navegador mostra na hora e assume a página quando os scripts rodaram.")
    return c


FIGURES = [("hydration", timeline)]
