NAME = "l4-group"
W, H = 720, 250
LABEL = ("The topic sales with partitions 0, 1 and 2 in the middle. On the right, group shelf with four members: c reads partition 0, b partition 1, a partition 2, and d has no partition. On the left, group stock with one member, c1, which reads all three partitions. Each group keeps its own offsets.",
         "O tópico sales com as partições 0, 1 e 2 no meio. À direita, o grupo shelf com quatro membros: c lê a partição 0, b a partição 1, a a partição 2, e d não tem partição. À esquerda, o grupo stock com um membro, c1, que lê as três partições. Cada grupo guarda os próprios offsets.")
CAPTION = ("Inside a group each partition has one reader; between groups, every group reads everything.",
           "Dentro de um grupo cada partição tem um leitor; entre grupos, todo grupo lê tudo.")
PT = {"topic sales": "tópico sales", "partition 0": "partição 0", "partition 1": "partição 1", "partition 2": "partição 2",
      "group stock": "grupo stock", "group shelf": "grupo shelf", "idle": "ocioso"}
SAME = []
def draw(s, t):
    s.text(360, 30, t("topic sales"), size=10.5, weight=600)
    ys = [70, 120, 170]
    for i, y in enumerate(ys):
        s.rect(290, y, 140, 30, fill="var(--panel)", stroke="var(--phosphor-dim)")
        s.text(360, y + 15, t(f"partition {i}"), size=10, fill="var(--phosphor)")
    s.rect(30, 95, 170, 80, fill="none", stroke="var(--wire)", dash="4 3")
    s.text(115, 112, t("group stock"), size=10, weight=600)
    s.rect(80, 125, 70, 30); s.text(115, 140, "c1", size=10, mono=True)
    for y in ys:
        s.path(f"M 286 {y + 15} L 154 140", arrow=True)
    s.rect(520, 45, 170, 195, fill="none", stroke="var(--wire)", dash="4 3")
    s.text(605, 62, t("group shelf"), size=10, weight=600)
    members = [("c", 0, 95), ("b", 1, 135), ("a", 2, 175), ("d", None, 205)]
    for name, p, y in members:
        idle = p is None
        s.rect(570, y - 12, 70, 26, stroke="var(--amber)" if idle else "var(--wire)", dash="3 3" if idle else None)
        s.text(605, y + 1, name, size=10, mono=True, fill="var(--amber)" if idle else "var(--paper)")
        if idle:
            s.text(605, y + 22, t("idle"), size=9, fill="var(--amber)")
        else:
            s.line(434, ys[p] + 15, 566, y + 1, stroke="var(--paper-dim)", arrow=True)
