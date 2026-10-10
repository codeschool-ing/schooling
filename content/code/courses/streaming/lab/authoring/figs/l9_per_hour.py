# Lesson 9, counting-by-arrival: the per-hour table of per_minute.py --size 60, as bars.
NAME = "l9-per-hour"
W, H = 720, 300
ROWS = [("09:00", 56, 57), ("10:00", 57, 62), ("11:00", 48, 59), ("12:00", 41, 54),
        ("13:00", 51, 60), ("14:00", 93, 54), ("15:00", 14, 14)]
LABEL = ("Bars of sales per hour, two per hour. Counted by event time the hours from 10:00 to 13:00 have 62, 59, 54 and 60 sales and 14:00 has 54. Counted by arrival, those four hours have 57, 48, 41 and 51, and 14:00 has 93.",
         "Barras de vendas por hora, duas por hora. Contadas pelo tempo do evento, as horas de 10:00 a 13:00 têm 62, 59, 54 e 60 vendas e 14:00 tem 54. Contadas pela chegada, essas quatro horas têm 57, 48, 41 e 51, e 14:00 tem 93.")
CAPTION = ("The same 360 sales per hour. By arrival, the morning loses Natal's sales and 14:00 gains them all.",
           "As mesmas 360 vendas por hora. Pela chegada, a manhã perde as vendas de Natal e as 14:00 ganham todas.")
PT = {"arrived": "chegaram", "happened": "aconteceram", "sales": "vendas"}
for r in ROWS: PT[r[0]] = r[0]
def draw(s, t):
    x0, base, top, scale = 70, 250, 40, 2.0
    s.line(x0 - 10, base, 700, base, stroke="var(--wire)")
    s.text(x0 - 10, top - 12, t("sales"), size=10, fill="var(--paper)", anchor="start")
    for v in (0, 50, 100):
        y = base - v * scale
        s.text(x0 - 16, y, str(v), size=9, fill="var(--paper-dim)", anchor="end")
        if v: s.line(x0 - 10, y, 700, y, stroke="var(--wire)", dash="2 4", sw=0.8)
    for i, (h, arr, hap) in enumerate(ROWS):
        x = x0 + i * 90
        s.rect(x, base - hap * scale, 30, hap * scale, fill="var(--phosphor)", stroke="none", rx=1)
        s.rect(x + 34, base - arr * scale, 30, arr * scale, fill="var(--amber)", stroke="none", rx=1)
        s.text(x + 15, base - hap * scale - 8, str(hap), size=9, fill="var(--paper)")
        s.text(x + 49, base - arr * scale - 8, str(arr), size=9, fill="var(--paper)")
        s.text(x + 32, base + 14, t(h), size=9.5, fill="var(--paper-dim)")
    s.rect(460, 18, 10, 10, fill="var(--phosphor)", stroke="none", rx=1)
    s.text(476, 23, t("happened"), size=10, anchor="start")
    s.rect(570, 18, 10, 10, fill="var(--amber)", stroke="none", rx=1)
    s.text(586, 23, t("arrived"), size=10, anchor="start")
