NAME = "l17-day"
W, H = 720, 230
LABEL = ("A day from midnight to midnight. The shops sell from nine to twenty-one, drawn as a band of traffic. A stream's cost is a flat line across all twenty-four hours, the same at three in the morning as at noon. A nightly batch's cost is a single short block at two in the morning.",
         "Um dia de meia-noite a meia-noite. As lojas vendem das nove às vinte e uma, desenhado como uma faixa de tráfego. O custo de um stream é uma linha reta pelas vinte e quatro horas, igual às três da manhã e ao meio-dia. O custo de um batch noturno é um único bloco curto às duas da manhã.")
CAPTION = ("The sales happen in twelve hours; the stream is paid for in twenty-four.",
           "As vendas acontecem em doze horas; o stream é pago em vinte e quatro.")
PT = {"sales": "vendas", "stream": "stream", "nightly batch": "batch noturno",
      "00:00": "00:00", "09:00": "09:00", "21:00": "21:00", "24:00": "24:00", "02:00": "02:00",
      "quiet hours": "horas quietas", "paid every hour": "pago a toda hora"}
SAME = ["stream"]
def draw(s, t):
    x0, x1 = 130, 690
    hx = lambda h: x0 + (x1 - x0) * h / 24
    rows = ((60, "sales"), (125, "stream"), (180, "nightly batch"))
    for y, n in rows:
        s.text(20, y, t(n), size=10.5, weight=600, anchor="start")
        s.line(x0, y + 15, x1, y + 15, stroke="var(--wire)", sw=0.8)
    for h in (0, 9, 21, 24):
        s.text(hx(h), 25, t(f"{h:02d}:00"), size=9, fill="var(--paper-dim)")
        s.line(hx(h), 32, hx(h), 200, stroke="var(--wire)", sw=0.8, dash="2 4")
    s.path(f"M {hx(9)} 75 C {hx(10)} 50 {hx(11)} 45 {hx(12.5)} 48 C {hx(14)} 52 {hx(16)} 46 {hx(18)} 50 C {hx(20)} 55 {hx(20.5)} 70 {hx(21)} 75 Z", stroke="var(--phosphor)", fill="var(--phosphor-dim)")
    s.rect(hx(0), 113, hx(24) - hx(0), 24, fill="var(--panel)", stroke="var(--amber)")
    s.text((hx(0) + hx(9)) / 2, 125, t("quiet hours"), size=9.5, fill="var(--amber)")
    s.text((hx(9) + hx(21)) / 2, 125, t("paid every hour"), size=9.5, fill="var(--paper-dim)")
    s.rect(hx(2), 168, hx(2.4) - hx(2), 24, fill="var(--panel)", stroke="var(--amber)")
    s.text(hx(2) + 14, 158, t("02:00"), size=9, fill="var(--paper-dim)", anchor="start")
