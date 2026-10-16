NAME = "l13-topology"
W, H = 720, 270
LABEL = ("The topology of SalesPerShop, in two parts. Part 0 reads the sales topic, keyed by shop. Its count per shop needs no new key, so it is counted at once into a local store, whose changes go to a changelog topic and to the output topic sales-per-shop. For the count per book, part 0 writes each sale again to a repartition topic, keyed by book. Part 1 reads that topic and counts per book into a second store, with its own changelog, and writes to sales-per-book. Each part runs as three tasks, one per partition.",
         "A topologia do SalesPerShop, em duas partes. A parte 0 lê o tópico sales, com a loja como chave. A contagem por loja não precisa de chave nova, então é contada na hora num store local, cujas mudanças vão para um tópico de changelog e para o tópico de saída sales-per-shop. Para a contagem por livro, a parte 0 escreve cada venda de novo num tópico de repartição, com o livro como chave. A parte 1 lê esse tópico e conta por livro num segundo store, com o seu próprio changelog, e escreve em sales-per-book. Cada parte roda como três tarefas, uma por partição.")
CAPTION = ("A new key costs a trip through Kafka: the repartition topic is where the sales are re-sorted by book.",
           "Uma chave nova custa uma volta pelo Kafka: o tópico de repartição é onde as vendas são reorganizadas por livro.")
PT = {"part 0: tasks 0_0, 0_1, 0_2": "parte 0: tarefas 0_0, 0_1, 0_2",
      "part 1: tasks 1_0, 1_1, 1_2": "parte 1: tarefas 1_0, 1_1, 1_2",
      "groupByKey, count": "groupByKey, count", "store: per shop": "store: por loja",
      "groupBy book": "groupBy livro", "count": "count", "store: per book": "store: por livro",
      "repartition topic": "tópico de repartição", "keyed by book": "chave: livro",
      "changelog": "changelog", "keyed by shop": "chave: loja"}
SAME = ["groupByKey, count", "count", "changelog"]


def topic(s, x, y, w, name, sub=None, stroke="var(--phosphor-dim)"):
    s.rect(x, y, w, 34, fill="var(--panel)", stroke=stroke)
    s.text(x + w / 2, y + (12 if sub else 17), name, size=9.5, mono=True)
    if sub:
        s.text(x + w / 2, y + 26, sub, size=8.5, fill="var(--paper-dim)")


def draw(s, t):
    topic(s, 20, 70, 90, "sales", t("keyed by shop"))
    s.rect(150, 20, 250, 140, fill="none", stroke="var(--wire)", dash="4 3")
    s.text(275, 34, t("part 0: tasks 0_0, 0_1, 0_2"), size=9.5, fill="var(--paper-dim)")
    s.rect(170, 50, 120, 34, stroke="var(--wire)")
    s.text(230, 67, t("groupByKey, count"), size=9.5)
    s.rect(170, 106, 120, 34, stroke="var(--wire)")
    s.text(230, 123, t("groupBy book"), size=9.5)
    s.path("M 112 82 L 166 70", arrow=True)
    s.path("M 112 92 L 166 118", arrow=True)
    s.rect(300, 50, 90, 34, stroke="var(--amber)")
    s.text(345, 67, t("store: per shop"), size=9, fill="var(--amber)")
    s.path("M 292 67 L 297 67", arrow=False)
    topic(s, 450, 50, 120, "sales-per-shop")
    s.path("M 392 67 L 446 67", stroke="var(--phosphor)", arrow=True)
    topic(s, 590, 10, 120, "…-changelog", stroke="var(--amber)")
    s.path("M 370 50 Q 420 20 586 27", stroke="var(--amber)", arrow=True)
    # repartition
    topic(s, 175, 190, 150, "…-repartition", t("keyed by book"), stroke="var(--amber)")
    s.path("M 230 142 L 240 186", arrow=True)
    s.rect(400, 180, 250, 80, fill="none", stroke="var(--wire)", dash="4 3")
    s.text(525, 252, t("part 1: tasks 1_0, 1_1, 1_2"), size=9.5, fill="var(--paper-dim)")
    s.rect(415, 192, 70, 34, stroke="var(--wire)")
    s.text(450, 209, t("count"), size=9.5)
    s.rect(495, 192, 90, 34, stroke="var(--amber)")
    s.text(540, 209, t("store: per book"), size=9, fill="var(--amber)")
    s.path("M 327 207 L 411 207", arrow=True)
    topic(s, 590, 120, 120, "sales-per-book")
    s.path("M 587 200 L 640 158", stroke="var(--phosphor)", arrow=True)
    s.path("M 587 215 L 662 215 L 662 250", stroke="var(--amber)", arrow=False)
    s.text(668, 250, t("changelog"), size=9, fill="var(--amber)", anchor="start")
