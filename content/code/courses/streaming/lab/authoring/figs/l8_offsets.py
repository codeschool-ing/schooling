# Lesson 8: where the record of progress lives, in three designs.
NAME = "l8-offsets"
W, H = 720, 220
LABEL = ("Three designs side by side. First, at least once: the database commits the effect, then Kafka is told the offset; a crash between the two repeats the sale. Second, deduplication: the effect and the sale's id commit together in the database, and a repeated sale is skipped because its id is there. Third, offsets in the sink: the effect and the next offset commit together in the database, the consumer starts from that offset, and Kafka's group offset is not used.",
         "Três desenhos lado a lado. Primeiro, pelo menos uma vez: o banco confirma o efeito, depois o Kafka recebe o offset; uma queda entre os dois repete a venda. Segundo, deduplicação: o efeito e o id da venda são confirmados juntos no banco, e uma venda repetida é pulada porque o id está lá. Terceiro, offsets no destino: o efeito e o próximo offset são confirmados juntos no banco, o consumidor começa desse offset, e o offset do grupo no Kafka não é usado.")
CAPTION = ("Two commits leave a gap; putting the record of progress in the same transaction as the effect closes it, either as the event's id or as the offset.",
           "Dois commits deixam um vão; pôr o registro do progresso na mesma transação que o efeito o fecha, seja como o id do evento, seja como o offset.")
PT = {"at least once": "pelo menos uma vez", "dedup by id": "deduplicação por id", "offset in the sink": "offset no destino",
      "database: stock - 2": "banco: stock - 2", "Kafka: commit offset": "Kafka: commit do offset",
      "crash here repeats the sale": "queda aqui repete a venda",
      "database: stock - 2, id": "banco: stock - 2, id", "repeat: id found, skipped": "repetida: id encontrado, pulada",
      "database: stock - 2, next offset": "banco: stock - 2, próximo offset", "start: seek to stored offset": "início: seek ao offset guardado",
      "one transaction": "uma transação", "two commits": "dois commits"}
def draw(s, t):
    cols = ((20, "at least once"), (260, "dedup by id"), (500, "offset in the sink"))
    for x, name in cols:
        s.text(x + 100, 22, t(name), size=11, weight=600)
    x = 20
    s.rect(x, 40, 200, 36, fill="var(--panel)", stroke="var(--wire)"); s.text(x + 100, 58, t("database: stock - 2"), size=9.5)
    s.rect(x, 120, 200, 36, fill="var(--panel)", stroke="var(--wire)"); s.text(x + 100, 138, t("Kafka: commit offset"), size=9.5)
    s.line(x + 100, 76, x + 100, 118, stroke="var(--paper-dim)", arrow=True)
    s.text(x + 108, 98, t("crash here repeats the sale"), size=9, fill="var(--amber)", anchor="start")
    s.text(x + 100, 176, t("two commits"), size=9.5, fill="var(--paper-dim)")
    for x, top, bottom in ((260, "database: stock - 2, id", "repeat: id found, skipped"),
                           (500, "database: stock - 2, next offset", "start: seek to stored offset")):
        s.rect(x, 40, 200, 70, fill="none", stroke="var(--amber)", dash="4 3")
        s.text(x + 100, 54, t("one transaction"), size=9, fill="var(--amber)")
        s.rect(x + 10, 64, 180, 36, fill="var(--panel)", stroke="var(--phosphor)")
        s.text(x + 100, 82, t(top), size=9.5)
        s.text(x + 100, 138, t(bottom), size=9.5, fill="var(--paper-dim)")
