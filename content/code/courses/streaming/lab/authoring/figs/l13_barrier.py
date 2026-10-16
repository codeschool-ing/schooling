NAME = "l13-barrier"
W, H = 720, 240
LABEL = ("A checkpoint barrier travelling with the records. Records flow from the Kafka source to the window operator to the sink. The source injects a barrier, marked N, between two records and saves its offsets at that point. The barrier travels downstream behind the records before it; when it reaches the window operator, the operator saves its counts. Both saves go to checkpoint N, which therefore holds the offsets and the counts as of the same point in the stream. Records after the barrier keep flowing and are not in it.",
         "Uma barreira de checkpoint viajando junto com os registros. Os registros vão da fonte Kafka ao operador de janela e ao sink. A fonte injeta uma barreira, marcada N, entre dois registros e salva os seus offsets nesse ponto. A barreira segue adiante atrás dos registros anteriores a ela; quando chega ao operador de janela, o operador salva as suas contagens. Os dois salvamentos vão para o checkpoint N, que portanto guarda os offsets e as contagens no mesmo ponto do stream. Os registros depois da barreira continuam passando e não estão nele.")
CAPTION = ("Each operator saves its state when the barrier reaches it, so the snapshot is one consistent moment of the whole job.",
           "Cada operador salva o seu estado quando a barreira chega até ele, então o snapshot é um momento consistente do job inteiro.")
PT = {"Kafka source": "fonte Kafka", "window operator": "operador de janela", "sink": "sink",
      "barrier N": "barreira N", "checkpoint N": "checkpoint N", "offsets": "offsets",
      "counts": "contagens", "before the barrier: in N": "antes da barreira: em N",
      "after it: not in N": "depois dela: fora de N", "records flow": "os registros seguem"}
SAME = ["sink", "checkpoint N", "offsets"]


def draw(s, t):
    boxes = [(30, "Kafka source"), (300, "window operator"), (580, "sink")]
    for x, name in boxes:
        s.rect(x, 60, 110, 44, stroke="var(--wire)")
        s.text(x + 55, 82, t(name), size=10, weight=600)
    # records between source and operator
    for i, x in enumerate([160, 180, 200, 250, 270]):
        s.rect(x, 74, 12, 16, fill="var(--phosphor)" if x > 230 else "var(--phosphor-dim)", stroke="none", rx=2)
    s.line(228, 64, 228, 100, stroke="var(--amber)", sw=3)
    s.text(228, 40, t("barrier N"), size=9.5, fill="var(--amber)")
    for x in [430, 450, 470]:
        s.rect(x, 74, 12, 16, fill="var(--phosphor)", stroke="none", rx=2)
    s.path("M 490 82 L 576 82", arrow=True)
    s.text(220, 150, t("records flow"), size=9, fill="var(--paper-dim)", anchor="end")
    s.path("M 230 150 L 290 150", stroke="var(--paper-dim)", arrow=True)
    s.text(222, 114, t("after it: not in N"), size=9, fill="var(--paper-dim)", anchor="end")
    s.text(234, 114, t("before the barrier: in N"), size=9, fill="var(--phosphor)", anchor="start")
    s.rect(240, 180, 200, 44, fill="var(--panel)", stroke="var(--amber)")
    s.text(340, 195, t("checkpoint N"), size=10, weight=600, fill="var(--amber)")
    s.text(340, 212, t("offsets") + " + " + t("counts"), size=9, fill="var(--paper-dim)")
    s.path("M 85 106 Q 90 190 236 198", stroke="var(--amber)", arrow=True, dash="4 3")
    s.path("M 355 106 L 345 176", stroke="var(--amber)", arrow=True, dash="4 3")
    s.text(110, 175, t("offsets"), size=9, fill="var(--amber)")
    s.text(375, 150, t("counts"), size=9, fill="var(--amber)", anchor="start")
