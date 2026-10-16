import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l10_common import SALES, sec, X, axis
NAME = "l10-session-merge"
W, H = 720, 250
LABEL = ("Two timelines of five-minute sessions. Above, after sale 7 has arrived: one session from 09:00:40 to 09:06:20 with five sales, and another from 09:12:30 to 09:13:05 with two, more than five minutes apart. Below, after sale 8, which happened at 09:08:50, has arrived: it is within five minutes of both, and the two sessions become one from 09:00:40 to 09:13:05.",
         "Duas linhas do tempo de sessões de cinco minutos. Em cima, depois de chegar a venda 7: uma sessão de 09:00:40 a 09:06:20 com cinco vendas e outra de 09:12:30 a 09:13:05 com duas, a mais de cinco minutos uma da outra. Embaixo, depois de chegar a venda 8, que aconteceu às 09:08:50: ela fica a menos de cinco minutos das duas, e as duas sessões viram uma de 09:00:40 a 09:13:05.")
CAPTION = ("A late event can join two sessions into one. Their edges are made by the events, so an event that arrives late can move them.",
           "Um evento atrasado pode juntar duas sessões numa só. As bordas delas são feitas pelos eventos, então um evento que chega tarde pode movê-las.")
PT = {"after sale 7 arrives": "depois que chega a venda 7", "after sale 8 arrives": "depois que chega a venda 8",
      "gap 6 min 10 s": "pausa de 6 min 10 s", "sale 8, 09:08:50": "venda 8, 09:08:50",
      "two sessions": "duas sessões", "one session": "uma sessão"}
def draw(s, t):
    def row(y, upto, merged):
        for i, (w, shop) in enumerate(SALES[:upto]):
            s.circle(X(sec(w)), y, 4, fill="var(--amber)" if i == 7 else "var(--phosphor)")
        if merged:
            s.rect(X(sec("09:00:40")) - 6, y - 12, X(sec("09:13:05")) - X(sec("09:00:40")) + 12, 24, fill="none", stroke="var(--amber)", rx=6)
        else:
            s.rect(X(sec("09:00:40")) - 6, y - 12, X(sec("09:06:20")) - X(sec("09:00:40")) + 12, 24, fill="none", stroke="var(--phosphor)", rx=6)
            s.rect(X(sec("09:12:30")) - 6, y - 12, X(sec("09:13:05")) - X(sec("09:12:30")) + 12, 24, fill="none", stroke="var(--phosphor)", rx=6)
    s.text(10, 30, t("after sale 7 arrives"), size=10, anchor="start", weight=600)
    s.text(690, 30, t("two sessions"), size=10, anchor="end", fill="var(--paper-dim)")
    row(60, 7, False)
    s.text((X(sec("09:06:20")) + X(sec("09:12:30"))) / 2, 86, t("gap 6 min 10 s"), size=9.5, fill="var(--paper-dim)")
    s.text(10, 120, t("after sale 8 arrives"), size=10, anchor="start", weight=600)
    s.text(690, 120, t("one session"), size=10, anchor="end", fill="var(--paper-dim)")
    row(150, 8, True)
    s.text(X(sec("09:08:50")), 178, t("sale 8, 09:08:50"), size=9.5, fill="var(--amber)")
    axis(s, t, 210)
