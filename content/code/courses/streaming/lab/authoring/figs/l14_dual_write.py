NAME = "l14-dual-write"
W, H = 720, 250
LABEL = ("Two programs that write a sale to the database and to Kafka in two steps, and fail between them. Above, the database is written first: the stock is changed and committed, the program crashes, and the event is never sent, so every reader of the topic still believes the old stock. Below, Kafka is written first: the event is sent, then the database transaction fails and rolls back, so the readers hear of a sale that never happened.",
         "Dois programas que gravam uma venda no banco e no Kafka em dois passos, e falham entre eles. Em cima, o banco é gravado primeiro: o estoque muda e é confirmado, o programa cai, e o evento nunca é enviado, então todo leitor do tópico continua acreditando no estoque antigo. Embaixo, o Kafka é gravado primeiro: o evento é enviado, depois a transação no banco falha e é desfeita, então os leitores ficam sabendo de uma venda que nunca aconteceu.")
CAPTION = ("Two writes, and the crash between them. Whichever goes first, one side ends up saying something the other does not.",
           "Duas escritas, e a queda entre elas. Seja qual for a primeira, um lado acaba dizendo algo que o outro não diz.")
PT = {
    "database first": "banco primeiro",
    "Kafka first": "Kafka primeiro",
    "UPDATE stock": "UPDATE stock",
    "COMMIT": "COMMIT",
    "crash": "queda",
    "send event": "enviar evento",
    "never sent": "nunca enviado",
    "rolled back": "desfeita",
    "sent, delivered": "enviado, entregue",
    "the table: 2 copies": "a tabela: 2 exemplares",
    "the topic: still 3": "o tópico: ainda 3",
    "the table: still 3": "a tabela: ainda 3",
    "the topic: 2 copies": "o tópico: 2 exemplares",
    "time": "tempo",
}
SAME = ["Kafka", "UPDATE stock", "COMMIT"]


def draw(s, t):
    def lane(y, title):
        s.text(20, y, t(title), size=11, weight=600, anchor="start")
        s.line(130, y, 540, y, stroke="var(--wire)")

    def box(x, y, label, stroke="var(--wire)", fill="var(--panel)", color="var(--paper)", dash=None):
        s.rect(x - 52, y - 15, 104, 30, stroke=stroke, fill=fill, dash=dash)
        s.text(x, y, label, size=10, fill=color)

    def cross(x, y):
        s.line(x - 8, y - 8, x + 8, y + 8, stroke="var(--amber)", sw=2)
        s.line(x - 8, y + 8, x + 8, y - 8, stroke="var(--amber)", sw=2)
        s.text(x, y + 22, t("crash"), size=9.5, fill="var(--amber)")

    # database first
    y = 70
    lane(y, "database first")
    box(190, y, t("UPDATE stock"))
    box(310, y, t("COMMIT"), stroke="var(--phosphor)")
    cross(400, y)
    box(485, y, t("never sent"), stroke="var(--amber)", color="var(--paper-dim)", dash="4 3")
    s.text(640, y - 10, t("the table: 2 copies"), size=9.5, fill="var(--phosphor)")
    s.text(640, y + 10, t("the topic: still 3"), size=9.5, fill="var(--amber)")

    # Kafka first
    y = 165
    lane(y, "Kafka first")
    box(190, y, t("send event"), stroke="var(--phosphor)")
    box(310, y, t("UPDATE stock"))
    cross(400, y)
    box(485, y, t("rolled back"), stroke="var(--amber)", color="var(--paper-dim)", dash="4 3")
    s.text(640, y - 10, t("the topic: 2 copies"), size=9.5, fill="var(--amber)")
    s.text(640, y + 10, t("the table: still 3"), size=9.5, fill="var(--phosphor)")

    s.path("M 130 225 L 540 225", arrow=True)
    s.text(335, 239, t("time"), size=9, fill="var(--paper-dim)")
