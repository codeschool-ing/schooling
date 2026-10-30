---
title: A tabela de preços, inteira
version: 1
---

Nada neste laboratório cobra, então nada nele consegue dizer quanto alguma coisa custa. **Todo
preço deste curso é um número das páginas públicas de preços do Google**, reunido no programa
abaixo, com o dia em que foi lido e a região a que se aplica.

## Por que é um programa e não um download

A AWS publica a lista de preços em arquivos que qualquer um baixa. O Google não, não exatamente.
Ele tem um catálogo legível por máquina, a Cloud Billing Catalog API, mas chamá-la exige uma chave
de API, e uma chave de API exige uma conta. As páginas que qualquer um lê são páginas web que
desenham as tabelas no navegador. Então os números abaixo foram lidos dessas páginas em **30 de
outubro de 2026** e digitados num programa, e cada bloco do programa diz de qual página veio.

São **preços de Iowa**, `us-central1`, porque é a região que toda página mostra até você escolher
outra, e a que um leitor confere sem escolher nada. Os preços mudam de região para região, e São
Paulo, onde o laboratório põe tudo, tem os seus. As lições só comparam preços entre si, todos da
mesma região e do mesmo dia, que é o que uma comparação precisa. Para um orçamento de verdade, abra
a página, escolha a sua região e leia o número de hoje.

## O programa

**Copie com o botão do bloco e salve como `~/gcp/prices.py`.** Qualquer editor serve; no terminal,
`nano prices.py` abre um, o colar do próprio terminal põe o programa lá dentro, e Ctrl+O, Enter e
Ctrl+X salvam e saem. As notas ao lado do código não são copiadas.

```schooling-example
{"language": "python", "file": "prices.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"The price sheet every number in the gcp-compute course comes from.\n\nGoogle publishes its prices as web pages rather than as a file a program can\ndownload without an account. These are the numbers those pages showed on\n30 October 2026: Iowa (us-central1), the region every page shows before you\nchoose one, on demand, in US dollars before tax.\n\n    python3 prices.py                 # the whole sheet\n    python3 prices.py vm disks        # some blocks of it\n    python3 prices.py custom n4 4 10  # a custom machine: series, vCPUs, GiB\n\"\"\"\n", "note": "A docstring diz de onde vieram os números, em que dia e de qual região, e como rodar o programa. Ela viaja com o arquivo, então a tabela carrega a própria procedência."}, {"code": "import sys\n\nMONTH = 730  # hours: the month Google's own monthly figures use\n\n", "note": "Um módulo da biblioteca padrão do Python, e o mês: os valores mensais do Google usam 730 horas, o mês médio de um ano de 365 dias."}, {"code": "# cloud.google.com/products/compute/pricing/general-purpose and /spot-vms/pricing\n# name: (vCPUs, GiB of memory, on demand per hour, Spot per hour or None)\nVM = {\n    'e2-micro':       (2, 1, 0.008376428, None),\n    'e2-small':       (2, 2, 0.016752855, None),\n    'e2-medium':      (2, 4, 0.03350571, None),\n    'e2-standard-2':  (2, 8, 0.06701142, 0.040212),\n    'e2-standard-4':  (4, 16, 0.13402284, None),\n    'e2-highcpu-2':   (2, 2, 0.04947024, None),\n    'e2-highmem-2':   (2, 16, 0.09039966, None),\n    'n4-standard-2':  (2, 8, 0.0907, 0.053652),\n    'n4-standard-4':  (4, 16, 0.1814, None),\n    'n4-highcpu-2':   (2, 4, 0.07654, None),\n    'n4-highmem-2':   (2, 16, 0.11902, None),\n    'n2-standard-2':  (2, 8, 0.097118, 0.058256),\n    'n2d-standard-2': (2, 8, 0.084492, None),\n    'c4-standard-2':  (2, 7, 0.096866, 0.057979),\n    'c4a-standard-2': (2, 8, 0.0898, 0.044388),\n    'g2-standard-4':  (4, 16, 0.706832276, None),\n}\n\n", "note": "Os tipos de máquina que o curso compara, cada um com as vCPUs, a memória, o preço sob demanda por hora e, quando a página de Spot o lista, o preço Spot. A lição 6 é sobre essa última coluna."}, {"code": "# per vCPU-hour and per GiB-hour, the same page's custom tables\nCUSTOM = {\n    'e2': (0.02290217, 0.003069707),\n    'n4': (0.03275, 0.003717),\n    'n2': (0.03319155, 0.00444885),\n}\n\n", "note": "Tipos custom têm preço por vCPU e por GiB, não por nome. Estas três taxas são as que o comando `custom` da lição 1 multiplica."}, {"code": "# cloud.google.com/compute/disks-image-pricing, per GiB-hour unless marked\nDISKS = [\n    ('pd-standard, after the free 30 GiB', 0.000054795),\n    ('pd-balanced', 0.000136986),\n    ('pd-ssd', 0.000232877),\n    ('pd-balanced, regional', 0.000273973),\n    ('hyperdisk-balanced', 0.000109589),\n    ('local SSD', 0.000109589),\n    ('standard snapshot', 0.000068493),\n    ('archive snapshot', 0.000026027),\n    ('custom image', 0.000068493),\n]\n\n", "note": "Discos e imagens, que o Google cobra por GiB por hora. A lição 3 trata dos discos e a lição 2 das imagens; o programa multiplica por 730 para dar o mês."}, {"code": "def shown(value):\n    return f'{value:.10f}'.rstrip('0').rstrip('.')\n\ndef line(label, value, unit):\n    print(f'  {label:<44}{shown(value):>14}  {unit}')\n\ndef head(title):\n    print()\n    print(title)\n\n", "note": "Impressão. `shown` escreve o número sem os zeros à direita, então o preço sai como a página o escreveu."}, {"code": "def vm():\n    head('Compute Engine, on demand')\n    print(f'  {\"\":<28}{\"per hour\":>14}{\"per month\":>12}{\"Spot/hour\":>12}')\n    for name, (cpu, mem, hour, spot) in VM.items():\n        off = f'{spot:>12}' if spot else f'{\"-\":>12}'\n        print(f'  {name:<15}{cpu:>2} vCPU{mem:>4} GiB{shown(hour):>14}{hour * MONTH:>12.2f}{off}')\n\n", "note": "O primeiro bloco: todos os tipos de máquina numa tabela, com o mês calculado ao lado da hora."}, {"code": "def custom(series='n4', cpus='4', gib='10'):\n    cpu_rate, mem_rate = CUSTOM[series]\n    cpus, gib = int(cpus), float(gib)\n    head(f'{series}-custom-{cpus}-{int(gib * 1024)}: {cpus} vCPU and {gib:g} GiB')\n    line(f'{cpus} x {cpu_rate} per vCPU', cpus * cpu_rate, 'per hour')\n    line(f'{gib:g} x {mem_rate} per GiB', gib * mem_rate, 'per hour')\n    total = cpus * cpu_rate + gib * mem_rate\n    line('together', total, 'per hour')\n    line('together, for 730 hours', round(total * MONTH, 2), 'per month')\n\n", "note": "Um tipo custom com preço montado pelas partes. Recebe a série, as vCPUs e a memória em GiB, e soma os dois produtos."}, {"code": "def disks():\n    head('Disks and images, per GiB per month')\n    for name, hour in DISKS:\n        line(name, round(hour * MONTH, 4), 'per GiB-month')\n\n", "note": "Discos e imagens, por GiB por mês."}, {"code": "def serverless():\n    head('Cloud Run, request-based billing (cloud.google.com/run/pricing)')\n    line('vCPU, while a request is being served', 0.000024, 'per vCPU-second')\n    line('memory, while a request is being served', 0.0000025, 'per GiB-second')\n    line('vCPU, an idle minimum instance', 0.0000025, 'per vCPU-second')\n    line('requests', 0.40, 'per million')\n    line('free each month: vCPU', 180000, 'vCPU-seconds')\n    line('free each month: memory', 360000, 'GiB-seconds')\n    line('free each month: requests', 2000000, 'requests')\n    head('Cloud Run, instance-based billing, and jobs')\n    line('vCPU, for the whole life of the instance', 0.000018, 'per vCPU-second')\n    line('memory, for the whole life of the instance', 0.000002, 'per GiB-second')\n    head('GKE (cloud.google.com/kubernetes-engine/pricing)')\n    line('cluster management fee', 0.10, 'per cluster-hour')\n    line('free credit each month, per billing account', 74.40, 'dollars')\n    line('Autopilot pod vCPU', 0.0445, 'per vCPU-hour')\n    line('Autopilot pod memory', 0.0049225, 'per GiB-hour')\n\n", "note": "Os preços de serverless e de contêiner, com as franquias gratuitas do mês: os dois modos de cobrança do Cloud Run para as lições 8 a 11, e a taxa do GKE e as do Autopilot para as lições 13 e 14."}, {"code": "def other():\n    head('Around the compute')\n    line('Artifact Registry, after the free 0.5 GiB', round(0.000136986 * MONTH, 4), 'per GiB-month')\n    line('Cloud Tasks, after the free million', 0.40, 'per million operations')\n    line('Cloud Scheduler, after 3 free jobs', 0.10, 'per job per 31 days')\n    line('App Engine standard F1, after 28 free hours', 0.05, 'per instance-hour')\n    line('App Engine standard B1, after 9 free hours', 0.05, 'per instance-hour')\n    line('App Engine flexible vCPU', 0.0526, 'per vCPU-hour')\n    line('App Engine flexible memory', 0.0071, 'per GiB-hour')\n    line('internet egress to North America, Premium', 0.12, 'per GiB')\n\n", "note": "Tudo em volta da computação que as lições seguintes precificam: Artifact Registry, Cloud Tasks, Cloud Scheduler, App Engine e a saída de dados de que a lição 23 precisa."}, {"code": "BLOCKS = {'vm': vm, 'disks': disks, 'serverless': serverless, 'other': other}\n\ndef main():\n    args = sys.argv[1:]\n    print('Google Cloud public prices, us-central1, USD, 30 October 2026')\n    if args[:1] == ['custom']:\n        custom(*args[1:])\n        return\n    for name in args or list(BLOCKS):\n        BLOCKS[name]()\n\nif __name__ == '__main__':\n    main()\n", "note": "A linha de comando. Sem argumento, todos os blocos; com nomes, esses blocos nessa ordem; com `custom`, um tipo custom."}]}
```

## Rodando

O bloco `vm` é o que esta lição lê:

```
ana@laptop:~/gcp$ python3 prices.py vm
Google Cloud public prices, us-central1, USD, 30 October 2026

Compute Engine, on demand
                                    per hour   per month   Spot/hour
  e2-micro        2 vCPU   1 GiB   0.008376428        6.11           -
  e2-small        2 vCPU   2 GiB   0.016752855       12.23           -
  e2-medium       2 vCPU   4 GiB    0.03350571       24.46           -
  e2-standard-2   2 vCPU   8 GiB    0.06701142       48.92    0.040212
  e2-standard-4   4 vCPU  16 GiB    0.13402284       97.84           -
  e2-highcpu-2    2 vCPU   2 GiB    0.04947024       36.11           -
  e2-highmem-2    2 vCPU  16 GiB    0.09039966       65.99           -
  n4-standard-2   2 vCPU   8 GiB        0.0907       66.21    0.053652
  n4-standard-4   4 vCPU  16 GiB        0.1814      132.42           -
  n4-highcpu-2    2 vCPU   4 GiB       0.07654       55.87           -
  n4-highmem-2    2 vCPU  16 GiB       0.11902       86.88           -
  n2-standard-2   2 vCPU   8 GiB      0.097118       70.90    0.058256
  n2d-standard-2  2 vCPU   8 GiB      0.084492       61.68           -
  c4-standard-2   2 vCPU   7 GiB      0.096866       70.71    0.057979
  c4a-standard-2  2 vCPU   8 GiB        0.0898       65.55    0.044388
  g2-standard-4   4 vCPU  16 GiB   0.706832276      515.99           -
```

O mês é a hora vezes 730, arredondado no centavo, e é o número para guardar de cabeça: **uma
`e2-standard-2` ligada o mês inteiro dá uns 49 dólares**, e a máquina mais barata desta tabela que
traz GPU custa dez vezes isso. A coluna de Spot é o assunto da lição 6; ela só vem preenchida para
os tipos que a página de Spot lista.

Um tipo custom tem o preço montado pelas partes, como a seção 06 explica. O programa recebe a
série, as vCPUs e a memória em GiB:

```
ana@laptop:~/gcp$ python3 prices.py custom n4 4 10
Google Cloud public prices, us-central1, USD, 30 October 2026

n4-custom-4-10240: 4 vCPU and 10 GiB
  4 x 0.03275 per vCPU                                 0.131  per hour
  10 x 0.003717 per GiB                              0.03717  per hour
  together                                           0.16817  per hour
  together, for 730 hours                             122.76  per month
```

A tabela não é uma fatura. Ela não sabe nada dos descontos que a lição 22 pesa, do nível gratuito,
dos impostos do seu país nem do que alguém de fato pagou. É o preço de tabela, que é o número de
onde toda outra conta começa.
