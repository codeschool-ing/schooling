NAME = "l16-maxpoll"
W, H = 720, 250
LABEL = ("A timeline of two members of one group. The slow member polls, receives a sale and works on it for eight seconds. At six seconds the poll interval runs out and it leaves the group, which rebalances: the fast member's partitions are revoked and assigned again. At eight seconds the slow member polls and rejoins, which is a second rebalance, and the next sale starts the same cycle.",
         "Uma linha do tempo de dois membros de um grupo. O membro lento faz poll, recebe uma venda e trabalha nela por oito segundos. Aos seis segundos o intervalo de poll se esgota e ele sai do grupo, que rebalanceia: as partições do membro rápido são revogadas e atribuídas de novo. Aos oito segundos o membro lento faz poll e volta ao grupo, o que é um segundo rebalanceamento, e a próxima venda começa o mesmo ciclo.")
CAPTION = ("Eight seconds of work against a six-second limit: every sale costs two rebalances, and the member that was keeping up pays for it too.",
           "Oito segundos de trabalho contra um limite de seis: toda venda custa dois rebalanceamentos, e o membro que acompanhava paga por ele também.")
PT = {"slow member": "membro lento", "fast member": "membro rápido",
      "8 s on one sale": "8 s numa venda", "6 s: leaves the group": "6 s: sai do grupo",
      "poll, rejoin": "poll, volta", "two rebalances": "dois rebalanceamentos",
      "0 s": "0 s", "8 s": "8 s", "16 s": "16 s", "24 s": "24 s", "handling sales": "tratando vendas"}
SAME = ["0 s", "8 s", "16 s", "24 s"]
def draw(s, t):
    x0, sc = 120, 22  # px per second
    ys, yf = 80, 170
    s.text(20, ys, t("slow member"), size=11, weight=600, anchor="start")
    s.text(20, yf, t("fast member"), size=11, weight=600, anchor="start")
    for k in range(4):
        x = x0 + k * 8 * sc
        s.text(x, 30, t(f"{k*8} s"), size=9, fill="var(--paper-dim)")
        s.line(x, 38, x, 205, stroke="var(--wire)", sw=0.8, dash="2 4")
    for k in range(3):
        a = x0 + k * 8 * sc
        s.rect(a + 2, ys - 13, 8 * sc - 4, 26, fill="var(--panel)", stroke="var(--phosphor-dim)")
        if k == 0:
            s.text(a + 4 * sc, ys, t("8 s on one sale"), size=9.5)
        xl = a + 6 * sc
        s.line(xl, ys - 22, xl, ys + 22, stroke="var(--amber)", sw=1.5)
        rb = a + 8 * sc
        # fast member: working, interrupted by a rebalance band
        s.rect(a + 2 + (0 if k else 6), yf - 11, rb - a - 10 - (0 if k else 6), 22, fill="var(--panel)", stroke="var(--wire)")
        for bx in (xl, rb):
            s.rect(bx - 6, yf - 16, 12, 32, fill="var(--amber)", stroke="none", rx=2)
            s.path(f"M {bx} {ys+22} L {bx} {yf-18}", stroke="var(--amber)", arrow=True, dash="3 3")
    s.text(x0 + 6 * sc, ys - 32, t("6 s: leaves the group"), size=9.5, fill="var(--amber)")
    s.text(x0 + 8 * sc + 4, ys + 36, t("poll, rejoin"), size=9.5, fill="var(--paper-dim)", anchor="start")
    s.text(x0 + 4 * sc, yf, t("handling sales"), size=9.5, fill="var(--paper-dim)")
    s.text(x0 + 7 * sc, yf + 34, t("two rebalances"), size=9.5, weight=600, fill="var(--amber)")
