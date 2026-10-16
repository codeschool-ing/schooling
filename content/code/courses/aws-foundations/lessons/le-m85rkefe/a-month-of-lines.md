---
title: A month of made-up lines, on your own machine
version: 1
---

**There is no report to read in this lab, so the lesson makes one: a small file in the shape of a
CUR 2.0 export, with every number in it invented and labelled so.** It is a substitute for the
data, not for the method. The questions asked of it in the next section are the questions asked of
a real report, in the same SQL, against columns with the same names; a real month simply has
millions of rows where this one has 29.

## The file

**Save this as `~/aws/make_cur.py`**. It writes `cur.csv`: one month of the shop across three
accounts, production, staging and a sandbox, with one instance under lesson 14's Compute Savings
Plan, the four lines of lesson 14's staging bill, some lines tagged with a team and some not, a
credit and a tax line per account.

```schooling-example
{"language": "python", "file": "make_cur.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Writes cur.csv: a SMALL, MADE-UP month in the shape of a Cost and Usage Report.\n\nNothing in it came from a bill. The rates are the price-list rates lessons 1,\n13 and 14 read; the accounts, resources, quantities, credit and tax are invented,\nand allowances such as the free 100 GB a month to the internet are left out.\n\"\"\"\nimport csv\nimport json\n\n", "note": "What the file is and, first, what it is not: nothing in it came from a bill. Only Python's own `csv` and `json`."}, {"code": "PAYER = '123456789012'\nPROD, STAGING, SANDBOX = '111122223333', '444455556666', '777788889999'\nSP = 'arn:aws:savingsplans::111122223333:savingsplan/sp-0shop1'\nWEB_PROD = {'user_team': 'web', 'user_env': 'prod'}\nDATA_PROD = {'user_team': 'data', 'user_env': 'prod'}\nWEB_STAGING = {'user_team': 'web', 'user_env': 'staging'}\nDATA = {'user_team': 'data'}\n\n", "note": "The payer is moto's management account, as in every lesson. The three member accounts use the made-up ids AWS's own documentation uses in examples, so they cannot be mistaken for anybody's. The tag sets are the shop's, written with the `user_` prefix a report gives tags somebody wrote."}, {"code": "# account, line type, product, usage type, resource, amount, rate, tags\nLINES = [\n    (PROD, 'SavingsPlanCoveredUsage', 'AmazonEC2', 'SAE1-BoxUsage:m7i.large', 'i-0web1', 730, 0.16065, WEB_PROD),\n    (PROD, 'SavingsPlanNegation', 'AmazonEC2', 'SAE1-BoxUsage:m7i.large', 'i-0web1', 730, -0.16065, WEB_PROD),\n    (PROD, 'SavingsPlanRecurringFee', 'ComputeSavingsPlans', 'ComputeSP:1yrNoUpfront', SP, 730, 0.10915, {}),\n    (PROD, 'Usage', 'AmazonEC2', 'SAE1-BoxUsage:m7i.large', 'i-0web2', 730, 0.16065, WEB_PROD),\n    (PROD, 'Usage', 'AmazonEC2', 'SAE1-BoxUsage:m7i.large', 'i-0db1', 730, 0.16065, DATA_PROD),\n    (PROD, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Out-Bytes', 'i-0web1', 400, 0.15, WEB_PROD),\n    (PROD, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Out-Bytes', 'i-0web2', 400, 0.15, WEB_PROD),\n    (PROD, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Regional-Bytes', 'i-0web1', 300, 0.01, WEB_PROD),\n    (PROD, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Out-Bytes', 'i-0db1', 50, 0.15, DATA_PROD),\n    (PROD, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Regional-Bytes', 'i-0web2', 300, 0.01, WEB_PROD),\n    (PROD, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Regional-Bytes', 'i-0db1', 600, 0.01, DATA_PROD),\n    (PROD, 'Usage', 'AmazonVPC', 'SAE1-PublicIPv4:InUseAddress', 'eipalloc-0p1', 730, 0.005, {}),\n    (PROD, 'Usage', 'AmazonVPC', 'SAE1-PublicIPv4:InUseAddress', 'eipalloc-0p2', 730, 0.005, {}),\n    (PROD, 'Usage', 'AWSCostExplorer', 'USE1-APIRequest', '', 120, 0.01, {}),\n    (STAGING, 'Usage', 'AmazonEC2', 'SAE1-BoxUsage:m7i.large', 'i-0stg1', 730, 0.16065, WEB_STAGING),\n    (STAGING, 'Usage', 'AmazonEC2', 'SAE1-NatGateway-Hours', 'nat-0stg1', 730, 0.093, {}),\n    (STAGING, 'Usage', 'AmazonEC2', 'SAE1-NatGateway-Bytes', 'nat-0stg1', 200, 0.093, {}),\n    (STAGING, 'Usage', 'AmazonVPC', 'SAE1-PublicIPv4:IdleAddress', 'eipalloc-0s1', 730, 0.005, {}),\n    (STAGING, 'Usage', 'AmazonVPC', 'SAE1-PublicIPv4:IdleAddress', 'eipalloc-0s2', 730, 0.005, {}),\n    (STAGING, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Regional-Bytes', 'i-0stg1', 1600, 0.01, WEB_STAGING),\n    (SANDBOX, 'Usage', 'AmazonEC2', 'SAE1-BoxUsage:m7i.large', 'i-0sbx1', 200, 0.16065, DATA),\n    (SANDBOX, 'Usage', 'AmazonEC2', 'SAE1-BoxUsage:m7i.large', 'i-0sbx2', 150, 0.16065, {}),\n    (SANDBOX, 'Usage', 'AWSDataTransfer', 'SAE1-DataTransfer-Out-Bytes', 'i-0sbx1', 20, 0.15, DATA),\n    (SANDBOX, 'Usage', 'AmazonVPC', 'SAE1-PublicIPv4:InUseAddress', 'eipalloc-0x1', 350, 0.005, {}),\n    (SANDBOX, 'Usage', 'AWSCostExplorer', 'USE1-APIRequest', '', 300, 0.01, {}),\n]\n", "note": "One line per resource and usage type for the month. The first three are one instance under the Compute Savings Plan of lesson 14: covered usage, its negation, and the plan's fee, which carries no tags because the plan is not a team's. The rest are on demand, at the price-list rates of lessons 1, 13 and 14, and several carry no `team` on purpose."}, {"code": "SP_RATE = 0.10915    # the plan's rate for an m7i.large, from lesson 14\nTAX = 0.10           # a made-up rate, not any country's\nCREDIT = {SANDBOX: 20.00}\n\nCOLUMNS = ['bill_payer_account_id', 'line_item_usage_account_id', 'line_item_line_item_type',\n           'line_item_product_code', 'line_item_usage_type', 'line_item_resource_id',\n           'line_item_usage_amount', 'line_item_unblended_cost',\n           'savings_plan_savings_plan_effective_cost', 'resource_tags']\n\n\n", "note": "The plan's rate, the made-up tax rate, a made-up credit for the sandbox, and the columns, a handful of the hundreds a real report carries, with their real names."}, {"code": "def main():\n    rows, before_tax = [], {}\n    for account, kind, product, usage, resource, amount, rate, tags in LINES:\n        cost = round(amount * rate, 6)\n        effective = round(amount * SP_RATE, 6) if kind == 'SavingsPlanCoveredUsage' else ''\n        rows.append([PAYER, account, kind, product, usage, resource, amount, cost, effective,\n                     json.dumps(tags)])\n        before_tax[account] = before_tax.get(account, 0) + cost\n", "note": "Each line's cost is the amount times the rate, and a covered line also gets the plan's effective cost. Tags go into one column as JSON, the way a CUR 2.0 file carries `resource_tags` as a map."}, {"code": "    for account, amount in CREDIT.items():\n        rows.append([PAYER, account, 'Credit', 'AmazonEC2', '', '', '', -amount, '', '{}'])\n        before_tax[account] -= amount\n    for account, total in before_tax.items():\n        rows.append([PAYER, account, 'Tax', '', '', '', '', round(total * TAX, 6), '', '{}'])\n    with open('cur.csv', 'w', newline='') as f:\n        out = csv.writer(f)\n        out.writerow(COLUMNS)\n        out.writerows(rows)\n    print(f'cur.csv: {len(rows)} lines, {len(before_tax)} accounts, made-up data')\n\n\nmain()\n", "note": "Then a credit line and one tax line per account, on what the account spent after its credit, and the file."}]}
```

Run it and look at the first lines:

```
ana@laptop:~/aws$ python3 make_cur.py
cur.csv: 29 lines, 3 accounts, made-up data
ana@laptop:~/aws$ head -4 cur.csv
bill_payer_account_id,line_item_usage_account_id,line_item_line_item_type,line_item_product_code,line_item_usage_type,line_item_resource_id,line_item_usage_amount,line_item_unblended_cost,savings_plan_savings_plan_effective_cost,resource_tags
123456789012,111122223333,SavingsPlanCoveredUsage,AmazonEC2,SAE1-BoxUsage:m7i.large,i-0web1,730,117.2745,79.6795,"{""user_team"": ""web"", ""user_env"": ""prod""}"
123456789012,111122223333,SavingsPlanNegation,AmazonEC2,SAE1-BoxUsage:m7i.large,i-0web1,730,-117.2745,,"{""user_team"": ""web"", ""user_env"": ""prod""}"
123456789012,111122223333,SavingsPlanRecurringFee,ComputeSavingsPlans,ComputeSP:1yrNoUpfront,arn:aws:savingsplans::111122223333:savingsplan/sp-0shop1,730,79.6795,,{}
```

**Every cell of `resource_tags` is a small piece of JSON**, `{"user_team": "web", "user_env":
"prod"}` or `{}` for a line with no tags, and the CSV doubles each quotation mark inside it, which
is how a CSV escapes one. In a real export in Parquet the map is a column type of its own, read with a query
engine's own functions for maps; JSON in a CSV is this file's stand-in for it.

## A program that asks it questions

The report is a table, so the tool for it is SQL. Python's library carries **`sqlite3`**, a whole
SQL database in a module, which is enough for 29 rows and would be for a few million. **Save this
as `~/aws/ask.py`**:

```schooling-example
{"language": "python", "file": "ask.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Asks cur.csv a question in SQL, with Python's own sqlite3: nothing to install.\n\n    python3 ask.py \"SELECT ... FROM cur ...\"\n    python3 ask.py question.sql\n\"\"\"\nimport csv\nimport sqlite3\nimport sys\n\nNUMBERS = {'line_item_usage_amount', 'line_item_unblended_cost',\n           'savings_plan_savings_plan_effective_cost'}\n\n\n", "note": "A question in SQL, on the command line or in a `.sql` file, asked of `cur.csv`. `sqlite3` is a database inside Python's own library, so there is nothing to install and no server to start."}, {"code": "def load(path):\n    db = sqlite3.connect(':memory:')\n    with open(path, newline='') as f:\n        rows = csv.reader(f)\n        head = next(rows)\n        kinds = ', '.join(f'{c} {\"REAL\" if c in NUMBERS else \"TEXT\"}' for c in head)\n        db.execute(f'CREATE TABLE cur ({kinds})')\n        marks = ', '.join('?' * len(head))\n        for row in rows:\n            db.execute(f'INSERT INTO cur VALUES ({marks})', [v if v != '' else None for v in row])\n    return db\n\n\n", "note": "Reads the CSV into a table called `cur` in memory. The three money and quantity columns are declared `REAL` so that `sum` adds numbers; every other column is text. An empty cell becomes `NULL`, which is how SQL says a value is absent."}, {"code": "def show(cursor):\n    names = [d[0] for d in cursor.description]\n    rows = cursor.fetchall()\n    cells = [[f'{v:,.2f}' if isinstance(v, float) else '' if v is None else str(v) for v in r]\n             for r in rows]\n    width = [max(len(x) for x in col) for col in zip(names, *cells)]\n    right = [any(isinstance(r[i], (int, float)) for r in rows) for i in range(len(names))]\n    for line in [names] + cells:\n        print('  '.join(x.rjust(w) if r else x.ljust(w) for x, w, r in zip(line, width, right)).rstrip())\n\n\n", "note": "Prints the answer as a table: numbers with two decimals and on the right, text on the left, and a column as wide as its widest cell."}, {"code": "def main():\n    question = sys.argv[1]\n    if question.endswith('.sql'):\n        with open(question) as f:\n            question = f.read()\n    show(load('cur.csv').execute(question))\n\n\nmain()\n", "note": "The argument is the question itself, or the name of a file that holds it."}]}
```

The first question every reader of a bill asks: what did each account cost?

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

**The three totals are the whole made-up bill, 806.60 dollars, and they add every line as it was
charged**: the usage, the tax, the credit taken off the sandbox, and the Savings Plan's three lines.
The second query says what each line type contributed. `SavingsPlanCoveredUsage` and
`SavingsPlanNegation` are 117.27 and minus 117.27, and they cancel, exactly as in the figure of
lesson 14; the plan's own 79.68 is a line of its own, `SavingsPlanRecurringFee`. A reader who
summed only the lines of type `Usage`, 673.59, would have missed the plan, the tax and the credit,
and called it the bill.

`444455556666`, the staging account, cost 249.77 with tax. That is lesson 14's bill that arrived
wrong, 227.06, plus the made-up tax of 10%, and the file is how the next section finds out whose
each part was.
