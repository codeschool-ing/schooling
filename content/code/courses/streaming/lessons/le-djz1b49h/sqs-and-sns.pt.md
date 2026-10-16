---
title: SQS e SNS, uma fila e um fan-out que você não mantém
version: 1
---

**O Amazon SQS é uma fila como serviço, e o SNS é um fan-out como serviço.** Não há servidor para
instalar, atualizar ou dimensionar: você cria uma fila com uma chamada de API, e a Amazon cobra por
requisição. O modelo é o do RabbitMQ com outros nomes e uma diferença importante no jeito de pegar
uma mensagem.

**No SQS nada é empurrado para um consumidor, e nada é confirmado.** Um consumidor pede mensagens;
cada uma que ele recebe fica **invisível** para todos os outros durante o *visibility timeout* da
fila; e o consumidor a apaga quando o trabalho termina. Um consumidor que morre, ou demora mais que
o timeout, não a apaga, então a mensagem volta a ficar visível e outro a recebe. O RabbitMQ percebe
um consumidor morto pela conexão fechando; o SQS não tem conexão para observar, então usa um
relógio. É entrega pelo menos uma vez de novo, com um cronômetro em vez de um socket.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"O visibility timeout de uma fila SQS ao longo de seis segundos. Em 0 segundo o worker A recebe o web-0001 e a mensagem fica invisível por 5 segundos. O worker B pede na hora e não recebe nada. O worker A cai e nunca a apaga. Aos 5 segundos a mensagem volta a ficar visível; aos 6 segundos o worker B a recebe, com contagem de recebimentos 2, e a apaga.\" data-fig=\"l15-visibility\"><line x1=\"120\" y1=\"185\" x2=\"696.0\" y2=\"185\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"120\" y1=\"181\" x2=\"120\" y2=\"189\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"120\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"210\" y1=\"181\" x2=\"210\" y2=\"189\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"210\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><line x1=\"300\" y1=\"181\" x2=\"300\" y2=\"189\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"300\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><line x1=\"390\" y1=\"181\" x2=\"390\" y2=\"189\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"390\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><line x1=\"480\" y1=\"181\" x2=\"480\" y2=\"189\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"480\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><line x1=\"570\" y1=\"181\" x2=\"570\" y2=\"189\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"570\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><line x1=\"660\" y1=\"181\" x2=\"660\" y2=\"189\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"660\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">segundos</text><rect x=\"120\" y=\"92\" width=\"450\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"345.0\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">invisível: visibility timeout de 5 s</text><text x=\"576\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">visível de novo</text><text x=\"20\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">worker A</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">worker B</text><circle cx=\"120\" cy=\"55\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"130\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">recebe</text><circle cx=\"255.0\" cy=\"55\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"265.0\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">cai, sem apagar</text><line x1=\"120\" y1=\"55\" x2=\"255.0\" y2=\"55\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><circle cx=\"124.5\" cy=\"150\" r=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></circle><text x=\"130\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pede: 0 mensagens</text><circle cx=\"660\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"650\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">recebe, contagem 2</text><text x=\"650\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">apaga</text></svg>", "caption": "O SQS não tem conexão para observar, então uma mensagem recebida fica escondida por um tempo fixo, e uma que não foi apagada volta quando o tempo acaba.", "same": ["worker A", "worker B"]}
```

## O emulador

Tudo daqui para baixo roda contra o moto, o emulador instalado antes nesta lição, e **não contra a
AWS**. Suba-o no **segundo shell** e deixe-o lá; ele responde na porta 5000:

```
ubuntu@stream:~/work$ moto_server -p 5000
```

O programa fala com ele via `boto3`, exatamente como falaria com a AWS, exceto pelo `endpoint_url`
e pelas credenciais inventadas. Tirar essas duas coisas é tudo o que bastaria para apontá-lo para
uma conta de verdade — e para uma fatura de verdade. Salve-o como `~/work/sqs_demo.py`:

```schooling-example
{
  "language": "python",
  "file": "sqs_demo.py",
  "parts": [
    {
      "code": "\"\"\"sqs_demo.py: SQS and SNS, against the moto emulator on localhost:5000 (not AWS).\n\n    python sqs_demo.py visibility | fifo | fanout\n\"\"\"\nimport json\nimport sys\nimport time\n\nimport boto3\n\nAWS = dict(endpoint_url=\"http://localhost:5000\", region_name=\"us-east-1\",\n           aws_access_key_id=\"testing\", aws_secret_access_key=\"testing\")\nsqs = boto3.client(\"sqs\", **AWS)\nsns = boto3.client(\"sns\", **AWS)",
      "note": "**O endpoint e as chaves falsas são as únicas coisas que fazem disto o moto e não a AWS.** Os dois clientes, SQS e SNS, vão para o mesmo emulador."
    },
    {
      "code": "def receive(url, wait=0):\n    r = sqs.receive_message(QueueUrl=url, MaxNumberOfMessages=10, WaitTimeSeconds=wait,\n                            MessageSystemAttributeNames=[\"ApproximateReceiveCount\"])\n    return r.get(\"Messages\", [])",
      "note": "Recebe até dez mensagens, e pede quantas vezes cada uma foi recebida, que o SQS conta por você."
    },
    {
      "code": "def visibility():\n    url = sqs.create_queue(QueueName=\"labels\",\n                           Attributes={\"VisibilityTimeout\": \"5\"})[\"QueueUrl\"]\n    sqs.send_message(QueueUrl=url, MessageBody=\"web-0001\")\n    m = receive(url)[0]\n    print(f\"worker A got {m['Body']}, and crashes without deleting it\")\n    print(f\"worker B, at once: {len(receive(url))} messages\")\n    time.sleep(6)\n    m = receive(url)[0]\n    count = m[\"Attributes\"][\"ApproximateReceiveCount\"]\n    print(f\"worker B, 6 s later: got {m['Body']}, received {count} times\")\n    sqs.delete_message(QueueUrl=url, ReceiptHandle=m[\"ReceiptHandle\"])\n    print(f\"after delete: {len(receive(url))} messages\")",
      "note": "**O visibility timeout, encenado.** Uma fila cujas mensagens se escondem por 5 segundos; o worker A recebe uma e nunca a apaga; o worker B olha na hora, e depois de 6 segundos."
    },
    {
      "code": "def fifo():\n    url = sqs.create_queue(QueueName=\"stock.fifo\",\n                           Attributes={\"FifoQueue\": \"true\"})[\"QueueUrl\"]\n    for sale, dedup in [(\"rec-1 bk-02 -1\", \"rec-1\"), (\"rec-1 bk-02 -1\", \"rec-1\"),\n                        (\"rec-2 bk-02 -1\", \"rec-2\")]:\n        sqs.send_message(QueueUrl=url, MessageBody=sale, MessageGroupId=\"recife\",\n                         MessageDeduplicationId=dedup)\n        print(f\"sent {sale!r} with deduplication id {dedup}\")\n    got = [m[\"Body\"] for m in receive(url)]\n    print(f\"received {got}\")",
      "note": "**Uma fila FIFO**: o nome dela precisa terminar em `.fifo`. O group id ordena as mensagens, e um id de deduplicação já visto é descartado. A mesma venda é enviada duas vezes, como faria um caixa tentando de novo."
    },
    {
      "code": "def fanout():\n    topic = sns.create_topic(Name=\"sales\")[\"TopicArn\"]\n    urls = {}\n    for name in [\"stock-updates\", \"loyalty-points\"]:\n        urls[name] = sqs.create_queue(QueueName=name)[\"QueueUrl\"]\n        arn = sqs.get_queue_attributes(QueueUrl=urls[name], AttributeNames=[\"QueueArn\"])\n        sns.subscribe(TopicArn=topic, Protocol=\"sqs\", Endpoint=arn[\"Attributes\"][\"QueueArn\"],\n                      Attributes={\"RawMessageDelivery\": \"true\"})\n    sns.publish(TopicArn=topic, Message=json.dumps({\"sale\": \"rec-000001\", \"cents\": 5490}))\n    for name, url in urls.items():\n        print(f\"{name}: {[m['Body'] for m in receive(url)]}\")",
      "note": "**Fan-out do SNS.** Um tópico, duas filas SQS assinando, uma mensagem publicada. A entrega crua passa o corpo como foi publicado, em vez de embrulhado no envelope JSON do próprio SNS."
    },
    {
      "code": "{\"visibility\": visibility, \"fifo\": fifo, \"fanout\": fanout}[sys.argv[1]]()",
      "note": "Roda a parte nomeada na linha de comando."
    }
  ]
}
```

## Visibilidade, e a contagem de recebimentos

```
ubuntu@stream:~/work$ python sqs_demo.py visibility
worker A got web-0001, and crashes without deleting it
worker B, at once: 0 messages
worker B, 6 s later: got web-0001, received 2 times
after delete: 0 messages
```

O worker B não vê nada enquanto a mensagem está escondida, e a recebe quando o timeout passa, com
uma contagem de recebimentos de 2. **O timeout precisa ser maior que o tempo do trabalho.** Se
embalar um pedido leva 40 segundos e o timeout é 30, todo pedido é entregue a um segundo embalador
enquanto o primeiro ainda está nele — duplicatas em toda mensagem, sem queda nenhuma. Uma fila
também pode ganhar uma **redrive policy**, a fila de dead-letter do SQS: depois de um número
definido de recebimentos, a mensagem vai para outra fila em vez de voltar de novo.

## FIFO, e uma janela de deduplicação

Uma fila padrão do SQS não promete nem ordem nem entrega única: uma mensagem pode chegar duas vezes
e fora de ordem, e o consumidor que se vire. Uma **fila FIFO** promete as duas coisas dentro de um
*message group*, com vazão menor. Dois dos três envios abaixo são a mesma venda, como um caixa a
mandaria ao tentar de novo depois de um timeout:

```
ubuntu@stream:~/work$ python sqs_demo.py fifo
sent 'rec-1 bk-02 -1' with deduplication id rec-1
sent 'rec-1 bk-02 -1' with deduplication id rec-1
sent 'rec-2 bk-02 -1' with deduplication id rec-2
received ['rec-1 bk-02 -1', 'rec-2 bk-02 -1']
```

Três enviadas, duas recebidas: o segundo `rec-1` foi descartado porque o id de deduplicação dele já
tinha sido visto. **A AWS guarda esses ids por cinco minutos**, pela documentação dela; uma nova
tentativa que chega depois disso é uma mensagem nova. Isso não foi testado aqui, porque o relógio do
emulador não é o da AWS. É a mesma janela limitada da tabela de deduplicação da lição 8, escolhida
para você.

## SNS: uma mensagem, todo assinante

```
ubuntu@stream:~/work$ python sqs_demo.py fanout
stock-updates: ['{"sale": "rec-000001", "cents": 5490}']
loyalty-points: ['{"sale": "rec-000001", "cents": 5490}']
EXIT 0
```

Uma publicação, uma cópia em cada fila assinante. **SNS mais uma fila por leitor é a grafia da AWS
para a exchange fanout do RabbitMQ**, e tem o mesmo limite: uma fila que assina amanhã não recebe
as vendas de hoje. Quando terminar, pare o moto com Ctrl+C no segundo shell; ele guarda tudo em
memória, então toda fila e todo tópico que ele criou somem com ele.
