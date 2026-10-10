NAME = "l17-formula"
W, H = 720, 140
LABEL = ("Four boxes multiplied together give the disk a topic needs: messages a day, bytes per message on disk, days kept, and copies. Under each box, what sets it: the business, the message and its compression, retention.ms, and the replication factor.",
         "Quatro caixas multiplicadas dão o disco que um tópico precisa: mensagens por dia, bytes por mensagem em disco, dias guardados e cópias. Embaixo de cada caixa, o que a define: o negócio, a mensagem e a compressão, retention.ms e o fator de replicação.")
CAPTION = ("Storage is four factors multiplied, and each one is somebody's decision.",
           "O armazenamento é quatro fatores multiplicados, e cada um é decisão de alguém.")
PT = {"messages a day": "mensagens por dia", "bytes per message": "bytes por mensagem", "days kept": "dias guardados",
      "copies": "cópias", "disk needed": "disco necessário", "the business": "o negócio",
      "message + compression": "mensagem + compressão", "retention.ms": "retention.ms",
      "replication factor": "fator de replicação", "×": "×", "=": "="}
SAME = []
def draw(s, t):
    boxes = [("messages a day", "the business"), ("bytes per message", "message + compression"),
             ("days kept", "retention.ms"), ("copies", "replication factor")]
    x, w = 20, 116
    for i, (a, b) in enumerate(boxes):
        s.rect(x, 45, w, 50, stroke="var(--phosphor)")
        s.text(x + w / 2, 70, t(a), size=10.5, weight=600)
        s.text(x + w / 2, 118, t(b), size=9.5, fill="var(--paper-dim)", mono=(b == "retention.ms"))
        if i < 3:
            s.text(x + w + 13, 70, t("×"), size=16, fill="var(--paper-dim)")
        x += w + 26
    s.text(x - 6, 70, t("="), size=16, fill="var(--paper-dim)")
    s.rect(x + 10, 45, 100, 50, stroke="var(--amber)")
    s.text(x + 60, 70, t("disk needed"), size=10.5, weight=600, fill="var(--amber)")
