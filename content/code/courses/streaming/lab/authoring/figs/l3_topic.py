NAME = "l3-topic"
W, H = 720, 250
LABEL = ("A topic named sales drawn as a box holding three partitions. Each partition is a row of records numbered from offset 0, and the rows have different lengths: partition 0 has seven records, partition 1 has eleven, partition 2 has four. A producer on the left hashes each message's key to choose one partition; new records are appended at the right-hand end of their row.",
         "Um tópico chamado sales desenhado como uma caixa com três partições. Cada partição é uma fileira de registros numerados a partir do offset 0, e as fileiras têm comprimentos diferentes: a partição 0 tem sete registros, a partição 1 tem onze, a partição 2 tem quatro. Um produtor à esquerda faz o hash da chave de cada mensagem para escolher uma partição; registros novos são anexados na ponta direita da sua fileira.")
CAPTION = ("One topic, three logs. Each partition has its own offsets, and nothing orders one partition against another.",
           "Um tópico, três logs. Cada partição tem seus próprios offsets, e nada ordena uma partição em relação a outra.")
PT = {"producer": "produtor", "hash(key) % 3": "hash(chave) % 3", "topic sales": "tópico sales",
      "partition 0": "partição 0", "partition 1": "partição 1", "partition 2": "partição 2",
      "new records here": "registros novos aqui"}
SAME = []
def draw(s, t):
    s.rect(20, 105, 80, 34); s.text(60, 122, t("producer"), size=10, weight=600)
    s.text(60, 155, t("hash(key) % 3"), size=9, fill="var(--paper-dim)", mono=True)
    s.rect(160, 30, 545, 200, fill="none", stroke="var(--wire)", dash="4 3")
    s.text(175, 46, t("topic sales"), size=10, weight=600, anchor="start")
    rows = [(0, 7, 75), (1, 11, 130), (2, 4, 185)]
    for p, n, y in rows:
        s.path(f"M 100 122 L 228 {y + 13}", arrow=True)
        s.text(195, y - 6, t(f"partition {p}"), size=9, fill="var(--paper-dim)")
        for i in range(n):
            x = 235 + i * 38
            s.rect(x, y, 34, 26, fill="var(--panel)", stroke="var(--phosphor-dim)")
            s.text(x + 17, y + 13, str(i), size=10, fill="var(--phosphor)", mono=True)
        xe = 235 + n * 38
        s.rect(xe, y, 34, 26, fill="none", stroke="var(--amber)", dash="3 3")
    s.text(620, 220, t("new records here"), size=9, fill="var(--amber)")
