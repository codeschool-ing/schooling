NAME = "l15-topic-routing"
W, H = 720, 240
LABEL = ("Three messages published to the topic exchange pf.topic, and where they went. sale.recife matches both bindings, sale.* and *.recife, so the queues all-sales and all-recife each get a copy. sale.natal matches only sale.* and goes to all-sales. refund.recife matches only *.recife and goes to all-recife.",
         "Três mensagens publicadas na exchange topic pf.topic, e para onde foram. sale.recife casa com os dois bindings, sale.* e *.recife, então as filas all-sales e all-recife recebem uma cópia cada. sale.natal casa só com sale.* e vai para all-sales. refund.recife casa só com *.recife e vai para all-recife.")
CAPTION = ("A topic exchange copies a message into every queue whose pattern matches its routing key, so one message can become two copies, and each copy is somebody's work.",
           "Uma exchange topic copia a mensagem para toda fila cujo padrão casa com a routing key dela, então uma mensagem pode virar duas cópias, e cada cópia é trabalho de alguém.")
PT = {"routing keys": "routing keys", "exchange": "exchange", "queues and their bindings": "filas e seus bindings"}
SAME = ["routing keys", "exchange"]


def draw(s, t):
    s.text(90, 22, t("routing keys"), size=9.5, fill="var(--paper-dim)")
    s.text(330, 22, t("exchange"), size=9.5, fill="var(--paper-dim)")
    s.text(630, 22, t("queues and their bindings"), size=9.5, fill="var(--paper-dim)")
    keys = [("sale.recife", 60, "var(--amber)"), ("sale.natal", 120, "var(--paper-dim)"), ("refund.recife", 180, "var(--paper-dim)")]
    for k, y, c in keys:
        s.rect(30, y - 14, 120, 28, stroke=c)
        s.text(90, y, k, size=10, mono=True)
    s.rect(280, 90, 100, 60, stroke="var(--phosphor)")
    s.text(330, 120, "pf.topic", size=10, mono=True, weight=600)
    for k, y, c in keys:
        s.path(f"M 150 {y} L 278 120", stroke=c, arrow=True)
    qs = [("all-sales", "sale.*", "sale.recife, sale.natal", 70), ("all-recife", "*.recife", "sale.recife, refund.recife", 165)]
    for q, pat, got, y in qs:
        s.rect(560, y - 20, 140, 40, stroke="var(--phosphor)")
        s.text(630, y - 7, q, size=10, mono=True, weight=600)
        s.text(630, y + 9, pat, size=9.5, mono=True, fill="var(--phosphor)")
        s.text(630, y + 33, got, size=9, mono=True, fill="var(--paper-dim)")
        s.path(f"M 380 120 L 558 {y}", arrow=True)
