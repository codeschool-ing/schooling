---
title: Um leitor que cai, contado duas vezes
version: 1
---

**Esta seção faz uma duplicata acontecer num programa que você pode executar, e as duas seguintes a
tornam inofensiva.** O leitor guarda o total acumulado de cada cliente com os pagamentos da seção
anterior, em blobs no Azurite, que é onde um programa pequeno desse tipo os guardaria; no Azure seria
uma conta de armazenamento, uma tabela ou uma linha de banco de dados, e a aritmética do que dá errado
é a mesma.

Cada maneira de gravar resultados ganha um contêiner para eles e um para os checkpoints:

```sh
for m in add guard upsert; do
  az storage container create -n "sink-$m" -o none
  az storage container create -n "checkpoints-$m" -o none
done
```

Salve o leitor como `totals.py`. Ele é longo porque guarda as três maneiras de gravar, e esta seção
usa a primeira:

```schooling-example
{"language": "python", "file": "totals.py", "parts": [{"code": "import json\nimport os\nimport sys\nimport threading\nimport time\n\nfrom azure.core.exceptions import ResourceNotFoundError\nfrom azure.eventhub import EventHubConsumerClient\nfrom azure.eventhub.extensions.checkpointstoreblob import BlobCheckpointStore\nfrom azure.storage.blob import BlobServiceClient\n\nAZURITE = (\"DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;\"\n           \"AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;\"\n           \"BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;\")\nmode = sys.argv[1]\ncrash_after = int(sys.argv[2]) if len(sys.argv) > 2 else None\nCHECKPOINT_EVERY = 3\nsink = BlobServiceClient.from_connection_string(AZURITE).get_container_client(f\"sink-{mode}\")\nhandled = 0\n\n", "note": "A string de conexão do Azurite por extenso, como na lição 22, porque a biblioteca de checkpoints recusa a forma curta. `mode` é como o leitor grava os resultados, um de três, e `crash_after` o faz morrer de propósito depois de tantos eventos. Cada modo tem um contêiner próprio para os resultados, `sink-add` e assim por diante, e um para os checkpoints, para que os três nunca vejam o trabalho um do outro."}, {"code": "def read(name, default):\n    try:\n        return json.loads(sink.download_blob(name).readall())\n    except ResourceNotFoundError:\n        return default\n\n", "note": "Lê um blob JSON pequeno, ou um valor padrão quando ele ainda não existe."}, {"code": "def handle(seq, p):\n    if mode == \"add\":\n        total = read(p[\"customer\"], 0)\n        sink.upload_blob(p[\"customer\"], json.dumps(total + p[\"cents\"]), overwrite=True)\n        return \"added to the total\"\n", "note": "**`add` é o leitor óbvio**: lê o total do cliente, soma o pagamento, grava o total de volta. Fazer isso duas vezes soma duas vezes."}, {"code": "    elif mode == \"guard\":\n        state = read(\"state\", {\"last_seq\": -1, \"totals\": {}})\n        if seq <= state[\"last_seq\"]:\n            return \"skipped, already in the state\"\n        totals = state[\"totals\"]\n        totals[p[\"customer\"]] = totals.get(p[\"customer\"], 0) + p[\"cents\"]\n        sink.upload_blob(\"state\", json.dumps({\"last_seq\": seq, \"totals\": totals}), overwrite=True)\n        return \"added, with its sequence number\"\n", "note": "`guard` guarda os totais e o último número de sequência tratado num blob só, gravado num upload só, e pula um evento com número igual ou menor. É o assunto da última seção desta lição."}, {"code": "    elif mode == \"upsert\":\n        sink.upload_blob(p[\"order\"], json.dumps(p), overwrite=True)\n        return \"written under its order id\"\n\n", "note": "`upsert` grava cada pagamento como um blob com o nome do id do pedido, e não soma nada enquanto trata. É o assunto da próxima seção."}, {"code": "def on_event(partition, event):\n    global handled\n    p = json.loads(event.body_as_str())\n    result = handle(event.sequence_number, p)\n    handled += 1\n    print(f\"seq {event.sequence_number}  {p['order']} {p['customer']} {p['cents']:>6}  {result}\")\n    if handled % CHECKPOINT_EVERY == 0:\n        partition.update_checkpoint(event)\n        print(f\"  checkpoint at seq {event.sequence_number}\", flush=True)\n    if handled == crash_after:\n        print(\"  crash\", flush=True)\n        os._exit(1)\n\n", "note": "**O trabalho, depois o checkpoint**: pelo menos uma vez. Um checkpoint a cada três eventos, o agrupamento que a lição 22 recomendou por custo, e `os._exit` quando `crash_after` é atingido, o que encerra o processo na hora, como termina um processo morto, sem fechar o cliente. O `flush=True` garante que as linhas impressas até ali cheguem à tela antes."}, {"code": "store = BlobCheckpointStore.from_connection_string(AZURITE, f\"checkpoints-{mode}\")\nclient = EventHubConsumerClient.from_connection_string(\n    os.environ[\"EVENTHUB_CONNECTION_STRING\"], consumer_group=\"$Default\",\n    eventhub_name=\"clicks\", checkpoint_store=store)\nlistener = threading.Thread(target=client.receive, kwargs={\n    \"on_event\": on_event, \"partition_id\": \"0\", \"starting_position\": \"-1\"})\nlistener.start()\ntime.sleep(5)\nclient.close()\nlistener.join()\n\n", "note": "O leitor da lição 22, na partição 0, com o armazenamento de checkpoints deste modo, escutando por cinco segundos."}, {"code": "if mode == \"upsert\":\n    totals = {}\n    for blob in sink.list_blobs():\n        p = read(blob.name, None)\n        totals[p[\"customer\"]] = totals.get(p[\"customer\"], 0) + p[\"cents\"]\nelif mode == \"guard\":\n    totals = read(\"state\", {\"totals\": {}})[\"totals\"]\nelse:\n    totals = {b.name: read(b.name, 0) for b in sink.list_blobs()}\nprint(\"totals:\", \"  \".join(f\"{c} {totals[c]}\" for c in sorted(totals)))\n", "note": "Os totais, como cada modo os guarda. No `upsert` eles são somados no fim a partir dos blobs, um por pedido."}]}
```

Execute-o no modo `add` e deixe-o cair depois de cinco eventos, depois execute de novo, do jeito que um
supervisor reinicia um processo que morreu:

```
ana@laptop:~/azure$ python totals.py add 5
seq 0  o-301 c-17   4590  added to the total
seq 1  o-302 c-02  12800  added to the total
seq 2  o-303 c-17    990  added to the total
  checkpoint at seq 2
seq 3  o-303 c-17    990  added to the total
seq 4  o-304 c-05   2350  added to the total
  crash
ana@laptop:~/azure$ python totals.py add
seq 3  o-303 c-17    990  added to the total
seq 4  o-304 c-05   2350  added to the total
seq 5  o-305 c-02   1500  added to the total
  checkpoint at seq 5
seq 6  o-306 c-17   7200  added to the total
totals: c-02 14300  c-05 4700  c-17 14760
```

**A primeira execução tratou os números de sequência 0 a 4 e fez checkpoint no 2.** Ela somou `o-301`,
`o-302` e o primeiro `o-303`, gravou um checkpoint, somou o segundo `o-303` e o `o-304`, e morreu
antes do checkpoint seguinte. **A segunda execução começou depois do número de sequência 2**, a partir
do checkpoint, então os números 3 e 4 foram tratados de novo: a segunda cópia de `o-303`, pela segunda
vez, e o `o-304`, pela segunda vez.

**Compare os totais com os corretos**: 12.780 para `c-17`, 14.300 para `c-02`, 2.350 para `c-05`.
`c-02` está certo, porque nenhum pagamento dele caiu entre o checkpoint e a queda. `c-05` está em
4.700, o dobro, porque o `o-304` foi repetido. `c-17` está em 14.760, 1.980 a mais: o `o-303` foi
contado três vezes, uma pela nova tentativa do produtor e mais uma pela repetição. **Nada imprimiu
erro nenhum**, e os dois enganos são do tipo que sobrevive até alguém conferir os totais contra os
pedidos, se alguém conferir.

## Por que fazer checkpoint mais vezes não resolve

Fazer checkpoint depois de cada evento encolhe a janela e não a fecha: uma queda entre o trabalho e o
checkpoint ainda repete um evento. E não faria nada quanto à duplicata do produtor, que são dois
eventos com dois números de sequência que qualquer leitor trata duas vezes, faça checkpoint como
fizer. **O conserto não está no tempo do leitor; está no que tratar um evento faz com o destino.** A
próxima seção muda isso.
