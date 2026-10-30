---
title: De onde vêm as duplicatas
version: 1
---

**Uma duplicata não é defeito do stream; é o que uma nova tentativa correta produz.** Quatro lugares
as fazem, e só um dos quatro é um leitor caindo. Esta seção nomeia os quatro e executa o primeiro.

O emulador da lição 22, subido do mesmo jeito, e a variável de que ele precisa:

```
ana@laptop:~/azure$ docker compose --profile eventhubs up -d 2>&1 | tail -1
 Container azure-eventhubs-1 Started 
```

```sh
export EVENTHUB_CONNECTION_STRING='Endpoint=sb://localhost;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=SAS_KEY_VALUE;UseDevelopmentEmulator=true;'
```

## O produtor que tenta de novo

A loja da Quitanda envia um evento por pedido pago. O laboratório tem um event hub, `clicks`, e os
pagamentos vão para ele: o Event Hubs nunca olha dentro de um evento, então um hub com nome de
cliques leva pagamentos tão bem quanto. Salve isto como `pay.py`:

```schooling-example
{"language": "python", "file": "pay.py", "parts": [{"code": "import json\nimport os\n\nfrom azure.eventhub import EventData, EventHubProducerClient\n\n", "note": "A biblioteca da lição 22."}, {"code": "PAYMENTS = [\n    (\"o-301\", \"c-17\", 4590), (\"o-302\", \"c-02\", 12800), (\"o-303\", \"c-17\", 990),\n    (\"o-304\", \"c-05\", 2350), (\"o-305\", \"c-02\", 1500), (\"o-306\", \"c-17\", 7200),\n]\nRETRIED = {\"o-303\"}\n\n", "note": "Seis pagamentos, em centavos, de três clientes. **O id do pedido é o que faz um pagamento ser o mesmo pagamento**: um pedido é pago uma vez, então um segundo evento de um pedido é uma duplicata, seja qual for a causa. `o-303` vai ser enviado duas vezes."}, {"code": "hub = EventHubProducerClient.from_connection_string(\n    os.environ[\"EVENTHUB_CONNECTION_STRING\"], eventhub_name=\"clicks\")\nwith hub:\n    for order, customer, cents in PAYMENTS:\n        body = json.dumps({\"order\": order, \"customer\": customer, \"cents\": cents})\n        for _ in range(2 if order in RETRIED else 1):\n            hub.send_event(EventData(body), partition_id=\"0\")\n            print(f\"sent {order} {customer} {cents:>6}\")\n", "note": "**O segundo envio de `o-303` é o que um produtor faz quando o primeiro envio estourou o tempo**: a resposta não voltou, então ele não sabe se o evento foi guardado, e envia de novo. Tudo vai para a partição 0, para que o leitor da próxima seção tenha um log só para ler."}]}
```

```
ana@laptop:~/azure$ python pay.py
sent o-301 c-17   4590
sent o-302 c-02  12800
sent o-303 c-17    990
sent o-303 c-17    990
sent o-304 c-05   2350
sent o-305 c-02   1500
sent o-306 c-17   7200
```

**Sete eventos para seis pagamentos.** O serviço guardou as duas cópias de `o-303`, como dois eventos
com dois números de sequência, porque não tem como saber que são um pagamento só: ele não compara
eventos e não olha dentro deles. Os totais corretos são as somas dos seis: 12.780 centavos para
`c-17`, 14.300 para `c-02` e 2.350 para `c-05`. São esses os números com que comparar no resto da
lição.

Um produtor só evita isso não tentando de novo, o que transforma uma resposta perdida num pagamento
perdido. As bibliotecas cliente tentam de novo por conta própria quando um envio falha por um motivo
que consideram passageiro, então um produtor que nunca escreveu uma nova tentativa tem uma assim
mesmo.

## O leitor que cai

O segundo lugar é o que a próxima seção executa. **Um leitor que tratou eventos e morreu antes de
fazer checkpoint deles os trata de novo quando reinicia**, a partir do checkpoint anterior. Quantos
voltam é quantos ele tratou desde aquele checkpoint: um leitor que faz checkpoint a cada cem eventos
repete até noventa e nove.

## A partição que troca de dono

**O balanceamento de carga faz duplicatas sem queda nenhuma.** A lição 22 mostrou os blobs de
ownership: cópias de um leitor num grupo de consumidores repartem as partições entre si. Quando uma
cópia é acrescentada, removida ou reiniciada, uma partição passa de um dono para outro, e o novo dono
começa do último checkpoint, o mesmo lugar de onde começaria um leitor reiniciado. O que o dono
antigo tratou depois desse checkpoint, ele tratou uma vez, e o novo dono trata de novo. Uma
implantação que reinicia as cópias uma a uma, como fazem as implantações graduais, move partições
várias vezes em poucos minutos.

## O serviço que tenta de novo por você

**Um leitor gerenciado também tenta de novo, e diz isso.** O gatilho do Event Hubs no Azure Functions
entrega a uma function um lote de eventos; a documentação da Microsoft descreve que uma function que
falha ou estoura o tempo vê o mesmo lote de novo. O Stream Analytics repete uma gravação que a saída
recusou e documenta a entrega às saídas como pelo menos uma vez, então uma linha do contador de
checkouts pode chegar duas vezes à tabela SQL. Nenhum dos dois é defeito: os dois cumprem a promessa
de pelo menos uma vez.

## Duas que não são duplicatas

**Um segundo evento parecido com o primeiro não é uma duplicata.** `c-17` pode pagar 990 centavos duas
vezes, por dois pedidos, na mesma noite; um leitor que removesse "o mesmo cliente e o mesmo valor"
apagaria um pagamento de verdade. O que faz dois eventos serem o mesmo é uma identidade que o produtor
lhes deu, aqui o id do pedido, nunca uma semelhança entre os conteúdos. E **um evento que o produtor
reenviou com um id novo não é um que o leitor consiga reconhecer**: se a loja desse a cada envio um id
novo, as duas cópias de `o-303` pareceriam dois pedidos para todo mundo depois dela. A identidade
precisa estar fixada antes do primeiro envio, e é por isso que o id do pedido, decidido quando o
pedido foi feito, é o certo.
