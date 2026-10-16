NAME = "l12-micro-batch"
W, H = 720, 270
LABEL = ("Spark's micro-batch model. Above, rows arrive in the topic one after another. A trigger cuts them into slices, and each slice becomes one numbered batch. Each batch reads only its new rows, combines them with the state the batch before it left, writes the rows of the result that changed to the sink, and hands the state on to the next batch.",
         "O modelo de micro-batch do Spark. Em cima, as linhas chegam ao tópico uma depois da outra. Um trigger corta essas linhas em fatias, e cada fatia vira um batch numerado. Cada batch lê só as linhas novas, junta com o estado que o batch anterior deixou, escreve no sink as linhas do resultado que mudaram e passa o estado adiante para o próximo batch.")
CAPTION = ("Each micro-batch reads only what is new; what it needs from the past travels as state from one batch to the next.",
           "Cada micro-batch lê só o que é novo; o que ele precisa do passado viaja como estado de um batch para o seguinte.")
PT = {"input": "entrada", "batches": "batches", "sink": "sink",
      "rows arriving in the topic": "linhas chegando ao tópico",
      "batch 0": "batch 0", "batch 1": "batch 1", "batch 2": "batch 2", "batch 3": "batch 3",
      "new rows": "linhas novas", "+ state": "+ estado", "state": "estado",
      "changed rows out": "linhas alteradas saem", "trigger": "trigger"}
SAME = ["batches", "sink", "batch 0", "batch 1", "batch 2", "batch 3", "trigger"]


def draw(s, t):
    s.text(20, 50, t("input"), size=11, weight=600, anchor="start")
    s.text(20, 150, t("batches"), size=11, weight=600, anchor="start")
    s.text(20, 238, t("sink"), size=11, weight=600, anchor="start")
    x0, cw, gap = 110, 18, 2
    sw_ = 6 * (cw + gap)
    for i in range(24):
        x = x0 + i * (cw + gap)
        s.rect(x, 40, cw, 20, fill="var(--phosphor-dim)" if (i // 6) % 2 == 0 else "var(--phosphor)", stroke="none", rx=2)
    s.text(x0 + 2 * sw_, 24, t("rows arriving in the topic"), size=9.5, fill="var(--paper-dim)")
    end = x0 + 4 * sw_
    for b in range(4):
        bx = x0 + b * sw_
        tx = bx + sw_ - gap / 2
        s.line(tx, 32, tx, 68, stroke="var(--amber)", sw=1.2, dash="3 2")
        cx = bx + (sw_ - gap) / 2
        s.rect(cx - 50, 120, 100, 60, stroke="var(--wire)")
        s.text(cx, 136, t(f"batch {b}"), size=10.5, weight=600)
        s.text(cx, 153, t("new rows"), size=9.5, fill="var(--paper-dim)")
        s.text(cx, 167, t("+ state"), size=9.5, fill="var(--amber)")
        s.path(f"M {cx} 64 L {cx} 116", arrow=True)
        s.path(f"M {cx} 182 L {cx} 224", stroke="var(--phosphor)", arrow=True)
        s.rect(cx - 40, 228, 80, 20, fill="var(--panel)", stroke="var(--phosphor-dim)", rx=3)
        s.path(f"M {cx + 51} 150 L {cx + sw_ - 54} 150", stroke="var(--amber)", arrow=True)
    s.text(end + 9, 150, t("state"), size=9.5, fill="var(--amber)", anchor="start")
    s.text(end + 6, 238, t("changed rows out"), size=9.5, fill="var(--phosphor)", anchor="start")
    s.text(end + 6, 50, t("trigger"), size=9.5, fill="var(--amber)", anchor="start")
