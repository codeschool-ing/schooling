---
title: Lendo uma partição, por número de sequência e offset
version: 1
---

**Quem lê um event hub não tira eventos dele.** Lê uma partição a partir de uma posição que escolhe,
e os eventos ficam onde estavam, para todos os outros leitores e para ele mesmo da próxima vez. Eles
saem da partição quando ficam mais velhos que a **retenção** do hub, um período de tempo definido no
hub, e por nenhum outro motivo. Quem já usou uma fila espera que ler remova a mensagem; a primeira
coisa a desaprender aqui é que ler um event hub não muda nada nele.

## Um leitor

Este programa lê todas as partições de `clicks` desde o começo, por cinco segundos, e imprime o que
encontrou. Salve-o como `read_clicks.py`:

```schooling-example
{"language": "python", "file": "read_clicks.py", "parts": [{"code": "import json\nimport os\nimport sys\nimport threading\nimport time\n\nfrom azure.eventhub import EventHubConsumerClient\n\n", "note": "A mesma biblioteca do envio, e a outra metade dela: o `EventHubConsumerClient` lê."}, {"code": "group = sys.argv[1] if len(sys.argv) > 1 else \"$Default\"\nstart = sys.argv[2] if len(sys.argv) > 2 else \"-1\"\nclient = EventHubConsumerClient.from_connection_string(\n    os.environ[\"EVENTHUB_CONNECTION_STRING\"], consumer_group=group, eventhub_name=\"clicks\")\nseen = []\n\n", "note": "**Um leitor sempre lê como membro de um grupo de consumidores**, e todo hub tem um chamado `$Default`. A próxima seção é sobre grupos. O segundo argumento é onde começar em cada partição: `-1` quer dizer o evento mais antigo que a partição ainda guarda."}, {"code": "def on_event(partition, event):\n    click = json.loads(event.body_as_str())\n    seen.append((partition.partition_id, event.sequence_number, event.offset,\n                 event.partition_key.decode(), click[\"n\"], click[\"page\"]))\n\ndef on_error(partition, error):\n    print(\"error:\", type(error).__name__, error)\n\n", "note": "A biblioteca chama `on_event` uma vez por evento, e diz de qual partição o evento veio. Todo evento traz seu **número de sequência**, seu **offset** e a chave de partição com que foi enviado. O `on_error` imprime o que der errado; sem ele, a biblioteca só escreveria num log que ninguém lê."}, {"code": "listener = threading.Thread(target=client.receive, kwargs={\n    \"on_event\": on_event, \"on_error\": on_error, \"starting_position\": start})\nlistener.start()\ntime.sleep(5)\nclient.close()\nlistener.join()\n", "note": "O `receive` nunca volta sozinho: um leitor de verdade escuta enquanto estiver rodando. Este escuta numa thread por cinco segundos e depois fecha o cliente, para que possa ser executado e lido."}, {"code": "for pid, seq, offset, key, n, page in sorted(seen):\n    print(f\"partition {pid}  seq {seq:>2}  offset {offset:>4}  {key}  #{n:<2} {page}\")\n", "note": "Os eventos chegam partição por partição, intercalados de um jeito diferente a cada execução, então o programa os ordena antes de imprimir."}]}
```

```
ana@laptop:~/azure$ python read_clicks.py
partition 0  seq  0  offset    0  c-05  #4  /bakery
partition 0  seq  1  offset  144  c-05  #8  /cart
partition 1  seq  0  offset    0  c-02  #2  /search?q=banana
partition 1  seq  1  offset  152  c-02  #5  /cart
partition 3  seq  0  offset    0  c-17  #1  /fruit
partition 3  seq  1  offset  144  c-17  #3  /fruit/banana
partition 3  seq  2  offset  296  c-17  #6  /cart
partition 3  seq  3  offset  440  c-03  #7  /dairy
partition 3  seq  4  offset  584  c-17  #9  /checkout
partition 3  seq  5  offset  728  c-03  #10 /cart
```

**Dentro de cada partição a ordem é exatamente a ordem de envio.** Na partição 3, `c-17` abre
`/fruit`, depois `/fruit/banana`, depois `/cart`, depois `/checkout`, os cliques 1, 3, 6 e 9, e os
dois cliques de `c-03` ficam no meio deles, onde foram enviados. Leia os cliques de um cliente e eles
fazem sentido.

**Entre partições a ordem some.** O clique 2 foi enviado em segundo lugar e aparece em quinto,
porque o programa ordenou por partição; um leitor que imprimisse os eventos na ordem de chegada
intercalaria as partições de outro jeito a cada execução. Nada nos eventos diz qual veio antes, o
clique 4 ou o clique 5, a não ser a hora em que o serviço recebeu cada um, o **enqueued time**, que é
do serviço e não do app. Uma pergunta sobre a ordem dos cliques entre clientes precisa de uma hora
que o próprio app põe no evento, e a lição 23 trata de ler por essa hora quando alguns eventos chegam
atrasados.

## Dois nomes para uma posição

**O número de sequência conta eventos; o offset os localiza.** Cada partição numera seus eventos a
partir de 0, um a um, então na partição 3 os seis cliques são 0 a 5, e o próximo será o 6 qualquer
que seja o tamanho dele. O offset é uma posição no armazenamento da partição, e neste emulador ele
cresce com o tamanho de cada evento: 0, 144, 296, 440. O segundo evento da partição 1 está em 152 e
não em 144 porque `"/search?q=banana"` é uma página mais longa que `"/bakery"`.

Trate os dois como pertencentes a uma partição só. **O número de sequência 1 da partição 0 e o número
de sequência 1 da partição 3 não têm nada a ver um com o outro**, e um leitor que guarda "o último
número de sequência que li" para um hub inteiro guardou um número que não quer dizer nada. E trate o
offset como uma string opaca que o serviço lhe deu, que é como a biblioteca o entrega: o uso seguro
dele é guardar e devolver, nunca fazer conta com ele.

## Onde começar

`starting_position` aceita quatro tipos de valor, e cada um é uma pergunta diferente:

| valor | começa em | serve para |
|---|---|---|
| `"-1"` | o evento mais antigo ainda guardado | reprocessar tudo o que a retenção permite |
| `"@latest"` | o fim, então só os eventos enviados daqui em diante | um painel que só se importa com o agora |
| um número de sequência | esse evento, ou o seguinte | retomar exatamente onde um leitor parou |
| um `datetime` | o primeiro evento recebido nessa hora ou depois | reprocessar desde as 9h, depois de corrigir um bug |

O número de sequência é por partição, então um programa passa um dicionário com um por partição, e
`starting_position_inclusive` diz se o próprio evento é lido de novo. Ler a partir do fim fica assim;
nada foi enviado durante os cinco segundos, então nada é impresso:

```
ana@laptop:~/azure$ python read_clicks.py '$Default' @latest
```

**Um leitor que começa em `@latest` e depois cai perde o que foi enviado enquanto estava fora**,
porque ao reiniciar ele começa no fim de novo. Esse é o problema que os checkpoints, duas seções à
frente, resolvem.

## A retenção, que é a única exclusão

**Um event hub guarda os eventos pelo período de retenção e depois os descarta, lidos ou não.** O
período é definido por hub, em horas ou dias, e a camada decide o quanto ele pode durar: a
documentação da Microsoft dá um dia no Basic, até sete dias no Standard e até noventa no Premium e no
Dedicated. O arquivo de configuração do emulador não define nenhum, e nada nesta lição espera o
bastante para ver um evento expirar, então a expiração não foi executada.

Duas consequências decidem projetos. Um leitor que fica mais atrasado que a retenção perde eventos
para sempre, sem erro nenhum, porque os eventos que ele pediria não existem mais. O número de
sequência mais antigo que uma partição informa anda para a frente à medida que eventos velhos
expiram, e é o leitor que compara esse número com o próprio checkpoint que percebe. E **um event hub
não é um armazenamento**: sete dias bastam para se recuperar de um fim de semana ruim e são pouco
para ser o histórico de alguém. O histórico vai para o armazenamento, que é para o que serve o
Capture, três seções à frente.
