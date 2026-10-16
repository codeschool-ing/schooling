NAME = "l13-three-shapes"
W, H = 720, 280
LABEL = ("Three shapes for the same count. Spark: your program hands a query to a Spark engine, which reads the topic in micro-batches and writes to a sink, keeping its state in a checkpoint directory. Flink: your SQL or program is submitted as a job to a Flink cluster, a JobManager and TaskManagers, which handle each record as it arrives and save state in snapshots. Kafka Streams: no cluster; the library runs inside two copies of your own program, which share the topic's partitions and back their local state up to Kafka topics.",
         "Três formas para a mesma contagem. Spark: o seu programa entrega uma consulta a um motor Spark, que lê o tópico em micro-batches e escreve num sink, guardando o estado num diretório de checkpoint. Flink: o seu SQL ou programa é submetido como um job a um cluster Flink, um JobManager e TaskManagers, que tratam cada registro quando ele chega e salvam o estado em snapshots. Kafka Streams: nenhum cluster; a biblioteca roda dentro de duas cópias do seu próprio programa, que dividem as partições do tópico e guardam cópia do estado local em tópicos do Kafka.")
CAPTION = ("Spark and Flink are engines your work is sent to; Kafka Streams runs inside your program, and Kafka is all it needs.",
           "Spark e Flink são motores para onde o seu trabalho é mandado; o Kafka Streams roda dentro do seu programa, e só precisa do Kafka.")
PT = {"Spark": "Spark", "Flink": "Flink", "Kafka Streams": "Kafka Streams",
      "your program": "seu programa", "query": "consulta", "Spark engine": "motor Spark",
      "micro-batches": "micro-batches", "checkpoint dir": "dir. de checkpoint",
      "SQL or job": "SQL ou job", "JobManager": "JobManager", "TaskManagers": "TaskManagers",
      "record by record": "registro a registro", "snapshots": "snapshots",
      "your program, copy 1": "seu programa, cópia 1", "your program, copy 2": "seu programa, cópia 2",
      "library inside": "biblioteca dentro", "changelog topics": "tópicos de changelog",
      "topic": "tópico", "sink": "sink", "output topic": "tópico de saída"}
SAME = ["Spark", "Flink", "Kafka Streams", "micro-batches", "JobManager", "TaskManagers", "snapshots", "sink"]


def lane(s, t, y, title):
    s.text(20, y + 30, t(title), size=11, weight=600, anchor="start")
    s.rect(120, y + 12, 60, 36, fill="var(--panel)", stroke="var(--phosphor-dim)")
    s.text(150, y + 30, t("topic"), size=9.5)


def draw(s, t):
    # Spark
    y = 10
    lane(s, t, y, "Spark")
    s.rect(220, y + 6, 100, 48, stroke="var(--wire)")
    s.text(270, y + 23, t("your program"), size=9.5)
    s.text(270, y + 39, t("query"), size=9, fill="var(--paper-dim)")
    s.rect(360, y + 6, 150, 48, stroke="var(--amber)")
    s.text(435, y + 23, t("Spark engine"), size=10, weight=600)
    s.text(435, y + 39, t("micro-batches"), size=9, fill="var(--paper-dim)")
    s.path(f"M 322 {y + 30} L 356 {y + 30}", arrow=True)
    s.path(f"M 182 {y + 30} Q 200 {y + 66} 360 {y + 52}", stroke="var(--phosphor)", arrow=True)
    s.rect(560, y + 12, 60, 36, fill="var(--panel)", stroke="var(--phosphor-dim)")
    s.text(590, y + 30, t("sink"), size=9.5)
    s.path(f"M 512 {y + 30} L 556 {y + 30}", stroke="var(--phosphor)", arrow=True)
    s.text(435, y + 70, t("checkpoint dir"), size=9, fill="var(--amber)")
    # Flink
    y = 100
    lane(s, t, y, "Flink")
    s.rect(220, y + 6, 100, 48, stroke="var(--wire)")
    s.text(270, y + 30, t("SQL or job"), size=9.5)
    s.rect(360, y + 2, 150, 56, stroke="var(--amber)")
    s.text(435, y + 16, t("JobManager"), size=10, weight=600)
    s.text(435, y + 32, t("TaskManagers"), size=10, weight=600)
    s.text(435, y + 48, t("record by record"), size=9, fill="var(--paper-dim)")
    s.path(f"M 322 {y + 30} L 356 {y + 30}", arrow=True)
    s.path(f"M 182 {y + 30} Q 200 {y + 70} 360 {y + 54}", stroke="var(--phosphor)", arrow=True)
    s.rect(560, y + 12, 60, 36, fill="var(--panel)", stroke="var(--phosphor-dim)")
    s.text(590, y + 30, t("sink"), size=9.5)
    s.path(f"M 512 {y + 30} L 556 {y + 30}", stroke="var(--phosphor)", arrow=True)
    s.text(435, y + 72, t("snapshots"), size=9, fill="var(--amber)")
    # Kafka Streams
    y = 190
    lane(s, t, y, "Kafka Streams")
    for i, yy in enumerate((y - 2, y + 40)):
        s.rect(260, yy, 200, 34, stroke="var(--wire)")
        s.text(360, yy + 11, t(f"your program, copy {i + 1}"), size=9.5)
        s.text(360, yy + 25, t("library inside"), size=9, fill="var(--amber)")
        s.path(f"M 182 {y + 30} L 256 {yy + 17}", stroke="var(--phosphor)", arrow=True)
        s.path(f"M 462 {yy + 17} L 556 {y + 30}", stroke="var(--phosphor)", arrow=True)
    s.rect(560, y + 12, 90, 36, fill="var(--panel)", stroke="var(--phosphor-dim)")
    s.text(605, y + 30, t("output topic"), size=9.5)
    s.text(605, y + 66, t("changelog topics"), size=9, fill="var(--amber)")
