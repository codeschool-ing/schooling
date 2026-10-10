NAME = "l16-bluegreen"
W, H = 720, 240
LABEL = ("One topic, sales, read by two consumer groups. The old version, group stock-count, writes to the output people read. The new version, group stock-v2, starts from the oldest message and writes to an output of its own. When the new one has caught up and its output has been checked, readers switch to it and the old group is deleted.",
         "Um tópico, sales, lido por dois grupos de consumidores. A versão antiga, grupo stock-count, escreve na saída que as pessoas leem. A versão nova, grupo stock-v2, começa da mensagem mais antiga e escreve numa saída própria. Quando a nova alcança o fim e a saída dela é conferida, os leitores mudam para ela e o grupo antigo é apagado.")
CAPTION = ("Blue-green reprocessing: the new version catches up beside the old one, and readers move only when it has.",
           "Reprocessamento blue-green: a versão nova alcança o fim ao lado da antiga, e os leitores só mudam quando ela alcança.")
PT = {"sales": "sales", "old version": "versão antiga", "new version": "versão nova",
      "group stock-count": "grupo stock-count", "group stock-v2": "grupo stock-v2",
      "from the oldest message": "da mensagem mais antiga", "at the end": "no fim",
      "stock": "stock", "stock.v2": "stock.v2", "readers today": "leitores hoje",
      "after the switch": "depois da troca", "compare": "comparar"}
SAME = ["sales"]
def draw(s, t):
    s.rect(20, 85, 130, 60, stroke="var(--phosphor)")
    s.text(85, 115, t("sales"), size=12, weight=600, mono=True)
    s.rect(250, 30, 190, 60, stroke="var(--wire)")
    s.text(345, 52, t("old version"), size=10.5, weight=600)
    s.text(345, 70, t("group stock-count"), size=9.5, fill="var(--paper-dim)")
    s.rect(250, 140, 190, 60, stroke="var(--amber)")
    s.text(345, 162, t("new version"), size=10.5, weight=600, fill="var(--amber)")
    s.text(345, 180, t("group stock-v2"), size=9.5, fill="var(--paper-dim)")
    s.path("M 150 105 L 245 62", arrow=True)
    s.text(195, 70, t("at the end"), size=9, fill="var(--paper-dim)")
    s.path("M 150 125 L 245 168", stroke="var(--amber)", arrow=True)
    s.text(190, 188, t("from the oldest message"), size=9, fill="var(--amber)", anchor="middle")
    s.rect(500, 40, 90, 40, stroke="var(--wire)")
    s.text(545, 60, t("stock"), size=10.5, mono=True)
    s.rect(500, 150, 90, 40, stroke="var(--amber)")
    s.text(545, 170, t("stock.v2"), size=10.5, mono=True)
    s.path("M 440 60 L 495 60", arrow=True)
    s.path("M 440 170 L 495 170", stroke="var(--amber)", arrow=True)
    s.path("M 545 85 L 545 145", dash="3 3")
    s.text(560, 115, t("compare"), size=9, fill="var(--paper-dim)", anchor="start")
    s.text(655, 50, t("readers today"), size=9.5, fill="var(--paper-dim)")
    s.path("M 625 60 L 595 60", arrow=True)
    s.text(655, 160, t("after the switch"), size=9.5, fill="var(--amber)")
    s.path("M 625 170 L 595 170", stroke="var(--amber)", arrow=True)
