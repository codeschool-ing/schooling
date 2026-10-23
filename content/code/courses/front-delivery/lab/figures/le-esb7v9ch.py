from fig import Canvas


def takeover(T):
    c = Canvas(720, 210, T(
        "Before: docs.example.com has a CNAME to example-docs.pages.dev, which is the team's project. After the "
        "project is deleted, the CNAME is still there and points at a name nobody owns. Anybody who creates a "
        "project with that name now serves pages under docs.example.com.",
        "Antes: docs.example.com tem um CNAME para example-docs.pages.dev, que é o projeto da equipe. Depois que o "
        "projeto é apagado, o CNAME continua lá e aponta para um nome que não é de ninguém. Qualquer pessoa que "
        "criar um projeto com esse nome passa a servir páginas sob docs.example.com."))
    for row, (label, mine, owner, stroke) in enumerate([
        (T("before", "antes"), "example-docs.pages.dev", T("your project", "o seu projeto"), "var(--phosphor)"),
        (T("after the project is deleted", "depois que o projeto é apagado"), "example-docs.pages.dev", T("nobody's, until somebody claims it", "de ninguém, até alguém reivindicar"), "var(--amber)")]):
        y = 50 + row * 90
        c.text(20, y - 22, label, anchor="start", size=10.5, weight="600")
        c.rect(20, y - 8, 190, 40, fill="var(--panel)")
        c.text(115, y + 12, "docs.example.com", mono=True, size=10)
        c.line(210, y + 12, 300, y + 12, stroke="var(--paper-dim)", arrow=True)
        c.text(255, y + 2, "CNAME", mono=True, size=9.5, fill="var(--paper-dim)")
        c.rect(302, y - 8, 210, 40, fill="var(--ink)", stroke=stroke, dash=None if row == 0 else "5 4")
        c.text(407, y + 12, mine, mono=True, size=10, fill=stroke)
        c.text(530, y + 12, owner, anchor="start", size=10, fill=stroke)
    c.caption = T("A record left pointing at a deleted site lends your domain to whoever takes the name next; delete the record first.",
                  "Um registro deixado apontando para um site apagado empresta o seu domínio a quem pegar o nome depois; apague o registro primeiro.")
    return c


def rewrite(T):
    c = Canvas(720, 200, T(
        "Two answers to a request for /course/git. A redirect answers 301 with a new location, and the browser asks "
        "again at another address, which changes the address bar. A rewrite answers 200 with the contents of "
        "index.html at the same address, and the app reads the address and draws the course.",
        "Duas respostas a um pedido de /course/git. Um redirecionamento responde 301 com um novo endereço, e o "
        "navegador pede de novo em outro lugar, o que muda a barra de endereço. Uma reescrita responde 200 com o "
        "conteúdo de index.html no mesmo endereço, e o app lê o endereço e desenha o curso."))
    for row, (title, status, body, note, stroke) in enumerate([
        (T("a redirect", "um redirecionamento"), "301", "location: /", T("the address bar changes", "a barra de endereço muda"), "var(--amber)"),
        (T("a rewrite", "uma reescrita"), "200", "index.html", T("same address, the app draws the course", "mesmo endereço, o app desenha o curso"), "var(--phosphor)")]):
        y = 40 + row * 80
        c.text(20, y, title, anchor="start", size=10.5, weight="600")
        c.rect(20, y + 12, 160, 36, fill="var(--panel)")
        c.text(100, y + 30, "GET /course/git", mono=True, size=10)
        c.line(180, y + 30, 260, y + 30, stroke="var(--paper-dim)", arrow=True)
        c.rect(262, y + 12, 200, 36, fill="var(--ink)", stroke=stroke)
        c.text(282, y + 30, status, mono=True, size=10.5, anchor="start", fill=stroke)
        c.text(320, y + 30, body, mono=True, size=10, anchor="start")
        c.text(480, y + 30, note, anchor="start", size=10, fill="var(--paper-dim)")
    c.caption = T("A redirect sends the browser elsewhere; a rewrite serves another file where the browser already is.",
                  "Um redirecionamento manda o navegador para outro lugar; uma reescrita serve outro arquivo onde o navegador já está.")
    return c


FIGURES = [("proving-it-is-yours", takeover), ("the-deep-link", rewrite)]
