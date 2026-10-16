NAME = "l14-pipeline"
W, H = 720, 230
LABEL = ("The path of one change from a table to a topic. A transaction commits and PostgreSQL writes it to the write-ahead log. The replication slot debezium_stock marks how far its reader has confirmed. The pgoutput plugin decodes the log from that point, keeping only the tables named in the publication ponto_final. Debezium, running inside Kafka Connect, turns each row change into an event and writes it to one topic per table: pf.public.books and pf.public.stock. The slot's position only moves when Debezium confirms, so everything after it stays on the database's disk.",
         "O caminho de uma mudança da tabela até o tópico. Uma transação é confirmada e o PostgreSQL a grava no write-ahead log. O slot de replicação debezium_stock marca até onde o leitor dele confirmou. O plugin pgoutput decodifica o log a partir desse ponto, ficando só com as tabelas citadas na publicação ponto_final. O Debezium, rodando dentro do Kafka Connect, transforma cada mudança de linha num evento e o grava num tópico por tabela: pf.public.books e pf.public.stock. A posição do slot só anda quando o Debezium confirma, então tudo o que vem depois dela fica no disco do banco.")
CAPTION = ("Logical decoding: the database's own log, read from a remembered position, filtered by a publication and turned into one topic per table.",
           "Decodificação lógica: o próprio log do banco, lido a partir de uma posição lembrada, filtrado por uma publicação e transformado num tópico por tabela.")
PT = {
    "PostgreSQL": "PostgreSQL",
    "COMMIT": "COMMIT",
    "write-ahead log (WAL)": "write-ahead log (WAL)",
    "slot debezium_stock": "slot debezium_stock",
    "confirmed up to here": "confirmado até aqui",
    "kept on disk until confirmed": "guardado em disco até a confirmação",
    "pgoutput": "pgoutput",
    "publication ponto_final": "publicação ponto_final",
    "Kafka Connect": "Kafka Connect",
    "Debezium connector": "conector Debezium",
    "Kafka": "Kafka",
}
SAME = ["PostgreSQL", "COMMIT", "write-ahead log (WAL)", "Kafka Connect", "Kafka"]


def draw(s, t):
    # database boundary
    s.rect(15, 20, 400, 190, fill="none", stroke="var(--wire)", dash="5 4")
    s.text(30, 36, t("PostgreSQL"), size=10, weight=600, anchor="start", fill="var(--paper-dim)")
    # COMMIT
    s.rect(30, 55, 80, 30, stroke="var(--phosphor)")
    s.text(70, 70, t("COMMIT"), size=10)
    s.path("M 110 70 L 140 70", arrow=True)
    # WAL as a strip of cells
    s.text(260, 50, t("write-ahead log (WAL)"), size=10, weight=600)
    for i in range(10):
        x = 145 + i * 24
        stroke = "var(--wire)" if i < 4 else "var(--phosphor)"
        s.rect(x, 58, 22, 24, fill="var(--panel)", stroke=stroke, rx=2)
    # slot marker
    s.line(241, 54, 241, 108, stroke="var(--amber)", sw=1.6)
    s.text(241, 118, t("slot debezium_stock"), size=9.5, fill="var(--amber)", mono=True)
    s.text(195, 98, t("confirmed up to here"), size=9, fill="var(--paper-dim)")
    s.text(318, 98, t("kept on disk until confirmed"), size=9, fill="var(--paper-dim)")
    # pgoutput + publication
    s.rect(150, 145, 230, 48, stroke="var(--wire)")
    s.text(265, 160, t("pgoutput"), size=10, weight=600, mono=True)
    s.text(265, 178, t("publication ponto_final"), size=9.5, fill="var(--paper-dim)")
    s.path("M 330 108 L 330 143", arrow=True)
    # Connect
    s.rect(440, 110, 120, 70, stroke="var(--amber)")
    s.text(500, 130, t("Kafka Connect"), size=10, weight=600)
    s.text(500, 150, t("Debezium connector"), size=9.5, fill="var(--paper-dim)")
    s.path("M 380 169 L 438 155", arrow=True)
    # Kafka topics
    s.rect(590, 60, 115, 140, fill="none", stroke="var(--wire)", dash="5 4")
    s.text(647, 76, t("Kafka"), size=10, weight=600, fill="var(--paper-dim)")
    s.rect(598, 95, 100, 30, stroke="var(--phosphor)")
    s.text(648, 110, "pf.public.books", size=9, mono=True)
    s.rect(598, 145, 100, 30, stroke="var(--phosphor)")
    s.text(648, 160, "pf.public.stock", size=9, mono=True)
    s.path("M 560 135 L 596 112", arrow=True)
    s.path("M 560 150 L 596 158", arrow=True)
