---
title: A hora do evento, e o relógio que importa
version: 1
---

**Todo evento tem duas horas, e contar pela errada dá uma resposta errada e confiante.** A **hora do
evento** é quando a coisa aconteceu: o cliente tocou em "checkout" às 20:00:55, e o app escreveu isso
no clique. A **hora de chegada** é quando o Azure o recebeu, o enqueued time da lição 22. As duas
ficam perto quando a rede é boa e longe quando não é, e o caso que importa é o celular no túnel: ele
guarda os cliques e os envia um minuto depois, juntos, então eles chegam atrasados e fora de ordem.

Uma consulta sem `TIMESTAMP BY` conta pela hora de chegada. É simples e está errado para qualquer
pergunta sobre o que os clientes fizeram, porque uma rajada de cliques atrasados cai no minuto em que
a rede voltou e falta no minuto em que os clientes tocaram. **`TIMESTAMP BY at` faz do campo do
próprio evento o relógio**, e a partir daí a consulta tem um problema que a hora de chegada nunca
teve: precisa decidir quanto esperar pelos retardatários de um minuto antes de publicar a contagem
desse minuto.

## Um substituto para o job, identificado

**O que vem a seguir é um programa em Python escrito para este curso. Não é o Stream Analytics**, e
não reproduz tudo o que o serviço faz; ele implementa janelas tumbling pela hora do evento e uma
tolerância para desordem, o que basta para ver o problema que o serviço resolve. Ele lê do emulador
do Event Hubs da lição 22, que esta lição sobe do mesmo jeito:

```
ana@laptop:~/azure$ docker compose --profile eventhubs up -d 2>&1 | tail -1
 Container azure-eventhubs-1 Started 
```

E no mesmo terminal, a variável da lição 22:

```sh
export EVENTHUB_CONNECTION_STRING='Endpoint=sb://localhost;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;'
```

Primeiro, dez checkouts de uma noite da Quitanda, na ordem em que chegaram ao Azure, cada um com a
hora que o app registrou. Salve como `send_checkouts.py`:

```schooling-example
{"language": "python", "file": "send_checkouts.py", "parts": [{"code": "import json\nimport os\n\nfrom azure.eventhub import EventData, EventHubProducerClient\n\n", "note": "A biblioteca da lição 22, enviando para o mesmo hub, `clicks`."}, {"code": "CHECKOUTS = [\n    (1, \"c-17\", \"20:00:05\"), (2, \"c-02\", \"20:00:20\"), (3, \"c-05\", \"20:00:50\"),\n    (4, \"c-03\", \"20:00:40\"), (5, \"c-08\", \"20:01:10\"), (6, \"c-11\", \"20:01:30\"),\n    (7, \"c-21\", \"20:00:55\"), (8, \"c-17\", \"20:02:05\"), (9, \"c-02\", \"20:01:50\"),\n    (10, \"c-05\", \"20:03:01\"),\n]\n\n", "note": "**A lista está na ordem de chegada, e as horas não.** O checkout 4 aconteceu dez segundos antes do checkout 3; o checkout 7, do celular no túnel, aconteceu às 20:00:55 e chegou depois de checkouts das 20:01:30; o checkout 9 está quinze segundos fora do lugar."}, {"code": "hub = EventHubProducerClient.from_connection_string(\n    os.environ[\"EVENTHUB_CONNECTION_STRING\"], eventhub_name=\"clicks\")\nwith hub:\n    batch = hub.create_batch(partition_id=\"0\")\n    for n, customer, at in CHECKOUTS:\n        batch.add(EventData(json.dumps(\n            {\"n\": n, \"customer\": customer, \"page\": \"/checkout\", \"at\": f\"2026-10-30T{at}\"})))\n    hub.send_batch(batch)\nprint(f\"sent {len(CHECKOUTS)} checkouts to partition 0 in one batch\")\n", "note": "**Um lote, para uma partição nomeada**, para que a ordem de chegada seja exatamente a ordem da lista e as execuções abaixo saiam iguais toda vez. `at` é o relógio do app, hora de São Paulo, escrito como texto no evento; o serviço nunca o vê como outra coisa além de bytes."}]}
```

Depois o contador. Salve como `windows.py`:

```schooling-example
{"language": "python", "file": "windows.py", "parts": [{"code": "import json\nimport os\nimport sys\nimport threading\nimport time\nfrom datetime import datetime, timedelta\n\nfrom azure.eventhub import EventHubConsumerClient\n\npolicy, tolerance = sys.argv[1], timedelta(seconds=int(sys.argv[2]))\nWINDOW = timedelta(minutes=1)\n\n", "note": "Dois argumentos: o que fazer com um evento atrasado, `drop` ou `adjust`, e quantos segundos de desordem tolerar. As janelas são de um minuto, como o `TumblingWindow(minute, 1)` do job."}, {"code": "client = EventHubConsumerClient.from_connection_string(\n    os.environ[\"EVENTHUB_CONNECTION_STRING\"], consumer_group=\"$Default\", eventhub_name=\"clicks\")\narrived = []\n\ndef on_event(partition, event):\n    arrived.append((json.loads(event.body_as_str()), event.enqueued_time))\n\nlistener = threading.Thread(target=client.receive, kwargs={\n    \"on_event\": on_event, \"partition_id\": \"0\", \"starting_position\": \"-1\"})\nlistener.start()\ntime.sleep(5)\nclient.close()\nlistener.join()\nprint(f\"{len(arrived)} events, enqueued from {arrived[0][1]:%H:%M:%S.%f} to {arrived[-1][1]:%H:%M:%S.%f} UTC\")\n\n", "note": "O leitor da lição 22, limitado à partição 0, guardando cada evento com o seu **enqueued time**, a hora de chegada. Ele lê tudo primeiro e depois repassa na ordem de chegada, que é a ordem que um job ao vivo teria visto."}, {"code": "counts, highest = {}, None\nfor click, _ in arrived:\n    at = datetime.fromisoformat(click[\"at\"])\n    watermark = highest - tolerance if highest else None\n", "note": "**A marca d'água (watermark) é a maior hora de evento vista até agora, menos a tolerância.** É a declaração do programa de que nada mais velho que isso é esperado."}, {"code": "    if watermark and at < watermark:\n        behind = int((watermark - at).total_seconds())\n        if policy == \"drop\":\n            print(f\"#{click['n']:<2} at {at:%H:%M:%S}  {behind} s behind the watermark: dropped\")\n            continue\n        print(f\"#{click['n']:<2} at {at:%H:%M:%S}  {behind} s behind the watermark: adjusted to {watermark:%H:%M:%S}\")\n        at = watermark\n", "note": "Um evento mais velho que a marca d'água está atrasado. `drop` o descarta; `adjust` o mantém e adianta a hora dele até a marca d'água, então ele é contado numa janela ainda aberta, que não é aquela em que aconteceu."}, {"code": "    start = at.replace(second=0)\n    counts[start] = counts.get(start, 0) + 1\n    highest = max(highest, at) if highest else at\n    for s in sorted(counts):\n        if s + WINDOW <= highest - tolerance:\n            print(f\"window {s:%H:%M}-{s + WINDOW:%H:%M}  {counts.pop(s)} checkouts  closed by #{click['n']}\")\n\n", "note": "Cada evento é contado no minuto em que a hora dele cai. Depois **toda janela que termina na nova marca d'água ou antes dela é fechada e impressa**, com o número do evento cuja chegada a fechou. Uma janela fechada é definitiva: nada pode ser acrescentado a ela."}, {"code": "for s in sorted(counts):\n    print(f\"window {s:%H:%M}-{s + WINDOW:%H:%M}  {counts[s]} checkouts  still open\")\n", "note": "As janelas que a marca d'água não passou quando os eventos acabam são impressas como ainda abertas. Um job ao vivo as manteria abertas até eventos posteriores moverem a marca d'água para além delas."}]}
```

Envie os checkouts, depois conte-os com uma tolerância de vinte segundos:

```
ana@laptop:~/azure$ python send_checkouts.py
sent 10 checkouts to partition 0 in one batch
ana@laptop:~/azure$ python windows.py drop 20
10 events, enqueued from 18:40:31.980000 to 18:40:31.980000 UTC
window 20:00-20:01  4 checkouts  closed by #6
#7  at 20:00:55  15 s behind the watermark: dropped
window 20:01-20:02  3 checkouts  closed by #10
window 20:02-20:03  1 checkouts  still open
window 20:03-20:04  1 checkouts  still open
```

**Olhe a primeira linha antes das janelas.** Os dez eventos foram recebidos no mesmo milissegundo,
porque foram enviados num lote só, e numa hora do dia que não tem nada a ver com 20:00: é o relógio
do emulador, em UTC, dizendo quando a gravação foi feita. **Contados pela hora de chegada, os dez
checkouts cairiam numa janela só**, o minuto em que o lote chegou, e a tela da sala de operações
mostraria dez checkouts num momento em que ninguém comprava nada. Contados pela hora do evento, eles
se espalham pelos quatro minutos em que os clientes de fato tocaram, e essa é a contagem que o
`TIMESTAMP BY at` pede.

**As janelas são impressas na ordem em que fecharam**, e não todas no fim. A janela das 20:00 às
20:01 fechou quando chegou o checkout 6, das 20:01:30: a maior hora vista passou a ser 20:01:30, a
marca d'água (watermark) 20:01:10, e nada antes de 20:01:00 era mais esperado. Ela guarda quatro checkouts, de 1
a 4, incluindo o checkout 4, que chegou depois do 3 embora tenha acontecido antes; vinte segundos de
tolerância bastaram para absorver esses dez segundos de desordem. As duas últimas janelas continuam
abertas porque nenhum evento posterior veio fechá-las.

**O checkout 7 é o assunto das próximas seções.** Ele aconteceu às 20:00:55, numa janela que já
estava fechada quando ele chegou, e com `drop` foi descartado: a janela das 20:00 diz quatro
checkouts e foram cinco. A seção sobre dados atrasados executa as outras duas escolhas, e a que fica
entre ela e esta apresenta as janelas que não são tumbling.
