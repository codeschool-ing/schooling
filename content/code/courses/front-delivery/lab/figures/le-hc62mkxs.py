from fig import Canvas


def flow(T):
    c = Canvas(720, 250, T(
        "The path from a push to a page. A commit is pushed to the repository. A build machine checks it out, "
        "runs npm ci and npm run build, and writes the folder dist, holding index.html, a script, a stylesheet and "
        "courses.json. Only that folder is uploaded to the host, which copies it to servers in many cities. A "
        "browser asks the nearest copy for each file and runs the app itself.",
        "O caminho de um push até uma página. Um commit é enviado ao repositório. Uma máquina de build faz o "
        "checkout, roda npm ci e npm run build e grava a pasta dist, com index.html, um script, uma folha de estilo "
        "e courses.json. Só essa pasta sobe para o host, que a copia para servidores em muitas cidades. Um navegador "
        "pede cada arquivo à cópia mais próxima e roda o próprio app."))
    boxes = [
        (20, T("repository", "repositório"), ["git push"]),
        (190, T("build machine", "máquina de build"), ["npm ci", "npm run build"]),
        (360, "dist/", ["index.html", "assets/…js", "assets/…css", "courses.json"]),
        (530, T("host and CDN", "host e CDN"), []),
    ]
    for x, title, lines in boxes:
        hi = title == "dist/"
        c.rect(x, 40, 150, 130, fill="var(--ink)" if hi else "var(--panel)", stroke="var(--phosphor)" if hi else "var(--wire)")
        c.text(x + 75, 60, title, size=11, weight="600", mono=hi)
        for i, l in enumerate(lines):
            c.text(x + 75, 88 + i * 18, l, mono=True, size=10, fill="var(--phosphor)" if hi else "var(--paper-dim)")
    for x in (170, 340, 510):
        c.line(x, 105, x + 20, 105, stroke="var(--paper-dim)", arrow=True)
    for i, (dx, dy) in enumerate([(560, 95), (605, 120), (650, 95), (575, 145), (635, 148)]):
        c.rect(dx, dy, 22, 14, fill="var(--ink)", stroke="var(--phosphor-dim)", rx=2)
    c.text(605, 80, T("copies in many cities", "cópias em muitas cidades"), size=9.5, fill="var(--paper-dim)")
    c.line(605, 172, 605, 200, stroke="var(--paper-dim)", arrow=True)
    c.rect(530, 202, 150, 36, fill="var(--panel)", stroke="var(--amber)")
    c.text(605, 220, T("the browser runs it", "o navegador roda"), size=10.5, fill="var(--amber)")
    c.text(20, 200, T("you do the first step;", "você faz o primeiro passo;"), anchor="start", size=10, fill="var(--paper-dim)")
    c.text(20, 216, T("a connected host does the other three", "um host conectado faz os outros três"), anchor="start", size=10, fill="var(--paper-dim)")
    c.caption = T("A static front end from push to page: what is deployed is the built folder, and nothing in it runs on the host.",
                  "Um front-end estático do push à página: o que vai para o ar é a pasta construída, e nada nela roda no host.")
    return c


def subpath(T):
    c = Canvas(720, 230, T(
        "A site published in the folder planner of its address. The folder holds index.html and assets. A page "
        "built for the root asks for /assets/index.js, which resolves from the root of the address, outside the "
        "folder, where there is nothing: 404. Built with base /planner/, it asks for /planner/assets/index.js, "
        "inside the folder: 200.",
        "Um site publicado na pasta planner do seu endereço. A pasta tem index.html e assets. Uma página construída "
        "para a raiz pede /assets/index.js, que se resolve a partir da raiz do endereço, fora da pasta, onde não há "
        "nada: 404. Construída com base /planner/, pede /planner/assets/index.js, dentro da pasta: 200."))
    c.text(20, 22, "https://ana.github.io/", mono=True, size=11, anchor="start")
    c.rect(20, 40, 340, 170, fill="none", stroke="var(--wire)", dash="4 3")
    c.text(30, 56, T("the root of the address", "a raiz do endereço"), anchor="start", size=10, fill="var(--paper-dim)")
    c.rect(130, 80, 210, 115, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(140, 96, "planner/", mono=True, size=11, anchor="start", fill="var(--phosphor)")
    c.text(150, 124, "index.html", mono=True, size=10, anchor="start")
    c.text(150, 146, "assets/index.js", mono=True, size=10, anchor="start")
    c.text(150, 168, "courses.json", mono=True, size=10, anchor="start")
    c.text(72, 140, T("nothing", "nada"), size=10, fill="var(--amber)")
    c.text(72, 154, T("here", "aqui"), size=10, fill="var(--amber)")
    c.text(390, 90, T("built for /", "construída para /"), anchor="start", size=10.5, weight="600")
    c.text(390, 108, "src=\"/assets/index.js\"", mono=True, size=10, anchor="start", fill="var(--amber)")
    c.path("M 385 112 C 350 55, 60 50, 72 126", stroke="var(--amber)", dash="4 3")
    c.text(548, 108, "404", mono=True, size=11, anchor="start", fill="var(--amber)")
    c.text(390, 160, T("built with base /planner/", "construída com base /planner/"), anchor="start", size=10.5, weight="600")
    c.text(390, 178, "src=\"/planner/assets/index.js\"", mono=True, size=10, anchor="start", fill="var(--phosphor)")
    c.line(388, 172, 344, 150, stroke="var(--phosphor)", arrow=True)
    c.text(592, 178, "200", mono=True, size=11, anchor="start", fill="var(--phosphor)")
    c.caption = T("A path that starts with / is resolved from the root of the address, so a site in a folder has to be built with the folder's name.",
                  "Um caminho que começa com / é resolvido a partir da raiz do endereço, então um site numa pasta precisa ser construído com o nome da pasta.")
    return c


FIGURES = [("from-push-to-page", flow), ("a-subpath", subpath)]
