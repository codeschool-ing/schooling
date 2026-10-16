# Lesson 9, skew: every sale of late_tills.py (seed 1), event time against arrival.
import random
from datetime import datetime, timedelta, timezone
NAME = "l9-skew"
W, H = 720, 420
LABEL = ("A scatter of the 360 sales of the day: event time across, arrival time up. Almost every dot sits on or just above the diagonal where arrival equals event. Thirty-eight of Natal's sales, made between 10:36 and 13:46, form a flat row at 14:00, the moment the till reconnected.",
         "Um gráfico de dispersão das 360 vendas do dia: tempo do evento na horizontal, tempo de chegada na vertical. Quase todos os pontos ficam sobre a diagonal, onde chegada é igual a evento, ou logo acima dela. Trinta e oito vendas de Natal, feitas entre 10:36 e 13:46, formam uma linha horizontal às 14:00, o momento em que o caixa voltou a se conectar.")
CAPTION = ("Skew is the height of a dot above the diagonal. Most sales arrive seconds after they happen; Natal's outage is the row at 14:00.",
           "O skew é a altura de um ponto acima da diagonal. A maioria das vendas chega segundos depois de acontecer; a queda de Natal é a linha das 14:00.")
PT = {"event time (when the sale happened)": "tempo do evento (quando a venda aconteceu)",
      "arrival": "chegada", "arrival = event": "chegada = evento",
      "Natal's till reconnects: 38 sales at once": "o caixa de Natal volta: 38 vendas de uma vez",
      "other shops, and Natal before 10:20": "outras lojas, e Natal antes das 10:20",
      "Natal, held from 10:20": "Natal, retidas desde 10:20"}
for h in range(9, 16): PT[f"{h:02d}:00"] = f"{h:02d}:00"

def sales():
    SHOPS = ["recife", "olinda", "caruaru", "natal", "joao-pessoa"]
    BOOKS = ["bk-01", "bk-02", "bk-03", "bk-04", "bk-05", "bk-06", "bk-07", "bk-08"]
    OPEN = datetime(2026, 3, 2, 9, 0, tzinfo=timezone(timedelta(hours=-3)))
    DOWN, BACK = OPEN.replace(hour=10, minute=20), OPEN.replace(hour=14)
    rng = random.Random(1); clock, held, out = OPEN, 0, []
    for n in range(1, 361):
        clock += timedelta(seconds=rng.randint(10, 110))
        shop, book = rng.choice(SHOPS), rng.choice(BOOKS)
        rng.choice([1, 1, 1, 2, 3])
        sent = clock + timedelta(seconds=rng.choice([1, 1, 1, 1, 1, 2, 2, 3, 5, 15, 40, 95]))
        h = shop == "natal" and DOWN <= clock < BACK
        if h:
            held += 1; sent = BACK + timedelta(seconds=held)
        out.append((clock, sent, h))
    return out

def draw(s, t):
    x0, x1, y0, y1 = 80, 690, 370, 40       # plot box: 09:00 .. 15:20 both ways
    span = 6 * 60 + 20
    def X(d): return x0 + (d.hour * 60 + d.minute + d.second / 60 - 540) / span * (x1 - x0)
    def Y(d): return y0 - (d.hour * 60 + d.minute + d.second / 60 - 540) / span * (y0 - y1)
    s.line(x0, y0, x1, y0, stroke="var(--wire)")
    s.line(x0, y0, x0, y1, stroke="var(--wire)")
    for h in range(9, 16):
        xx = x0 + (h * 60 - 540) / span * (x1 - x0); yy = y0 - (h * 60 - 540) / span * (y0 - y1)
        s.line(xx, y0, xx, y0 + 4, stroke="var(--wire)")
        s.text(xx, y0 + 14, t(f"{h:02d}:00"), size=9, fill="var(--paper-dim)")
        s.line(x0 - 4, yy, x0, yy, stroke="var(--wire)")
        s.text(x0 - 8, yy, t(f"{h:02d}:00"), size=9, fill="var(--paper-dim)", anchor="end")
    s.text((x0 + x1) / 2, y0 + 34, t("event time (when the sale happened)"), size=10, fill="var(--paper)")
    s.text(x0, y1 - 18, t("arrival"), size=10, fill="var(--paper)", anchor="middle")
    s.line(x0, y0, x1, y1, stroke="var(--wire)", dash="4 3")
    s.text(560, 120, t("arrival = event"), size=9.5, fill="var(--paper-dim)", anchor="start")
    for at, sent, h in sales():
        s.circle(round(X(at), 1), round(Y(sent), 1), 2.6, fill="var(--amber)" if h else "var(--phosphor)")
    yb = Y(datetime(2026, 3, 2, 14, 0))
    s.text(X(datetime(2026, 3, 2, 12, 10)), yb - 16, t("Natal's till reconnects: 38 sales at once"), size=10, fill="var(--amber)")
    s.circle(430, 330, 3, fill="var(--phosphor)"); s.text(440, 330, t("other shops, and Natal before 10:20"), size=9.5, fill="var(--paper-dim)", anchor="start")
    s.circle(430, 348, 3, fill="var(--amber)"); s.text(440, 348, t("Natal, held from 10:20"), size=9.5, fill="var(--paper-dim)", anchor="start")
