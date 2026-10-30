---
title: Um event hub é um conjunto de partições
version: 1
---

**Um event hub não é uma fila.** É um número fixo de **partições**, e cada partição é um log ordenado
próprio: os eventos entram no fim dela, ficam guardados por um período de tempo e são lidos a partir
de qualquer ponto. Um evento enviado ao hub vai para exatamente uma partição. Todo o resto desta
lição, a ordem, a leitura, os checkpoints e o preço, é propriedade da partição e não do hub, então a
partição é por onde começar.

Três nomes vêm primeiro, porque a documentação do Azure usa os três numa frase só. Um **namespace** é
o recurso que você cria e pelo qual paga, com um endereço próprio como
`evhns-quitanda-app-prd.servicebus.windows.net`; é ele que tem a capacidade. Um **event hub** mora
dentro de um namespace e é para onde um produtor envia; quem usa Kafka chamaria de tópico. Uma
**partição** mora dentro de um event hub. O app da Quitanda envia seus cliques para um event hub,
`clicks`, num namespace.

## Subindo o emulador

O emulador do Event Hubs veio com o laboratório na lição 1: o `compose.yaml` o declara no perfil
`eventhubs`, e o `eventhubs/config.json` declara um namespace, `emulatorNs1`, com um event hub,
`clicks`, de quatro partições e um grupo de consumidores a mais, `fraud`. **O emulador guarda a
própria contabilidade no Azurite**, e é por isso que o Compose sobe o Azurite primeiro. Em
`~/azure`, com o terminal preparado como a lição 1 manda:

```
ana@laptop:~/azure$ docker compose --profile eventhubs up -d 2>&1 | tail -1
 Container azure-eventhubs-1 Started 
```

A linha volta na hora e o emulador ainda não está pronto: ele está pronto quando o log dele diz
isso, alguns segundos depois.

```
ana@laptop:~/azure$ docker compose logs eventhubs 2>&1 | grep -o 'Emulator Service is Successfully Up!' | head -1
Emulator Service is Successfully Up!
```

Os programas desta lição o encontram por uma variável, que você exporta no mesmo terminal:

```sh
export EVENTHUB_CONNECTION_STRING='Endpoint=sb://localhost;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;'
```

**Essa é a string de conexão do próprio emulador, publicada pela Microsoft e igual em todo
computador.** `SAS_KEY_VALUE` é literalmente a chave; o emulador não confere nada. No Azure a mesma
string leva o endereço do namespace e uma chave de acesso compartilhado de verdade, e o
`UseDevelopmentEmulator` não aparece. A lição 6 trata do que uma chave dessas dá a quem a tem, e vale
aqui palavra por palavra.

A linha de comando também tem comandos para o Event Hubs, `az eventhubs`, e eles não servem aqui.
Eles administram namespaces e hubs, que são o Azure Resource Manager, o plano de controle, e a lição
1 mostrou o que a linha de comando faz com uma pergunta que nenhum emulador responde:

```
ana@laptop:~/azure$ az eventhubs eventhub show -g rg-quitanda-stream-prd --namespace-name evhns-quitanda-app-prd -n clicks 2>&1 | tail -1
ERROR: Please run 'az login' to setup account.
```

## Quatro partições, vazias

Este programa pergunta ao hub sobre cada uma das partições. Salve-o como `partitions.py`:

`partitions.py`:

```python
import os

from azure.eventhub import EventHubProducerClient

hub = EventHubProducerClient.from_connection_string(
    os.environ["EVENTHUB_CONNECTION_STRING"], eventhub_name="clicks")
with hub:
    for pid in hub.get_partition_ids():
        p = hub.get_partition_properties(pid)
        print(f"partition {pid}  first {p['beginning_sequence_number']:>2}  "
              f"last {p['last_enqueued_sequence_number']:>2}  "
              f"last offset {p['last_enqueued_offset']:>4}  empty {p['is_empty']}")
```

```
ana@laptop:~/azure$ python partitions.py
partition 0  first -1  last -1  last offset   -1  empty True
partition 1  first -1  last -1  last offset   -1  empty True
partition 2  first -1  last -1  last offset   -1  empty True
partition 3  first -1  last -1  last offset   -1  empty True
```

**As partições se chamam `0` a `3`, como strings, e cada uma está vazia.** `-1` é como o serviço diz
"nenhum evento ainda". Os dois números que ele informa, o número de sequência e o offset, são as duas
maneiras de nomear uma posição numa partição, e a próxima seção os lê.

## Enviando cliques, com o cliente como chave

O app da Quitanda envia um evento por toque. Salve isto como `send_clicks.py`:

```schooling-example
{"language": "python", "file": "send_clicks.py", "parts": [{"code": "import json\nimport os\nimport sys\n\nfrom azure.eventhub import EventData, EventHubProducerClient\n\n", "note": "`azure-eventhub` é a biblioteca da Microsoft para o Event Hubs, instalada no ambiente virtual do laboratório na lição 1. Ela fala AMQP, o protocolo sobre o qual o serviço é construído, na porta 5672."}, {"code": "CLICKS = [\n    (\"c-17\", \"/fruit\"), (\"c-02\", \"/search?q=banana\"), (\"c-17\", \"/fruit/banana\"),\n    (\"c-05\", \"/bakery\"), (\"c-02\", \"/cart\"), (\"c-17\", \"/cart\"),\n    (\"c-03\", \"/dairy\"), (\"c-05\", \"/cart\"), (\"c-17\", \"/checkout\"), (\"c-03\", \"/cart\"),\n]\n\n", "note": "Dez toques de quatro clientes, na ordem em que aconteceram. `c-17` olha as frutas, compra uma banana e fecha o pedido; os outros passeiam."}, {"code": "first = int(sys.argv[1]) if len(sys.argv) > 1 else 1\nhub = EventHubProducerClient.from_connection_string(\n    os.environ[\"EVENTHUB_CONNECTION_STRING\"], eventhub_name=\"clicks\")\n", "note": "Cada clique é numerado a partir de `first`, para que uma segunda execução, `python send_clicks.py 11`, envie os mesmos toques numerados de 11 a 20 e as duas execuções possam ser distinguidas."}, {"code": "with hub:\n    for n, (customer, page) in enumerate(CLICKS, first):\n        body = json.dumps({\"n\": n, \"customer\": customer, \"page\": page})\n        hub.send_event(EventData(body), partition_key=customer)\nprint(f\"sent clicks {first} to {first + len(CLICKS) - 1}\")\n", "note": "**A chave de partição é o cliente.** O serviço calcula o hash da chave e o hash escolhe a partição, então todo clique de um cliente cai na mesma. O corpo é uma linha de JSON, e o Event Hubs nunca olha dentro dele."}]}
```

```
ana@laptop:~/azure$ python send_clicks.py
sent clicks 1 to 10
ana@laptop:~/azure$ python partitions.py
partition 0  first  0  last  1  last offset  144  empty False
partition 1  first  0  last  1  last offset  152  empty False
partition 2  first -1  last -1  last offset   -1  empty True
partition 3  first  0  last  5  last offset  728  empty False
```

**Dez cliques, quatro clientes, quatro partições, e uma partição não recebeu nada.** A partição 3
guarda seis eventos, numerados de 0 a 5, as partições 0 e 1 guardam dois cada, e a partição 2
continua vazia. Repare no que o produtor não ficou sabendo: o `send_event` não devolveu nada, e o
programa não tem ideia de para onde foram os cliques. Foi preciso uma segunda pergunta ao hub para
descobrir, e o programa de leitura da próxima seção diz qual cliente está onde.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"As chaves de quatro clientes caem por hash nas quatro partições do event hub clicks. c-05 vai para a partição 0, que guarda os cliques 4 e 8. c-02 vai para a partição 1, que guarda os cliques 2 e 5. A partição 2 não recebe nada. c-17 e c-03 vão ambos para a partição 3, que guarda os cliques 1, 3, 6, 7, 9 e 10 na ordem em que foram enviados.\" data-fig=\"l22-partitions\"><text x=\"60\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">chave de partição</text><text x=\"240\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partição: um log ordenado</text><rect x=\"20\" y=\"36\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-05</text><line x1=\"102\" y1=\"49\" x2=\"220.0\" y2=\"49.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"226,49 220.0,52.0 220.0,46.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><rect x=\"20\" y=\"82\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-02</text><line x1=\"102\" y1=\"95\" x2=\"220.0\" y2=\"95.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"226,95 220.0,98.0 220.0,92.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><rect x=\"20\" y=\"128\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-17</text><line x1=\"102\" y1=\"141\" x2=\"220.4\" y2=\"184.9\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"226,187 219.3,187.7 221.4,182.1\" fill=\"var(--amber)\" stroke=\"none\"></polygon><rect x=\"20\" y=\"174\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-03</text><line x1=\"102\" y1=\"187\" x2=\"220.0\" y2=\"187.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"226,187 220.0,190.0 220.0,184.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><rect x=\"230\" y=\"30\" width=\"470\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"242\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partição 0</text><rect x=\"340\" y=\"37\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"363\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#4</text><rect x=\"394\" y=\"37\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"417\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#8</text><rect x=\"230\" y=\"76\" width=\"470\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"242\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partição 1</text><rect x=\"340\" y=\"83\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"363\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#2</text><rect x=\"394\" y=\"83\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"417\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#5</text><rect x=\"230\" y=\"122\" width=\"470\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"242\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partição 2</text><text x=\"345\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nada ainda</text><rect x=\"230\" y=\"168\" width=\"470\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"242\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partição 3</text><rect x=\"340\" y=\"175\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"363\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#1</text><rect x=\"394\" y=\"175\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"417\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#3</text><rect x=\"448\" y=\"175\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"471\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#6</text><rect x=\"502\" y=\"175\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"525\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#7</text><rect x=\"556\" y=\"175\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"579\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#9</text><rect x=\"610\" y=\"175\" width=\"46\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"633\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">#10</text></svg>", "caption": "O hash da chave escolhe uma partição por cliente; dois clientes dividem a partição 3 e a partição 2 fica vazia."}
```

## O que a chave de partição decide

**A chave decide duas coisas ao mesmo tempo, e elas puxam para lados opostos.** Todo evento com a
mesma chave vai para a mesma partição, então a chave é a unidade de ordem: os cliques de um cliente
são lidos de volta na ordem em que foram enviados. E a chave é a unidade de espalhamento: as partições
dividem a carga só na medida em que as chaves dividem o hash. Quatro chaves em quatro partições é
pouco para espalhar, e a execução acima mostra isso: dois dos quatro clientes caíram na partição 3.
Com as dezenas de milhares de clientes da Quitanda os hashes se equilibram; com a loja como chave, e
três lojas, no máximo três partições do hub receberiam alguma coisa.

O hash é calculado pelo serviço, e o produtor não tem como escolher a partição por meio da chave. Um
produtor pode contorná-lo de duas maneiras. Pode nomear uma partição diretamente, com `partition_id`
em vez de `partition_key`, o que deixa a cargo do produtor espalhar a carga. Ou pode enviar sem
nenhum dos dois, e então o próprio serviço espalha os eventos pelas partições, sem manter ordem
entre eles.

**As duas escolhas se comportam de modo diferente quando uma partição está indisponível**, e a
documentação da Microsoft é explícita sobre isso. Um evento sem chave é mandado para uma partição que
está de pé, então um envio dá certo enquanto alguma partição está sendo movida ou reparada. Um evento
com chave, ou com partição nomeada, tem exatamente um lugar para ir, então o envio espera ou falha
até essa partição voltar. A chave compra ordem e paga em disponibilidade. Escolha-a como a menor
coisa cujos eventos precisam ficar em ordem, e envie sem chave nenhuma quando nada precisar.

**O número de partições é escolhido quando o hub é criado**, e nas camadas Basic e Standard não pode
ser mudado depois. Premium e Dedicated permitem aumentá-lo, nunca diminuí-lo, e a documentação avisa
da consequência: com mais partições o hash leva uma chave para uma partição diferente, então os
eventos antigos de uma chave e os novos ficam em dois logs, e a ordem entre eles se perde nesse
momento. A última seção desta lição põe partições contra preço.
