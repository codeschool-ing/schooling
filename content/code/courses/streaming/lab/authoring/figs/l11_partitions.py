# Lesson 11, idle sources: three partitions, the latest event time in each, and the minimum.
NAME = "l11-partitions"
W, H = 720, 230
LABEL = ("Three partitions after sale 10. Partition 0, Recife and Olinda, has reached 09:21:00. Partition 1, Natal and Caruaru, has reached 09:12:30. Partition 2, João Pessoa, has nothing. The watermark is the lowest of the three minus the bound, so with partition 2 empty there is no watermark at all; leaving it out as idle gives 09:12:30 minus two minutes, 09:10:30.",
         "Três partições depois da venda 10. A partição 0, Recife e Olinda, chegou a 09:21:00. A partição 1, Natal e Caruaru, chegou a 09:12:30. A partição 2, João Pessoa, não tem nada. O watermark é o menor dos três menos o limite, então com a partição 2 vazia não existe watermark nenhum; deixá-la de fora como ociosa dá 09:12:30 menos dois minutos, 09:10:30.")
CAPTION = ("The slowest partition sets the watermark. An empty one sets none, until it is declared idle.",
           "A partição mais lenta define o watermark. Uma vazia não define nenhum, até ser declarada ociosa.")
PT = {"partition 0: recife, olinda": "partição 0: recife, olinda", "partition 1: natal, caruaru": "partição 1: natal, caruaru",
      "partition 2: joao-pessoa": "partição 2: joao-pessoa", "latest 09:21:00": "mais recente 09:21:00",
      "latest 09:12:30": "mais recente 09:12:30", "nothing yet": "nada ainda",
      "lowest of the three: none, so no watermark": "o menor dos três: nenhum, então sem watermark",
      "partition 2 idle: 09:12:30 minus 2 min = 09:10:30": "partição 2 ociosa: 09:12:30 menos 2 min = 09:10:30"}
def draw(s, t):
    rows = (("partition 0: recife, olinda", "latest 09:21:00", 560, "var(--phosphor)"),
            ("partition 1: natal, caruaru", "latest 09:12:30", 400, "var(--phosphor)"),
            ("partition 2: joao-pessoa", "nothing yet", None, "var(--wire)"))
    for i, (name, what, x, col) in enumerate(rows):
        y = 40 + i * 40
        s.text(20, y, t(name), size=10, anchor="start")
        s.line(220, y, 640, y, stroke="var(--wire)", dash="2 4", sw=0.8)
        if x:
            s.line(220, y, x, y, stroke=col, sw=3)
            s.circle(x, y, 4, fill=col)
            s.text(x + 10, y, t(what), size=9.5, fill="var(--paper-dim)", anchor="start")
        else:
            s.text(230, y, t(what), size=9.5, fill="var(--paper-dim)", anchor="start")
    s.rect(20, 160, 680, 26, fill="var(--panel)", stroke="var(--amber)")
    s.text(360, 173, t("lowest of the three: none, so no watermark"), size=10, fill="var(--paper)")
    s.text(360, 206, t("partition 2 idle: 09:12:30 minus 2 min = 09:10:30"), size=10, fill="var(--amber)")
