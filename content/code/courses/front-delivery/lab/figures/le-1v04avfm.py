from fig import Canvas


def baked(T):
    c = Canvas(720, 230, T(
        "Before the build, src/env.ts reads import.meta.env.VITE_TITLE with a fallback, and the shell or a .env file "
        "holds VITE_TITLE set to Study planner (staging). The build replaces the expression with the value. After the "
        "build, the bundle contains only the string Study planner (staging); the variable's name is gone. The browser "
        "receives that string and has no environment of its own.",
        "Antes do build, src/env.ts lê import.meta.env.VITE_TITLE com um valor padrão, e o shell ou um arquivo .env "
        "guarda VITE_TITLE valendo Study planner (staging). O build troca a expressão pelo valor. Depois do build, o "
        "pacote contém só a string Study planner (staging); o nome da variável sumiu. O navegador recebe essa string e "
        "não tem ambiente próprio."))
    c.text(20, 22, T("before the build", "antes do build"), anchor="start", size=10.5, weight="600")
    c.rect(20, 34, 300, 62, fill="var(--panel)")
    c.text(32, 52, "src/env.ts", mono=True, size=9.5, anchor="start", fill="var(--paper-dim)")
    c.text(32, 76, "import.meta.env.VITE_TITLE ?? …", mono=True, size=10, anchor="start")
    c.rect(20, 108, 300, 50, fill="var(--panel)")
    c.text(32, 124, T("the shell, or .env.staging", "o shell, ou .env.staging"), size=9.5, anchor="start", fill="var(--paper-dim)")
    c.text(32, 144, "VITE_TITLE=Study planner (staging)", mono=True, size=10, anchor="start")
    c.line(330, 96, 380, 96, stroke="var(--paper-dim)", arrow=True)
    c.text(355, 82, "build", mono=True, size=10, fill="var(--paper-dim)")
    c.text(390, 22, T("after the build", "depois do build"), anchor="start", size=10.5, weight="600")
    c.rect(390, 34, 310, 62, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(402, 52, "dist/assets/index-….js", mono=True, size=9.5, anchor="start", fill="var(--paper-dim)")
    c.text(402, 76, "`Study planner (staging)`", mono=True, size=10, anchor="start", fill="var(--phosphor)")
    c.text(390, 122, T("the name VITE_TITLE: gone", "o nome VITE_TITLE: sumiu"), anchor="start", size=10, fill="var(--amber)")
    c.text(390, 140, T("the value: a string like any other", "o valor: uma string como outra qualquer"), anchor="start", size=10, fill="var(--paper-dim)")
    c.line(545, 96, 545, 172, stroke="var(--paper-dim)", arrow=True)
    c.rect(450, 176, 190, 40, fill="var(--panel)", stroke="var(--amber)")
    c.text(545, 190, T("the browser", "o navegador"), size=10.5)
    c.text(545, 205, T("has no environment to read", "não tem ambiente para ler"), size=9.5, fill="var(--paper-dim)")
    c.caption = T("A front end's variable is read by the build and written into the bundle as a value; the page never sees the variable.",
                  "Uma variável de front-end é lida pelo build e gravada no pacote como valor; a página nunca vê a variável.")
    return c


def proxy(T):
    c = Canvas(720, 200, T(
        "Three boxes from left to right. The browser holds the page, which knows only the path /api/support. Your "
        "server holds SUPPORT_TOKEN in its own environment; it accepts POST /api/support and adds the token. The "
        "service checks the token and opens a ticket. A dashed line marks the boundary: everything left of it is the "
        "reader's, everything right of it is yours.",
        "Três caixas da esquerda para a direita. O navegador tem a página, que só conhece o caminho /api/support. O "
        "seu servidor guarda SUPPORT_TOKEN no próprio ambiente; ele aceita POST /api/support e acrescenta o token. O "
        "serviço confere o token e abre um chamado. Uma linha tracejada marca a fronteira: tudo à esquerda dela é de "
        "quem lê, tudo à direita é seu."))
    c.rect(20, 50, 190, 100, fill="var(--panel)")
    c.text(115, 70, T("the browser", "o navegador"), size=11, weight="600")
    c.text(115, 98, "POST /api/support", mono=True, size=10)
    c.text(115, 122, T("no key in the bundle", "nenhuma chave no pacote"), size=9.5, fill="var(--paper-dim)")
    c.line(250, 30, 250, 180, stroke="var(--amber)", dash="5 4")
    c.text(240, 186, T("the reader's", "de quem lê"), anchor="end", size=9.5, fill="var(--amber)")
    c.text(260, 186, T("yours", "seu"), anchor="start", size=9.5, fill="var(--amber)")
    c.rect(280, 50, 190, 100, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(375, 70, T("your server", "o seu servidor"), size=11, weight="600")
    c.text(375, 98, "SUPPORT_TOKEN", mono=True, size=10, fill="var(--phosphor)")
    c.text(375, 122, T("adds the key", "acrescenta a chave"), size=9.5, fill="var(--paper-dim)")
    c.rect(510, 50, 190, 100, fill="var(--panel)")
    c.text(605, 70, T("the service", "o serviço"), size=11, weight="600")
    c.text(605, 98, "Authorization: Bearer …", mono=True, size=9.5)
    c.text(605, 122, T("checks it", "confere a chave"), size=9.5, fill="var(--paper-dim)")
    c.line(210, 100, 280, 100, stroke="var(--paper-dim)", arrow=True)
    c.line(470, 100, 510, 100, stroke="var(--paper-dim)", arrow=True)
    c.caption = T("The key stays on the side of the line you control; the page knows a path and nothing else.",
                  "A chave fica do lado da linha que você controla; a página conhece um caminho e mais nada.")
    return c


FIGURES = [("baked-in", baked), ("a-key-that-must-stay-secret", proxy)]
