NAME = "l5-acks"
W, H = 720, 320
LABEL = ("A sequence over time, top to bottom, between a producer, the leader on node 1 and two followers. With acks=0 the producer counts the message as sent the moment it leaves. The leader writes it to its log and, with acks=1, answers straight away. The followers fetch it, and on their next fetch the leader learns both have it, moves the high watermark and only then answers a producer that asked for acks=all.",
         "Uma sequência no tempo, de cima para baixo, entre um produtor, o líder no nó 1 e dois seguidores. Com acks=0 o produtor dá a mensagem por enviada no instante em que ela sai. O líder a grava no log e, com acks=1, responde na hora. Os seguidores a buscam, e no fetch seguinte o líder fica sabendo que os dois a têm, move o high watermark e só então responde a um produtor que pediu acks=all.")
CAPTION = ("The three settings of acks are three moments in the same exchange: the later the answer, the more copies stand behind it.",
           "Os três valores de acks são três momentos da mesma troca: quanto mais tarde a resposta, mais cópias estão por trás dela.")
PT = {"producer": "produtor", "node 1 · leader": "nó 1 · líder", "node 2": "nó 2", "node 3": "nó 3",
      "acks=0: counted as sent": "acks=0: dada por enviada", "acks=1: answered": "acks=1: respondida",
      "acks=all: answered": "acks=all: respondida", "produce": "produce", "written to its log": "gravada no log",
      "fetch": "fetch", "the record": "o registro", "next fetch": "fetch seguinte",
      "high watermark moves": "high watermark avança", "copied": "copiada"}
SAME = ["produce", "fetch"]
def draw(s, t):
    lanes = {"p": 230, "l": 400, "a": 540, "b": 660}
    heads = [("p", "producer"), ("l", "node 1 · leader"), ("a", "node 2"), ("b", "node 3")]
    for k, name in heads:
        x = lanes[k]
        s.rect(x - 52, 14, 104, 26, fill="var(--panel)", stroke="var(--amber)" if k == "l" else "var(--wire)")
        s.text(x, 27, t(name), size=10, weight=600)
        s.line(x, 40, x, 305, stroke="var(--wire)", sw=1, dash="3 3")
    P, L, A, B = lanes["p"], lanes["l"], lanes["a"], lanes["b"]
    # produce
    s.line(P, 62, L - 2, 82, stroke="var(--paper)", arrow=True)
    s.text((P + L) / 2, 62, t("produce"), size=9.5, fill="var(--paper-dim)", mono=True)
    s.circle(P, 62, 4, fill="var(--paper-dim)")
    s.text(P - 12, 62, t("acks=0: counted as sent"), size=10, anchor="end", fill="var(--paper-dim)")
    s.rect(L - 48, 84, 96, 20, fill="var(--panel)", stroke="var(--phosphor-dim)")
    s.text(L, 94, t("written to its log"), size=9, fill="var(--paper)")
    # acks=1
    s.line(L - 2, 110, P + 2, 130, stroke="var(--phosphor-dim)", arrow=True)
    s.circle(P, 130, 4, fill="var(--phosphor-dim)")
    s.text(P - 12, 130, t("acks=1: answered"), size=10, anchor="end", fill="var(--phosphor-dim)")
    # followers fetch
    for x, y in ((A, 150), (B, 160)):
        s.line(x - 2, y, L + 2, y, stroke="var(--paper-dim)", sw=1, arrow=True)
        s.line(L + 2, y + 14, x - 2, y + 22, stroke="var(--paper)", sw=1, arrow=True)
    s.text((L + A) / 2, 143, t("fetch"), size=9, fill="var(--paper-dim)", mono=True)
    s.text((A + B) / 2 + 10, 196, t("the record"), size=9, fill="var(--paper-dim)")
    s.text(A, 214, t("copied"), size=9, fill="var(--phosphor)")
    s.text(B, 214, t("copied"), size=9, fill="var(--phosphor)")
    for x, y in ((A, 236), (B, 244)):
        s.line(x - 2, y, L + 2, y, stroke="var(--paper-dim)", sw=1, arrow=True)
    s.text((L + A) / 2 + 8, 228, t("next fetch"), size=9, fill="var(--paper-dim)")
    s.rect(L - 62, 254, 124, 20, fill="var(--panel)", stroke="var(--phosphor)")
    s.text(L, 264, t("high watermark moves"), size=9, fill="var(--phosphor)")
    # acks=all
    s.line(L - 2, 282, P + 2, 298, stroke="var(--phosphor)", arrow=True)
    s.circle(P, 298, 4, fill="var(--phosphor)")
    s.text(P - 12, 298, t("acks=all: answered"), size=10, anchor="end", fill="var(--phosphor)", weight=600)
