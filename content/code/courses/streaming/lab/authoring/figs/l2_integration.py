NAME = "l2-integration"
W, H = 720, 260
LABEL = ("Left: five tills each connected directly to four systems, stock, loyalty, warehouse and accounts, which is twenty connections. Right: the five tills each write once to one log, and the four systems each read from the log, which is nine connections, and a new system adds one.",
         "À esquerda: cinco caixas, cada um ligado diretamente a quatro sistemas, estoque, fidelidade, warehouse e contabilidade, o que dá vinte ligações. À direita: os cinco caixas escrevem uma vez num log, e os quatro sistemas leem do log, o que dá nove ligações, e um sistema novo acrescenta uma.")
CAPTION = ("Without a log, every writer knows every reader. With one, each knows only the log.",
           "Sem um log, todo escritor conhece todo leitor. Com um, cada um só conhece o log.")
PT = {"till": "caixa", "stock": "estoque", "loyalty": "fidelidade", "warehouse": "warehouse",
      "accounts": "contabilidade", "log": "log", "20 connections": "20 ligações", "9 connections": "9 ligações"}
SAME = ["warehouse", "log"]
SYS = ["stock", "loyalty", "warehouse", "accounts"]
def draw(s, t):
    ty = [40 + i * 45 for i in range(5)]
    sy = [55 + i * 50 for i in range(4)]
    for y in ty:
        for y2 in sy:
            s.line(80, y + 12, 240, y2 + 12, stroke="var(--wire)", sw=1)
    for y in ty:
        s.rect(20, y, 60, 24); s.text(50, y + 12, t("till"), size=9.5)
    for y, n in zip(sy, SYS):
        s.rect(240, y, 90, 24); s.text(285, y + 12, t(n), size=9.5)
    s.text(175, 250, t("20 connections"), size=10, weight=600, fill="var(--amber)")
    s.line(360, 20, 360, 250, stroke="var(--wire)", dash="3 4")
    for y in ty:
        s.rect(390, y, 60, 24); s.text(420, y + 12, t("till"), size=9.5)
        s.line(450, y + 12, 506, 152, stroke="var(--paper-dim)", sw=1, arrow=True)
    s.rect(510, 132, 50, 40, fill="var(--panel)", stroke="var(--phosphor)")
    s.text(535, 152, t("log"), size=11, weight=600, fill="var(--phosphor)")
    for y, n in zip(sy, SYS):
        s.line(562, 152, 606, y + 12, stroke="var(--paper-dim)", sw=1, arrow=True)
        s.rect(610, y, 90, 24); s.text(655, y + 12, t(n), size=9.5)
    s.text(545, 250, t("9 connections"), size=10, weight=600, fill="var(--phosphor)")
