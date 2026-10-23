from fig import Canvas


def install_ci(T):
    c = Canvas(720, 250, T(
        "Two commands and three things on disk. npm install reads package.json, writes package-lock.json and fills node_modules. "
        "npm ci reads only package-lock.json, refuses if it does not match package.json, deletes node_modules and installs exactly what the lockfile lists.",
        "Dois comandos e três coisas no disco. O npm install lê o package.json, escreve o package-lock.json e preenche o node_modules. "
        "O npm ci lê só o package-lock.json, recusa se ele não bater com o package.json, apaga o node_modules e instala exatamente o que o lockfile lista."))
    for x, name, sub in ((30, "package.json", T("ranges you ask for", "as faixas que você pede")),
                         (275, "package-lock.json", T("exact versions installed", "as versões exatas instaladas")),
                         (520, "node_modules/", T("the code that runs", "o código que roda"))):
        c.rect(x, 100, 170, 54, fill="var(--panel)", stroke="var(--wire)")
        c.text(x + 85, 120, name, mono=True, size=11, fill="var(--paper)")
        c.text(x + 85, 140, sub, size=9.5, fill="var(--paper-dim)")
    c.text(30, 30, "npm install", mono=True, size=11.5, anchor="start", fill="var(--amber)")
    c.path("M115 98 C 115 60, 360 60, 360 96", stroke="var(--amber)")
    c.line(360, 90, 360, 97, stroke="var(--amber)", arrow=True)
    c.path("M115 98 C 115 40, 605 40, 605 96", stroke="var(--amber)")
    c.line(605, 90, 605, 97, stroke="var(--amber)", arrow=True)
    c.text(238, 86, T("writes what it resolved", "escreve o que resolveu"), size=9.5, fill="var(--amber)")
    c.text(480, 46, T("fills", "preenche"), size=9.5, fill="var(--amber)")
    c.text(30, 226, "npm ci", mono=True, size=11.5, anchor="start", fill="var(--phosphor)")
    c.path("M360 156 C 360 200, 605 200, 605 160", stroke="var(--phosphor)")
    c.line(605, 166, 605, 157, stroke="var(--phosphor)", arrow=True)
    c.text(483, 210, T("deletes, then installs exactly this", "apaga, depois instala exatamente isto"), size=9.5, fill="var(--phosphor)")
    c.path("M115 156 C 115 196, 360 196, 360 160", stroke="var(--phosphor)", dash="4 3")
    c.text(238, 208, T("only compares: refuses if they differ", "só compara: recusa se forem diferentes"), size=9.5, fill="var(--phosphor)")
    c.caption = T("On a laptop, npm install changes the lockfile. Where a deployment is built, npm ci reads it and changes nothing.",
                  "No notebook, o npm install muda o lockfile. Onde um deploy é montado, o npm ci o lê e não muda nada.")
    return c


def ranges(T):
    c = Canvas(720, 210, T(
        "A line of Express versions from 5.0.0 to 6.0.0 and beyond. The range ^5.1.0 covers 5.1.0 up to, but not "
        "including, 6.0.0. Current is 5.1.0, what node_modules holds; Wanted and Latest are both 5.3.0, the newest the "
        "range accepts. A 6.0.0, if one were published, would be Latest and outside the range, and npm update would not "
        "move to it.",
        "Uma linha de versões do Express de 5.0.0 a 6.0.0 e além. A faixa ^5.1.0 cobre de 5.1.0 até 6.0.0, sem incluir "
        "o 6.0.0. O Current é 5.1.0, o que o node_modules tem; Wanted e Latest são os dois 5.3.0, o mais novo que a faixa "
        "aceita. Um 6.0.0, se fosse publicado, seria o Latest e ficaria fora da faixa, e o npm update não iria até ele."))
    xs = {"5.0.0": 60, "5.1.0": 170, "5.2.0": 280, "5.3.0": 390, "6.0.0": 560}
    c.line(30, 110, 700, 110, stroke="var(--wire)", arrow=True)
    for v, x in xs.items():
        c.line(x, 104, x, 116, stroke="var(--paper-dim)")
        c.text(x, 130, v, mono=True, size=10, fill="var(--paper-dim)" if v != "6.0.0" else "var(--amber)")
    c.rect(170, 78, 385, 18, fill="var(--ink)", stroke="var(--phosphor)", rx=2)
    c.text(362, 87, "^5.1.0", mono=True, size=10, fill="var(--phosphor)")
    c.text(170, 60, "Current", mono=True, size=10)
    c.line(170, 66, 170, 76, stroke="var(--paper)")
    c.text(390, 60, "Wanted = Latest", mono=True, size=10, fill="var(--phosphor)")
    c.line(390, 66, 390, 76, stroke="var(--phosphor)")
    c.text(560, 160, T("a new major: outside the range", "um major novo: fora da faixa"), size=10, fill="var(--amber)")
    c.text(560, 178, T("npm update leaves it alone", "o npm update não mexe"), size=10, fill="var(--amber)")
    c.text(280, 160, T("npm update moves here", "o npm update vem até aqui"), size=10, fill="var(--phosphor)")
    c.caption = T("A caret range accepts every minor and patch release of its major, and nothing past it.",
                  "Uma faixa com circunflexo aceita toda versão minor e patch do seu major, e nada além dele.")
    return c


FIGURES = [("npm-ci", install_ci), ("updating", ranges)]
