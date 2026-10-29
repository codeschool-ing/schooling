from fig import Canvas


def chain(T):
    c = Canvas(720, 230, T(
        "The chain this lesson builds. In the browser, the error and unhandledrejection listeners and the planner's "
        "own catches call report, which sends a beacon to /errors. Vite's proxy passes it to the collector, which "
        "writes one line of JSON per report to errors.jsonl. Later, symbolicate.mjs reads a report's stack with the "
        "release's source maps, kept in maps/, off the public host, and prints the original lines.",
        "A cadeia que esta aula constrói. No navegador, os listeners de error e unhandledrejection e os catches do "
        "próprio planner chamam report, que manda um beacon para /errors. O proxy do Vite o repassa ao coletor, que "
        "grava uma linha de JSON por relatório em errors.jsonl. Depois, o symbolicate.mjs lê a pilha de um "
        "relatório com os source maps da release, guardados em maps/, fora do host público, e imprime as linhas "
        "originais."))
    c.text(20, 20, T("somebody's browser", "o navegador de alguém"), size=10.5, anchor="start", weight="600")
    c.rect(20, 32, 230, 130, fill="var(--panel)")
    for i, s in enumerate(['"error"', '"unhandledrejection"', "saveDone · load · Planner"]):
        c.text(36, 54 + i * 22, s, mono=True, size=10, anchor="start")
    c.rect(36, 120, 198, 28, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(135, 134, "report()", mono=True, size=10.5, fill="var(--phosphor)")
    c.line(250, 134, 300, 134, stroke="var(--phosphor)", arrow=True)
    c.text(275, 120, "/errors", mono=True, size=9.5, fill="var(--phosphor)")
    c.text(310, 20, T("the team's side", "o lado da equipe"), size=10.5, anchor="start", weight="600")
    c.rect(302, 110, 170, 48, fill="var(--panel)")
    c.text(387, 134, "collector.mjs", mono=True, size=10.5)
    c.line(472, 134, 520, 134, stroke="var(--paper-dim)", arrow=True)
    c.rect(522, 110, 178, 48, fill="var(--panel)")
    c.text(611, 134, "errors.jsonl", mono=True, size=10.5)
    c.rect(522, 34, 178, 48, fill="var(--ink)", stroke="var(--amber)", dash="4 3")
    c.text(611, 52, "maps/<release>/", mono=True, size=10, fill="var(--amber)")
    c.text(611, 68, T("never on the host", "nunca no host"), size=9.5, fill="var(--amber)")
    c.rect(302, 176, 398, 40, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(320, 196, "symbolicate.mjs", mono=True, size=10.5, anchor="start", fill="var(--phosphor)")
    c.text(690, 196, "src/main.ts:16:45", mono=True, size=10.5, anchor="end")
    c.line(611, 160, 611, 174, stroke="var(--paper-dim)", arrow=True)
    c.line(700, 82, 708, 82, stroke="var(--amber)")
    c.path("M 708 82 L 708 196 L 702 196", stroke="var(--amber)")
    c.caption = T("Catch, send, keep, then read the stack with the maps of the same release.",
                  "Capturar, mandar, guardar, e depois ler a pilha com os maps da mesma release.")
    return c


def maps(T):
    c = Canvas(720, 190, T(
        "A source map joins positions. The built file index.js has one long line, and the position line 1, column "
        "5016 in it is inside the function the build renamed A. The map records that this position came from src/main.ts, line 16, column 45, "
        "where the planner's own code throws.",
        "Um source map liga posições. O arquivo construído index.js tem uma linha comprida, e a posição linha 1, "
        "coluna 5016 nele fica dentro da função que o build renomeou para A. O map registra que essa posição veio de src/main.ts, linha 16, coluna "
        "45, onde o código do próprio planner lança o erro."))
    c.text(20, 20, T("what the browser ran", "o que o navegador rodou"), size=10.5, anchor="start", weight="600")
    c.rect(20, 32, 300, 64, fill="var(--panel)")
    c.text(32, 54, "index-BzxC4LxE.js", mono=True, size=10, anchor="start", fill="var(--paper-dim)")
    c.text(32, 76, "function A(){if(location.search…", mono=True, size=10, anchor="start", fill="var(--amber)")
    c.text(170, 112, "1:5016", mono=True, size=11, fill="var(--amber)")
    c.text(400, 20, T("what the team wrote", "o que a equipe escreveu"), size=10.5, anchor="start", weight="600")
    c.rect(400, 32, 300, 64, fill="var(--panel)")
    c.text(412, 54, "src/main.ts", mono=True, size=10, anchor="start", fill="var(--paper-dim)")
    c.text(412, 76, 'if (location.search === "?bug")', mono=True, size=9.5, anchor="start", fill="var(--phosphor)")
    c.text(550, 112, "16:45", mono=True, size=11, fill="var(--phosphor)")
    c.rect(220, 132, 280, 40, fill="var(--ink)", stroke="var(--wire)", dash="4 3")
    c.text(360, 152, "index-BzxC4LxE.js.map", mono=True, size=10.5)
    c.line(200, 116, 222, 140, stroke="var(--paper-dim)")
    c.line(498, 140, 520, 116, stroke="var(--paper-dim)", arrow=True)
    c.caption = T("The map is the only thing that knows both positions, which is why it has to be the map of the same build.",
                  "O map é a única coisa que conhece as duas posições, e por isso precisa ser o map do mesmo build.")
    return c


FIGURES = [("errors-nobody-sees", chain), ("source-maps", maps)]
