import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l10_common import SALES, sec, X, axis, dots
NAME = "l10-tumbling-hopping"
W, H = 720, 250
LABEL = ("The ten sales on a line from 08:55 to 09:30, the late sale at 09:08:50 in another colour. Below, five-minute tumbling windows: 09:00 to 09:05 with 3 sales, 09:05 to 09:10 with 3, 09:10 to 09:15 with 3, and 09:20 to 09:25 with 1. Below that, ten-minute hopping windows every five minutes, overlapping: 08:55 with 3, 09:00 with 6, 09:05 with 6, 09:10 with 3, 09:15 with 1 and 09:20 with 1.",
         "As dez vendas numa linha de 08:55 a 09:30, a venda atrasada das 09:08:50 em outra cor. Abaixo, janelas tumbling de cinco minutos: 09:00 a 09:05 com 3 vendas, 09:05 a 09:10 com 3, 09:10 a 09:15 com 3, e 09:20 a 09:25 com 1. Abaixo delas, janelas hopping de dez minutos a cada cinco, sobrepostas: 08:55 com 3, 09:00 com 6, 09:05 com 6, 09:10 com 3, 09:15 com 1 e 09:20 com 1.")
CAPTION = ("Tumbling windows touch and never overlap, so each sale is in one. Hopping windows of ten minutes every five overlap, so each sale is in two, and the busy stretch from 09:00 to 09:10 is whole in one of them.",
           "Janelas tumbling se encostam e nunca se sobrepõem, então cada venda está em uma. Janelas hopping de dez minutos a cada cinco se sobrepõem, então cada venda está em duas, e o trecho movimentado das 09:00 às 09:10 fica inteiro numa delas.")
PT = {"sales": "vendas", "tumbling, 5 min": "tumbling, 5 min", "hopping, 10 min every 5": "hopping, 10 min a cada 5"}
SAME = ["tumbling, 5 min"]
def draw(s, t):
    s.text(10, 40, t("sales"), size=10, anchor="start", weight=600)
    dots(s, 40); axis(s, t, 62)
    s.text(10, 105, t("tumbling, 5 min"), size=10, anchor="start", weight=600)
    for a, b, n in (("09:00", "09:05", 3), ("09:05", "09:10", 3), ("09:10", "09:15", 3), ("09:20", "09:25", 1)):
        x1, x2 = X(sec(a + ":00")), X(sec(b + ":00"))
        s.rect(x1 + 1, 118, x2 - x1 - 2, 22, fill="var(--panel)", stroke="var(--phosphor)", rx=2)
        s.text((x1 + x2) / 2, 129, str(n), size=10, mono=True)
    s.text(10, 165, t("hopping, 10 min every 5"), size=10, anchor="start", weight=600)
    hop = (("08:55", 3), ("09:00", 6), ("09:05", 6), ("09:10", 3), ("09:15", 1), ("09:20", 1))
    for i, (a, n) in enumerate(hop):
        st = sec(a + ":00"); y = 178 + (i % 2) * 30
        x1, x2 = X(st), X(st + 600)
        s.rect(x1 + 1, y, x2 - x1 - 2, 22, fill="var(--panel)", stroke="var(--amber)", rx=2)
        s.text((x1 + x2) / 2, y + 11, str(n), size=10, mono=True)
    for a in ("09:00", "09:05", "09:10", "09:15", "09:20"):
        x = X(sec(a + ":00")); s.line(x, 70, x, 240, stroke="var(--wire)", sw=0.6, dash="2 3")
