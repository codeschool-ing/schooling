---
title: Uma carga, com preço de cinco jeitos
version: 1
---

**Uma comparação de preços de computação é uma conta, e o lugar dela é num programa, não numa
planilha que ninguém consegue refazer.** Esta tem dois arquivos. O `rates.json` guarda todas as
tarifas que a conta usa, e nada mais; o `compare.py` guarda as suposições sobre a carga, escritas
no topo onde dá para ver e mudar, e dá preço a cada perfil da seção anterior de cinco jeitos: em
duas máquinas virtuais, no Container Apps, num plano do App Service, no Functions num plano Flex
Consumption e no AKS.

**As tarifas do arquivo são ilustrativas, não os preços do Azure.** Este curso não cita nenhum preço
da tabela do Azure, pelo motivo que a lição 1 deu. Cada tarifa abaixo é um número redondo escolhido
para deixar a conta legível. A primeira chave do arquivo diz isso, e a última linha que o
programa imprime também. Três números nele não são ilustrativos: as cotas gratuitas mensais do
Container Apps, que a página de cobrança da Microsoft informa. O fim desta seção mostra como pôr as
tarifas reais, e até você pôr, leia a tabela pelo formato e nunca pelos totais.

Copie o arquivo com o botão do bloco e salve como `~/azure/rates.json`. As notas não são copiadas.

```schooling-example
{"language": "json", "file": "rates.json", "parts": [{"code": "{\n  \"_\": \"ILLUSTRATIVE RATES, NOT AZURE'S PRICES: round numbers in USD. The three Container Apps free grants are Microsoft's documented ones. Replace every rate with the real one for your region before deciding anything.\",\n", "note": "**A primeira chave diz o que o arquivo é**, para o aviso viajar junto com os números: cada tarifa abaixo é um número redondo escolhido para a conta, não um preço que o Azure cobra. JSON não tem comentários, então o aviso é um valor; o `compare.py` nunca o lê."}, {"code": "  \"vm_hour\": 0.10,\n", "note": "Um `Standard_D2s_v5` por uma hora, a tarifa ilustrativa que a lição 1 usou para o tamanho que a CLI escolhe por padrão."}, {"code": "  \"ca_vcpu_second\": 0.00002,\n  \"ca_gib_second\": 0.000002,\n  \"ca_idle_vcpu_second\": 0.000002,\n  \"ca_idle_gib_second\": 0.000002,\n  \"ca_million_requests\": 0.40,\n  \"ca_free_vcpu_seconds\": 180000,\n  \"ca_free_gib_seconds\": 360000,\n  \"ca_free_requests\": 2000000,\n", "note": "Container Apps no perfil Consumption: um vCPU-segundo e um GiB-segundo na tarifa ativa, os mesmos dois na tarifa ociosa reduzida, e um preço por milhão de requisições. **As três últimas linhas não são ilustrativas**: são as cotas gratuitas mensais por assinatura que a página de cobrança da Microsoft informa, lida em 30 de outubro de 2026."}, {"code": "  \"plan_instance_hour\": 0.15,\n", "note": "Uma instância de um plano do App Service `P1v3` por uma hora, o tamanho que a lição 18 dá à loja."}, {"code": "  \"flex_gb_second\": 0.000026,\n  \"flex_million_executions\": 0.40,\n  \"flex_free_gb_seconds\": 0,\n  \"flex_free_executions\": 0,\n  \"flex_always_ready_month\": 150.00,\n", "note": "Functions no Flex Consumption, como a lição 16 calculou: o GB-segundo e o milhão de execuções do exemplo resolvido da própria Microsoft, as cotas gratuitas em zero porque o tamanho delas só está na página de preços, e 150 USD por mês para uma instância always ready."}, {"code": "  \"node_hour\": 0.20,\n  \"control_plane_hour\": 0.10\n}\n", "note": "AKS: um nó de 4 vCPUs por uma hora, o dobro da máquina de dois vCPUs lá de cima, e a hora de um plano de controle no tier Standard. No tier Free essa segunda linha seria 0."}]}
```

Depois o programa, salvo ao lado como `~/azure/compare.py`:

```schooling-example
{"language": "python", "file": "compare.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"One workload priced five ways, from the rates in rates.json.\n\n    python3 compare.py\n    python3 compare.py shop=2,2,2,2,2,2,2,10,...\n\nWith no argument it prices the five profiles below. Each argument is a\nprofile of its own instead: a name, then 24 rates in requests per second,\none for each hour of the day from 00:00. Every price comes from rates.json.\n\"\"\"\nimport json\nimport math\nimport sys\n\n", "note": "A docstring diz como rodar. Três módulos da biblioteca padrão, então nada precisa ser instalado, e **nenhum preço está escrito no programa**: todos são lidos do `rates.json`."}, {"code": "HOURS = 730                # an average month: 8,760 hours over 12\nDAYS = HOURS / 24          # 30.42 days\nPER_VCPU = 100             # one vCPU serves 100 requests a second\nLEAST = 2                  # never fewer than two of anything\n\n", "note": "O mês, e duas suposições sobre a carga. **Um vCPU atendendo 100 requisições da loja por segundo é o palpite do exemplo, não uma medição**; meça a sua e troque. `LEAST` mantém dois de tudo, para que uma falha nunca tire o serviço do ar."}, {"code": "VM_VCPU = 2                # Standard_D2s_v5, lesson 1\nCA_VCPU, CA_GIB = 0.5, 1   # one Container Apps replica, lesson 8\nCA_MIN = 2                 # replicas kept when nobody calls\nPLAN_VCPU = 2              # one P1v3 instance of an App Service plan\nFLEX_GB = 2                # a 2,048 MB Flex Consumption instance\nBILLED_S = 1.0             # each request billed as the 1,000 ms minimum\nALWAYS_READY = 0           # Flex instances kept ready: none\nNODE_VCPU, NODES = 4, 3    # AKS: three nodes of 4 vCPUs at least\n\n", "note": "As cinco maneiras, cada uma no formato que uma lição anterior deu a ela. Uma réplica de meio núcleo aguenta 50 requisições por segundo, que é o `concurrentRequests` da regra da lição 8. Uma requisição no Flex é cobrada como um segundo de uma instância de 2 GB, a leitura da lição 16. Três nós de 4 vCPUs são o que a lição 11 recomenda para um pool de sistema."}, {"code": "PROFILES = {\n    'steady': [30] * 24,\n    'office': [0] * 9 + [60] * 9 + [0] * 6,\n    'nightly': [0] * 2 + [14] * 2 + [0] * 20,\n    'webhook': [0.05] * 24,\n    'busy': [400] * 24,\n}\n\n\n", "note": "Os cinco perfis da seção anterior, cada um uma lista de 24 taxas, uma por hora a partir da meia-noite."}, {"code": "def copies(rate, vcpus, least=LEAST):\n    return max(least, math.ceil(rate / (vcpus * PER_VCPU)))\n\n\n", "note": "Quantas máquinas, instâncias, réplicas ou nós uma hora precisa: o bastante para a sua taxa, e nunca menos que o piso."}, {"code": "def month(profile, r):\n    requests = sum(rate * 3600 for rate in profile) * DAYS\n    vm = plan = aks = active = idle = 0.0\n    for rate in profile:\n        vm += copies(rate, VM_VCPU) * r['vm_hour'] * DAYS\n        plan += copies(rate, PLAN_VCPU) * r['plan_instance_hour'] * DAYS\n        aks += (copies(rate, NODE_VCPU, NODES) * r['node_hour'] + r['control_plane_hour']) * DAYS\n        replica_s = copies(rate, CA_VCPU, CA_MIN) * 3600 * DAYS\n        if rate:\n            active += replica_s\n        else:\n            idle += replica_s\n", "note": "Hora a hora. Máquinas virtuais, instâncias do plano e nós são pagos por toda hora em que existem, chegue o que chegar. O Container Apps conta réplica-segundos, e **uma hora sem nenhuma requisição é contada como ociosa**; uma hora com qualquer requisição é contada como ativa."}, {"code": "    ca = (max(active * CA_VCPU - r['ca_free_vcpu_seconds'], 0) * r['ca_vcpu_second']\n          + max(active * CA_GIB - r['ca_free_gib_seconds'], 0) * r['ca_gib_second']\n          + idle * (CA_VCPU * r['ca_idle_vcpu_second'] + CA_GIB * r['ca_idle_gib_second'])\n          + max(requests - r['ca_free_requests'], 0) / 1e6 * r['ca_million_requests'])\n", "note": "A conta do Container Apps: vCPU-segundos e GiB-segundos ativos menos as cotas gratuitas, segundos ociosos nas tarifas ociosas, e as requisições além dos dois primeiros milhões. A página de cobrança não diz se as cotas saem dos segundos ativos ou dos ociosos; o programa as tira dos ativos, e essa suposição é dele."}, {"code": "    gb_s = requests * BILLED_S * FLEX_GB\n    if ALWAYS_READY:\n        flex = (ALWAYS_READY * r['flex_always_ready_month'] + gb_s * r['flex_gb_second']\n                + requests / 1e6 * r['flex_million_executions'])\n    else:\n        flex = (max(gb_s - r['flex_free_gb_seconds'], 0) * r['flex_gb_second']\n                + max(requests - r['flex_free_executions'], 0) / 1e6 * r['flex_million_executions'])\n    return requests, {'two VMs': vm, 'Container Apps': ca, 'App Service': plan,\n                      'Functions Flex': flex, 'AKS': aks}\n\n\n", "note": "O Flex Consumption paga por requisição e nada por uma hora em que ninguém chama. Com instâncias always ready configuradas, ele soma a linha de base delas e **perde as cotas gratuitas**, porque a tabela de cobrança da Microsoft diz que a cobrança always ready não tem nenhuma."}, {"code": "def main():\n    with open('rates.json') as f:\n        r = json.load(f)\n    profiles = {} if sys.argv[1:] else dict(PROFILES)\n    for arg in sys.argv[1:]:\n        name, rates = arg.split('=')\n        profiles[name] = [float(x) for x in rates.split(',')]\n        if len(profiles[name]) != 24:\n            sys.exit(f'{name}: a profile is 24 rates, one per hour')\n    columns = month(PROFILES['busy'], r)[1]\n    print(f'{\"profile\":<9}{\"requests\":>10}' + ''.join(f'{k:>15}' for k in columns))\n    for name, profile in profiles.items():\n        requests, cost = month(profile, r)\n        print(f'{name:<9}{requests / 1e6:>9.2f}M' + ''.join(f'{v:>15.2f}' for v in cost.values()))\n", "note": "Lê as tarifas, pega os perfis da linha de comando se houver algum, e imprime uma linha por perfil: as requisições do mês em milhões, depois as cinco contas."}, {"code": "    floor = LEAST * r['vm_hour'] * HOURS\n    per_request = BILLED_S * FLEX_GB * r['flex_gb_second'] + r['flex_million_executions'] / 1e6\n    grants = (r['flex_free_gb_seconds'] * r['flex_gb_second']\n              + r['flex_free_executions'] / 1e6 * r['flex_million_executions'])\n    even = (floor + grants) / per_request\n    print(f'\\nFunctions costs what two VMs cost at {even / 1e6:.2f}M requests a month,'\n          f' {even / (HOURS * 3600):.2f} a second on average.')\n    print(\"USD a month, at the rates in rates.json: illustrative, not Azure's prices.\")\n\n\nif __name__ == '__main__':\n    main()\n", "note": "O ponto de equilíbrio: o volume mensal em que o Flex custa exatamente o que as duas máquinas virtuais custam, como total e como taxa média. Uma cota gratuita o empurra para cima pelas requisições que ela paga. A última linha repete o aviso, para que uma tabela copiada para qualquer lugar o leve junto."}]}
```

Rode a partir de `~/azure`, onde ele encontra o `rates.json`:

```
ana@laptop:~/azure$ python3 compare.py
profile    requests        two VMs Container Apps    App Service Functions Flex            AKS
steady       78.84M         146.00          89.49         219.00        4131.22         511.00
office       59.13M         146.00          52.04         219.00        3098.41         511.00
nightly       3.07M         146.00          15.82         219.00         160.66         511.00
webhook       0.13M         146.00          58.75         219.00           6.89         511.00
busy       1051.20M         146.00         667.65         219.00       55082.88         511.00

Functions costs what two VMs cost at 2.79M requests a month, 1.06 a second on average.
USD a month, at the rates in rates.json: illustrative, not Azure's prices.
```

A coluna de requisições está em milhões por mês, e todo outro número é em dólares americanos por mês
nas tarifas do arquivo. **As cinco colunas são cinco respostas à mesma pergunta**, e a única coisa
que muda entre as linhas é o perfil.

## Lendo a tabela

Três colunas não se mexem. Duas máquinas virtuais custam 146,00 em todas as linhas, o plano do App
Service 219,00, o AKS 511,00: cada uma é um número fixo de máquinas pago por hora, e nenhum destes
perfis passa do piso de duas, ou de três nós. **Uma coluna fixa é a mesma conta para 0,13 milhão de
requisições e para 1.051 milhões**, o que é uma pechincha na linha busy e um desperdício no
webhook. As outras duas colunas se mexem em toda linha.

**steady, office e nightly: Container Apps.** 89,49, 52,04 e 15,82 USD. Duas réplicas de meio núcleo
carregam os 30 por segundo do steady e os 60 do office, e as cotas gratuitas da assinatura pagam os
primeiros 180.000 vCPU-segundos e 360.000 GiB-segundos. Nas linhas office e nightly as horas em
silêncio são cobradas na tarifa ociosa, um quarto da ativa neste arquivo, e é por isso que o serviço
nightly custa menos que o preço de uma máquina virtual.

**webhook: Functions, de longe.** 0,13 milhão de requisições custam 6,89 USD no Flex, contra 58,75
no Container Apps. O webhook nunca tem uma hora ociosa, então as duas réplicas são cobradas como
ativas o mês todo; uma função é cobrada por 131.400 segundos de execução e nada pelo resto.

**busy: as máquinas virtuais.** A 400 por segundo as duas máquinas `D2s_v5` ficam exatamente
cheias, e continuam custando 146,00. O Container Apps custa 667,65: oito réplicas rodam o dia todo,
e 1.049,20 milhões de requisições além dos dois milhões grátis custam 419,68 sozinhas.

**E o Functions perde em todas as linhas menos uma**: por dez vezes na linha nightly e por mais de
quarenta nas outras. É a suposição da loja encontrando o medidor do Flex: uma requisição é cobrada
como um segundo de uma instância de 2 GB, o mínimo documentado, e um app Python aceita uma requisição
por instância de cada vez. 78,84 milhões de requisições por mês são 157,68 milhões de GB-segundos. A
coluna é um teto, e a próxima subseção diz o que a move.

O AKS custa mais que o Container Apps em todas as linhas menos a busy, e seria errado ler isso como
um veredito sobre o AKS. Três nós de 4 vCPUs são o pool de sistema que a lição 11 recomenda, e o
tier Standard é o que a lição 11 dá à produção. Eles são dimensionados para os pods de sistema do
próprio cluster e para muitos serviços, e uma API pequena usa um canto deles. O próximo serviço que
a loja acrescentar não custa nada a mais no AKS até os nós encherem, e uma linha nova em toda outra
coluna.

## Quanto vale o zero

O programa mantém duas réplicas mesmo quando ninguém chama. O arquivo da lição 8 deixava a loja ir a
zero, e uma linha do `compare.py` diz qual dos dois vale:

```
ana@laptop:~/azure$ sed 's/^CA_MIN = 2 /CA_MIN = 0 /' compare.py > zero.py
ana@laptop:~/azure$ python3 zero.py
profile    requests        two VMs Container Apps    App Service Functions Flex            AKS
steady       78.84M         146.00          57.95         219.00        4131.22         511.00
office       59.13M         146.00          42.18         219.00        3098.41         511.00
nightly       3.07M         146.00           0.43         219.00         160.66         511.00
webhook       0.13M         146.00          27.22         219.00           6.89         511.00
busy       1051.20M         146.00         667.65         219.00       55082.88         511.00

Functions costs what two VMs cost at 2.79M requests a month, 1.06 a second on average.
USD a month, at the rates in rates.json: illustrative, not Azure's prices.
```

O serviço nightly cai de 15,82 para 0,43 USD: as duas horas movimentadas rodam numa réplica dentro
das cotas gratuitas, os 0,43 que sobram são as requisições além de dois milhões, e as 22 horas em
silêncio não custam nada. A ferramenta office cai de 52,04 para 42,18, com as quinze horas em
silêncio agora de graça. É para isso que o zero serve. **Outras duas linhas caíram por outro
motivo**: sem piso, o serviço steady roda numa réplica só, e 89,49 viram 57,95 porque não há uma
segunda cópia, não porque algo ficou ocioso. Isso é disponibilidade vendida, e entra na decisão como
tal. O webhook cai à metade pelo mesmo motivo e nunca chega a zero, porque as chamadas chegam a cada
vinte segundos. O cool-down que a lição 8 leu na documentação espera 300 segundos antes de a última
réplica sair. Uma chamada a cada vinte segundos mantém, então, uma réplica de pé para sempre, e o
Flex ainda custa um quarto dela.

O preço do zero é pago pela primeira requisição depois dele: uma partida a frio enquanto uma réplica
é provisionada (lição 8), ou enquanto o host e o worker de uma função sobem (lição 16).

## O ponto de equilíbrio

A penúltima linha responde à pergunta que as pessoas de fato fazem: abaixo de que volume uma função
sai mais barata que manter máquinas? Aqui uma requisição custa um segundo de 2 GB a 0,000026 USD, o
que dá 0,000052, mais 0,40 por milhão de execuções, 0,0000524 ao todo. Duas máquinas virtuais custam
146,00 por mês aconteça o que acontecer. **Abaixo de 2,79 milhões de requisições por mês, 1,06 por
segundo em média, o Functions é o mais barato dos dois**; acima disso, as máquinas são. O ponto de
equilíbrio se move com cada suposição do arquivo. Uma instância de 512 MB cobra um quarto dos
GB-segundos e o empurra para quase quatro vezes mais. Uma cota gratuita o empurra para cima pelas
requisições que ela paga. E uma concorrência HTTP maior muda a própria contagem, porque o Flex cobra a
memória de uma instância enquanto ela executa, não por requisição: a lição 16 seguiu o exemplo da
Microsoft de dez requisições em andamento custando uma instância em vez de dez. Mude o `FLEX_GB` ou
as cotas, rode de novo e veja; é para isso que o programa existe.

## Pondo as tarifas reais

**O `rates.json` é o único arquivo a mudar**, e o programa não precisa de edição quando você muda. As
duas tarifas de máquina vêm da Retail Prices API da lição 1, que não pede conta. Este pedido
pergunta pelo tamanho de quatro vCPUs da coluna do AKS em São Paulo; troque o nome por
`Standard_D2s_v5` para o outro. Ele não foi executado neste curso:

```sh
curl -s "https://prices.azure.com/api/retail/prices?\$filter=armRegionName%20eq%20'brazilsouth'%20and%20armSkuName%20eq%20'Standard_D4s_v5'" | jq '.Items[] | {productName, meterName, retailPrice, unitOfMeasure}'
```

Pegue o item Linux pago por uso, cuja unidade é uma hora. Os medidores por segundo do Container Apps
e do Functions, a instância de plano do App Service e o tier do AKS não têm um tamanho de máquina
virtual para filtrar; leia-os na página de preços de cada serviço para `brazilsouth`, ou na
calculadora de preços, e escreva-os no arquivo nas unidades que ele já usa. Depois rode o
`compare.py` de novo. Até lá, a tabela acima é uma lição sobre formatos.

## O que o programa deixa de fora

Quatro coisas, cada uma capaz de mexer num resultado apertado:

- **A porta de entrada.** Duas máquinas virtuais precisam de um balanceador ou de um Application
  Gateway na frente, que a lição 22 de `azure-foundations` precifica; o AKS precisa de um ingress ou
  de um gateway, que é o assunto da lição 14. O Container Apps, o App Service e o Functions já vêm
  com o seu.
- **Descontos.** A resposta da API para um tamanho de máquina lista reservas ao lado do pago por uso,
  e é uma carga estável que elas recompensam; o Spot, lição 5, desconta trabalho que pode ser
  interrompido. Nenhum deles está no arquivo.
- **A escala como ela se comporta de verdade.** O programa dimensiona cada hora com perfeição. Um
  scale set reage minutos atrasado (lição 4), o Container Apps espera 300 segundos antes de remover
  réplicas (lição 8), e uma função fria soma a partida à conta. Frotas reais rodam um pouco mais que
  isto.
- **As cotas são por assinatura.** Os segundos e as requisições grátis do Container Apps são
  divididos por todos os apps da assinatura, então o segundo app que a loja publicar já os encontra
  gastos.

**Nada disso torna os números errados; torna-os aproximados.** Uma comparação que dá 20% para
qualquer lado é empate, e um empate é decidido pelas próximas duas seções: o que a mudança custa, e
o que a equipe consegue operar.
