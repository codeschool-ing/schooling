from fig import Canvas


def layers(T):
    c = Canvas(720, 200, T(
        "Four places a setting can come from, from farthest to closest to the command: the default in the code, a .env file, "
        "the real environment, and a command-line flag. Each one closer to the command overrides the ones before it.",
        "Quatro lugares de onde uma configuração pode vir, do mais longe ao mais perto do comando: o padrão no código, um "
        "arquivo .env, o ambiente de verdade, e uma flag na linha de comando. Cada um mais perto do comando sobrepõe os anteriores."))
    rows = [(T("the default in the code", "o padrão no código"), '?? "data/links.json"'),
            (T("a .env file", "um arquivo .env"), "--env-file=.env"),
            (T("the real environment", "o ambiente de verdade"), "DATA_FILE=… node"),
            (T("a flag on the command line", "uma flag na linha de comando"), "--file …")]
    for i, (name, ex) in enumerate(rows):
        x = 20 + i * 172
        c.rect(x, 50, 160, 80, fill="var(--ink)" if i == 3 else "var(--panel)", stroke="var(--phosphor)" if i == 3 else "var(--wire)")
        c.text(x + 80, 78, name, size=10.5, fill="var(--phosphor)" if i == 3 else "var(--paper)")
        c.text(x + 80, 104, ex, mono=True, size=9, fill="var(--paper-dim)")
        if i < 3:
            c.line(x + 160, 90, x + 170, 90, stroke="var(--paper-dim)", arrow=True)
    c.line(20, 160, 700, 160, stroke="var(--amber)", arrow=True)
    c.text(700, 178, T("closer to the command: it wins", "mais perto do comando: vence"), anchor="end", size=10, fill="var(--amber)")
    c.text(20, 178, T("farther: used only if nothing else says", "mais longe: só vale se nada mais disser"), anchor="start", size=10, fill="var(--paper-dim)")
    c.caption = T("Whoever is closest to the command decides; a default is only the last resort.",
                  "Quem está mais perto do comando decide; um padrão é só o último recurso.")
    return c


FIGURES = [("argv", layers)]
