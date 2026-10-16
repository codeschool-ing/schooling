NAME = "l4-rebalance"
W, H = 720, 230
LABEL = ("Two timelines of member a while member b joins. Eager: a holds partitions 0, 1 and 2, gives all three back when b joins, and then holds 0 and 1 again, so every partition stops reading for a moment. Incremental, as in cooperative-sticky and the consumer protocol: a keeps 1 and 2 throughout and gives up only partition 0, which moves to b; only partition 0 stops.",
         "Duas linhas do tempo do membro a enquanto o membro b entra. Eager: a tem as partições 0, 1 e 2, devolve as três quando b entra, e depois volta a ter 0 e 1, então toda partição para de ser lida por um momento. Incremental, como no cooperative-sticky e no protocolo consumer: a mantém 1 e 2 o tempo todo e só abre mão da partição 0, que vai para b; só a partição 0 para.")
CAPTION = ("An eager rebalance stops every partition; an incremental one stops only the partitions that move.",
           "Um rebalanceamento eager para todas as partições; um incremental para só as que mudam de dono.")
PT = {"eager": "eager", "incremental": "incremental", "b joins": "b entra", "a holds": "a tem", "b holds": "b tem",
      "nothing read": "nada é lido", "0, 1, 2": "0, 1, 2", "0, 1": "0, 1", "1, 2": "1, 2"}
SAME = ["eager", "incremental"]
def bar(s, x0, x1, y, label, col):
    s.rect(x0, y, x1 - x0, 24, fill="var(--panel)", stroke=col)
    s.text((x0 + x1) / 2, y + 12, label, size=9.5, fill=col, mono=True)
def draw(s, t):
    jx = 330
    s.line(jx, 30, jx, 215, stroke="var(--amber)", dash="3 3")
    s.text(jx, 22, t("b joins"), size=9.5, fill="var(--amber)")
    s.text(20, 70, t("eager"), size=11, weight=600, anchor="start")
    s.text(130, 52, t("a holds"), size=9, fill="var(--paper-dim)")
    bar(s, 120, jx - 20, 60, "0, 1, 2", "var(--phosphor)")
    s.rect(jx - 20, 60, 50, 24, fill="none", stroke="var(--amber)", dash="2 2")
    s.text(jx + 5, 96, t("nothing read"), size=9, fill="var(--amber)")
    bar(s, jx + 30, 690, 60, "0, 1", "var(--phosphor)")
    bar(s, jx + 30, 690, 105, "2", "var(--paper-dim)")
    s.text(700, 117, "b", size=9.5, mono=True, anchor="start", fill="var(--paper-dim)")
    s.text(20, 165, t("incremental"), size=11, weight=600, anchor="start")
    bar(s, 120, 690, 155, "1, 2", "var(--phosphor)")
    bar(s, 120, jx - 20, 185, "0", "var(--phosphor)")
    s.rect(jx - 20, 185, 50, 24, fill="none", stroke="var(--amber)", dash="2 2")
    bar(s, jx + 30, 690, 185, "0", "var(--paper-dim)")
    s.text(700, 197, "b", size=9.5, mono=True, anchor="start", fill="var(--paper-dim)")
    s.text(700, 167, "a", size=9.5, mono=True, anchor="start", fill="var(--phosphor)")
    s.text(700, 72, "a", size=9.5, mono=True, anchor="start", fill="var(--phosphor)")
