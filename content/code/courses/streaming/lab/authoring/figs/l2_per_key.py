NAME = "l2-per-key"
W, H = 720, 270
LABEL = ("Left: one log holding every event in one total order, recife and olinda interleaved, with one writer in front of it. Right: the same events split by key into two logs. A hash of the key picks the log, so every recife event goes to log 0 and every olinda event to log 1. Each log keeps its own order, and nothing orders log 0 against log 1.",
         "À esquerda: um log com todos os eventos numa ordem total, recife e olinda intercalados, com um único escritor na frente. À direita: os mesmos eventos divididos por chave em dois logs. Um hash da chave escolhe o log, então todo evento de recife vai para o log 0 e todo evento de olinda para o log 1. Cada log mantém a própria ordem, e nada ordena o log 0 em relação ao log 1.")
CAPTION = ("A total order needs one place every event goes through; order per key needs one place per key.",
           "Uma ordem total precisa de um lugar por onde passa todo evento; ordem por chave precisa de um lugar por chave.")
PT = {"one log: total order": "um log: ordem total", "by key: order per key": "por chave: ordem por chave",
      "log 0": "log 0", "log 1": "log 1", "hash(key) % 2": "hash(chave) % 2",
      "no order between the two logs": "nenhuma ordem entre os dois logs",
      "every write goes through one place": "toda escrita passa por um lugar só"}
SAME = ["log 0", "log 1"]
SEQ = ["R", "O", "R", "O", "R", "R", "O", "R"]
def cell(s, x, y, k, i):
    col = "var(--phosphor)" if k == "R" else "var(--amber)"
    s.rect(x, y, 34, 30, fill="var(--panel)", stroke=col)
    s.text(x + 17, y + 15, ("rec" if k == "R" else "oli") + str(i), size=9.5, fill=col, mono=True)
def draw(s, t):
    s.text(175, 30, t("one log: total order"), size=11, weight=600)
    for i, k in enumerate(SEQ):
        cell(s, 20 + i * 40, 110, k, i)
    s.text(175, 170, t("every write goes through one place"), size=9.5, fill="var(--paper-dim)")
    s.line(360, 20, 360, 250, stroke="var(--wire)", dash="3 4")
    s.text(545, 30, t("by key: order per key"), size=11, weight=600)
    s.text(545, 58, t("hash(key) % 2"), size=9.5, fill="var(--paper-dim)", mono=True)
    s.text(400, 100, t("log 0"), size=9.5, fill="var(--paper-dim)")
    s.text(400, 170, t("log 1"), size=9.5, fill="var(--paper-dim)")
    r = [i for i, k in enumerate(SEQ) if k == "R"]
    o = [i for i, k in enumerate(SEQ) if k == "O"]
    for j, i in enumerate(r):
        cell(s, 425 + j * 40, 85, "R", i)
    for j, i in enumerate(o):
        cell(s, 425 + j * 40, 155, "O", i)
    s.text(545, 222, t("no order between the two logs"), size=9.5, fill="var(--paper-dim)")
