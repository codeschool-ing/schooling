---
title: Um mês de linhas inventadas, na sua própria máquina
version: 1
---

**Não há relatório para ler neste laboratório, então a lição faz um: um arquivo pequeno na forma de
uma exportação CUR 2.0, com cada número inventado e rotulado assim.** Ele substitui os dados, não o
método. As perguntas feitas a ele na próxima seção são as perguntas feitas a um relatório real, no
mesmo SQL, contra colunas com os mesmos nomes. Um mês real só tem milhões de linhas onde este tem 29.

## O arquivo

**Salve isto como `~/aws/make_cur.py`**. Ele grava o `cur.csv`: um mês da loja em três contas,
produção, staging e um sandbox. Ele traz uma instância sob o Compute Savings Plan da lição 14 e as
quatro linhas da fatura de staging da lição 14. Algumas linhas têm tag de time e outras não, e cada
conta tem um crédito e uma linha de imposto.

```schooling-example
{"language": "python", "file": "make_cur.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Writes cur.csv: a SMALL, MADE-UP month in the shape of a Cost and Usage Report.\n\nNothing in it came from a bill. The rates are the price-list rates lessons 1,\n13 and 14 read; the accounts, resources, quantities, credit and tax are invented,\nand allowances such as the free 100 GB a month to the internet are left out.\n\"\"\"\nimport csv\nimport json\n\n", "note": "O que o arquivo é e, antes, o que ele não é: nada nele veio de uma fatura. Só o `csv` e o `json` do próprio Python."}, {"code": "PAYER = '123456789012'\nPROD, STAGING, SANDBOX = '111122223333', '444455556666', '777788889999'\nSP = 'arn:aws:savingsplans::111122223333:savingsplan/sp-0shop1'\nWEB_PROD = {'user_team': 'web', 'user_env': 'prod'}\nDATA_PROD = {'user_team': 'data', 'user_env': 'prod'}\nWEB_STAGING = {'user_team': 'web', 'user_env': 'staging'}\nDATA = {'user_team': 'data'}\n\n", "note": "A pagadora é a conta de gerenciamento do moto, como em toda lição. As três contas-membro usam os ids inventados que a própria documentação da AWS usa em exemplos, então não podem ser confundidas com as de ninguém. Os conjuntos de tags são os da loja, escritos com o prefixo `user_` que um relatório dá às tags que alguém escreveu."}, {"code": "# account, line type, product, usage type, resource, amount, rate, tags\nLINES = [\n    (PROD, 'SavingsPlanCoveredUsage', 'AmazonEC2', 'SAE1-BoxUsage:m7i.large', 'i-0web1', 730, 0.16065, WEB_PROD),\n    (PROD, 'SavingsPlanNegation', 'AmazonEC2', 'SAE1-BoxUsage:m7i.large', 'i-0web1', 730, -0.16065, WEB_PROD),\n    (PROD, 'SavingsPlanRecurringFee', 'ComputeSavingsPlans', 'ComputeSP:1yrNoUpfront', SP, 730, 0.10915, {}),\n    (PROD, 'Usage', 'AmazonEC2', 'SAE1-BoxUsage:m7i.large', 'i-0web2', 730, 0.16065, WEB_PROD),\n    (PROD, 'Usage', 'AmazonEC2', 'SAE1-BoxUsage:m7i.large', 'i-0db1', 730, 0.16065, DATA_PROD),\n    (PROD, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Out-Bytes', 'i-0web1', 400, 0.15, WEB_PROD),\n    (PROD, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Out-Bytes', 'i-0web2', 400, 0.15, WEB_PROD),\n    (PROD, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Regional-Bytes', 'i-0web1', 300, 0.01, WEB_PROD),\n    (PROD, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Out-Bytes', 'i-0db1', 50, 0.15, DATA_PROD),\n    (PROD, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Regional-Bytes', 'i-0web2', 300, 0.01, WEB_PROD),\n    (PROD, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Regional-Bytes', 'i-0db1', 600, 0.01, DATA_PROD),\n    (PROD, 'Usage', 'AmazonVPC', 'SAE1-PublicIPv4:InUseAddress', 'eipalloc-0p1', 730, 0.005, {}),\n    (PROD, 'Usage', 'AmazonVPC', 'SAE1-PublicIPv4:InUseAddress', 'eipalloc-0p2', 730, 0.005, {}),\n    (PROD, 'Usage', 'AWSCostExplorer', 'USE1-APIRequest', '', 120, 0.01, {}),\n    (STAGING, 'Usage', 'AmazonEC2', 'SAE1-BoxUsage:m7i.large', 'i-0stg1', 730, 0.16065, WEB_STAGING),\n    (STAGING, 'Usage', 'AmazonEC2', 'SAE1-NatGateway-Hours', 'nat-0stg1', 730, 0.093, {}),\n    (STAGING, 'Usage', 'AmazonEC2', 'SAE1-NatGateway-Bytes', 'nat-0stg1', 200, 0.093, {}),\n    (STAGING, 'Usage', 'AmazonVPC', 'SAE1-PublicIPv4:IdleAddress', 'eipalloc-0s1', 730, 0.005, {}),\n    (STAGING, 'Usage', 'AmazonVPC', 'SAE1-PublicIPv4:IdleAddress', 'eipalloc-0s2', 730, 0.005, {}),\n    (STAGING, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Regional-Bytes', 'i-0stg1', 1600, 0.01, WEB_STAGING),\n    (SANDBOX, 'Usage', 'AmazonEC2', 'SAE1-BoxUsage:m7i.large', 'i-0sbx1', 200, 0.16065, DATA),\n    (SANDBOX, 'Usage', 'AmazonEC2', 'SAE1-BoxUsage:m7i.large', 'i-0sbx2', 150, 0.16065, {}),\n    (SANDBOX, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Out-Bytes', 'i-0sbx1', 20, 0.15, DATA),\n    (SANDBOX, 'Usage', 'AmazonVPC', 'SAE1-PublicIPv4:InUseAddress', 'eipalloc-0x1', 350, 0.005, {}),\n    (SANDBOX, 'Usage', 'AWSCostExplorer', 'USE1-APIRequest', '', 300, 0.01, {}),\n]\n", "note": "Uma linha por recurso e tipo de uso no mês. As três primeiras são uma instância sob o Compute Savings Plan da lição 14: uso coberto, a negação dele, e a taxa do plano, que não tem tags porque o plano não é de um time. O resto é sob demanda, pelas tarifas da lista de preços das lições 1, 13 e 14, e várias linhas não têm `team` de propósito."}, {"code": "SP_RATE = 0.10915    # the plan's rate for an m7i.large, from lesson 14\nTAX = 0.10           # a made-up rate, not any country's\nCREDIT = {SANDBOX: 20.00}\n\nCOLUMNS = ['bill_payer_account_id', 'line_item_usage_account_id', 'line_item_line_item_type',\n           'line_item_product_code', 'line_item_usage_type', 'line_item_resource_id',\n           'line_item_usage_amount', 'line_item_unblended_cost',\n           'savings_plan_savings_plan_effective_cost', 'resource_tags']\n\n\n", "note": "A tarifa do plano, a alíquota inventada do imposto, um crédito inventado para o sandbox, e as colunas, um punhado das centenas que um relatório real tem, com os nomes reais."}, {"code": "def main():\n    rows, before_tax = [], {}\n    for account, kind, product, usage, resource, amount, rate, tags in LINES:\n        cost = round(amount * rate, 6)\n        effective = round(amount * SP_RATE, 6) if kind == 'SavingsPlanCoveredUsage' else ''\n        rows.append([PAYER, account, kind, product, usage, resource, amount, cost, effective,\n                     json.dumps(tags)])\n        before_tax[account] = before_tax.get(account, 0) + cost\n", "note": "O custo de cada linha é a quantidade vezes a tarifa, e uma linha coberta recebe também o custo efetivo do plano. As tags vão numa coluna só, como JSON, do jeito que um arquivo CUR 2.0 traz `resource_tags` como um mapa."}, {"code": "    for account, amount in CREDIT.items():\n        rows.append([PAYER, account, 'Credit', 'AmazonEC2', '', '', '', -amount, '', '{}'])\n        before_tax[account] -= amount\n    for account, total in before_tax.items():\n        rows.append([PAYER, account, 'Tax', '', '', '', '', round(total * TAX, 6), '', '{}'])\n    with open('cur.csv', 'w', newline='') as f:\n        out = csv.writer(f)\n        out.writerow(COLUMNS)\n        out.writerows(rows)\n    print(f'cur.csv: {len(rows)} lines, {len(before_tax)} accounts, made-up data')\n\n\nmain()\n", "note": "Depois uma linha de crédito e uma linha de imposto por conta, sobre o que a conta gastou depois do crédito, e o arquivo."}]}
```

Rode-o e olhe as primeiras linhas:

```
ana@laptop:~/aws$ python3 make_cur.py
cur.csv: 29 lines, 3 accounts, made-up data
ana@laptop:~/aws$ head -4 cur.csv
bill_payer_account_id,line_item_usage_account_id,line_item_line_item_type,line_item_product_code,line_item_usage_type,line_item_resource_id,line_item_usage_amount,line_item_unblended_cost,savings_plan_savings_plan_effective_cost,resource_tags
123456789012,111122223333,SavingsPlanCoveredUsage,AmazonEC2,SAE1-BoxUsage:m7i.large,i-0web1,730,117.2745,79.6795,"{""user_team"": ""web"", ""user_env"": ""prod""}"
123456789012,111122223333,SavingsPlanNegation,AmazonEC2,SAE1-BoxUsage:m7i.large,i-0web1,730,-117.2745,,"{""user_team"": ""web"", ""user_env"": ""prod""}"
123456789012,111122223333,SavingsPlanRecurringFee,ComputeSavingsPlans,ComputeSP:1yrNoUpfront,arn:aws:savingsplans::111122223333:savingsplan/sp-0shop1,730,79.6795,,{}
```

**Cada célula de `resource_tags` é um pedacinho de JSON**, `{"user_team": "web", "user_env":
"prod"}` ou `{}` para uma linha sem tags. O CSV dobra cada aspa dentro dele, que é como um CSV
escapa uma aspa. Numa exportação real em Parquet o mapa é um tipo de coluna próprio, lido com as
funções de mapa de um motor de consulta. JSON num CSV é o substituto dele neste arquivo.

## Um programa que lhe faz perguntas

O relatório é uma tabela, então a ferramenta para ele é SQL. A biblioteca do Python traz o
**`sqlite3`**, um banco de dados SQL inteiro num módulo, o que basta para 29 linhas e bastaria para
alguns milhões. **Salve isto como `~/aws/ask.py`**:

```schooling-example
{"language": "python", "file": "ask.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Asks cur.csv a question in SQL, with Python's own sqlite3: nothing to install.\n\n    python3 ask.py \"SELECT ... FROM cur ...\"\n    python3 ask.py question.sql\n\"\"\"\nimport csv\nimport sqlite3\nimport sys\n\nNUMBERS = {'line_item_usage_amount', 'line_item_unblended_cost',\n           'savings_plan_savings_plan_effective_cost'}\n\n\n", "note": "Uma pergunta em SQL, na linha de comando ou num arquivo `.sql`, feita ao `cur.csv`. O `sqlite3` é um banco de dados dentro da biblioteca do próprio Python, então não há nada para instalar nem servidor para iniciar."}, {"code": "def load(path):\n    db = sqlite3.connect(':memory:')\n    with open(path, newline='') as f:\n        rows = csv.reader(f)\n        head = next(rows)\n        kinds = ', '.join(f'{c} {\"REAL\" if c in NUMBERS else \"TEXT\"}' for c in head)\n        db.execute(f'CREATE TABLE cur ({kinds})')\n        marks = ', '.join('?' * len(head))\n        for row in rows:\n            db.execute(f'INSERT INTO cur VALUES ({marks})', [v if v != '' else None for v in row])\n    return db\n\n\n", "note": "Lê o CSV para uma tabela chamada `cur` na memória. As três colunas de dinheiro e quantidade são declaradas `REAL` para que o `sum` some números; toda outra coluna é texto. Uma célula vazia vira `NULL`, que é como o SQL diz que um valor não existe."}, {"code": "def show(cursor):\n    names = [d[0] for d in cursor.description]\n    rows = cursor.fetchall()\n    cells = [[f'{v:,.2f}' if isinstance(v, float) else '' if v is None else str(v) for v in r]\n             for r in rows]\n    width = [max(len(x) for x in col) for col in zip(names, *cells)]\n    right = [any(isinstance(r[i], (int, float)) for r in rows) for i in range(len(names))]\n    for line in [names] + cells:\n        print('  '.join(x.rjust(w) if r else x.ljust(w) for x, w, r in zip(line, width, right)).rstrip())\n\n\n", "note": "Imprime a resposta como uma tabela: números com duas casas e à direita, texto à esquerda, e cada coluna tão larga quanto a célula mais larga."}, {"code": "def main():\n    question = sys.argv[1]\n    if question.endswith('.sql'):\n        with open(question) as f:\n            question = f.read()\n    show(load('cur.csv').execute(question))\n\n\nmain()\n", "note": "O argumento é a própria pergunta, ou o nome de um arquivo que a guarda."}]}
```

A primeira pergunta que todo leitor de fatura faz: quanto custou cada conta?

```
ana@laptop:~/aws$ python3 ask.py "SELECT line_item_usage_account_id AS account, sum(line_item_unblended_cost) AS dollars FROM cur GROUP BY account ORDER BY dollars DESC"
account       dollars
111122223333   508.45
444455556666   249.77
777788889999    48.38
ana@laptop:~/aws$ python3 ask.py "SELECT line_item_line_item_type AS type, count(*) AS lines, sum(line_item_unblended_cost) AS dollars FROM cur GROUP BY type ORDER BY dollars DESC"
type                     lines  dollars
Usage                       22   673.59
SavingsPlanCoveredUsage      1   117.27
SavingsPlanRecurringFee      1    79.68
Tax                          3    73.33
Credit                       1   -20.00
SavingsPlanNegation          1  -117.27
```

**Os três totais são a fatura inventada inteira, 806,60 dólares, e somam cada linha como foi
cobrada**: o uso, o imposto, o crédito descontado do sandbox, e as três linhas do Savings Plan. A
segunda consulta diz com quanto cada tipo de linha contribuiu. `SavingsPlanCoveredUsage` e
`SavingsPlanNegation` são 117,27 e menos 117,27, e se anulam, exatamente como na figura da lição 14.
Os 79,68 do próprio plano são uma linha à parte, `SavingsPlanRecurringFee`. Quem somasse só as
linhas do tipo `Usage`, 673,59, teria perdido o plano, o imposto e o crédito, e chamado isso de
fatura.

A `444455556666`, a conta de staging, custou 249,77 com imposto. É a fatura que chegou errada da
lição 14, 227,06, mais o imposto inventado de 10%. O arquivo é como a próxima seção descobre de quem
foi cada parte.
