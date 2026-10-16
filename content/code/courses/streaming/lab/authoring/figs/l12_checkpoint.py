NAME = "l12-checkpoint"
W, H = 720, 230
LABEL = ("The life of one micro-batch, N, against the checkpoint. First Spark writes offsets/N, the plan of which offsets the batch will read. Then the batch runs, reading those offsets and the state. Then its rows are written to the sink. Last, commits/N is written. If the process dies after offsets/N and before commits/N, a restart finds the plan without its commit and runs batch N again with the same offsets, so the sink may receive batch N twice.",
         "A vida de um micro-batch, N, em relação ao checkpoint. Primeiro o Spark escreve offsets/N, o plano de quais offsets o batch vai ler. Depois o batch roda, lendo esses offsets e o estado. Depois as linhas dele são escritas no sink. Por último, commits/N é escrito. Se o processo morre depois de offsets/N e antes de commits/N, um reinício encontra o plano sem o commit e roda o batch N de novo com os mesmos offsets, então o sink pode receber o batch N duas vezes.")
CAPTION = ("The plan is written before the batch and the commit after it; a crash in between means the same batch runs again.",
           "O plano é escrito antes do batch e o commit depois; uma queda no meio significa que o mesmo batch roda de novo.")
PT = {"write offsets/N": "escreve offsets/N", "the plan": "o plano",
      "run batch N": "roda o batch N", "offsets + state": "offsets + estado",
      "write to the sink": "escreve no sink", "rows out": "linhas saem",
      "write commits/N": "escreve commits/N", "batch done": "batch concluído",
      "crash here": "queda aqui",
      "restart: offsets/N has no commit, so batch N runs again, same offsets":
      "reinício: offsets/N não tem commit, então o batch N roda de novo, mesmos offsets"}
SAME = []


def draw(s, t):
    boxes = [("write offsets/N", "the plan"), ("run batch N", "offsets + state"),
             ("write to the sink", "rows out"), ("write commits/N", "batch done")]
    xs = [30, 205, 380, 555]
    for (a, b), x in zip(boxes, xs):
        s.rect(x, 50, 140, 50, stroke="var(--wire)")
        s.text(x + 70, 68, t(a), size=10.5, weight=600)
        s.text(x + 70, 86, t(b), size=9.5, fill="var(--paper-dim)")
    for x in xs[:-1]:
        s.path(f"M {x + 142} 75 L {x + 172} 75", arrow=True)
    cx = 380 + 140 + 17
    s.line(cx - 7, 112, cx + 7, 126, stroke="var(--amber)", sw=2)
    s.line(cx + 7, 112, cx - 7, 126, stroke="var(--amber)", sw=2)
    s.text(cx, 140, t("crash here"), size=9.5, fill="var(--amber)")
    s.path(f"M {cx} 150 Q {cx} 185 {(205 + 70 + cx) / 2} 185 Q 275 185 275 106",
           stroke="var(--amber)", arrow=True, dash="4 3")
    s.text(360, 205, t("restart: offsets/N has no commit, so batch N runs again, same offsets"),
           size=9.5, fill="var(--amber)")
