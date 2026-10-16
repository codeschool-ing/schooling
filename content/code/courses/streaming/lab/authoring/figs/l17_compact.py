NAME = "l17-compact"
W, H = 720, 210
LABEL = ("Above, a topic of stock updates keyed by book, in the order they were written: bk-01, bk-02, bk-01, bk-03, bk-02, bk-01. Below, the same topic after compaction: only the last message for each key remains, bk-03, bk-02 and bk-01, at their original offsets.",
         "Em cima, um tópico de atualizações de estoque com a chave do livro, na ordem em que foram escritas: bk-01, bk-02, bk-01, bk-03, bk-02, bk-01. Embaixo, o mesmo tópico depois da compactação: só a última mensagem de cada chave fica, bk-03, bk-02 e bk-01, nos offsets originais.")
CAPTION = ("Compaction keeps the last value of each key: the topic is bounded by its keys, not by time.",
           "A compactação guarda o último valor de cada chave: o tópico é limitado pelas chaves, não pelo tempo.")
PT = {"before cleaning": "antes da limpeza", "after cleaning": "depois da limpeza",
      "replaced by a later value": "substituída por um valor posterior"}
SAME = []
def draw(s, t):
    msgs = [("bk-01", 12), ("bk-02", 7), ("bk-01", 11), ("bk-03", 4), ("bk-02", 6), ("bk-01", 9)]
    last = {k: i for i, (k, v) in enumerate(msgs)}
    x0, w = 150, 88
    s.text(20, 60, t("before cleaning"), size=10.5, weight=600, anchor="start")
    s.text(20, 150, t("after cleaning"), size=10.5, weight=600, anchor="start")
    for i, (k, v) in enumerate(msgs):
        x = x0 + i * w
        keep = last[k] == i
        s.rect(x, 40, w - 10, 40, stroke="var(--phosphor)" if keep else "var(--wire)", dash=None if keep else "3 3")
        s.text(x + (w - 10) / 2, 53, str(i), size=9, mono=True, fill="var(--paper-dim)")
        s.text(x + (w - 10) / 2, 68, f"{k}: {v}", size=10, mono=True, fill="var(--paper)" if keep else "var(--paper-dim)")
        if keep:
            s.rect(x, 130, w - 10, 40, stroke="var(--phosphor)")
            s.text(x + (w - 10) / 2, 143, str(i), size=9, mono=True, fill="var(--paper-dim)")
            s.text(x + (w - 10) / 2, 158, f"{k}: {v}", size=10, mono=True)
            s.line(x + (w - 10) / 2, 84, x + (w - 10) / 2, 126, stroke="var(--phosphor-dim)", arrow=True)
    s.text(x0 + 1 * w + 39, 100, t("replaced by a later value"), size=9.5, fill="var(--paper-dim)")
