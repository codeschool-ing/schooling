---
title: A tabela de preços, inteira
version: 1
---

O moto não cobra, e nada do que ele informa sobre dinheiro é real. **Todo preço deste curso é uma
linha da lista de preços pública da AWS**, lida pelo programa abaixo. A AWS publica a lista como
arquivos JSON que qualquer um pode baixar, sem conta e sem chave, um arquivo por serviço e região, e
guarda toda versão que já publicou. O programa lê uma versão fixa de cada um, então imprime no ano
que vem a mesma tabela que imprime hoje.

**Copie-o com o botão do bloco e salve como `~/aws/prices.py`.** Qualquer editor serve; no terminal,
`nano prices.py` abre um, a colagem do próprio terminal põe o programa lá dentro, e Ctrl+O, Enter e
Ctrl+X salvam e saem. As notas ao lado do código não são copiadas.

```schooling-example
{"language": "python", "file": "prices.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"The price sheet every number in the aws-compute course comes from.\n\nAWS publishes its price list as JSON, with no account and no key. Each service\nis an \"offer\", each offer keeps every version it ever published, and this\nscript reads ONE PINNED VERSION of each, for sa-east-1 (São Paulo). Running it\nnext year prints the same sheet: the prices move, the files do not.\n\n    python3 prices.py              # the whole sheet\n    python3 prices.py containers   # one block of it\n\nThe files go into ~/.cache/aws-prices the first time and are read from there\nafterwards. The EC2 one is about 290 MB.\n\"\"\"\n", "note": "A docstring diz o que o programa lê e como rodá-lo. Ela viaja com o arquivo, então o programa leva o próprio manual."}, {"code": "import json\nimport os\nimport sys\nimport urllib.request\n\n", "note": "Quatro módulos da biblioteca padrão do Python. Não há nada para instalar, e é por isso que a tabela roda onde quer que o Python 3 rode."}, {"code": "BASE = 'https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws'\nCACHE = os.path.expanduser('~/.cache/aws-prices')\nREGION, PREFIX = 'sa-east-1', 'SAE1-'\nVERSION = {\n    'AmazonEC2': '20261015191316',\n    'AmazonEFS': '20260911124425',\n    'AmazonECS': '20260911124425',\n    'AmazonEKS': '20260928194255',\n    'AmazonECR': '20260911124425',\n    'AWSAppRunner': '20260911124525',\n    'AWSLambda': '20261014171944',\n    'AmazonApiGateway': '20261013003044',\n    'AmazonStates': '20260911124511',\n    'AWSQueueService': '20260911124607',\n    'AmazonSNS': '20260915151944',\n    'AWSEvents': '20260924163903',\n}\n\n\n", "note": "Onde a lista fica, onde os downloads são guardados e a única região em que o curso trabalha. `VERSION` fixa uma versão publicada de cada oferta, e é o motivo de a tabela imprimir os mesmos números no ano que vem. As versões são as vigentes em 16 de outubro de 2026."}, {"code": "def offer(code, region=REGION):\n    os.makedirs(CACHE, exist_ok=True)\n    path = os.path.join(CACHE, f'{code}-{VERSION[code]}-{region}.json')\n    if not os.path.exists(path):\n        url = f'{BASE}/{code}/{VERSION[code]}/{region}/index.json'\n        urllib.request.urlretrieve(url, path + '.part')\n        os.rename(path + '.part', path)\n    with open(path) as f:\n        return json.load(f)\n\n\n", "note": "Uma oferta como um dicionário Python. A primeira chamada a baixa para o cache com um nome que leva a versão; toda chamada seguinte lê a cópia. O download vai para um arquivo `.part`, renomeado só quando está completo, então uma conexão cortada nunca deixa um arquivo pela metade que pareça pronto."}, {"code": "def usage(doc, name, prefix=PREFIX):\n    \"\"\"The first-tier on-demand price of one usage type.\"\"\"\n    for sku, p in doc['products'].items():\n        if p['attributes'].get('usagetype') == prefix + name:\n            for term in doc['terms']['OnDemand'].get(sku, {}).values():\n                for d in term['priceDimensions'].values():\n                    if float(d['beginRange']) == 0:\n                        return float(d['pricePerUnit']['USD'])\n    return None\n\n\n", "note": "O preço de um tipo de uso, como um gigabyte guardado por um mês ou um milhão de requisições. Toda oferta dá nome aos preços pelo tipo de uso, e em São Paulo cada um começa com `SAE1-`. Um preço em faixas é lido na primeira faixa, a que uma carga pequena paga."}, {"code": "def row(label, value, unit):\n    shown = '-' if value is None else f'{value:.10f}'.rstrip('0').rstrip('.')\n    print(f'  {label:<40}{shown:>14}  {unit}')\n\n\ndef million(value):\n    return None if value is None else value * 1_000_000\n\n\ndef head(title):\n    print()\n    print(title)\n\n\n", "note": "Impressão. Um preço que ninguém encontrou sai como um traço, nunca como zero, e `million` transforma um preço por requisição no preço por milhão que a AWS informa."}, {"code": "INSTANCES = ['t3.micro', 't3.medium', 't4g.medium', 'm7i.large', 'm7g.large',\n             'c7i.large', 'c7g.large', 'r7i.large', 'r7g.large', 'i4i.large',\n             'm7i.xlarge', 'm7i.2xlarge']\n\n\ndef ec2():\n    doc = offer('AmazonEC2')\n    head('EC2, Linux, on demand')\n    lines = {}\n    for sku, p in doc['products'].items():\n        a = p['attributes']\n        if (a.get('instanceType') in INSTANCES and a.get('operatingSystem') == 'Linux'\n                and a.get('tenancy') == 'Shared' and a.get('preInstalledSw') == 'NA'\n                and a.get('capacitystatus') == 'Used'\n                and a.get('licenseModel') == 'No License required'):\n            for term in doc['terms']['OnDemand'][sku].values():\n                for d in term['priceDimensions'].values():\n                    lines[a['instanceType']] = (a, float(d['pricePerUnit']['USD']))\n    for name in INSTANCES:\n        a, price = lines[name]\n        label = f'{name:<12}{a[\"vcpu\"]:>2} vCPU {a[\"memory\"]:>7}  {a[\"storage\"][:12]}'\n        row(label, price, 'per hour')\n    head('EBS and EFS')\n    row('gp3 volume', usage(doc, 'EBS:VolumeUsage.gp3'), 'per GB-month')\n    row('gp3 IOPS above 3,000', usage(doc, 'EBS:VolumeP-IOPS.gp3'), 'per IOPS-month')\n    # The list prices throughput per GiB/s; AWS quotes it per MiB/s.\n    row('gp3 throughput above 125 MiB/s', usage(doc, 'EBS:VolumeP-Throughput.gp3') / 1024, 'per MiBps-month')\n    row('io2 volume', usage(doc, 'EBS:VolumeUsage.io2'), 'per GB-month')\n    row('st1 volume', usage(doc, 'EBS:VolumeUsage.st1'), 'per GB-month')\n    row('snapshot', usage(doc, 'EBS:SnapshotUsage'), 'per GB-month')\n    row('EFS Standard', usage(offer('AmazonEFS'), 'TimedStorage-ByteHrs'), 'per GB-month')\n    head('Network')\n    row('NAT gateway', usage(doc, 'NatGateway-Hours'), 'per hour')\n    row('NAT gateway, data processed', usage(doc, 'NatGateway-Bytes'), 'per GB')\n\n\n", "note": "Os doze tipos de instância que a lição 1 compara, e o primeiro bloco: os preços por hora deles, os discos da lição 3 e o NAT gateway de que trata a lição 18. Os seis testes de atributo separam a máquina Linux simples das muitas entradas que dividem o nome de um tipo: outros sistemas operacionais, hardware dedicado, software pré-instalado."}, {"code": "def containers():\n    ecs, eks = offer('AmazonECS'), offer('AmazonEKS')\n    head('Fargate')\n    row('vCPU, x86', usage(ecs, 'Fargate-vCPU-Hours:perCPU'), 'per hour')\n    row('memory, x86', usage(ecs, 'Fargate-GB-Hours'), 'per GB-hour')\n    row('vCPU, Arm', usage(ecs, 'Fargate-ARM-vCPU-Hours:perCPU'), 'per hour')\n    row('memory, Arm', usage(ecs, 'Fargate-ARM-GB-Hours'), 'per GB-hour')\n    row('ephemeral storage above 20 GB', usage(ecs, 'Fargate-EphemeralStorage-GB-Hours'), 'per GB-hour')\n    head('EKS and ECR')\n    row('EKS cluster, standard support', usage(eks, 'AmazonEKS-Hours:perCluster'), 'per hour')\n    row('EKS cluster, extended support', usage(eks, 'AmazonEKS-Hours:extendedSupport'), 'per hour')\n    row('ECR storage', usage(offer('AmazonECR'), 'TimedStorage-ByteHrs'), 'per GB-month')\n    # App Runner is not offered in sa-east-1; this line is us-east-1's.\n    run = offer('AWSAppRunner', 'us-east-1')\n    head('App Runner, us-east-1 (not offered in sa-east-1)')\n    row('vCPU, while serving', usage(run, 'AppRunner-vCPU-hours', 'USE1-'), 'per hour')\n    row('memory, provisioned or serving', usage(run, 'AppRunner-GB-hours', 'USE1-'), 'per GB-hour')\n\n\n", "note": "Contêineres: os dois medidores do Fargate para a lição 9, o plano de controle do EKS para a lição 11, o armazenamento do ECR para a lição 10. **O App Runner não é oferecido em São Paulo**, então as duas linhas dele vêm de us-east-1, e o título diz isso."}, {"code": "def lam():\n    fn = offer('AWSLambda')\n    head('Lambda')\n    row('requests', million(usage(fn, 'Request')), 'per million')\n    row('duration, x86', usage(fn, 'Lambda-GB-Second'), 'per GB-second')\n    row('duration, Arm', usage(fn, 'Lambda-GB-Second-ARM'), 'per GB-second')\n    row('provisioned concurrency, x86', usage(fn, 'Lambda-Provisioned-Concurrency'), 'per GB-second')\n    row('duration on provisioned, x86', usage(fn, 'Lambda-Provisioned-GB-Second'), 'per GB-second')\n\n\n", "note": "Lambda: quanto custa uma requisição, quanto custa um gigabyte-segundo de execução em cada processador e os dois medidores de concorrência provisionada que a lição 16 pesa."}, {"code": "def integration():\n    api, sfn = offer('AmazonApiGateway'), offer('AmazonStates')\n    head('API Gateway, first tier')\n    row('REST API', million(usage(api, 'ApiGatewayRequest')), 'per million')\n    row('HTTP API', million(usage(api, 'ApiGatewayHttpRequest')), 'per million')\n    row('WebSocket, messages', million(usage(api, 'ApiGatewayMessage')), 'per million')\n    row('WebSocket, connection time', million(usage(api, 'ApiGatewayMinute')), 'per million minutes')\n    head('Step Functions')\n    row('Standard, state transitions', million(usage(sfn, 'StateTransition')), 'per million')\n    row('Express, requests', million(usage(sfn, 'StepFunctions-Request')), 'per million')\n    row('Express, duration (first tier)', usage(sfn, 'StepFunctions-GB-Second'), 'per GB-second')\n    head('Queues, topics and buses')\n    row('SQS standard', million(usage(offer('AWSQueueService'), 'Requests-Tier1')), 'per million')\n    row('SQS FIFO', million(usage(offer('AWSQueueService'), 'Requests-FIFO-Tier1')), 'per million')\n    sns = offer('AmazonSNS')\n    row('SNS publish, after the first million', million(next(\n        float(d['pricePerUnit']['USD'])\n        for sku, p in sns['products'].items() if p['attributes'].get('usagetype') == PREFIX + 'Requests-Tier1'\n        for t in sns['terms']['OnDemand'][sku].values() for d in t['priceDimensions'].values()\n        if float(d['beginRange']) > 0)), 'per million')\n    row('EventBridge custom event', million(usage(offer('AWSEvents'), 'Event-64K-Chunks')), 'per million')\n\n\n", "note": "Os serviços que ligam os outros, para as lições 19 a 21. O SNS dá o primeiro milhão de publicações de graça, então a linha dele é lida da segunda faixa, e não da primeira."}, {"code": "BLOCKS = {'ec2': ec2, 'containers': containers, 'lambda': lam, 'integration': integration}\n\n\ndef main():\n    wanted = sys.argv[1:] or list(BLOCKS)\n    print(f'AWS public price list, {REGION}, USD, excluding tax')\n    for name in wanted:\n        BLOCKS[name]()\n\n\nif __name__ == '__main__':\n    main()\n", "note": "A linha de comando. Sem argumento, todos os blocos; com nomes, só esses, na ordem dada."}]}
```

## Rodando

```
ana@laptop:~/aws$ python3 prices.py lambda
AWS public price list, sa-east-1, USD, excluding tax

Lambda
  requests                                           0.2  per million
  duration, x86                             0.0000166667  per GB-second
  duration, Arm                             0.0000133334  per GB-second
  provisioned concurrency, x86              0.0000066372  per GB-second
  duration on provisioned, x86              0.0000154867  per GB-second
ana@laptop:~/aws$ ls ~/.cache/aws-prices
AWSLambda-20261014171944-sa-east-1.json
```

A primeira execução baixou o arquivo do Lambda e mais nada, e a listagem o mostra no cache com a
versão no nome. Uma segunda execução do mesmo comando lê a cópia e não precisa de rede.

A tabela inteira é o próximo comando, e é o lento da primeira vez, porque **o arquivo do EC2 tem uns
290 MB**: ele dá preço a todo tipo de instância em toda combinação de sistema operacional, licença e
tenancy, e o programa precisa ler tudo para achar doze linhas.

```
ana@laptop:~/aws$ time python3 prices.py
AWS public price list, sa-east-1, USD, excluding tax

EC2, Linux, on demand
  t3.micro     2 vCPU   1 GiB  EBS only           0.0168  per hour
  t3.medium    2 vCPU   4 GiB  EBS only           0.0672  per hour
  t4g.medium   2 vCPU   4 GiB  EBS only           0.0536  per hour
  m7i.large    2 vCPU   8 GiB  EBS only          0.16065  per hour
  m7g.large    2 vCPU   8 GiB  EBS only           0.1301  per hour
  c7i.large    2 vCPU   4 GiB  EBS only          0.13755  per hour
  c7g.large    2 vCPU   4 GiB  EBS only           0.1111  per hour
  r7i.large    2 vCPU  16 GiB  EBS only          0.21105  per hour
  r7g.large    2 vCPU  16 GiB  EBS only           0.1704  per hour
  i4i.large    2 vCPU  16 GiB  1 x 468 NVMe         0.274  per hour
  m7i.xlarge   4 vCPU  16 GiB  EBS only           0.3213  per hour
  m7i.2xlarge  8 vCPU  32 GiB  EBS only           0.6426  per hour

EBS and EFS
  gp3 volume                                       0.152  per GB-month
  gp3 IOPS above 3,000                            0.0095  per IOPS-month
  gp3 throughput above 125 MiB/s                   0.076  per MiBps-month
  io2 volume                                       0.238  per GB-month
  st1 volume                                       0.086  per GB-month
  snapshot                                         0.068  per GB-month
  EFS Standard                                      0.57  per GB-month

Network
  NAT gateway                                      0.093  per hour
  NAT gateway, data processed                      0.093  per GB

Fargate
  vCPU, x86                                       0.0696  per hour
  memory, x86                                     0.0076  per GB-hour
  vCPU, Arm                                       0.0557  per hour
  memory, Arm                                    0.00612  per GB-hour
  ephemeral storage above 20 GB                 0.000211  per GB-hour

EKS and ECR
  EKS cluster, standard support                      0.1  per hour
  EKS cluster, extended support                      0.5  per hour
  ECR storage                                        0.1  per GB-month

App Runner, us-east-1 (not offered in sa-east-1)
  vCPU, while serving                              0.064  per hour
  memory, provisioned or serving                   0.007  per GB-hour

Lambda
  requests                                           0.2  per million
  duration, x86                             0.0000166667  per GB-second
  duration, Arm                             0.0000133334  per GB-second
  provisioned concurrency, x86              0.0000066372  per GB-second
  duration on provisioned, x86              0.0000154867  per GB-second

API Gateway, first tier
  REST API                                          4.25  per million
  HTTP API                                          1.59  per million
  WebSocket, messages                               1.55  per million
  WebSocket, connection time                       0.388  per million minutes

Step Functions
  Standard, state transitions                       37.5  per million
  Express, requests                                    1  per million
  Express, duration (first tier)              0.00001667  per GB-second

Queues, topics and buses
  SQS standard                                       0.4  per million
  SQS FIFO                                           0.5  per million
  SNS publish, after the first million               0.5  per million
  EventBridge custom event                             1  per million

real	0m8.847s
user	0m2.159s
sys	0m4.524s
```

Na máquina em que estas lições foram gravadas, a primeira execução inteira levou 9 segundos, quase
tudo download; numa conexão mais lenta leva minutos. **O download acontece uma vez e a leitura
acontece toda vez**, então um bloco que precisa do arquivo do EC2 custa alguns segundos a cada
execução, enquanto os outros respondem na hora:

```
ana@laptop:~/aws$ du -sh ~/.cache/aws-prices
282M	/home/ana/.cache/aws-prices
ana@laptop:~/aws$ time python3 prices.py ec2 > /dev/null

real	0m4.035s
user	0m1.740s
sys	0m2.283s
```

**O cache ocupa uns 280 MB de disco**, e o Python segura o arquivo do EC2 na memória enquanto lê,
então dê à tabela uma máquina com pelo menos 2 GB livres. Se um download for cortado no meio, a
execução para com um `ContentTooShortError`, deixa para trás só um arquivo `.part`, e a próxima
execução começa esse arquivo de novo do início.

Todo número da tabela está em dólares americanos, antes de impostos, para São Paulo, sob demanda,
como publicado em 16 de outubro de 2026. Não é uma fatura: não diz nada sobre descontos, o free tier
ou o que alguém de fato pagou, e a lição 23 é onde isso entra na conta.
