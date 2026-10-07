---
title: A tabela de preços, inteira
version: 1
---

O programa que imprime todo preço deste curso está abaixo, inteiro. **Copie-o com o botão do bloco e
salve como `~/cloud/prices.py`.** Qualquer editor serve; no terminal, `nano prices.py` abre um, o
colar do próprio terminal põe o programa dentro, e Ctrl+O, Enter e Ctrl+X salvam e saem. As notas ao
lado do código não são copiadas.

```schooling-example
{"language": "python", "file": "prices.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"The price sheet every number in the cloud course comes from.\n\nAWS publishes its whole price list as JSON, with no account and no key:\nhttps://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json names one\n\"offer\" per service, and each offer keeps every version it ever published. This\nscript reads ONE PINNED VERSION of each offer, for two regions, and prints the\nprices the course quotes. Pinned, so that running it next year prints the same\nsheet: the prices move, the files they were read from do not.\n\n    python3 prices.py            # the whole sheet\n    python3 prices.py lambda     # one block of it\n\nNothing here needs credentials, and nothing here is a bill. It is a reading of a\npublished list, taken on the date in each offer's `publicationDate`, and the\ncourse says so wherever it quotes a line. The EC2 files are large (about 290 MB\nfor sa-east-1 and 480 MB for us-east-1), so they are downloaded once into\n~/.cache/cloud-prices and read from there afterwards.\n\nStandard library only: urllib and json.\n\"\"\"\n", "note": "A docstring diz o que o programa lê e como rodá-lo. É o manual do próprio programa, então ele viaja junto com o arquivo."}, {"code": "import json\nimport os\nimport sys\nimport urllib.request\n\n", "note": "Quatro módulos da biblioteca padrão do Python: nada para instalar, e é por isso que a tabela roda em qualquer máquina com Python 3."}, {"code": "BASE = 'https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws'\nCACHE = os.path.expanduser('~/.cache/cloud-prices')\nREGIONS = ['sa-east-1', 'us-east-1']\n# How each region spells a usage type. us-east-1 is the oldest region and most of\n# its usage types carry no prefix at all; a few newer services give it one.\nPREFIX = {'sa-east-1': ['SAE1-'], 'us-east-1': ['', 'USE1-']}\nVERSION = {\n    'AmazonEC2': '20260925174521',\n    'AWSLambda': '20260919002359',\n    'AmazonS3': '20260926015512',\n    'AWSDataTransfer': '20260916132208',\n    'AmazonEFS': '20260911124425',\n    'AmazonVPC': '20260917190528',\n}\n\n\n", "note": "Onde a lista fica, onde os downloads são guardados, e as duas regiões que a tabela compara. `VERSION` fixa uma versão publicada de cada oferta, e é o motivo de a tabela imprimir os mesmos números no ano que vem."}, {"code": "def offer(code, region):\n    os.makedirs(CACHE, exist_ok=True)\n    path = os.path.join(CACHE, f'{code}-{VERSION[code]}-{region}.json')\n    if not os.path.exists(path):\n        url = f'{BASE}/{code}/{VERSION[code]}/{region}/index.json'\n        urllib.request.urlretrieve(url, path + '.part')\n        os.rename(path + '.part', path)\n    with open(path) as f:\n        return json.load(f)\n\n\n", "note": "Uma oferta de uma região, como um dicionário do Python. A primeira chamada baixa o arquivo para o cache, com um nome que carrega a versão; toda chamada depois lê a cópia. O download vai para um arquivo `.part` que só é renomeado quando está completo, então uma conexão que cai nunca deixa um arquivo pela metade que parece pronto."}, {"code": "def dims(doc, sku, term='OnDemand'):\n    for t in doc['terms'].get(term, {}).get(sku, {}).values():\n        for d in t['priceDimensions'].values():\n            yield t.get('termAttributes', {}), d\n\n\n", "note": "Todo preço de uma oferta é uma dimensão de preço dentro de um termo, e um termo pertence a um SKU, o código de um produto. Isto percorre os termos de um SKU e devolve cada dimensão com os atributos do próprio termo."}, {"code": "def by_usage(doc, region, usage, first=True):\n    \"\"\"The price of a usage type, in its first tier unless first is False.\"\"\"\n    want = {prefix + usage for prefix in PREFIX[region]}\n    found = []\n    for sku, p in doc['products'].items():\n        if p['attributes'].get('usagetype') in want:\n            for _, d in dims(doc, sku):\n                found.append((float(d['beginRange']), float(d['pricePerUnit']['USD'])))\n    if not found:\n        return None\n    found.sort()\n    return found[0][1] if first else found\n\n\n", "note": "O preço de um tipo de uso, como um gigabyte armazenado. O prefixo da região é acrescentado aqui, porque cada região escreve os seus tipos de uso de um jeito. Um preço com faixas volta como a primeira faixa, ou como a lista inteira de faixas quando `first` é falso."}, {"code": "def instance(doc, name, reserved=False):\n    for sku, p in doc['products'].items():\n        a = p['attributes']\n        if (a.get('instanceType') == name and a.get('operatingSystem') == 'Linux'\n                and a.get('tenancy') == 'Shared' and a.get('preInstalledSw') == 'NA'\n                and a.get('capacitystatus') == 'Used'\n                and a.get('licenseModel') == 'No License required'):\n            if not reserved:\n                for _, d in dims(doc, sku):\n                    return a, float(d['pricePerUnit']['USD'])\n            for ta, d in dims(doc, sku, 'Reserved'):\n                if (ta.get('LeaseContractLength') == '1yr' and ta.get('PurchaseOption') == 'No Upfront'\n                        and ta.get('OfferingClass') == 'standard'):\n                    return a, float(d['pricePerUnit']['USD'])\n    return None, None\n\n\n", "note": "O preço por hora de um tipo de instância, sob demanda ou reservado por um ano. Os seis testes de atributo separam a máquina Linux comum dos muitos SKUs que dividem o nome do tipo: outros sistemas operacionais, hardware dedicado, software pré-instalado."}, {"code": "def row(label, values, fmt='{:.4f}'):\n    cells = ''.join(f'{(fmt.format(v) if v is not None else \"-\"):>13}' for v in values)\n    print(f'  {label:<34}{cells}')\n\n\ndef head(title):\n    print()\n    print(title)\n\n\n", "note": "A impressão. `row` alinha um rótulo e um valor por região; um preço que falta sai como um traço, nunca como zero."}, {"code": "INSTANCES = ['t3.micro', 't4g.small', 't3.medium', 'm7i.large', 'm7g.large', 'c7i.large', 'm7i.xlarge']\n\n\ndef ec2():\n    docs = {r: offer('AmazonEC2', r) for r in REGIONS}\n    head('EC2, Linux, on demand, USD per hour')\n    for name in INSTANCES:\n        a, _ = instance(docs[REGIONS[0]], name)\n        label = f'{name:<11}{a[\"vcpu\"]:>2} vCPU {a[\"memory\"]:>7}'\n        row(label, [instance(docs[r], name)[1] for r in REGIONS], '{:.5f}')\n    head('EC2, Linux, 1-year reserved, no upfront, USD per hour')\n    for name in INSTANCES:\n        row(name, [instance(docs[r], name, reserved=True)[1] for r in REGIONS], '{:.5f}')\n    head('EBS, USD per GB-month')\n    for usage, label in [('EBS:VolumeUsage.gp3', 'gp3 SSD volume'),\n                         ('EBS:VolumeUsage.st1', 'st1 HDD volume'),\n                         ('EBS:SnapshotUsage', 'snapshot')]:\n        row(label, [by_usage(docs[r], r, usage) for r in REGIONS])\n    head('Networking, USD')\n    for usage, label in [('NatGateway-Hours', 'NAT gateway, per hour'),\n                         ('NatGateway-Bytes', 'NAT gateway, per GB processed'),\n                         ('LoadBalancerUsage', 'load balancer (ALB), per hour')]:\n        row(label, [by_usage(docs[r], r, usage) for r in REGIONS])\n    vpc = {r: offer('AmazonVPC', r) for r in REGIONS}\n    row('public IPv4 address, per hour',\n        [by_usage(vpc[r], r, 'PublicIPv4:InUseAddress') for r in REGIONS])\n\n\n", "note": "Os sete tipos de instância que as aulas citam, e o primeiro bloco da tabela: os preços deles, os preços reservados, os discos e as cobranças de rede que ficam na oferta do EC2. É este o bloco que precisa dos dois arquivos grandes."}, {"code": "def storage():\n    s3 = {r: offer('AmazonS3', r) for r in REGIONS}\n    head('S3, USD per GB-month (first tier)')\n    for usage, label in [('TimedStorage-ByteHrs', 'Standard'),\n                         ('TimedStorage-SIA-ByteHrs', 'Standard-Infrequent Access'),\n                         ('TimedStorage-GIR-ByteHrs', 'Glacier Instant Retrieval'),\n                         ('TimedStorage-GlacierByteHrs', 'Glacier Flexible Retrieval')]:\n        row(label, [by_usage(s3[r], r, usage) for r in REGIONS], '{:.5f}')\n    head('S3 requests, USD per 1,000')\n    for usage, label in [('Requests-Tier1', 'PUT, COPY, POST, LIST'),\n                         ('Requests-Tier2', 'GET and the rest')]:\n        row(label, [by_usage(s3[r], r, usage) * 1000 for r in REGIONS], '{:.5f}')\n    efs = {r: offer('AmazonEFS', r) for r in REGIONS}\n    head('EFS, USD per GB-month')\n    row('Standard', [by_usage(efs[r], r, 'TimedStorage-ByteHrs') for r in REGIONS])\n\n\n", "note": "Armazenamento: as classes do S3 e os seus pedidos, depois o EFS. Na lista, o preço de pedido é por pedido, e sai impresso por mil, que é como ele costuma ser citado."}, {"code": "def transfer():\n    dt = {r: offer('AWSDataTransfer', r) for r in REGIONS}\n    head('Data transfer, USD per GB')\n    # Egress is priced in tiers of monthly volume, and the tiers are the point:\n    # the first 10 TB of a month cost more per GB than the next 40.\n    tiers = {r: by_usage(dt[r], r, 'DataTransfer-Out-Bytes', first=False) for r in REGIONS}\n    names = ['first 10 TB', 'next 40 TB', 'next 100 TB', 'over 150 TB']\n    for i, name in enumerate(names):\n        row(f'out to the internet, {name}', [tiers[r][i][1] for r in REGIONS])\n    row('between zones, each direction',\n        [by_usage(dt[r], r, 'DataTransfer-Regional-Bytes') for r in REGIONS])\n    row('to the other region',\n        [by_usage(dt['sa-east-1'], 'sa-east-1', 'USE1-AWS-Out-Bytes'),\n         by_usage(dt['us-east-1'], 'us-east-1', 'USE1-SAE1-AWS-Out-Bytes')])\n    row('in from the internet',\n        [by_usage(dt[r], r, 'DataTransfer-In-Bytes') for r in REGIONS])\n\n\n", "note": "Transferência de dados. A saída tem quatro faixas de volume mensal, e a tabela imprime as quatro, porque as faixas são o assunto da aula 2."}, {"code": "def lam():\n    fn = {r: offer('AWSLambda', r) for r in REGIONS}\n    head('Lambda, USD')\n    row('per 1 million requests',\n        [by_usage(fn[r], r, 'Request') * 1_000_000 for r in REGIONS], '{:.2f}')\n    row('per GB-second, x86',\n        [by_usage(fn[r], r, 'Lambda-GB-Second') for r in REGIONS], '{:.10f}')\n    row('per GB-second, Arm',\n        [by_usage(fn[r], r, 'Lambda-GB-Second-ARM') for r in REGIONS], '{:.10f}')\n    # The free allowance is in the list too, as a price of zero up to a limit.\n    free = {r: offer('AWSLambda', r) for r in REGIONS}\n    for usage, label in [('Request', 'free tier, requests'),\n                         ('Lambda-GB-Second', 'free tier, GB-seconds')]:\n        limits = []\n        for r in REGIONS:\n            limit = None\n            for sku, p in free[r]['products'].items():\n                if p['attributes'].get('usagetype') == 'Global-' + usage:\n                    for _, d in dims(free[r], sku):\n                        limit = float(d['endRange'])\n            limits.append(limit)\n        row(label, limits, '{:,.0f}')\n\n\n", "note": "Os dois preços do Lambda e a sua cota gratuita. A cota está na lista como um preço zero até um limite, e o limite é o número impresso."}, {"code": "BLOCKS = {'ec2': ec2, 'storage': storage, 'transfer': transfer, 'lambda': lam}\n\n\ndef main():\n    wanted = sys.argv[1:] or list(BLOCKS)\n    print('AWS public price list, USD, excluding tax')\n    for code, version in VERSION.items():\n        print(f'  offer {code:<16} version {version}')\n    print(f'  {\"\":<34}' + ''.join(f'{r:>13}' for r in REGIONS))\n    for name in wanted:\n        BLOCKS[name]()\n\n\nif __name__ == '__main__':\n    main()\n", "note": "A linha de comando. Sem argumento, todos os blocos; com nomes, só esses, na ordem dada. O cabeçalho com as versões sai sempre, então toda citação carrega as versões de onde veio."}]}
```

Ele não precisa de nada além de Python e rede, e de nenhuma conta: todo arquivo que ele lê é público.
Rode-o primeiro para um bloco só, o pequeno:

```
ana@laptop:~/cloud$ python3 prices.py lambda | tail -6
Lambda, USD
  per 1 million requests                     0.20         0.20
  per GB-second, x86                 0.0000166667 0.0000166667
  per GB-second, Arm                 0.0000133334 0.0000133334
  free tier, requests                   1,000,000    1,000,000
  free tier, GB-seconds                   400,000      400,000
ana@laptop:~/cloud$ ls ~/.cache/cloud-prices
AWSLambda-20260919002359-sa-east-1.json
AWSLambda-20260919002359-us-east-1.json
```

**A primeira execução levou alguns segundos porque baixou dois arquivos**, um por região, e a
listagem os mostra no cache, com a versão no nome. Rode o mesmo comando de novo e ele os lê de lá,
sem rede nenhuma.

## O bloco do EC2 é o pesado

`storage`, `transfer` e `lambda` juntos leem uns 5 MB de lista de preços. **`ec2` lê dois arquivos,
de 292 MB e de 482 MB**, porque a oferta do EC2 dá preço a todo tipo de máquina em toda combinação de
sistema operacional, licença e locação, e o programa precisa ler o arquivo inteiro para achar as sete
linhas que quer. O primeiro `python3 prices.py ec2`, ou um `python3 prices.py` sem argumento, baixa
os dois:

```
ana@laptop:~/cloud$ time python3 prices.py ec2 | head -12
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

EC2, Linux, on demand, USD per hour
  t3.micro    2 vCPU   1 GiB              0.01680      0.01040
  t4g.small   2 vCPU   2 GiB              0.02680      0.01680

real	0m37.845s
user	0m9.000s
sys	0m13.981s
ana@laptop:~/cloud$ du -sh ~/.cache/cloud-prices
740M	/home/ana/.cache/cloud-prices
ana@laptop:~/cloud$ time python3 prices.py ec2 > /dev/null

real	0m14.957s
user	0m7.084s
sys	0m7.663s
```

A primeira execução levou 38 segundos, a maior parte no download; a segunda, com os dois arquivos já
no cache, levou 15, todos lendo os arquivos. **O download acontece uma vez. A leitura acontece toda
vez**, então o `prices.py ec2` de uma aula leva um quarto de minuto, enquanto os outros blocos
respondem na hora, e nenhum deles precisa de rede de novo.

Essa execução também precisou de 2,2 GB de memória no pico, porque o Python guarda o arquivo maior na
memória como um dicionário só enquanto procura nele. **Dê à tabela uma máquina com 4 GB de memória e
1 GB de disco livre para o cache.** Com menos memória, a seção sobre falhas diz o que acontece e o que
fazer.
