"""Lesson 16: the figures."""
from fig import Fig

T = {
    "en": dict(
        aria="Where a secret should live and where it should not. On the left, the places a secret leaks from: the code, a committed configuration file, the repository's history, a log line, a screenshot in a ticket. On the right, the path a secret should take: it is kept in a secret manager or an environment file that git ignores, it reaches the running process as an environment variable, and the process refuses to start without it. Only the process ever reads it.",
        bad="where secrets leak from", good="where a secret belongs",
        leaks=["the code", "a committed config file", "the repository's history", "a log line", "a screenshot in a ticket"],
        store="secret manager, or .env", store2="(ignored by git)",
        envv="environment variable", proc="the process", proc2="refuses to start without it",
        cap="A secret reaches the process through its environment, and nothing that is shared or kept ever holds it.",
    ),
    "pt": dict(
        aria="Onde um segredo deve morar e onde não deve. À esquerda, os lugares de onde um segredo vaza: o código, um arquivo de configuração no commit, o histórico do repositório, uma linha de log, uma captura de tela num chamado. À direita, o caminho que um segredo deve fazer: fica num cofre de segredos ou num arquivo de ambiente que o git ignora, chega ao processo em execução como variável de ambiente, e o processo se recusa a iniciar sem ele. Só o processo o lê.",
        bad="de onde segredos vazam", good="onde um segredo deve ficar",
        leaks=["o código", "um arquivo de configuração no commit", "o histórico do repositório", "uma linha de log", "uma captura de tela num chamado"],
        store="cofre de segredos, ou .env", store2="(ignorado pelo git)",
        envv="variável de ambiente", proc="o processo", proc2="se recusa a iniciar sem ele",
        cap="Um segredo chega ao processo pelo ambiente, e nada que é compartilhado ou guardado o contém.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l16-paths", 720, 290, t["aria"])
    f.text(170, 22, t["bad"], fill="paper-dim", italic=True)
    for i, leak in enumerate(t["leaks"]):
        f.box(20, 40 + i * 46, 300, 36, [leak], stroke="amber", size=9.5)
    f.text(540, 22, t["good"], fill="paper-dim", italic=True)
    f.box(400, 40, 280, 50, [t["store"], t["store2"]], stroke="phosphor")
    f.box(400, 120, 280, 40, [t["envv"]], stroke="wire")
    f.box(400, 190, 280, 50, [t["proc"], t["proc2"]], stroke="phosphor", bold=False)
    f.arrow([(540, 90), (540, 120)])
    f.arrow([(540, 160), (540, 190)])
    out["l16-paths"] = f.json(t["cap"])
    return out
