from fig import Canvas


def race(T):
    c = Canvas(720, 250, T(
        "A timeline from 0 to 700 milliseconds. At 0 the course becomes statistics and its request starts; it "
        "answers at 600. Almost at once the course becomes Spanish and its request starts; it answers about 100 milliseconds later. "
        "The careless watcher shows Spanish when it arrives, and then statistics at 600, which is wrong. The careful "
        "watcher's cleanup marked the statistics run stale when Spanish was chosen, so at 600 it drops the "
        "answer and keeps Spanish.",
        "Uma linha do tempo de 0 a 700 milissegundos. Em 0 o curso vira statistics e a requisição dele começa; "
        "ela responde em 600. Quase no mesmo instante o curso vira Spanish e a requisição dele começa; ela "
        "responde cerca de 100 milissegundos depois. O watcher descuidado mostra Spanish nesse momento e depois statistics em 600, o que está "
        "errado. A limpeza do watcher cuidadoso marcou a execução de statistics como velha quando Spanish foi "
        "escolhido, então em 600 ele descarta a resposta e mantém Spanish."))
    x0, scale = 150, 0.8   # 700 ms -> 560 px
    X = lambda ms: x0 + ms * scale
    c.line(X(0), 220, X(700), 220, stroke="var(--paper-dim)", arrow=True)
    for ms in (0, 100, 600):
        c.line(X(ms), 215, X(ms), 225, stroke="var(--paper-dim)")
        c.text(X(ms), 236, f"{ms} ms", mono=True, size=9.5, fill="var(--paper-dim)")
    c.text(20, 40, T("statistics asked", "statistics pedido"), anchor="start", size=10.5)
    c.rect(X(0), 30, X(600) - X(0), 20, fill="var(--ink)", stroke="var(--amber)")
    c.text(X(300), 40, T("slow answer", "resposta lenta"), size=9.5, fill="var(--amber)")
    c.text(20, 75, T("Spanish asked", "Spanish pedido"), anchor="start", size=10.5)
    c.rect(X(5), 65, X(105) - X(5), 20, fill="var(--ink)", stroke="var(--phosphor)")
    c.text(20, 125, T("without cleanup", "sem limpeza"), anchor="start", size=10.5, weight="600")
    c.rect(X(105), 113, X(600) - X(105), 24, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(X(350), 125, T("shows Spanish", "mostra Spanish"), size=10, fill="var(--phosphor)")
    c.rect(X(600), 113, X(700) - X(600), 24, fill="var(--panel)", stroke="var(--amber)")
    c.text(X(650), 125, "statistics", mono=True, size=10, fill="var(--amber)")
    c.text(20, 170, T("with cleanup", "com limpeza"), anchor="start", size=10.5, weight="600")
    c.rect(X(105), 158, X(700) - X(105), 24, fill="var(--panel)", stroke="var(--phosphor)")
    c.text(X(350), 170, T("shows Spanish", "mostra Spanish"), size=10, fill="var(--phosphor)")
    c.line(X(600), 52, X(600), 155, stroke="var(--amber)", dash="3 3")
    c.text(X(600) - 4, 196, T("stale: dropped", "velha: descartada"), anchor="end", size=9.5, fill="var(--amber)")
    c.caption = T("The answers arrive in the order the server finishes them, not the order they were asked. Only "
                  "the cleanup knows which question is still current.",
                  "As respostas chegam na ordem em que o servidor termina, não na ordem em que foram pedidas. Só a "
                  "limpeza sabe qual pergunta ainda vale.")
    return c


FIGURES = [("cleanup", race)]
