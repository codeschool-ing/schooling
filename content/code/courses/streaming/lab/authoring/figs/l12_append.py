NAME = "l12-append"
W, H = 720, 250
LABEL = ("Append mode over the two hundred sales. Eight five-minute windows from 09:00 to 09:40 lie along a time axis. Below them, the watermark Spark used in each batch: zero in batch 0, then 09:08:12, 09:15:49, 09:24:24, 09:34:33 and 09:34:41. Each window is printed in the first batch whose watermark has passed its end: 09:00 in batch 1, 09:05 and 09:10 in batch 2, 09:15 in batch 3, 09:20 and 09:25 in batch 4. The 09:30 and 09:35 windows are never printed, because the watermark stops at 09:34:41.",
         "O modo append sobre as duzentas vendas. Oito janelas de cinco minutos, de 09:00 a 09:40, ao longo de um eixo de tempo. Abaixo delas, o watermark que o Spark usou em cada batch: zero no batch 0, depois 09:08:12, 09:15:49, 09:24:24, 09:34:33 e 09:34:41. Cada janela é impressa no primeiro batch cujo watermark passou do fim dela: 09:00 no batch 1, 09:05 e 09:10 no batch 2, 09:15 no batch 3, 09:20 e 09:25 no batch 4. As janelas de 09:30 e 09:35 nunca são impressas, porque o watermark para em 09:34:41.")
CAPTION = ("A window leaves in append mode when the watermark passes its end; the last two wait for a sale that never comes.",
           "Uma janela sai no modo append quando o watermark passa do fim dela; as duas últimas esperam uma venda que nunca chega.")
PT = {"windows": "janelas", "watermark": "watermark", "printed in": "impressa no",
      "never printed": "nunca impressas", "last sale 09:36:41": "última venda 09:36:41"}
for h in ("09:00", "09:05", "09:10", "09:15", "09:20", "09:25", "09:30", "09:35", "09:40"):
    PT[h] = h
for b in ("1", "2", "3", "4", "5"):
    PT["batch " + b] = "batch " + b
SAME = ["watermark", "batch 1", "batch 2", "batch 3", "batch 4", "batch 5"]


def X(hh, mm, ss=0):
    return 110 + ((hh - 9) * 60 + mm + ss / 60) * 14


def draw(s, t):
    s.text(20, 70, t("windows"), size=11, weight=600, anchor="start")
    s.text(20, 160, t("watermark"), size=11, weight=600, anchor="start")
    emitted = {0: 1, 5: 2, 10: 2, 15: 3, 20: 4, 25: 4}
    for i, m in enumerate(range(0, 40, 5)):
        x = X(9, m)
        b = emitted.get(m)
        col = "var(--phosphor)" if b else "var(--amber)"
        s.rect(x + 1, 55, 68, 30, fill="var(--panel)", stroke=col, dash=None if b else "4 3")
        s.text(x + 35, 70, t(f"09:{m:02d}"), size=10, mono=True)
        if b:
            s.text(x + 35, 98, t(f"batch {b}"), size=9, fill="var(--phosphor)")
    s.text(X(9, 32), 112, t("never printed"), size=9.5, fill="var(--amber)")
    s.text(20, 98, t("printed in"), size=9.5, fill="var(--paper-dim)", anchor="start")
    s.line(X(9, 0), 140, X(9, 40), 140, stroke="var(--wire)")
    marks = [(1, 9, 8, 12, "09:08:12"), (2, 9, 15, 49, "09:15:49"), (3, 9, 24, 24, "09:24:24"),
             (4, 9, 34, 33, "09:34:33")]
    for b, h, m, sec, lab in marks:
        x = X(h, m, sec)
        s.line(x, 128, x, 152, stroke="var(--phosphor)", sw=1.5)
        s.text(x, 166, t(f"batch {b}"), size=9, fill="var(--paper-dim)")
        s.text(x, 180, lab, size=9, mono=True, fill="var(--paper)")
    x5 = X(9, 34, 41)
    s.line(x5, 128, x5, 152, stroke="var(--amber)", sw=1.5)
    s.text(x5 - 4, 200, t("batch 5"), size=9, fill="var(--amber)", anchor="end")
    s.text(x5 - 4, 214, "09:34:41", size=9, mono=True, fill="var(--amber)", anchor="end")
    xl = X(9, 36, 41)
    s.circle(xl, 140, 3.5, fill="var(--paper-dim)")
    s.text(xl + 6, 232, t("last sale 09:36:41"), size=9, fill="var(--paper-dim)", anchor="start")
    s.line(xl, 146, xl, 222, stroke="var(--paper-dim)", sw=0.8, dash="2 2")
