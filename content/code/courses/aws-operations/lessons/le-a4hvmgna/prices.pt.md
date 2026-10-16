---
title: A lista de preços, lida por um programa
version: 1
---

O moto não conhece preço nenhum. Cada custo que este curso cita vem da **lista de preços que a AWS
publica para qualquer pessoa**, em arquivos JSON em `pricing.us-east-1.amazonaws.com`, sem conta e
sem chave: um arquivo por serviço e região, e uma versão nova toda vez que um preço muda. O programa
abaixo lê o arquivo de São Paulo de um serviço e imprime as linhas dele. **É o único programa que o
curso pede para você guardar**, porque as lições 8 a 25 o usam para pôr um preço ao lado do que
constroem.

Grave-o em `~/aws/price.py`:

```schooling-example
{"language": "python", "file": "price.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"price.py: lines of AWS's public price list for sa-east-1, at pinned versions.\n\n    python3 price.py AWSCodePipeline            every line for one service\n    python3 price.py CodeBuild general1.small   only lines with all those words\n\nEach service's offer is downloaded once into ~/.cache/aws-prices and read\nfrom there. No account and no key: the list is published for anybody.\n\"\"\"\n", "note": "A docstring diz como chamá-lo. O primeiro argumento é o código de um serviço na lista de preços, e as palavras seguintes filtram as linhas."}, {"code": "import json\nimport os\nimport sys\nimport urllib.request\n\n", "note": "Só a biblioteca padrão, então nada novo precisa ser instalado: `urllib` baixa, `json` lê."}, {"code": "BASE = 'https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws'\nCACHE = os.path.expanduser('~/.cache/aws-prices')\nVERSION = {\n    'AWSCodePipeline': '20260911124534',\n    'CodeBuild': '20260911124625',\n    'AmazonECR': '20260911124425',\n    'AmazonCloudWatch': '20261007115540',\n    'AWSXRay': '20260911124622',\n    'awswaf': '20260914163921',\n    'AWSShield': '20260916132208',\n    'AWSSecretsManager': '20260911124610',\n    'AWSSystemsManager': '20261008071021',\n    'awskms': '20260911124601',\n    'AmazonGuardDuty': '20261008231203',\n    'AWSSecurityHub': '20260930174933',\n    'AmazonInspectorV2': '20261015180712',\n    'AWSCloudTrail': '20260911124531',\n    'AWSConfig': '20260911124534',\n    'AmazonS3': '20261015173540',\n    'AmazonDynamoDB': '20260911124422',\n}\n\n\n", "note": "**Cada oferta fica fixada numa versão.** A AWS guarda todas as versões que já publicou, então o mesmo comando imprime os mesmos preços no ano que vem, e a data na primeira linha da saída é a data do preço, não da execução. Uma versão mais nova é uma linha editada aqui."}, {"code": "def offer(code):\n    path = os.path.join(CACHE, f'{code}-{VERSION[code]}.json')\n    if not os.path.exists(path):\n        os.makedirs(CACHE, exist_ok=True)\n        url = f'{BASE}/{code}/{VERSION[code]}/sa-east-1/index.json'\n        urllib.request.urlretrieve(url, path + '.part')\n        os.rename(path + '.part', path)\n    with open(path) as f:\n        return json.load(f)\n\n\n", "note": "Um arquivo por serviço, baixado na primeira vez em que é pedido e lido do cache depois. O nome `.part` garante que um download interrompido nunca pareça terminado."}, {"code": "def lines(doc):\n    for sku, product in doc['products'].items():\n        usage = product['attributes'].get('usagetype', '')\n        for term in doc['terms'].get('OnDemand', {}).get(sku, {}).values():\n            for d in term['priceDimensions'].values():\n                yield usage, float(d['pricePerUnit']['USD']), d['unit'], d['description']\n\n\n", "note": "Um produto é um `usagetype`, o nome que a fatura usa para uma linha, e os termos sob demanda dele têm uma ou mais dimensões de preço: um preço, uma unidade e uma frase que o descreve."}, {"code": "def main():\n    code, words = sys.argv[1], [w.lower() for w in sys.argv[2:]]\n    doc = offer(code)\n    print(f'{code}, sa-east-1, published {doc[\"publicationDate\"][:10]}')\n    for usage, usd, unit, text in sorted(lines(doc)):\n        if all(w in (usage + ' ' + text).lower() for w in words):\n            print(f'  {usage:<36} {usd:>12.6f} USD per {unit:<10} {text}')\n\n\nmain()\n", "note": "Imprime primeiro a data de publicação e depois cada linha cujo tipo de uso ou descrição contém todas as palavras pedidas, em ordem, para duas execuções imprimirem a mesma sequência."}]}
```

Os dois serviços de que esta lição trata custam isto, por linha da fatura:

```
ana@laptop:~/aws$ python3 price.py AWSCodePipeline
AWSCodePipeline, sa-east-1, published 2026-09-11
  Global-actionExecutionMinute             0.000000 USD per minutes    $0.00 for 100 action execution minutes
  Global-activePipeline                    0.000000 USD per pipelines  $0.00 for first active pipeline
  SAE1-actionExecutionMinute               0.002000 USD per minutes    $0.002 per action execution minute
  SAE1-activePipeline                      1.000000 USD per pipelines  $1.00 per additional active pipeline
  SAE1-trialPipeline                       0.000000 USD per pipelines  $0.00 per trial pipeline - no charge for pipelines created within 30 days
ana@laptop:~/aws$ python3 price.py CodeBuild Build-Min:Linux:g1
CodeBuild, sa-east-1, published 2026-09-11
  Global-Build-Min:Linux:g1.small          0.000000 USD per minutes    AWS CodeBuild Free Tier - 100 build minutes on build.general1.small
  SAE1-Build-Min:Linux:g1.2xlarge          0.300000 USD per minutes    AWS CodeBuild - Build minutes on build.general1.2xlarge in South America (Sao Paulo)
  SAE1-Build-Min:Linux:g1.large            0.020000 USD per minutes    AWS CodeBuild - Build minutes on build.general1.large - South America (Sao Paulo)
  SAE1-Build-Min:Linux:g1.medium           0.010000 USD per minutes    AWS CodeBuild - Build minutes on build.general1.medium - South America (Sao Paulo)
  SAE1-Build-Min:Linux:g1.small            0.005000 USD per minutes    AWS CodeBuild - Build minutes on build.general1.small - South America (Sao Paulo)
  SAE1-Build-Min:Linux:g1.xlarge           0.125000 USD per minutes    AWS CodeBuild - Build minutes on build.general1.xlarge in South America (Sao Paulo)
```

Leia uma linha da direita para a esquerda. A frase é da própria AWS. O número é em dólares por
unidade, e a unidade é um minuto de build, um minuto de ação ou uma esteira por mês. A coluna da
esquerda é o **tipo de uso**, o nome que a mesma linha terá numa fatura, e a lição 24 lê faturas por
ele. `SAE1-` é São Paulo; as linhas `Global-` são a franquia gratuita, que vale para a conta inteira.

Então **um build na menor máquina Linux custa meio centavo por minuto**, e uma esteira do tipo mais
novo não custa nada para existir e custa 0,2 centavo por minuto em que uma ação dela roda. Uma esteira
cujo build leva seis minutos e cujo deploy leva quatro, executada vinte vezes por dia útil durante 22
dias, custa 440 execuções × 6 minutos × 0,005 = 13,20 USD em builds, e 440 × 10 minutos × 0,002 =
8,80 USD em minutos de ação, menos os 100 minutos gratuitos de cada. O tipo antigo de esteira cobrava
1 USD por mês, fizesse o que fizesse; essa é a linha `activePipeline`, e por qual delas uma esteira
é cobrada depende do `pipelineType` dela, `V1` ou `V2`.

**Estes são preços de lista, na data da primeira linha de cada bloco.** Desconto, crédito ou imposto
não entram, e a lição 22 é sobre os descontos. Uma versão mais nova de uma oferta é uma `VERSION`
mais nova no programa, e a data que ele imprime muda junto.
