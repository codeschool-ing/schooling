---
title: Checkpoints, guardados pelo leitor num blob
version: 1
---

**O Event Hubs não lembra onde um leitor parou. O leitor lembra, e anota isso num lugar seu.** Um
checkpoint é essa anotação: para um grupo de consumidores e uma partição, o número de sequência e o
offset do último evento que o leitor terminou de tratar. Quando o leitor começa de novo, ele lê a
anotação e continua a partir do evento seguinte. O serviço não participa disso, o que surpreende quem
espera que um stream se comporte como uma fila que sabe o que foi entregue.

As bibliotecas guardam a anotação num contêiner de blobs, e o laboratório já tem um lugar para pôr um
blob: o Azurite. Crie um contêiner para ela:

```
ana@laptop:~/azure$ az storage container create -n checkpoints
{
  "created": true
}
```

## Um leitor que faz checkpoint

Salve isto como `checkpointed.py`:

```schooling-example
{"language": "python", "file": "checkpointed.py", "parts": [{"code": "import json\nimport os\nimport threading\nimport time\n\nfrom azure.eventhub import EventHubConsumerClient\nfrom azure.eventhub.extensions.checkpointstoreblob import BlobCheckpointStore\n\n", "note": "O `BlobCheckpointStore` vem do `azure-eventhub-checkpointstoreblob`, a quarta biblioteca que a lição 1 instalou. É a peça que grava os checkpoints como blobs."}, {"code": "AZURITE = (\"DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;\"\n           \"AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;\"\n           \"BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;\")\nstore = BlobCheckpointStore.from_connection_string(AZURITE, \"checkpoints\")\n", "note": "**A string de conexão do Azurite escrita por extenso**, com o nome de conta e a chave publicados. A forma curta, `UseDevelopmentStorage=true`, é recusada por esta biblioteca, como mostra a execução abaixo."}, {"code": "client = EventHubConsumerClient.from_connection_string(\n    os.environ[\"EVENTHUB_CONNECTION_STRING\"], consumer_group=\"$Default\",\n    eventhub_name=\"clicks\", checkpoint_store=store)\nseen = []\n\n", "note": "A única diferença em relação ao `read_clicks.py` na criação do cliente: ele recebe o armazenamento de checkpoints."}, {"code": "def on_event(partition, event):\n    click = json.loads(event.body_as_str())\n    seen.append((partition.partition_id, event.sequence_number, click[\"n\"], click[\"page\"]))\n    partition.update_checkpoint(event)\n\n", "note": "**O `update_checkpoint` grava a anotação**, depois que o evento foi tratado. Aqui tratar é acrescentar a uma lista; na checagem de fraude seria a checagem inteira. A ordem dessas duas linhas é o assunto da lição 24."}, {"code": "listener = threading.Thread(target=client.receive, kwargs={\n    \"on_event\": on_event, \"starting_position\": \"-1\"})\nlistener.start()\ntime.sleep(5)\nclient.close()\nlistener.join()\nfor pid, seq, n, page in sorted(seen):\n    print(f\"partition {pid}  seq {seq:>2}  #{n:<2} {page}\")\nprint(f\"{len(seen)} clicks read\")\n", "note": "O `starting_position` continua dizendo `-1`, e agora vale só para uma partição sem checkpoint. Onde há um, o checkpoint ganha."}]}
```

Primeiro a string de conexão curta, para ver o que esta biblioteca diz dela. O `sed` escreve uma
cópia do programa com só essa linha trocada:

```
ana@laptop:~/azure$ sed 's/^store = .*/store = BlobCheckpointStore.from_connection_string("UseDevelopmentStorage=true", "checkpoints")/' checkpointed.py > short.py && python short.py 2>&1 | tail -1
ValueError: Connection string missing required connection details.
```

**A mensagem é sobre a string, não sobre o Azurite**: a biblioteca interpreta a string de conexão por
conta própria, com uma cópia própria do código de armazenamento dentro dela, e essa cópia não conhece
o atalho de desenvolvimento que o `azure-storage-blob` mais novo e a linha de comando expandem para
você. A forma completa é a mesma coisa por extenso, e é ela que o programa usa. Agora a execução de
verdade, duas vezes, com mais dez cliques enviados entre uma e outra:

```
ana@laptop:~/azure$ python checkpointed.py
partition 0  seq  0  #4  /bakery
partition 0  seq  1  #8  /cart
partition 1  seq  0  #2  /search?q=banana
partition 1  seq  1  #5  /cart
partition 3  seq  0  #1  /fruit
partition 3  seq  1  #3  /fruit/banana
partition 3  seq  2  #6  /cart
partition 3  seq  3  #7  /dairy
partition 3  seq  4  #9  /checkout
partition 3  seq  5  #10 /cart
10 clicks read
ana@laptop:~/azure$ python send_clicks.py 11
sent clicks 11 to 20
ana@laptop:~/azure$ python checkpointed.py
partition 0  seq  2  #14 /bakery
partition 0  seq  3  #18 /cart
partition 1  seq  2  #12 /search?q=banana
partition 1  seq  3  #15 /cart
partition 3  seq  6  #11 /fruit
partition 3  seq  7  #13 /fruit/banana
partition 3  seq  8  #16 /cart
partition 3  seq  9  #17 /dairy
partition 3  seq 10  #19 /checkout
partition 3  seq 11  #20 /cart
10 clicks read
```

**A primeira execução leu os dez cliques; a segunda leu só os dez novos.** A segunda começou com o
mesmo `starting_position` de `-1`, encontrou um checkpoint em cada partição que tinha um, e começou
depois dele. A partição 3 continua no número de sequência 6, onde o clique 11 foi parar.

## Como é a anotação

Os checkpoints são blobs comuns, e o conteúdo deles está nos metadados:

```
ana@laptop:~/azure$ az storage blob list -c checkpoints --include m --query "[].[name, metadata.sequencenumber, metadata.offset]" -o tsv
localhost/clicks/$default/checkpoint/0	3	432
localhost/clicks/$default/checkpoint/1	3	448
localhost/clicks/$default/checkpoint/3	11	1600
localhost/clicks/$default/ownership/0	None	None
localhost/clicks/$default/ownership/1	None	None
localhost/clicks/$default/ownership/2	None	None
localhost/clicks/$default/ownership/3	None	None
```

**Um blob por partição por grupo de consumidores, sob o host do namespace, o hub e o grupo**:
`localhost/clicks/$default/checkpoint/3` diz que no grupo `$default` (a biblioteca escreve o nome em
minúsculas) a partição 3 foi tratada até o número de sequência 11, no offset 1600. A partição 2 não
tem checkpoint, porque nada foi lido dela. Os blobs `ownership` são o balanceamento de carga da seção
anterior: cada um registra qual leitor em execução é dono de uma partição, e um leitor que para de
renovar o pedido perde a partição para outro. Eles dizem `None` aqui porque o programa fechou direito
e devolveu as partições.

No Azure esses blobs vão para um contêiner de uma conta de armazenamento sua, e isso tem duas
consequências. **Os checkpoints são tão seguros quanto esse contêiner**: uma regra de ciclo de vida da
lição 5 que os apagasse, ou uma chave da lição 6 nas mãos erradas, mandaria todo leitor de volta ao
`starting_position`. E **cada checkpoint é uma escrita no Blob Storage**, cobrada como qualquer outra.
Este programa faz checkpoint depois de cada evento, o que dá vinte escritas para vinte cliques; com as
centenas de cliques por segundo da Quitanda, são centenas de escritas no armazenamento por segundo, um
custo que a lição 7 conta. O meio-termo de costume é fazer checkpoint a cada tantos eventos ou a cada
poucos segundos, e aceitar que um leitor que cai vai ler de novo o que tratou desde o último. A lição
24 faz essa queda acontecer.
