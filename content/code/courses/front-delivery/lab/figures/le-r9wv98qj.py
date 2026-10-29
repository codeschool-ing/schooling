from fig import Canvas


def scopes(T):
    c = Canvas(720, 210, T(
        "npm install in the planner reads the project's .npmrc. A package in the @planner scope is fetched from the "
        "private registry at 127.0.0.1:4873, which needs the login token kept in ~/.npmrc. Every other package, such "
        "as vite, is fetched from the public registry at registry.npmjs.org.",
        "O npm install no planner lê o .npmrc do projeto. Um pacote do escopo @planner é buscado no registry privado "
        "em 127.0.0.1:4873, que exige o token de login guardado em ~/.npmrc. Todo outro pacote, como o vite, é "
        "buscado no registry público em registry.npmjs.org."))
    c.rect(20, 70, 170, 70, fill="var(--panel)")
    c.text(105, 92, "npm install", mono=True, size=10.5)
    c.text(105, 116, T("in the planner", "no planner"), size=10, fill="var(--paper-dim)")
    c.rect(220, 30, 230, 44, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(232, 52, "@planner/*", mono=True, size=10.5, anchor="start", fill="var(--phosphor)")
    c.text(440, 52, "127.0.0.1:4873", mono=True, size=10, anchor="end")
    c.rect(220, 136, 230, 44, fill="var(--panel)")
    c.text(232, 158, T("everything else", "todo o resto"), size=10.5, anchor="start")
    c.text(440, 158, "registry.npmjs.org", mono=True, size=10, anchor="end")
    c.line(190, 95, 218, 60, stroke="var(--paper-dim)", arrow=True)
    c.line(190, 115, 218, 150, stroke="var(--paper-dim)", arrow=True)
    c.text(470, 46, T("from the project's .npmrc", "do .npmrc do projeto"), size=9.5, anchor="start", fill="var(--paper-dim)")
    c.text(470, 64, T("needs the token in ~/.npmrc", "exige o token em ~/.npmrc"), size=9.5, anchor="start", fill="var(--amber)")
    c.text(470, 158, T("public, no token", "público, sem token"), size=9.5, anchor="start", fill="var(--paper-dim)")
    c.caption = T("One line in the project's .npmrc sends one scope to a private registry; the token that opens it stays in the home folder.",
                  "Uma linha no .npmrc do projeto manda um escopo para um registry privado; o token que o abre fica na pasta pessoal.")
    return c


def behind(T):
    c = Canvas(720, 170, T(
        "A timeline of @planner/ui versions: 0.1.0, then 0.2.0. The planner is pinned at 0.1.0; npm outdated reports "
        "Current 0.1.0, Wanted 0.1.0 and Latest 0.2.0. Upgrading is a commit that installs 0.2.0.",
        "Uma linha do tempo de versões de @planner/ui: 0.1.0, depois 0.2.0. O planner está fixado em 0.1.0; o npm "
        "outdated relata Current 0.1.0, Wanted 0.1.0 e Latest 0.2.0. Atualizar é um commit que instala a 0.2.0."))
    c.line(40, 60, 680, 60, stroke="var(--wire)", arrow=True)
    c.text(680, 44, T("releases", "versões"), size=10, anchor="end", fill="var(--paper-dim)")
    for x, v in [(160, "0.1.0"), (460, "0.2.0")]:
        c.rect(x - 40, 46, 80, 28, fill="var(--ink)", stroke="var(--phosphor)")
        c.text(x, 60, v, mono=True, size=10.5, fill="var(--phosphor)")
    c.text(460, 92, "+ progressBar", mono=True, size=10)
    c.rect(100, 112, 120, 36, fill="var(--panel)", stroke="var(--amber)")
    c.text(160, 130, T("the planner", "o planner"), size=10.5)
    c.line(160, 112, 160, 78, stroke="var(--amber)", arrow=True)
    c.text(240, 124, "Current 0.1.0 · Wanted 0.1.0 · Latest 0.2.0", mono=True, size=9.5, anchor="start", fill="var(--paper-dim)")
    c.text(240, 142, T("upgrading is a commit, made on purpose", "atualizar é um commit, feito de propósito"), size=10, anchor="start", fill="var(--paper-dim)")
    c.caption = T("A pinned consumer stays where it is until somebody moves it, and npm outdated says how far behind it is.",
                  "Quem consome com versão fixa fica onde está até alguém mudar, e o npm outdated diz quanto está atrás.")
    return c


FIGURES = [("publishing", scopes), ("a-second-release", behind)]
