---
title: Exportando os custos, e respondendo quem gastou o quê
version: 1
---

**A análise de custos responde as perguntas que alguém pensou em fazer no portal; uma exportação
responde as que ninguém pensou ainda.** É o custo do mês, linha por linha, escrito como arquivos numa
storage account num horário, onde uma planilha, um banco de dados ou um programa pode lê-lo. Uma
equipe financeira que distribui os custos por centros de custo todo mês faz isso a partir da
exportação, não de um gráfico.

## O que é uma exportação

Tudo nesta parte vem da documentação da Microsoft, e **não foi executado**: uma exportação é
configurada no Cost Management contra um escopo de cobrança de verdade e escreve numa storage account
de verdade.

- **O que ela guarda.** Vários conjuntos de dados podem ser exportados. O da distribuição de custos é
  o de detalhes de custo e uso, oferecido como custo real, como custo amortizado, ou no formato
  **FOCUS** que a lição 14 leu, que traz os dois como `BilledCost` e `EffectiveCost` na mesma linha.
- **De onde.** Uma assinatura, um grupo de recursos, um grupo de gerenciamento, ou os escopos de
  cobrança acima deles: as caixas da lição 2 de novo.
- **Com que frequência.** Uma vez; todo dia, com o mês até a data; ou todo mês, com o mês anterior. Uma
  exportação diária **sobrescreve** o arquivo do dia anterior por padrão, então o último arquivo do mês
  é o mês até ali, não mais um dia.
- **Em que forma.** CSV ou Parquet, com compressão opcional, e **particionada**: um mês grande é
  dividido em vários arquivos, o que não dá para desligar. Um programa que lê só o primeiro arquivo lê
  parte do mês.

Um mês de uma loja pequena são algumas centenas de linhas por dia; o de uma empresa são milhões. As
colunas que a lição 14 descreveu são as que distribuem: `x_ResourceGroupName` e `ResourceId` dizem
onde está um custo, e **`Tags` traz as tags do recurso como um objeto JSON**, que é como uma tag chega
à fatura.

## Um mês para praticar, inventado

Não há exportação neste laboratório, então a lição faz uma. **O programa abaixo escreve um mês de
linhas de custo que nunca aconteceu**: seis recursos da loja, um custo por dia para cada um que é um
número redondo escolhido para o exemplo, e a reserva da aritmética da lição 14 comprada no primeiro
dia do mês. Ele usa nove colunas FOCUS das muitas que uma exportação real tem, para que o que vem
depois possa ser lido de olho. Salve-o em `~/azure/tags` como `gen_export.py`:

```python
#!/usr/bin/env python3
"""gen_export.py: write an invented month of cost lines in a few FOCUS columns. Not Azure's data."""
import csv
import json

# group, resource, service, cost per day, the resource's own tags
RESOURCES = [
    ('rg-shop-prod-app', 'vm-shop-web-1', 'Virtual Machines', 3.20, {'cost-centre': 'cc-410'}),
    ('rg-shop-prod-app', 'vm-shop-web-2', 'Virtual Machines', 3.20, {}),
    ('rg-shop-prod-app', 'pip-shop-web', 'Virtual Network', 0.12, {}),
    ('rg-shop-prod-data', 'sql-shop-prod', 'SQL Database', 6.00, {'cost-centre': 'cc-420'}),
    ('rg-shop-prod-data', 'stshopassets', 'Storage', 0.85, {}),
    ('rg-shop-hub', 'vpng-shop-hub', 'VPN Gateway', 4.50, {}),
]
# the tags the shop put on its resource groups; rg-shop-hub has none
GROUPS = {'rg-shop-prod-app': {'cost-centre': 'cc-410'}, 'rg-shop-prod-data': {'cost-centre': 'cc-420'}}
COLUMNS = ['ChargePeriodStart', 'ChargeCategory', 'PricingCategory', 'x_ResourceGroupName',
           'ResourceName', 'ServiceName', 'BilledCost', 'EffectiveCost', 'Tags']

with open('shop-2026-10.csv', 'w', newline='') as f:
    out = csv.writer(f)
    out.writerow(COLUMNS)
    # a one-year reservation for vm-shop-web-1, paid up front on the first of the month
    out.writerow(['2026-10-01', 'Purchase', 'Committed', '', 'shop-web-1y', 'Virtual Machines',
                  '1168.00', '0.00', ''])
    for day in range(1, 32):
        for group, name, service, cost, tags in RESOURCES:
            reserved = name == 'vm-shop-web-1'
            out.writerow([f'2026-10-{day:02d}', 'Usage', 'Committed' if reserved else 'Standard',
                          group, name, service, '0.00' if reserved else f'{cost:.2f}', f'{cost:.2f}',
                          json.dumps(tags) if tags else ''])

with open('groups.json', 'w') as f:
    json.dump(GROUPS, f, indent=2)
print(f'wrote {1 + 31 * len(RESOURCES)} lines to shop-2026-10.csv, and groups.json')
```

`RESOURCES` é a loja, uma linha por recurso: o seu grupo, o seu nome, o seu serviço, o seu custo
inventado por dia, e as suas próprias tags. Dois dos seis estão tagueados, como na maioria dos
ambientes reais, onde os recursos feitos pelo template trazem o esquema e os feitos à mão, ou por um
script mais antigo, não. `GROUPS` é o que a primeira seção desta lição poria nos grupos, escrito em
`groups.json`. A linha da reserva não tem grupo de recursos nem tags: uma compra pertence à conta de
cobrança, não a algo da árvore. Rode-o e olhe as primeiras linhas:

```
ana@laptop:~/azure/tags$ python3 gen_export.py
wrote 187 lines to shop-2026-10.csv, and groups.json
ana@laptop:~/azure/tags$ head -4 shop-2026-10.csv
ChargePeriodStart,ChargeCategory,PricingCategory,x_ResourceGroupName,ResourceName,ServiceName,BilledCost,EffectiveCost,Tags
2026-10-01,Purchase,Committed,,shop-web-1y,Virtual Machines,1168.00,0.00,
2026-10-01,Usage,Committed,rg-shop-prod-app,vm-shop-web-1,Virtual Machines,0.00,3.20,"{""cost-centre"": ""cc-410""}"
2026-10-01,Usage,Standard,rg-shop-prod-app,vm-shop-web-2,Virtual Machines,3.20,3.20,
```

As tags são um objeto JSON dentro de um campo CSV, e é por isso que as aspas dele aparecem dobradas:
é assim que o CSV escreve uma aspa dentro de um valor. Qualquer leitor de CSV desfaz isso.

## Quem gastou o quê

Distribuir um mês é agrupar as linhas por uma tag e somar uma coluna de custo. Salve isto como
`who_spent.py`:

```schooling-example
{"language": "python", "file": "who_spent.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"who_spent.py FILE [--effective] [--inherit GROUPS]: a month's cost by cost centre.\"\"\"\nimport csv\nimport json\nimport sys\nfrom collections import defaultdict\n\nTAG = 'cost-centre'\ncolumn = 'EffectiveCost' if '--effective' in sys.argv else 'BilledCost'\n", "note": "Qual coluna somar é a primeira decisão, e a lição 14 explicou as duas: `BilledCost`, o que foi cobrado no dia, ou `EffectiveCost`, o mesmo amortizado. O programa diz qual usou debaixo do total, para que um número nunca viaje sem a sua definição."}, {"code": "groups = {}\nif '--inherit' in sys.argv:\n    with open(sys.argv[sys.argv.index('--inherit') + 1]) as f:\n        groups = json.load(f)\n", "note": "Com `--inherit`, as tags dos grupos de recursos também são lidas, e emprestadas às linhas cujo recurso não tem a sua: o que a herança de tags do Cost Management faz com os registros de uso, feito aqui à mão."}, {"code": "totals = defaultdict(float)\nwith open(sys.argv[1], newline='') as f:\n    for row in csv.DictReader(f):\n        tags = json.loads(row['Tags'] or '{}')\n        group_tags = groups.get(row['x_ResourceGroupName'], {})\n        owner = tags.get(TAG) or group_tags.get(TAG) or '(untagged)'\n        totals[owner] += float(row[column])\n", "note": "A tag do próprio recurso vence, a do grupo preenche, e uma linha sem nenhuma das duas é contada como **`(untagged)`**, nunca descartada. Um relatório que deixa de fora o que não consegue atribuir soma menos do que a fatura, e ninguém percebe qual parte falta."}, {"code": "for owner, cost in sorted(totals.items(), key=lambda kv: -kv[1]):\n    print(f'{owner:<12}{cost:>10.2f}')\nprint(f'{\"total\":<12}{sum(totals.values()):>10.2f}  ({column})')\n", "note": "Do maior para o menor, e o total por último, que precisa ser igual à fatura seja qual for o agrupamento: distribuir move dinheiro entre linhas e nunca cria nem perde nenhum."}]}
```

Pergunte a ele três vezes: o custo real, o custo amortizado, e o custo amortizado com as tags dos
grupos emprestadas aos recursos:

```
ana@laptop:~/azure/tags$ python3 who_spent.py shop-2026-10.csv
(untagged)     1436.77
cc-420          186.00
cc-410            0.00
total          1622.77  (BilledCost)
ana@laptop:~/azure/tags$ python3 who_spent.py shop-2026-10.csv --effective
(untagged)      268.77
cc-420          186.00
cc-410           99.20
total           553.97  (EffectiveCost)
ana@laptop:~/azure/tags$ python3 who_spent.py shop-2026-10.csv --effective --inherit groups.json
cc-420          212.35
cc-410          202.12
(untagged)      139.50
total           553.97  (EffectiveCost)
```

**A primeira resposta é inútil, e cada número dela está certo.** O custo real põe o ano inteiro da
reserva em outubro, numa linha sem tags, então quase tudo é `(untagged)` e a máquina da equipe de
checkout não custa nada, porque o uso dela foi coberto por uma compra cobrada de ninguém. Essa é a
lição da lição 14, encontrada num relatório.

**A segunda é honesta sobre a reserva e continua quase toda sem tag.** Amortizada, a máquina sob a
reserva leva a sua parte diária, então `cc-410` tem os 99,20 do mês, e o total cai para o consumo real
de outubro. O ano de reserva ainda não usado não é custo de outubro. Mas quatro dos seis recursos não
têm tag, e o dinheiro deles fica em `(untagged)`.

**A terceira é a que uma equipe financeira consegue usar.** Com as tags dos grupos emprestadas aos
recursos que não têm a sua, o servidor web, o endereço IP público e a storage account acham os seus
centros de custo, e `(untagged)` encolhe para um recurso: o VPN gateway, cujo grupo nunca foi
tagueado. **O que sobra sem tag depois da herança é uma lista de grupos que ninguém assume**, e é a
lista mais curta e mais útil que este relatório consegue produzir. O total fica em 553,97 nas duas
respostas amortizadas: distribuir move dinheiro entre linhas, e nunca acrescenta nem perde nenhum.
