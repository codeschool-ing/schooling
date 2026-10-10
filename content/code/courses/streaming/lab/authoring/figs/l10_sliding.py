import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l10_common import SALES, sec, X, axis, dots
NAME = "l10-sliding"
W, H = 720, 330
ROWS = [("09:00:40", 1), ("09:02:10", 2), ("09:03:55", 3), ("09:05:00", 4), ("09:06:20", 4),
        ("09:08:50", 4), ("09:12:30", 2), ("09:13:05", 3), ("09:14:10", 3), ("09:21:00", 1)]
LABEL = ("The ten sales on a line, and below them ten five-minute windows, each ending at one sale and stretching five minutes back. The counts are 1, 2, 3, 4, 4, 4, 2, 3, 3 and 1; the windows ending at 09:05:00, 09:06:20 and 09:08:50 hold four sales each.",
         "As dez vendas numa linha e, abaixo, dez janelas de cinco minutos, cada uma terminando numa venda e voltando cinco minutos. As contagens são 1, 2, 3, 4, 4, 4, 2, 3, 3 e 1; as janelas que terminam às 09:05:00, 09:06:20 e 09:08:50 têm quatro vendas cada.")
CAPTION = ("Sliding windows in the Kafka Streams sense: one window ending at each sale, both edges included. No window starts on a mark of the clock.",
           "Janelas sliding no sentido do Kafka Streams: uma janela terminando em cada venda, com as duas bordas incluídas. Nenhuma janela começa numa marca do relógio.")
PT = {"sales": "vendas", "window ending at each sale": "janela terminando em cada venda", "busiest: 4": "mais cheias: 4"}
def draw(s, t):
    s.text(10, 40, t("sales"), size=10, anchor="start", weight=600)
    dots(s, 40); axis(s, t, 62)
    s.text(10, 95, t("window ending at each sale"), size=10, anchor="start", weight=600)
    for i, (end, n) in enumerate(sorted(ROWS)):
        e = sec(end); y = 108 + i * 20
        col = "var(--amber)" if n == 4 else "var(--phosphor-dim)"
        s.rect(X(e - 300), y, X(e) - X(e - 300), 14, fill="var(--panel)", stroke=col, rx=2)
        s.circle(X(e), y + 7, 3, fill="var(--paper)")
        s.text(X(e) + 10, y + 7, str(n), size=9.5, mono=True, anchor="start")
    s.text(560, 160, t("busiest: 4"), size=10, fill="var(--amber)", anchor="start")
