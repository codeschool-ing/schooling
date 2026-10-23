from fig import Canvas


def one_thread(T):
    c = Canvas(720, 290, T(
        "Three requests over time. Each runs a short piece of JavaScript, waits a long time for the database, "
        "then runs another short piece to reply. On the bottom row the one JavaScript thread runs those short "
        "pieces one after another, and is free while all three wait.",
        "Três requisições ao longo do tempo. Cada uma roda um trecho curto de JavaScript, espera muito tempo pelo "
        "banco de dados e roda outro trecho curto para responder. Na linha de baixo, a única thread de JavaScript "
        "roda esses trechos um depois do outro, e fica livre enquanto as três esperam."))
    rows = [("A", 40, (150, 180), (420, 450)), ("B", 90, (200, 230), (380, 410)), ("C", 140, (250, 280), (520, 550))]
    for name, y, a, b in rows:
        c.text(20, y, T(f"request {name}", f"requisição {name}"), anchor="start", size=11)
        c.rect(a[0], y - 12, a[1] - a[0], 24, fill="var(--ink)", stroke="var(--phosphor)")
        c.text((a[0] + a[1]) / 2, y, name, mono=True, size=10.5, fill="var(--phosphor)")
        c.rect(a[1] + 4, y - 6, b[0] - a[1] - 8, 12, fill="none", stroke="var(--wire)", dash="4 3")
        c.rect(b[0], y - 12, b[1] - b[0], 24, fill="var(--ink)", stroke="var(--phosphor)")
        c.text((b[0] + b[1]) / 2, y, name, mono=True, size=10.5, fill="var(--phosphor)")
    c.line(140, 172, 700, 172, stroke="var(--wire)", dash="2 3")
    y = 210
    c.text(20, y, T("the one", "a única thread"), anchor="start", size=11, weight="600")
    c.text(20, y + 15, T("JavaScript thread", "de JavaScript"), anchor="start", size=11, weight="600")
    c.rect(140, y - 16, 560, 32, fill="var(--panel)", stroke="var(--wire)")
    for name, _, a, b in rows:
        for s in (a, b):
            c.rect(s[0], y - 12, s[1] - s[0], 24, fill="var(--ink)", stroke="var(--phosphor)")
            c.text((s[0] + s[1]) / 2, y, name, mono=True, size=10.5, fill="var(--phosphor)")
    c.line(140, 256, 700, 256, stroke="var(--paper-dim)", arrow=True)
    c.text(700, 272, T("time", "tempo"), anchor="end", size=10, fill="var(--paper-dim)")
    c.rect(150, 262, 20, 12, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(176, 268, T("your code running", "o seu código rodando"), anchor="start", size=10, fill="var(--paper-dim)")
    c.rect(330, 263, 30, 10, fill="none", stroke="var(--wire)", dash="4 3")
    c.text(366, 268, T("waiting for the database", "esperando o banco de dados"), anchor="start", size=10, fill="var(--paper-dim)")
    c.caption = T("Most of a request's life is spent waiting, and waiting needs no thread. The one thread runs "
                  "whichever piece of code is ready next.",
                  "A maior parte da vida de uma requisição é espera, e esperar não precisa de thread. A única thread "
                  "roda o trecho de código que estiver pronto a seguir.")
    return c


def path_search(T):
    c = Canvas(720, 200, T(
        "The shell looking for the command node. It tries the folders of PATH from left to right: ~/.local/bin, which "
        "holds a link to the course's Node 22, then /usr/sbin, /usr/bin, which holds Ubuntu's Node 18, /sbin and /bin. "
        "It stops at the first folder that has a node, so Node 22 answers.",
        "O shell procurando o comando node. Ele tenta as pastas do PATH da esquerda para a direita: ~/.local/bin, que "
        "tem um link para o Node 22 do curso, depois /usr/sbin, /usr/bin, que tem o Node 18 do Ubuntu, /sbin e /bin. Ele "
        "para na primeira pasta que tem um node, então quem responde é o Node 22."))
    c.text(20, 24, "$ node --version", mono=True, size=11, anchor="start")
    dirs = [("~/.local/bin", "node → v22", True), ("/usr/sbin", "", False), ("/usr/bin", "node: v18", False),
            ("/sbin", "", False), ("/bin", T("= /usr/bin", "= /usr/bin"), False)]
    x = 20
    for name, has, first in dirs:
        w = 150 if first else 120
        c.rect(x, 50, w, 70, fill="var(--ink)" if first else "var(--panel)", stroke="var(--phosphor)" if first else "var(--wire)")
        c.text(x + w / 2, 72, name, mono=True, size=10)
        if has:
            c.text(x + w / 2, 98, has, mono=True, size=9.5, fill="var(--phosphor)" if first else "var(--paper-dim)")
        x += w + 12
    c.line(20, 145, 700, 145, stroke="var(--paper-dim)", arrow=True)
    c.text(20, 162, T("the order the shell tries them: PATH, left to right", "a ordem em que o shell as tenta: o PATH, da esquerda para a direita"),
           size=10, anchor="start", fill="var(--paper-dim)")
    c.text(95, 185, T("first match: it stops here", "primeiro achado: para aqui"), size=10, fill="var(--phosphor)")
    c.caption = T("Two Nodes on one PATH: the first folder that has one decides, and the other is never asked.",
                  "Dois Nodes num PATH: decide a primeira pasta que tem um, e o outro nunca é consultado.")
    return c


FIGURES = [("what-node-is-for", one_thread), ("when-setup-fails", path_search)]
