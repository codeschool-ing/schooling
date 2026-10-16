# Lesson 9, three-clocks: one of Natal's sales, and its three times.
NAME = "l9-three-clocks"
W, H = 720, 200
LABEL = ("A timeline of one sale from Natal. Event time: the sale at 11:08. Ingestion time: Kafka stores it at 14:00, when the till reconnects. Processing time: a reader keeping up handles it a second later, and somebody replaying the topic in April handles it then, so the same sale has many processing times.",
         "Uma linha do tempo de uma venda de Natal. Tempo do evento: a venda às 11:08. Tempo de ingestão: o Kafka a grava às 14:00, quando o caixa volta. Tempo de processamento: um leitor em dia a trata um segundo depois, e alguém que relê o tópico em abril a trata em abril, então a mesma venda tem muitos tempos de processamento.")
CAPTION = ("Event time belongs to the sale and never changes. Ingestion time is fixed once the log has it. Processing time is every moment anybody reads it.",
           "O tempo do evento pertence à venda e nunca muda. O tempo de ingestão fica fixo quando o log a recebe. O tempo de processamento é cada momento em que alguém a lê.")
PT = {"event time": "tempo do evento", "ingestion time": "tempo de ingestão",
      "processing time": "tempo de processamento",
      "11:08, sold in Natal": "11:08, vendida em Natal", "the till's clock": "o relógio do caixa",
      "14:00:07, appended": "14:00:07, gravada", "the broker's clock": "o relógio do broker",
      "14:00:08, a reader keeping up": "14:00:08, um leitor em dia", "a replay in April": "uma releitura em abril",
      "the reader's clock": "o relógio de quem lê", "till offline": "caixa sem conexão", "2 March": "2 de março"}
def draw(s, t):
    y = 110
    s.line(40, y, 690, y, stroke="var(--wire)")
    s.rect(70, y - 6, 400, 12, fill="var(--panel)", stroke="var(--wire)", dash="3 3", rx=2)
    s.text(330, y, t("till offline"), size=9, fill="var(--paper-dim)")
    s.text(40, y + 20, t("2 March"), size=9, fill="var(--paper-dim)", anchor="start")
    pts = [(160, "event time", "11:08, sold in Natal", "the till's clock", "var(--phosphor)", -1),
           (480, "ingestion time", "14:00:07, appended", "the broker's clock", "var(--amber)", -1),
           (520, "processing time", "14:00:08, a reader keeping up", "the reader's clock", "var(--paper)", 1)]
    for x, name, what, who, col, side in pts:
        s.circle(x, y, 5, fill=col)
        yy = y - 62 if side < 0 else y + 34
        s.line(x, y + (-8 if side < 0 else 8), x, yy + (14 if side < 0 else -12), stroke=col, sw=1)
        s.text(x, yy - 8, t(name), size=10.5, weight=600, fill=col)
        s.text(x, yy + 6, t(what), size=9.5, fill="var(--paper)")
        s.text(x, yy + 20 if side > 0 else yy - 22, t(who), size=9, fill="var(--paper-dim)")
    s.line(560, y, 680, y, stroke="var(--paper-dim)", dash="2 3", arrow=True)
    s.circle(668, y, 4, fill="none", stroke="var(--paper)")
    s.text(668, y - 18, t("a replay in April"), size=9.5, fill="var(--paper)", anchor="end")
