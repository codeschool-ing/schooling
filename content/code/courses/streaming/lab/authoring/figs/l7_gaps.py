NAME = "l7-gaps"
W, H = 720, 210
LABEL = ("A sale travels from the till's producer to Kafka and from Kafka to a consumer that writes to a database. Two gaps are marked. The first is between the leader writing the sale and the producer receiving the acknowledgement: if the acknowledgement is lost, a retry may write the sale twice. The second is between the consumer processing the sale and committing its offset: depending on which comes first, a crash loses the sale or processes it again.",
         "Uma venda vai do produtor do caixa para o Kafka e do Kafka para um consumidor que grava num banco. Duas lacunas estão marcadas. A primeira fica entre o líder gravar a venda e o produtor receber a confirmação: se a confirmação se perde, uma nova tentativa pode gravar a venda duas vezes. A segunda fica entre o consumidor processar a venda e confirmar o offset: conforme o que vem primeiro, uma queda perde a venda ou a processa de novo.")
CAPTION = ("Two programs that do not share a memory, joined twice: every guarantee is a choice about these two gaps.",
           "Dois programas que não compartilham memória, ligados duas vezes: toda garantia é uma escolha sobre essas duas lacunas.")
PT = {"till · producer": "caixa · produtor", "Kafka": "Kafka", "consumer": "consumidor", "database": "banco de dados",
      "1  write": "1  grava", "2  acknowledge": "2  confirma", "3  process": "3  processa", "4  commit offset": "4  confirma o offset",
      "gap 1: ack lost": "lacuna 1: confirmação perdida", "retry → written twice": "nova tentativa → gravada duas vezes",
      "gap 2: crash between 3 and 4": "lacuna 2: queda entre 3 e 4", "lost, or processed again": "perdida, ou processada de novo"}
SAME = ["Kafka"]
def draw(s, t):
    boxes = [(20, "till · producer"), (250, "Kafka"), (470, "consumer"), (600, "database")]
    for x, name in boxes:
        w = 110 if name != "Kafka" else 140
        s.rect(x, 30, w, 40, stroke="var(--amber)" if name == "Kafka" else "var(--wire)")
        s.text(x + w / 2, 50, t(name), size=10.5, weight=600)
    s.line(130, 42, 248, 42, stroke="var(--paper)", arrow=True)
    s.text(189, 34, t("1  write"), size=9.5, fill="var(--paper-dim)")
    s.line(248, 60, 132, 60, stroke="var(--phosphor-dim)", arrow=True, dash="4 3")
    s.text(189, 80, t("2  acknowledge"), size=9.5, fill="var(--paper-dim)")
    s.line(390, 50, 468, 50, stroke="var(--paper)", arrow=True)
    s.line(580, 42, 598, 42, stroke="var(--paper)", arrow=True)
    s.text(625, 88, t("3  process"), size=9.5, fill="var(--paper-dim)")
    s.path("M 525 72 Q 460 120 392 72", stroke="var(--phosphor-dim)", arrow=True, dash="4 3")
    s.text(460, 118, t("4  commit offset"), size=9.5, fill="var(--paper-dim)")
    s.rect(110, 140, 180, 52, fill="var(--panel)", stroke="var(--amber)", dash="4 3")
    s.text(200, 158, t("gap 1: ack lost"), size=10, fill="var(--amber)", weight=600)
    s.text(200, 176, t("retry → written twice"), size=9.5, fill="var(--paper-dim)")
    s.rect(440, 140, 220, 52, fill="var(--panel)", stroke="var(--amber)", dash="4 3")
    s.text(550, 158, t("gap 2: crash between 3 and 4"), size=10, fill="var(--amber)", weight=600)
    s.text(550, 176, t("lost, or processed again"), size=9.5, fill="var(--paper-dim)")
    s.line(189, 86, 189, 138, stroke="var(--amber)", sw=1, dash="2 3")
    s.line(550, 124, 550, 138, stroke="var(--amber)", sw=1, dash="2 3")
