---
title: Uma carga de trabalho, com preço de quatro jeitos
version: 1
---

**Comparar preços de computação é um cálculo, e o lugar dele é um programa, e não uma planilha que
ninguém consegue rodar de novo.** O programa abaixo recebe por um pipe a tabela que o `prices.py`
imprime (aula 1, preços como publicados em 16 de outubro de 2026), então nenhum preço nele é
digitado à mão. Ele acrescenta algumas suposições sobre a carga de trabalho, escritas no topo, onde
você pode vê-las e mudá-las, e dá o preço de cada perfil da seção anterior de quatro jeitos: em
instâncias EC2, em tasks de Fargate, no Lambda e no App Runner.

Copie com o botão do bloco e salve como `~/aws/compare.py`, ao lado do `prices.py`. Como sempre, as
notas não são copiadas.

```schooling-example
{"language": "python", "file": "compare.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"One workload priced four ways, from the sheet prices.py prints.\n\n    python3 prices.py | python3 compare.py\n    python3 prices.py | python3 compare.py shop=2,2,2,2,2,2,2,10,...\n\nWith no argument it prices the four profiles below. Each argument is a\nprofile of its own instead: a name, then 24 rates in requests per second,\none for each hour of the day from 00:00. Every price is read from the sheet.\n\"\"\"\n", "note": "A docstring diz como rodar o programa: a tabela de preços entra por um pipe, então todo preço abaixo é um que o prices.py imprimiu, e não um digitado aqui."}, {"code": "import math\nimport re\nimport sys\n\n", "note": "Três módulos da biblioteca padrão. Como o prices.py, ele não precisa de nada instalado."}, {"code": "HOURS = 730                # an average month: 8,760 hours over 12\nDAYS = HOURS / 24          # 30.42 days\n\nMS = 100                   # each request runs for 100 ms\nLAMBDA_GB = 0.5            # in a function of 512 MB\nPER_VCPU = 100             # one vCPU serves 100 requests a second\nTASK_VCPU, TASK_GB = 0.5, 1                 # one container\nINSTANCE, INSTANCE_VCPU = 'c7g.large', 2    # one machine\nLEAST = 2                  # never fewer than two of anything\n\n", "note": "A carga de trabalho, em oito números. **São as suposições do exemplo, não medições**: uma requisição que roda 100 ms numa função de 512 MB, e uma vCPU atendendo 100 requisições por segundo. Troque pelos seus e a comparação muda junto. `LEAST` mantém dois de tudo, para que uma falha nunca tire o serviço do ar."}, {"code": "PROFILES = {\n    'steady': [30] * 24,\n    'office': [0] * 9 + [60] * 9 + [0] * 6,\n    'nightly': [0] * 2 + [14] * 2 + [0] * 20,\n    'busy': [400] * 24,\n}\n\n\n", "note": "Quatro perfis de requisição, cada um uma lista de 24 taxas, uma por hora. `steady` é 30 por segundo o dia todo; `office` é 60 por segundo das 09:00 às 18:00 e nada no resto; `nightly` é uma rajada de duas horas de 14 por segundo; `busy` é 400 por segundo, o dia todo."}, {"code": "def read_sheet(lines):\n    \"\"\"{(block, label): price} out of the sheet's text.\"\"\"\n    sheet, block = {}, None\n    for line in lines:\n        if not line.strip():\n            continue\n        if not line.startswith(' '):\n            block = line.strip()\n            continue\n        label, price, _ = re.match(r'  (.+?) +(\\S+)  (per .+)', line).groups()\n        if price != '-':\n            sheet[(block, label)] = float(price)\n    return sheet\n\n\n", "note": "Lê de volta o texto da tabela como números. Uma linha sem recuo é o título de um bloco; uma linha recuada é um rótulo, um preço e uma unidade. Um preço impresso como traço não foi encontrado, e fica de fora em vez de ser lido como zero."}, {"code": "def price(sheet, block, label):\n    for (b, l), p in sheet.items():\n        if b.startswith(block) and l.startswith(label):\n            return p\n    sys.exit(f'not on the sheet: {block} / {label}')\n\n\n", "note": "Acha um preço pelo começo do bloco e do rótulo, e para o programa se ele faltar, para que uma linha renomeada na tabela seja um erro e não um serviço de graça."}, {"code": "def copies(rate, capacity):\n    return max(LEAST, math.ceil(rate / capacity))\n\n\n", "note": "Quantas cópias uma hora precisa: o suficiente para a taxa dela, e nunca menos que `LEAST`."}, {"code": "def month(profile, s):\n    requests = sum(rate * 3600 for rate in profile) * DAYS\n    machine = price(s, 'EC2', INSTANCE + ' ')\n    task = TASK_VCPU * price(s, 'Fargate', 'vCPU, Arm') + TASK_GB * price(s, 'Fargate', 'memory, Arm')\n    serving = TASK_VCPU * price(s, 'App Runner', 'vCPU') + TASK_GB * price(s, 'App Runner', 'memory')\n    waiting = TASK_GB * price(s, 'App Runner', 'memory')\n    ec2 = fargate = runner = 0.0\n    for rate in profile:\n        ec2 += copies(rate, INSTANCE_VCPU * PER_VCPU) * machine * DAYS\n        fargate += copies(rate, TASK_VCPU * PER_VCPU) * task * DAYS\n        runner += copies(rate, TASK_VCPU * PER_VCPU) * (serving if rate else waiting) * DAYS\n    gb_seconds = requests * MS / 1000 * LAMBDA_GB\n    lam = requests / 1e6 * price(s, 'Lambda', 'requests') + gb_seconds * price(s, 'Lambda', 'duration, Arm')\n    return requests, {'EC2 ' + INSTANCE: ec2, 'Fargate, Arm': fargate,\n                      'Lambda, Arm': lam, 'App Runner*': runner}\n\n\n", "note": "O mês, com preço de quatro jeitos, hora a hora. EC2 e Fargate são dimensionados ao tráfego de cada hora e pagam toda cópia que rodam. O App Runner roda as mesmas cópias, mas uma hora sem requisições paga só memória. O Lambda paga por requisição e por GB-segundo, e nada numa hora em que ninguém o chama."}, {"code": "def main():\n    s = read_sheet(sys.stdin)\n    profiles = {} if sys.argv[1:] else dict(PROFILES)\n    for arg in sys.argv[1:]:\n        name, rates = arg.split('=')\n        profiles[name] = [float(r) for r in rates.split(',')]\n        if len(profiles[name]) != 24:\n            sys.exit(f'{name}: a profile is 24 rates, one per hour')\n    print(f'{\"profile\":<9}{\"requests\":>12}' + ''.join(f'{k:>16}' for k in month(PROFILES['busy'], s)[1]))\n    for name, profile in profiles.items():\n        requests, cost = month(profile, s)\n        print(f'{name:<9}{requests / 1e6:>11.2f}M' + ''.join(f'{v:>16.2f}' for v in cost.values()))\n    floor = LEAST * (TASK_VCPU * price(s, 'Fargate', 'vCPU, Arm') + TASK_GB * price(s, 'Fargate', 'memory, Arm')) * HOURS\n    per_request = price(s, 'Lambda', 'requests') / 1e6 + MS / 1000 * LAMBDA_GB * price(s, 'Lambda', 'duration, Arm')\n    even = floor / per_request\n    print(f'\\nLambda costs what two Fargate tasks cost at {even / 1e6:.2f}M requests a month,'\n          f' {even / (HOURS * 3600):.1f} a second on average.')\n    print('* App Runner is priced in us-east-1: it is not offered in sa-east-1.')\n\n\nif __name__ == '__main__':\n    main()\n", "note": "Imprime uma linha por perfil e depois o ponto de equilíbrio: o volume mensal em que o Lambda custa exatamente o que as duas menores tasks de Fargate custam, como total e como taxa média."}], "output": "profile      requests   EC2 c7g.large    Fargate, Arm     Lambda, Arm     App Runner*\nsteady         78.84M          162.21           49.60           68.33           56.94\noffice         59.13M          162.21           49.60           51.25           27.74\nnightly         3.07M          162.21           49.60            2.66           14.11\nbusy         1051.20M          162.21          198.38          911.04          227.76\n\nLambda costs what two Fargate tasks cost at 57.23M requests a month, 21.8 a second on average.\n* App Runner is priced in us-east-1: it is not offered in sa-east-1.\n"}
```

Rode com a tabela entrando pelo pipe. O arquivo do EC2 faz o `prices.py` levar alguns segundos,
como a aula 1 mediu:

```
ana@laptop:~/aws$ python3 prices.py | python3 compare.py
profile      requests   EC2 c7g.large    Fargate, Arm     Lambda, Arm     App Runner*
steady         78.84M          162.21           49.60           68.33           56.94
office         59.13M          162.21           49.60           51.25           27.74
nightly         3.07M          162.21           49.60            2.66           14.11
busy         1051.20M          162.21          198.38          911.04          227.76

Lambda costs what two Fargate tasks cost at 57.23M requests a month, 21.8 a second on average.
* App Runner is priced in us-east-1: it is not offered in sa-east-1.
```

A coluna de requisições está em milhões por mês, e todos os outros números são dólares americanos
por mês, a preço de lista. **As quatro colunas são quatro respostas à mesma pergunta**, e a única
coisa que muda de uma linha para outra é o perfil.

## Lendo a tabela

O perfil busy é o que reordena tudo, então comece pelos outros três.

**nightly: o Lambda, de longe.** 3,07 milhões de requisições custam 2,66 USD como funções, contra
49,60 das duas menores tasks de Fargate, que o programa nunca deixa cair abaixo de duas. Vinte e
duas horas em silêncio por dia são pagas inteiras por todas as opções, menos o Lambda. O App Runner,
a 14,11, paga a memória durante elas, o que sai mais barato do que pagar uma task inteira.

**office: o App Runner, e depois quase um empate.** Quinze horas ociosas por dia são aquilo para que
o App Runner foi feito: 27,74 USD, só com a memória cobrada à noite. O Lambda (51,25) e o Fargate
(49,60) saem quase empatados, porque 59,13 milhões de requisições por mês ficam perto do ponto de
equilíbrio que a última linha imprime.

**steady: o Fargate.** Sem nenhuma hora ociosa, a vantagem do App Runner some, e ele custa 56,94
contra 49,60 do Fargate. O Lambda, a 68,33, agora paga 78,84 milhões de requisições que duas tasks
pequenas absorvem sem perceber.

**busy: o EC2.** A 400 por segundo o programa precisa de oito tasks, oito instâncias do App Runner
ou duas instâncias `c7g.large` de 2 vCPU cada, e as máquinas ganham: 162,21 USD contra 198,38 do
Fargate, 227,76 do App Runner e 911,04 do Lambda. O mesmo 162,21 aparece em todas as outras linhas
também, e essa é a outra metade da lição: **a menor instância que vale a pena rodar é maior do que
um serviço pequeno**, então o EC2 é a opção mais cara até o tráfego crescer e ocupar a máquina.

## O ponto de equilíbrio

A última linha responde à pergunta que as pessoas de fato fazem: a partir de que volume um contêiner
vence uma função? Cada requisição aqui custa 0,2 USD por milhão mais 0,05 GB-segundo a 0,0000133334,
o que dá 0,8667 USD por milhão de requisições. Duas tasks de Fargate custam 49,60 por mês aconteça o
que acontecer. **Abaixo de 57,23 milhões de requisições por mês, 21,8 por segundo em média, o Lambda
é o mais barato dos dois**; acima disso, as tasks. Esse equilíbrio se move com as suposições: uma
requisição de 200 ms dobra os GB-segundos e o traz para cerca de 32 milhões, e uma função de 256 MB
o empurra para cima. Mude `MS` ou `LAMBDA_GB` e rode de novo, que é a razão de o programa existir.

## O que o programa deixa de fora

Quatro coisas, cada uma capaz de virar um resultado apertado:

- **A porta de entrada.** EC2 e Fargate precisam de um load balancer, cujas tarifas por hora e por
  capacidade não estão na tabela deste curso; a aula 22 de `aws-foundations` dá o preço dele. O
  Lambda pode ser alcançado por uma function URL, que a AWS não cobra à parte, ou por uma HTTP API a
  1,59 USD por milhão (aula 19), o que somaria 125,36 USD ao perfil steady, mais do que a própria
  função. O App Runner inclui a sua.
- **A região.** Os preços do App Runner são de `us-east-1`, porque ele não é oferecido em São Paulo.
  Todo o resto é de `sa-east-1`, e São Paulo está entre as regiões mais caras, então a coluna do App
  Runner sai favorecida.
- **Os descontos.** Savings Plans cobrem EC2, Fargate e Lambda, e Reserved Instances cobrem o EC2.
  As tarifas deles não estão na tabela, e são a aula 14 de `aws-foundations` e a aula 22 de
  `aws-operations` que os pesam. Uma carga constante é exatamente o que eles premiam.
- **A escala como ela se comporta de verdade.** O programa dimensiona cada hora com perfeição. Um
  grupo de auto scaling real reage com minutos de atraso (aula 5), e uma função fria soma o tempo de
  inicialização (aula 17), então contêineres reais rodam um pouco mais de capacidade do que isto, e
  funções reais um pouco mais de duração.

**Nada disso torna os números errados; torna-os um piso.** Uma comparação que sai dentro de 20% para
um lado ou para o outro é um empate, e um empate é decidido pelas duas próximas seções: quanto custa
a mudança e o que a equipe consegue operar.
