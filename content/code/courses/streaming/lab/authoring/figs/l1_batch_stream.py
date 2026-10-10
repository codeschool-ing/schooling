NAME = "l1-batch-stream"
W, H = 720, 250
LABEL = ("The same day of sales handled two ways. Above, a batch: sales collect all day and one job at two in the morning reads them all, so every answer is about yesterday. Below, a stream: each sale is handled seconds after it happens, and one sale from Natal arrives three hours and forty minutes late, after sales that happened later than it.",
         "O mesmo dia de vendas tratado de dois jeitos. Em cima, um batch: as vendas se acumulam o dia todo e um job às duas da manhã lê todas, então toda resposta é sobre ontem. Embaixo, um stream: cada venda é tratada segundos depois de acontecer, e uma venda de Natal chega três horas e quarenta minutos atrasada, depois de vendas que aconteceram mais tarde que ela.")
CAPTION = ("A batch waits for the period to close; a stream handles each event as it comes, including the one that comes late.",
           "Um batch espera o período fechar; um stream trata cada evento quando ele chega, inclusive o que chega atrasado.")
PT = {"batch": "batch", "stream": "stream", "sales during the day": "vendas durante o dia",
      "one job at 02:00": "um job às 02:00", "reads all of yesterday": "lê todo o dia de ontem",
      "each sale handled seconds after it happens": "cada venda tratada segundos depois de acontecer",
      "late: happened 10:20, arrived 14:00": "atrasada: aconteceu 10:20, chegou 14:00",
      "09:00": "09:00", "21:00": "21:00", "02:00": "02:00"}
SAME = ["batch", "stream"]
def draw(s, t):
    x0, x1 = 90, 520
    # axis labels
    for y, name in ((70, "batch"), (175, "stream")):
        s.text(20, y, t(name), size=11, weight=600, anchor="start")
        s.line(x0, y, x1, y, stroke="var(--wire)")
    s.text(x0, 38, t("09:00"), size=9, fill="var(--paper-dim)")
    s.text(x1, 38, t("21:00"), size=9, fill="var(--paper-dim)")
    s.text(630, 38, t("02:00"), size=9, fill="var(--paper-dim)")
    xs = [110, 160, 185, 215, 245, 300, 330, 360, 395, 440, 470, 500]
    for x in xs:
        s.circle(x, 70, 4, fill="var(--phosphor)")
    s.text((x0 + x1) / 2, 92, t("sales during the day"), size=9.5, fill="var(--paper-dim)")
    s.rect(565, 48, 130, 44, stroke="var(--amber)")
    s.text(630, 63, t("one job at 02:00"), size=10, weight=600)
    s.text(630, 79, t("reads all of yesterday"), size=9.5, fill="var(--paper-dim)")
    s.path("M 520 70 L 560 70", arrow=True)
    for x in xs:
        s.circle(x, 175, 4, fill="var(--phosphor)")
        s.line(x, 168, x, 150, stroke="var(--phosphor-dim)", sw=1)
    # late event: belongs at 175, arrives at 300
    s.circle(138, 175, 4, fill="none", stroke="var(--amber)")
    s.circle(270, 175, 4, fill="var(--amber)")
    s.line(270, 168, 270, 150, stroke="var(--amber)", sw=1)
    s.path("M 141 184 Q 204 214 266 184", stroke="var(--amber)", arrow=True)
    s.text(204, 226, t("late: happened 10:20, arrived 14:00"), size=9.5, fill="var(--amber)")
    s.text(305, 136, t("each sale handled seconds after it happens"), size=9.5, fill="var(--paper-dim)")
