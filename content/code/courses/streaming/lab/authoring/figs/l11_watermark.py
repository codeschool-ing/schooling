# Lesson 11, watermarks: the twelve sales in arrival order, and the watermark two minutes behind.
NAME = "l11-watermark"
W, H = 720, 360
SALES = ["09:00:40", "09:02:10", "09:03:55", "09:05:00", "09:06:20", "09:12:30", "09:13:05",
         "09:08:50", "09:14:10", "09:21:00", "09:04:30", "09:23:10"]
LABEL = ("A chart with the twelve sales in arrival order across and event time up. Each sale is a dot; a stepped line two minutes below the highest dot so far is the watermark, and it never goes down. The two sales whose window had already been passed by the watermark when they arrived, 09:08:50 and 09:04:30, are marked as dropped. Horizontal lines at 09:05, 09:10, 09:15 and 09:20 are window ends, and each window is emitted at the arrival where the watermark first crosses its end.",
         "Um gráfico com as doze vendas em ordem de chegada na horizontal e o tempo do evento na vertical. Cada venda é um ponto; uma linha em degraus dois minutos abaixo do ponto mais alto até então é o watermark, e ela nunca desce. As duas vendas cuja janela o watermark já tinha passado quando chegaram, 09:08:50 e 09:04:30, estão marcadas como descartadas. Linhas horizontais em 09:05, 09:10, 09:15 e 09:20 são fins de janela, e cada janela é emitida na chegada em que o watermark cruza o fim dela pela primeira vez.")
CAPTION = ("The watermark follows the latest event time two minutes behind and never moves back. A sale below it whose window has ended is late.",
           "O watermark segue o tempo do evento mais recente dois minutos atrás e nunca volta. Uma venda abaixo dele cuja janela já terminou está atrasada.")
PT = {"event time": "tempo do evento", "sales in the order they arrived": "vendas na ordem em que chegaram",
      "watermark": "watermark", "dropped": "descartada", "window ends": "fins de janela", "sale": "venda"}
SAME = ["watermark"]
def sec(h):
    a, b, c = map(int, h.split(":")); return a * 3600 + b * 60 + c
def draw(s, t):
    x0, x1, y0, y1 = 90, 640, 310, 40
    lo, hi = sec("08:58:00"), sec("09:24:00")
    def Y(v): return round(y0 - (v - lo) / (hi - lo) * (y0 - y1), 1)
    def X(i): return x0 + 20 + i * (x1 - x0 - 40) / 11
    s.line(x0, y0, x1, y0, stroke="var(--wire)"); s.line(x0, y0, x0, y1, stroke="var(--wire)")
    for m in (0, 5, 10, 15, 20):
        v = sec(f"09:{m:02d}:00")
        s.text(x0 - 8, Y(v), f"09:{m:02d}", size=9, mono=True, fill="var(--paper-dim)", anchor="end")
        if m:
            s.line(x0, Y(v), x1, Y(v), stroke="var(--wire)", dash="2 4", sw=0.8)
    s.text(x1 + 6, Y(sec("09:15:00")), t("window ends"), size=9, fill="var(--paper-dim)", anchor="start")
    s.text(x0 - 60, y1 - 18, t("event time"), size=10, anchor="start")
    s.text((x0 + x1) / 2, y0 + 36, t("sales in the order they arrived"), size=10)
    latest, pts = None, []
    for i, h in enumerate(SALES):
        v = sec(h); late = i in (7, 10)
        if not late: latest = v if latest is None or v > latest else latest
        pts.append((X(i), Y(latest - 120)))
        s.text(X(i), y0 + 14, str(i + 1), size=9, mono=True, fill="var(--paper-dim)")
    d = f"M {pts[0][0] - 18} {pts[0][1]}"
    for k, (x, y) in enumerate(pts):
        d += f" L {x - 18 if k else x} {y}" if k else ""
        d += f" L {x + 18} {y}"
        if k + 1 < len(pts): d += f" L {x + 18} {pts[k + 1][1]}"
    s.path(d, stroke="var(--amber)", sw=1.6)
    s.text(X(11) + 22, pts[-1][1], t("watermark"), size=10, fill="var(--amber)", anchor="start")
    for i, h in enumerate(SALES):
        late = i in (7, 10)
        s.circle(X(i), Y(sec(h)), 4.5, fill="none" if late else "var(--phosphor)", stroke="var(--amber)" if late else "none", sw=1.6)
        if late:
            s.text(X(i), Y(sec(h)) + 15, t("dropped"), size=9, fill="var(--amber)")
