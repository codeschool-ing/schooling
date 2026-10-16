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


FIGURES = [("npm-ci", install_ci)]
