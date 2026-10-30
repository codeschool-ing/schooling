---
title: Um serviço, com preço de quatro jeitos
version: 1
---

**Comparar preços de computação é um cálculo, e o lugar dele é um programa, não uma planilha que
ninguém consegue rodar de novo.** O programa abaixo recebe pela entrada a tabela que o `prices.py`
imprime (lição 1, preços publicados em 30 de outubro de 2026), então nenhum preço nele é digitado à
mão. Ele acrescenta algumas hipóteses sobre o serviço, escritas no topo onde você as vê e muda, e
dá preço a cada perfil da seção anterior de quatro jeitos: em máquinas do Compute Engine, no Cloud
Run com cada um dos seus dois modos de cobrança, e no GKE Autopilot.

Copie com o botão do bloco e salve como `~/gcp/compare.py`, ao lado do `prices.py`. Como sempre, as
notas não são copiadas.

```schooling-example
{"language": "python", "file": "compare.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"One service priced four ways, from the sheet prices.py prints.\n\n    python3 prices.py | python3 compare.py\n    python3 prices.py | python3 compare.py shop=2,2,2,2,2,2,2,10,...\n\nWith no argument it prices the four profiles below. Each argument is a\nprofile of its own instead: a name, then 24 rates in requests per second,\none for each hour of the day from 00:00. Every price is read from the sheet.\n\"\"\"\n", "note": "A docstring diz como rodar o programa: a tabela de preços entra por um pipe, então todo preço abaixo é um que o prices.py imprimiu, não um digitado aqui."}, {"code": "import math\nimport re\nimport sys\n\n", "note": "Três módulos da biblioteca padrão. Como o prices.py, não precisa de nada instalado."}, {"code": "HOURS = 730                # an average month: 8,760 hours over 12\nDAYS = HOURS / 24          # 30.42 days\n\nMS = 100                   # each request runs for 100 ms\nPER_VCPU = 100             # one vCPU serves 100 requests a second\nRUN_VCPU, RUN_GIB = 1, 0.5         # one Cloud Run instance\nPOD_VCPU, POD_GIB = 0.5, 1         # one Autopilot pod\nVM = 'e2-standard-2'               # one Compute Engine machine\nLEAST = 2                  # never fewer than two machines or pods\n\n", "note": "O serviço, em sete números. **São as hipóteses do exemplo, não medições**: uma requisição que roda 100 ms, uma vCPU atendendo 100 requisições por segundo, uma instância do Cloud Run de 1 vCPU e 512 MiB, um pod do Autopilot de meia vCPU e 1 GiB. Troque pelos seus e a comparação muda junto. `LEAST` mantém duas máquinas ou dois pods, para que uma falha nunca derrube o serviço; o Cloud Run não precisa desse piso, porque ele mesmo substitui uma instância."}, {"code": "PROFILES = {\n    'steady': [30] * 24,\n    'office': [0] * 9 + [60] * 9 + [0] * 6,\n    'nightly': [0] * 2 + [14] * 2 + [0] * 20,\n    'busy': [400] * 24,\n    'sparse': [1] * 24,\n}\n\n\n", "note": "Cinco perfis de requisições, cada um uma lista de 24 taxas, uma por hora. `steady` é 30 por segundo o dia todo; `office` é 60 por segundo das 09:00 às 18:00; `nightly` é uma rajada de duas horas a 14 por segundo; `busy` é 400 por segundo; `sparse` é uma requisição por segundo, o dia todo."}, {"code": "def read_sheet(lines):\n    \"\"\"{(block, label): price} out of the sheet's text.\"\"\"\n    sheet, block = {}, None\n    for line in lines:\n        if not line.strip() or line.startswith('    '):\n            continue\n        if not line.startswith(' '):\n            block = line.strip()\n            continue\n        vm = re.match(r'  (\\S+) +(\\d+) vCPU +\\d+ GiB +(\\S+)', line)\n        if vm:\n            sheet[(block, vm.group(1))] = float(vm.group(3))\n            continue\n        label, value = re.match(r'  (.+?) +(\\S+)  \\S', line).groups()\n        sheet[(block, label)] = float(value)\n    return sheet\n\n\n", "note": "Lê o texto da tabela de volta em números. Uma linha sem recuo é o título de um bloco. Uma linha de máquina é lida pelo nome e pelo preço por hora; qualquer outra linha com recuo é um rótulo, um número e uma unidade."}, {"code": "def price(sheet, block, label):\n    for (b, l), p in sheet.items():\n        if b.startswith(block) and l.startswith(label):\n            return p\n    sys.exit(f'not on the sheet: {block} / {label}')\n\n\n", "note": "Acha um preço pelo começo do bloco e do rótulo, e para o programa se ele faltar, para que uma linha renomeada na tabela seja um erro e não um serviço de graça."}, {"code": "def copies(rate, capacity, least=0):\n    return max(least, math.ceil(rate / capacity))\n\n\n", "note": "Quantas cópias uma hora precisa: o suficiente para a taxa dela, e nunca menos que o piso recebido."}, {"code": "def month(profile, s):\n    requests = sum(rate * 3600 for rate in profile) * DAYS\n    machine = price(s, 'Compute Engine', VM)\n    vcpu_s = price(s, 'Cloud Run, request', 'vCPU, while')\n    gib_s = price(s, 'Cloud Run, request', 'memory, while')\n    per_request = price(s, 'Cloud Run, request', 'requests') / 1e6\n    inst_vcpu_s = price(s, 'Cloud Run, instance', 'vCPU')\n    inst_gib_s = price(s, 'Cloud Run, instance', 'memory')\n    pod = POD_VCPU * price(s, 'GKE', 'Autopilot pod vCPU') + POD_GIB * price(s, 'GKE', 'Autopilot pod memory')\n    fee = price(s, 'GKE', 'cluster management fee')\n    run_hour = 3600 * (RUN_VCPU * vcpu_s + RUN_GIB * gib_s)\n    inst_hour = 3600 * (RUN_VCPU * inst_vcpu_s + RUN_GIB * inst_gib_s)\n    vm = request = instance = autopilot = 0.0\n    for rate in profile:\n        vm += copies(rate, 2 * PER_VCPU, LEAST) * machine * DAYS\n        n = copies(rate, RUN_VCPU * PER_VCPU)\n        busy = 1 - math.exp(-rate / max(n, 1) * MS / 1000)\n        request += n * busy * run_hour * DAYS\n        instance += n * inst_hour * DAYS\n        autopilot += (copies(rate, POD_VCPU * PER_VCPU, LEAST) * pod + fee) * DAYS\n    request += requests * per_request\n    return requests, {'Compute Engine': vm, 'Run, request': request,\n                      'Run, instance': instance, 'Autopilot': autopilot}\n\n\n", "note": "O mês, com preço de quatro jeitos, hora a hora. Compute Engine e Autopilot são dimensionados para o tráfego de cada hora e pagam cada cópia que rodam, o Autopilot com a taxa do cluster por cima. O Cloud Run com cobrança por instância paga cada instância que roda. Com cobrança por requisição ele paga só a fração da hora em que há uma requisição em andamento, que para requisições chegando ao acaso é `1 - e^(-taxa × duração)`, e depois a taxa por requisição."}, {"code": "def main():\n    s = read_sheet(sys.stdin)\n    profiles = {} if sys.argv[1:] else dict(PROFILES)\n    for arg in sys.argv[1:]:\n        name, rates = arg.split('=')\n        profiles[name] = [float(r) for r in rates.split(',')]\n        if len(profiles[name]) != 24:\n            sys.exit(f'{name}: a profile is 24 rates, one per hour')\n    print(f'{\"profile\":<9}{\"requests\":>12}' + ''.join(f'{k:>16}' for k in month(PROFILES['busy'], s)[1]))\n    for name, profile in profiles.items():\n        requests, cost = month(profile, s)\n        print(f'{name:<9}{requests / 1e6:>11.2f}M' + ''.join(f'{v:>16.2f}' for v in cost.values()))\n    serving = RUN_VCPU * price(s, 'Cloud Run, request', 'vCPU, while') + RUN_GIB * price(s, 'Cloud Run, request', 'memory, while')\n    living = RUN_VCPU * price(s, 'Cloud Run, instance', 'vCPU') + RUN_GIB * price(s, 'Cloud Run, instance', 'memory')\n    print(f'\\nRequest-based billing is the cheaper of the two while an instance is busy less than'\n          f' {living / serving:.0%} of the time, before the charge per request.')\n    print('Autopilot includes the cluster fee; the free tier credit covers one cluster\\'s fee a month.')\n\n\nif __name__ == '__main__':\n    main()\n", "note": "Imprime uma linha por perfil, depois a fração de ocupação abaixo da qual a cobrança por requisição é o mais barato dos dois modos do Cloud Run, e um lembrete sobre a taxa do GKE."}]}
```

Rode com a tabela entrando pelo pipe:

```
ana@laptop:~/gcp$ python3 prices.py | python3 compare.py
profile      requests  Compute Engine    Run, request   Run, instance       Autopilot
steady         78.84M           97.84           94.59           49.93          112.67
office         59.13M           97.84           48.47           18.72          112.67
nightly         3.07M           97.84            5.39            4.16          112.67
busy         1051.20M           97.84          685.90          199.73          231.69
sparse          2.63M           97.84            7.37           49.93          112.67

Request-based billing is the cheaper of the two while an instance is busy less than 75% of the time, before the charge per request.
Autopilot includes the cluster fee; the free tier credit covers one cluster's fee a month.
```

A coluna de requisições é em milhões por mês, e todo outro número é dólares americanos por mês a
preço de tabela. **As quatro colunas são quatro respostas à mesma pergunta**, e a única coisa que
muda entre as linhas é o perfil.

## Lendo a tabela

**sparse: Cloud Run com cobrança por requisição, com folga.** 7,37 dólares contra 49,93 da mesma
instância cobrada pela vida inteira. Uma requisição por segundo deixa a instância ocupada mais ou
menos um décimo do tempo, e a cobrança por requisição cobra só esse décimo. É o formato para o qual
ela foi feita.

**nightly e office: Cloud Run, em qualquer modo.** Vinte e duas e quinze horas ociosas por dia não
custam nada ao Cloud Run, porque ele escala até zero, enquanto as duas máquinas e os dois pods são
pagos em cada uma delas: 97,84 e 112,67 qualquer que seja o perfil. Dentro das horas de movimento a
instância quase nunca fica vazia, então o modo por instância, com a taxa menor, sai na frente: 4,16
contra 5,39 à noite, 18,72 contra 48,47 no horário comercial.

**steady: Cloud Run, por instância.** Com a instância ocupada 95% do tempo, a cobrança por
requisição paga a taxa mais alta em quase todo segundo e ainda a taxa sobre 78,84 milhões de
requisições: 94,59 contra 49,93.

**busy: Compute Engine.** A 400 por segundo o programa precisa de quatro instâncias do Cloud Run,
oito pods ou duas máquinas `e2-standard-2`, e as máquinas ganham: 97,84 contra 199,73 do Cloud Run
por instância, 231,69 do Autopilot e 685,90 do Cloud Run por requisição, dos quais 420,48 são a
taxa sobre um bilhão de requisições. O mesmo 97,84 aparece em todas as outras linhas também, e essa
é a outra metade da lição: **o menor par de máquinas que vale rodar é maior que um serviço
pequeno**, então o Compute Engine é a opção mais cara até o tráfego crescer até ele.

## O ponto de equilíbrio entre os dois modos do Cloud Run

A linha embaixo da tabela responde à pergunta que se faz sobre o Cloud Run: qual modo de cobrança?
Uma instância de 1 vCPU e 512 MiB custa 0,000019 por segundo durante a vida inteira na cobrança por
instância, e 0,00002525 por segundo enquanto atende na cobrança por requisição. **Abaixo de 75% de
ocupação, a cobrança por requisição é a mais barata das duas antes da taxa por requisição; acima
disso, a por instância é.** A taxa só empurra a linha para baixo. A lição 11 é onde o modo é
escolhido num serviço real, e esta é a aritmética por trás do conselho dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Um gráfico do que uma instância do Cloud Run de 1 vCPU e 512 MiB custa por hora contra quão ocupada ela fica. A cobrança por instância é uma linha reta em 0,0684 dólar por hora qualquer que seja a ocupação. A cobrança por requisição sobe em linha reta de zero, ociosa, até 0,0909 dólar, ocupada o tempo todo. As duas linhas se cruzam em 75% de ocupação; à esquerda a cobrança por requisição é mais barata, à direita a por instância.\"><path d=\"M90 40 L90 290 L650 290\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90 290 L90 295\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"90\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0%</text><path d=\"M228 290 L228 295\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"228\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">25%</text><path d=\"M365 290 L365 295\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"365\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">50%</text><path d=\"M502 290 L502 295\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"502\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">75%</text><path d=\"M640 290 L640 295\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"640\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">100%</text><path d=\"M85 290 L90 290\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"81\" y=\"290\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.00</text><path d=\"M85 170 L90 170\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"81\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.05</text><path d=\"M85 50 L90 50\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"81\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.10</text><text x=\"365\" y=\"330\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">parte da hora com uma requisição dentro</text><text x=\"50\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">dólares por hora</text><path d=\"M90 125.8 L640 125.8\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M90 290.0 L640 71.8\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><circle cx=\"503.9\" cy=\"125.8\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"106\" y=\"116\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">por instância: a hora inteira</text><text x=\"255\" y=\"247\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">por requisição: só enquanto atende</text><text x=\"518\" y=\"156\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">elas se cruzam em 75%</text><text x=\"101\" y=\"56\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">por requisição mais barata</text><text x=\"629\" y=\"56\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">por instância mais barata</text></svg>", "caption": "Uma instância de 1 vCPU e 512 MiB, antes da taxa por requisição. O perfil sparse fica perto de 10%, o steady perto de 95%."}
```

## O que o programa deixa de fora

Quatro coisas, cada uma capaz de mexer num resultado apertado:

- **A porta de entrada.** Compute Engine e Autopilot precisam de um balanceador para dividir as
  requisições entre as cópias, e o preço por hora dele não está na tabela deste curso; o Cloud Run
  tem um embutido.
- **Os níveis gratuitos.** Os primeiros 180.000 vCPU-segundos, 360.000 GiB-segundos e 2 milhões de
  requisições por mês do Cloud Run na cobrança por requisição ficam de fora, e também o crédito do
  GKE, que cobre a taxa de um cluster: o programa avisa isso embaixo da tabela. Para os perfis
  sparse e nightly o nível gratuito levaria a conta do Cloud Run a quase nada.
- **Descontos.** Descontos por compromisso de uso, de até 55% na maioria dos tipos de máquina por
  um ou três anos, e o desconto por uso contínuo que a E2 não recebe. A lição 23 pesa a que um
  compromisso amarra você.
- **A cauda ociosa.** O Cloud Run mantém uma instância aquecida por um tempo depois da última
  requisição, até 15 minutos, e na cobrança por instância essa cauda é cobrada; o programa liga e
  desliga instâncias na virada da hora.

Nenhuma das quatro inverte as linhas busy e sparse. Cada uma pode mexer na linha steady, e é por
isso que o programa é um ponto de partida para os seus números e não um veredito.
