from fig import Canvas


def proxy(T):
    c = Canvas(720, 250, T(
        "The browser sends every request to one address, localhost:4200, the dev server. Requests whose path "
        "starts with /api the dev server passes on to the API at localhost:3000, which reads and writes "
        "planner.json, and the answer comes back the same way. Every other request the dev server answers "
        "itself, with the application's files.",
        "O navegador manda todo pedido a um endereço, localhost:4200, o servidor de desenvolvimento. Os pedidos "
        "cujo caminho começa com /api o servidor de desenvolvimento repassa à API em localhost:3000, que lê e "
        "escreve o planner.json, e a resposta volta pelo mesmo caminho. Todo outro pedido o servidor de "
        "desenvolvimento responde sozinho, com os arquivos da aplicação."))
    def box(x, y, w, h, title, sub, stroke, sub_mono=True):
        c.rect(x, y, w, h, stroke=stroke)
        c.text(x + w / 2, y + h / 2 - 8, title, size=10.5)
        c.text(x + w / 2, y + h / 2 + 9, sub, size=9.5, mono=sub_mono, fill="var(--paper-dim)")
    box(20, 90, 130, 56, T("browser", "navegador"), T("one origin", "uma origem"), "var(--wire)", sub_mono=False)
    box(250, 90, 170, 56, T("dev server", "servidor de dev"), "localhost:4200", "var(--phosphor)")
    box(540, 30, 160, 56, "API", "localhost:3000", "var(--amber)")
    box(540, 160, 160, 56, T("the application", "a aplicação"), "main.js, index.html", "var(--phosphor)")
    c.line(150, 112, 248, 112, arrow=True)
    c.line(250, 126, 152, 126, arrow=True)
    c.text(200, 104, T("every request", "todo pedido"), size=9, fill="var(--paper-dim)")
    c.line(420, 104, 538, 64, stroke="var(--amber)", arrow=True)
    c.text(478, 72, "/api/...", size=9.5, mono=True, fill="var(--amber)")
    c.line(420, 134, 538, 184, arrow=True)
    c.text(462, 190, T("everything else", "todo o resto"), size=9, fill="var(--paper-dim)")
    c.rect(560, 102, 120, 26, fill="var(--ink)", stroke="var(--amber)", dash="4 3")
    c.text(620, 115, "planner.json", size=9.5, mono=True)
    c.line(620, 86, 620, 100, stroke="var(--amber)")
    c.text(335, 176, "proxy.conf.json", size=9.5, mono=True, fill="var(--paper-dim)")
    c.text(335, 192, T("decides which way", "decide para onde"), size=9, fill="var(--paper-dim)")
    c.caption = T("The browser only ever talks to localhost:4200; the dev server sends /api on to the API and answers the rest itself.",
                  "O navegador só conversa com localhost:4200; o servidor de desenvolvimento manda /api para a API e responde o resto sozinho.")
    return c


FIGURES = [("the-api", proxy)]
