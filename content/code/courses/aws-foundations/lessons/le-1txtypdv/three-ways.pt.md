---
title: Três jeitos de pagar por uma máquina
version: 1
---

**A mesma hora da mesma máquina tem três preços na AWS, e qual você paga é decidido pelo que você
prometeu, não pela máquina.** Sob demanda (*on demand*) não promete nada e paga a tarifa cheia. Uma
**Reserved Instance** promete pagar por um tipo de instância numa região, toda hora, por um ou três
anos. Um **Savings Plan** promete gastar um número de dólares por hora em computação, toda hora, por
um ou três anos. A imagem comum de uma reserva é uma máquina guardada para você em algum lugar. Ela
é um desconto na fatura: nenhuma máquina é ligada, separada ou nomeada quando você a compra, e uma
instância rodando que combina com ela é simplesmente cobrada a menos.

## O moto tem uma lista de preços, e ela não é a da AWS

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição
comece de uma AWS vazia. A API do EC2 tem uma operação que lista reservas à venda, e o moto a
responde:

```
ana@laptop:~/aws$ aws ec2 describe-reserved-instances-offerings --instance-type m7i.large --query 'ReservedInstancesOfferings[:4].[InstanceType,OfferingType,FixedPrice,UsagePrice]' --output text
t2.micro	No Upfront	0.0	0.05
t2.micro	Partial Upfront	215.0	0.05
t2.micro	All Upfront	203.0	0.0
t2.micro	No Upfront	0.0	0.05
ana@laptop:~/aws$ aws savingsplans describe-savings-plans 2>&1 | grep ERROR
aws: [ERROR]: An error occurred (500) when calling the DescribeSavingsPlans operation (reached max retries: 2): <!doctype html>
```

**A pergunta citou um `m7i.large` e o moto respondeu sobre um `t2.micro`**, com preços adiantados
inventados por ele. O moto guarda algumas ofertas inventadas para que código que compra reservas
tenha algo para comprar, e a API de Savings Plans dele nem existe. Nada na aritmética desta lição
vem do moto. Vem de duas ofertas da lista de preços da AWS, lidas por um programa curto.

## Um programa que lê todo termo de uma instância

O `price.py`, da lição 1, imprime só preços sob demanda. Os preços das reservas ficam na mesma
oferta do EC2 sob um segundo tipo de termo, e as tarifas dos Savings Plans ficam numa oferta própria,
`AWSComputeSavingsPlan`, que a AWS publica ao lado das outras. **Salve isto como `~/aws/terms.py`**:

```schooling-example
{"language": "python", "file": "terms.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Every way to pay for one EC2 instance type, from the AWS public price list.\n\n    python3 terms.py EC2VERSION SPVERSION REGION INSTANCETYPE\n\nEC2VERSION is a version of the AmazonEC2 offer, SPVERSION one of the\nAWSComputeSavingsPlan offer. Linux, shared tenancy, one-year terms. Both files\nare large and are downloaded once into ~/.cache/aws-prices.\n\"\"\"\n", "note": "O que o programa lê e como chamá-lo. Duas ofertas, cada uma numa versão que você nomeia, então o mesmo comando imprime os mesmos preços no ano que vem."}, {"code": "import json\nimport os\nimport resource\nimport sys\nimport urllib.request\n\n", "note": "Só a biblioteca do próprio Python, como no `price.py`. O `resource` está ali para informar quanta memória a execução precisou."}, {"code": "HOST = 'https://pricing.us-east-1.amazonaws.com'\nCACHE = os.path.expanduser('~/.cache/aws-prices')\nHOURS_A_YEAR = 8760\nHOURS_A_MONTH = 730\nORDER = ['No Upfront', 'Partial Upfront', 'All Upfront']\n\n\n", "note": "Onde a lista de preços mora e onde os downloads ficam guardados, o mesmo cache que o `price.py` usa. Um ano de reserva são 8.760 horas, e a AWS fatura um mês como 730 delas, que é 8.760 dividido por doze."}, {"code": "def fetch(code, version, region, url):\n    os.makedirs(CACHE, exist_ok=True)\n    path = os.path.join(CACHE, f'{code}-{version}-{region}.json')\n    if not os.path.exists(path):\n        urllib.request.urlretrieve(url, path + '.part')\n        os.rename(path + '.part', path)\n    with open(path) as f:\n        doc = json.load(f)\n    print(f'{code} {doc[\"version\"]}, published {doc[\"publicationDate\"][:10]}, USD')\n    return doc\n\n\n", "note": "Baixa um arquivo uma vez, para um nome `.part` que só é renomeado quando completo, depois o lê inteiro com `json.load` e imprime a linha que diz qual versão é esta e quando a AWS a publicou."}, {"code": "def ec2(version, region, itype):\n    url = f'{HOST}/offers/v1.0/aws/AmazonEC2/{version}/{region}/index.json'\n    doc = fetch('AmazonEC2', version, region, url)\n    for sku, p in doc['products'].items():\n        a = p['attributes']\n        if (a.get('instanceType') == itype and a.get('operatingSystem') == 'Linux'\n                and a.get('tenancy') == 'Shared' and a.get('preInstalledSw') == 'NA'\n                and a.get('capacitystatus') == 'Used'\n                and a.get('licenseModel') == 'No License required'):\n            break\n    else:\n        sys.exit(f'{itype}: no Linux, shared tenancy product in this offer')\n", "note": "A oferta do EC2 tem um produto para cada combinação de tipo de instância, sistema operacional, licença e tenancy. Os seis testes guardam a máquina Linux simples em hardware compartilhado, cujo SKU é o código de que todo outro preço dela depende."}, {"code": "    for t in doc['terms']['OnDemand'][sku].values():\n        for d in t['priceDimensions'].values():\n            on_demand = float(d['pricePerUnit']['USD'])\n    rows = []\n    for t in doc['terms']['Reserved'][sku].values():\n        ta = t['termAttributes']\n        if ta['LeaseContractLength'] != '1yr':\n            continue\n        upfront = hourly = 0.0\n        for d in t['priceDimensions'].values():\n            if d['unit'] == 'Quantity':\n                upfront = float(d['pricePerUnit']['USD'])\n            else:\n                hourly = float(d['pricePerUnit']['USD'])\n        rows.append((f'reserved, {ta[\"OfferingClass\"]}', ta['PurchaseOption'], upfront, hourly))\n    return sku, a, on_demand, rows\n\n\n", "note": "O SKU tem dois tipos de termo. `OnDemand` é um preço por hora. Cada termo `Reserved` é uma duração, uma classe e uma opção de compra, e até dois preços: uma taxa adiantada, na unidade `Quantity`, e um preço por hora. Só os termos de um ano ficam."}, {"code": "def plans(version, region, sku):\n    url = f'{HOST}/savingsPlan/v1.0/aws/AWSComputeSavingsPlan/{version}/{region}/index.json'\n    doc = fetch('AWSComputeSavingsPlan', version, region, url)\n    kind = {p['sku']: p for p in doc['products']}\n    rows = []\n    for term in doc['terms']['savingsPlan']:\n        a = kind[term['sku']]['attributes']\n        if a['purchaseTerm'] != '1yr':\n            continue\n        for rate in term['rates']:\n            if rate['discountedSku'] == sku:\n                name = 'compute' if a['productFamily'] == 'ComputeSavingsPlans' \\\n                    else f'{a[\"instanceType\"]} family'\n                rows.append((f'savings plan, {name}', a['purchaseOption'],\n                             None, float(rate['discountedRate']['price'])))\n    return rows\n\n\n", "note": "A oferta de Savings Plans é uma lista de planos e, para cada um, a tarifa que ele cobra por cada SKU que cobre. A tarifa desta instância é aquela cujo `discountedSku` é o SKU achado acima, então os dois arquivos se juntam por esse código e por nada mais."}, {"code": "def main():\n    ec2_version, sp_version, region, itype = sys.argv[1:]\n    sku, a, on_demand, rows = ec2(ec2_version, region, itype)\n    rows += plans(sp_version, region, sku)\n    rows.sort(key=lambda r: (r[0], ORDER.index(r[1])))\n    print(f'{itype}, {a[\"vcpu\"]} vCPU, {a[\"memory\"]}, Linux, shared tenancy, {region}')\n    print(f'{\"\":<47}{\"upfront\":>8}{\"hourly\":>9}{\"effective\":>10}{\"a month\":>9}{\"break-even\":>11}')\n    print(f'{\"on demand\":<47}{\"-\":>8}{on_demand:>9.5f}{on_demand:>10.5f}'\n          f'{on_demand * HOURS_A_MONTH:>9.2f}{HOURS_A_MONTH:>9} h')\n    for kind, option, upfront, hourly in rows:\n        if upfront is None:\n            effective, upfront_s, hourly_s = hourly, '-', '-'\n        else:\n            effective = upfront / HOURS_A_YEAR + hourly\n            upfront_s, hourly_s = f'{upfront:,.0f}', f'{hourly:.5f}'\n        hours = effective / on_demand * HOURS_A_MONTH\n        print(f'{kind + \", 1yr, \" + option:<47}{upfront_s:>8}{hourly_s:>9}{effective:>10.5f}'\n              f'{effective * HOURS_A_MONTH:>9.2f}{hours:>9.0f} h')\n", "note": "A tabela. A tarifa efetiva de uma reserva é a taxa adiantada espalhada pelas 8.760 horas do ano, mais o preço por hora. A tarifa de um Savings Plan já é efetiva. Um mês nessa tarifa, e o ponto de equilíbrio: quantas horas por mês a máquina tem de rodar sob demanda antes que pagar o compromisso saia mais barato."}, {"code": "    peak = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss // 1024\n    print(f'peak memory {peak:,} MB')\n\n\nmain()\n", "note": "A última linha, a maior quantidade de memória que a execução ocupou de uma vez, lida do sistema operacional."}]}
```

As versões são a oferta do EC2 que o curso `cloud` fixou, publicada em 25 de setembro de 2026, e a
oferta de Savings Plans que a AWS publicou no mesmo dia. A máquina é um `m7i.large`, dois
processadores e 8 GiB, Linux em hardware compartilhado, em São Paulo:

```
ana@laptop:~/aws$ python3 terms.py 20260925174521 20260925170412 sa-east-1 m7i.large
AmazonEC2 20260925174521, published 2026-09-25, USD
AWSComputeSavingsPlan 20260925170412, published 2026-09-25, USD
m7i.large, 2 vCPU, 8 GiB, Linux, shared tenancy, sa-east-1
                                                upfront   hourly effective  a month break-even
on demand                                             -  0.16065   0.16065   117.27      730 h
reserved, convertible, 1yr, No Upfront                0  0.10915   0.10915    79.68      496 h
reserved, convertible, 1yr, Partial Upfront         455  0.05198   0.10392    75.86      472 h
reserved, convertible, 1yr, All Upfront             892  0.00000   0.10183    74.33      463 h
reserved, standard, 1yr, No Upfront                   0  0.09956   0.09956    72.68      452 h
reserved, standard, 1yr, Partial Upfront            415  0.04741   0.09478    69.19      431 h
reserved, standard, 1yr, All Upfront                814  0.00000   0.09292    67.83      422 h
savings plan, compute, 1yr, No Upfront                -        -   0.10915    79.68      496 h
savings plan, compute, 1yr, Partial Upfront           -        -   0.10395    75.88      472 h
savings plan, compute, 1yr, All Upfront               -        -   0.10187    74.37      463 h
savings plan, m7i family, 1yr, No Upfront             -        -   0.09956    72.68      452 h
savings plan, m7i family, 1yr, Partial Upfront        -        -   0.09482    69.22      431 h
savings plan, m7i family, 1yr, All Upfront            -        -   0.09292    67.83      422 h
peak memory 936 MB
ana@laptop:~/aws$ ls -sh ~/.cache/aws-prices | grep -e AmazonEC2 -e SavingsPlan
230M AWSComputeSavingsPlan-20260925170412-sa-east-1.json
279M AmazonEC2-20260925174521-sa-east-1.json
```

**A primeira execução baixa dois arquivos grandes, e toda execução lê os dois inteiros.** A
listagem os mostra no cache: 279 MB de oferta do EC2, porque ela dá preço a todo tipo de instância
em toda combinação de sistema, licença e tenancy, e 230 MB de tarifas de Savings Plans. Ler um com `json.load` o guarda na memória como um dicionário do Python. O
programa os lê um depois do outro, então o pico que ele informa, 936 MB na execução acima, é o maior dos dois e não
a soma. Um computador com 2 GB de memória livre o roda com folga.

## Lendo a tabela

Todo preço está em dólares, antes de impostos, pelas listas de **25 de setembro de 2026**. As linhas
que importam para uma decisão:

| como é pago | efetivo por hora | um mês de 730 horas | contra sob demanda |
|---|---|---|---|
| sob demanda | 0,16065 | 117,27 | |
| Reserved Instance, padrão, 1 ano, sem adiantamento | 0,09956 | 72,68 | 38% a menos |
| Reserved Instance, padrão, 1 ano, tudo adiantado (814) | 0,09292 | 67,83 | 42% a menos |
| Compute Savings Plan, 1 ano, sem adiantamento | 0,10915 | 79,68 | 32% a menos |
| EC2 Instance Savings Plan, m7i, 1 ano, sem adiantamento | 0,09956 | 72,68 | 38% a menos |

**A tarifa efetiva é o que torna as linhas comparáveis.** Uma reserva com adiantamento parcial
cobra 415 dólares no dia da compra e 0,04741 por hora depois disso; espalhados pelas 8.760 horas do
ano, os 415 são 0,04737 por hora, e os dois juntos dão 0,09478. Pagar mais adiantado baixa um pouco a
tarifa efetiva, aqui de 0,09956 para 0,09292, em troca de dinheiro pago um ano antes e que não volta.

**Dois pares de números são iguais**, e a coincidência é projeto da AWS e não um defeito do
programa. O EC2 Instance Savings Plan da família `m7i` cobra exatamente a tarifa da reserva padrão,
0,09956; o Compute Savings Plan cobra exatamente a da reserva conversível, 0,10915. Um plano tão
estreito quanto uma reserva tem preço de reserva, e um plano tão flexível quanto a reserva mais
flexível tem o preço dela. Em que cada um é flexível é a próxima seção.

Um **mês são 730 horas** em toda linha, um doze avos de 8.760, que é o mês que a própria calculadora
de preços da AWS usa; um mês real de 31 dias são 744 horas rodando, e a fatura conta as horas que
aconteceram. A coluna `a month` é a tarifa efetiva vezes 730. Esses valores mensais supõem que a
máquina roda o mês inteiro. O compromisso é pago rode ela ou não, e é disso que trata a última coluna
do programa.
