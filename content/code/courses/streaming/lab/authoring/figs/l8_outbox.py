# Lesson 8: the outbox. One transaction writes the change and the event; a relay sends it later.
NAME = "l8-outbox"
W, H = 720, 200
LABEL = ("Left, the program that restocks writes one database transaction containing two rows: the stock change and the event in the outbox table. Right, a separate relay reads unsent rows from the outbox, sends them to Kafka, waits for the acknowledgement, and only then marks them sent. A crash before the commit loses both rows together; a crash in the relay after Kafka's acknowledgement sends the event again, with the same id.",
         "À esquerda, o programa que repõe o estoque escreve uma transação de banco com duas linhas: a mudança de estoque e o evento na tabela outbox. À direita, um relay separado lê as linhas não enviadas da outbox, manda para o Kafka, espera a confirmação e só então as marca como enviadas. Uma queda antes do commit perde as duas linhas juntas; uma queda no relay depois da confirmação do Kafka manda o evento de novo, com o mesmo id.")
CAPTION = ("The change and its event commit together. The relay delivers at least once, so the event carries an id for its readers to deduplicate.",
           "A mudança e o evento dela são confirmados juntos. O relay entrega pelo menos uma vez, então o evento carrega um id para os leitores deduplicarem.")
PT = {"one database transaction": "uma transação de banco", "stock: bk-04 +10": "stock: bk-04 +10",
      "outbox: restocked, id, sent = 0": "outbox: restocked, id, sent = 0", "relay": "relay",
      "1  read unsent rows": "1  lê as linhas não enviadas", "2  produce, wait for the ack": "2  produz, espera a confirmação",
      "3  mark them sent": "3  marca como enviadas", "Kafka: stock-events": "Kafka: stock-events",
      "a crash here repeats step 2": "uma queda aqui repete o passo 2"}
def draw(s, t):
    s.rect(20, 30, 240, 130, fill="none", stroke="var(--amber)", dash="4 3")
    s.text(140, 46, t("one database transaction"), size=10, weight=600, fill="var(--amber)")
    s.rect(40, 62, 200, 34, fill="var(--panel)", stroke="var(--wire)")
    s.text(140, 79, t("stock: bk-04 +10"), size=10, mono=True)
    s.rect(40, 108, 200, 34, fill="var(--panel)", stroke="var(--phosphor)")
    s.text(140, 125, t("outbox: restocked, id, sent = 0"), size=9.5, mono=True)
    s.rect(330, 92, 110, 50, fill="var(--panel)", stroke="var(--phosphor)")
    s.text(385, 117, t("relay"), size=11, weight=600, mono=True)
    s.line(240, 125, 328, 117, stroke="var(--paper-dim)", arrow=True)
    s.text(294, 98, t("1  read unsent rows"), size=9, fill="var(--paper-dim)")
    s.rect(560, 92, 140, 50, fill="var(--panel)", stroke="var(--wire)")
    s.text(630, 117, t("Kafka: stock-events"), size=10, mono=True)
    s.line(440, 110, 558, 110, stroke="var(--paper)", arrow=True)
    s.text(500, 100, t("2  produce, wait for the ack"), size=9, fill="var(--paper-dim)")
    s.path("M 385 142 Q 300 190 240 140", stroke="var(--phosphor-dim)", dash="4 3", arrow=True)
    s.text(320, 186, t("3  mark them sent"), size=9, fill="var(--paper-dim)")
    s.text(560, 170, t("a crash here repeats step 2"), size=9.5, fill="var(--amber)")
    s.line(470, 125, 470, 160, stroke="var(--amber)", sw=1, dash="2 3")
