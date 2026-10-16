---
title: A pergunta para a qual ninguém projetou
version: 1
---

**O padrão A5 da lição 9 ficou sem chave, e esta seção põe um número nisso.** O back office quer todos
os pedidos feitos em 1º de outubro, de todos os clientes, para planejar o estoque do dia seguinte. A
chave de partição da tabela é o cliente, então a pergunta não nomeia partição nenhuma, e a única leitura
que a responde é um scan com filtro. Com trinta itens, na lição 9, o custo não aparecia. Por isso esta lição começa de uma tabela que vale um scan. Comece com o moto rodando no terminal
dele e as quatro linhas de "O seu laboratório, em resumo" da lição 1 digitadas neste. Crie a tabela com o
primeiro comando de "A chave de partição e a chave de ordenação" da lição 9, e peça ao `seed.py` da
lição 9, salvo em `~/aws`, quatro mil clientes. Leva uns vinte segundos contra o moto.

```
ana@laptop:~/aws$ python3 seed.py 4000
4000 customers: 4000 profiles, 10029 orders, 20071 order lines, 34100 items
ana@laptop:~/aws$ aws dynamodb describe-table --table-name quitanda --query "Table.[ItemCount,TableSizeBytes]" --output text
34100	0
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --filter-expression 'order_day = :d' --expression-attribute-values '{":d": {"S": "2026-10-01"}}' --select COUNT --query '[Count,ScannedCount]' --output text
240	11439
238	11445
260	11216
```

**34.100 itens, e `TableSizeBytes` diz 0.** O moto conta os itens e não os mede; a AWS mede os dois e
atualiza esses números mais ou menos a cada seis horas, então em nenhum dos lados eles servem para
acompanhar uma tabela. O scan responde em três linhas porque a linha de comando seguiu as páginas por
você, como faz por padrão, e rodou o `--query` uma vez por página. Somando: 738 pedidos achados, 34.100
itens lidos.

## Um scan, página por página

**O DynamoDB nunca devolve uma tabela inteira numa resposta.** Um scan ou uma query para depois de 1 MB
de dados lidos, diz onde parou e espera que peçam o resto. O programa abaixo faz esses pedidos e conta o
que cada página leu, devolveu e pesou, coisa que o moto não informa. Salve-o como `~/aws/pages.py`.

```schooling-example
{"language": "python", "file": "pages.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Read the table `quitanda` page by page, as DynamoDB hands it out.\n\n    python3 pages.py                      # a scan of every item\n    python3 pages.py 2026-10-01           # the same scan, filtered to one day's orders\n    python3 pages.py 2026-10-01 by-day    # a query on the index by-day instead\n\nFor each page: how many items DynamoDB read, how many it returned, and the\nsize of what it returned by AWS's rule for item size. moto reports neither\nsizes nor real read units, so this program counts them itself.\n\"\"\"\nimport math\nimport sys\n\nimport boto3\n\n", "note": "O manual. Um programa para três leituras da mesma pergunta, para que as páginas delas possam ser postas lado a lado."}, {"code": "day = sys.argv[1] if len(sys.argv) > 1 else None\nindex = sys.argv[2] if len(sys.argv) > 2 else None\ndb = boto3.client('dynamodb')\nrequest = {'TableName': 'quitanda'}\nif index:\n    request.update(IndexName=index, KeyConditionExpression='order_day = :d',\n                   ExpressionAttributeValues={':d': {'S': day}})\nelif day:\n    request.update(FilterExpression='order_day = :d',\n                   ExpressionAttributeValues={':d': {'S': day}})\nread = db.query if index else db.scan\n\n\n", "note": "Os argumentos, e a requisição que toda página repete. Um filtro é uma `FilterExpression`; o índice é uma `query` com `IndexName` e uma condição de chave na chave de partição dele."}, {"code": "def size(item):\n    total = 0\n    for name, value in item.items():\n        (kind, v), = value.items()\n        if kind == 'N':\n            digits = v.lstrip('-').replace('.', '').strip('0') or '0'\n            total += len(name) + (len(digits) + 1) // 2 + 1\n        else:\n            total += len(name) + len(v.encode())\n    return total\n\n\n", "note": "**A regra da AWS para o tamanho de um item**: o nome de cada atributo mais o valor dele. Uma string conta os bytes UTF-8; um número, mais ou menos um byte para cada dois dígitos significativos, mais um. Perto o bastante para pôr preço numa leitura, que é para isso que serve."}, {"code": "page, scanned, returned, size_back, units = 0, 0, 0, 0, 0.0\nwhile True:\n    answer = read(**request)\n    page += 1\n    got = sum(size(i) for i in answer['Items'])\n    more = 'LastEvaluatedKey' in answer\n    print(f\"page {page}: read {answer['ScannedCount']:>6} items, returned {answer['Count']:>6}, \"\n          f\"{got:>9,} bytes returned, {'more' if more else 'last page'}\")\n    scanned += answer['ScannedCount']\n    returned += answer['Count']\n    size_back += got\n    units += 0.5 * math.ceil(got / 4096)\n    if not more:\n        break\n    request['ExclusiveStartKey'] = answer['LastEvaluatedKey']\n\n", "note": "**O laço que todo leitor do DynamoDB tem.** Uma página termina em 1 MB de dados lidos, ou antes com um `Limit`, e quando há mais a resposta traz `LastEvaluatedKey`. A próxima requisição a devolve como `ExclusiveStartKey`, e a leitura só para quando uma página volta sem ela."}, {"code": "print(f\"{page} page{'s' if page > 1 else ''}, {scanned} items read, {returned} returned, {size_back:,} bytes returned, \"\n      f'{units:g} read units for them')\n", "note": "Os totais. As unidades de leitura são do que voltou: os bytes de cada página em blocos de 4 KB, arredondados para cima, e meia unidade por bloco porque essas leituras são eventualmente consistentes. Sem filtro, o que voltou é o que foi lido, e essas são as unidades que a AWS cobraria."}]}
```

```
ana@laptop:~/aws$ python3 pages.py
page 1: read  11439 items, returned  11439, 1,001,827 bytes returned, more
page 2: read  11445 items, returned  11445, 1,002,008 bytes returned, more
page 3: read  11216 items, returned  11216,   975,707 bytes returned, last page
3 pages, 34100 items read, 34100 returned, 2,979,542 bytes returned, 364.5 read units for them
ana@laptop:~/aws$ python3 pages.py 2026-10-01
page 1: read  11439 items, returned    240,    24,720 bytes returned, more
page 2: read  11445 items, returned    238,    24,503 bytes returned, more
page 3: read  11216 items, returned    260,    26,630 bytes returned, last page
3 pages, 34100 items read, 738 returned, 75,853 bytes returned, 10 read units for them
```

**O filtro mudou o que voltou, e não o que foi lido.** As duas execuções leram as mesmas três páginas de
cerca de um megabyte, 34.100 itens ao todo. A primeira devolveu tudo, 2.979.542 bytes, o que dá 364,5
unidades de leitura: os bytes de cada página em blocos de 4 KB, meia unidade cada numa leitura
eventualmente consistente. A segunda devolveu 738 itens e 75.853 bytes, e a AWS ainda a cobraria pelo
que leu, as mesmas 364,5 unidades, porque o filtro roda depois da leitura. O `10` na última linha dela é
o que os 738 pedidos custariam se algo pudesse ler só eles, e um índice pode.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três páginas de scan, de cerca de um megabyte cada, leram 11.439, 11.445 e 11.216 itens e devolveram 240, 238 e 260 deles, uma lasca de cada página, por 364,5 unidades de leitura no total. A query no índice by-day lê uma página de 738 itens e devolve os 738, por 8,5 unidades de leitura.\" data-fig=\"l10-pages\"><defs><marker id=\"l10-pages-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">scan, filtrado para 1º de outubro</text><text x=\"20\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">página 1</text><rect x=\"100\" y=\"40\" width=\"379.8007863695937\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><rect x=\"100\" y=\"40\" width=\"7.968545216251638\" height=\"28\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"490\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">11.439 lidos</text><text x=\"490\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">240 devolvidos</text><text x=\"20\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">página 2</text><rect x=\"100\" y=\"80\" width=\"380.0\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><rect x=\"100\" y=\"80\" width=\"7.902140672782874\" height=\"28\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"490\" y=\"89\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">11.445 lidos</text><text x=\"490\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">238 devolvidos</text><text x=\"20\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">página 3</text><rect x=\"100\" y=\"120\" width=\"372.39667977282653\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><rect x=\"100\" y=\"120\" width=\"8.632590650939274\" height=\"28\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"490\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">11.216 lidos</text><text x=\"490\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">260 devolvidos</text><text x=\"620\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">364,5 unidades de leitura</text><text x=\"20\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">query no by-day</text><text x=\"20\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">página 1</text><rect x=\"100\" y=\"192\" width=\"24.503276539973786\" height=\"28\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"140\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">738 lidos</text><text x=\"140\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">738 devolvidos</text><text x=\"620\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">8,5 unidades de leitura</text></svg>", "caption": "Desenhado em escala pelos itens. O filtro afina o que volta; as páginas, e a conta, continuam do tamanho da tabela."}
```

## Quanto custa o scan

```
ana@laptop:~/aws$ python3 prices.py dynamodb
AWS public price list, sa-east-1, USD, excluding tax

DynamoDB, USD
  on demand, per million write request units            0.93750  million
  on demand, per million read request units             0.18750  million
  provisioned, per WCU-hour                            0.000975  WCU-hour
  provisioned, per RCU-hour                            0.000195  RCU-hour
  storage beyond 25 GB                                  0.37500  GB-month
  storage, Standard-IA table class                      0.15000  GB-month
  streams, per million read requests beyond free        0.30000  million
  point-in-time recovery                                0.30000  GB-month
```

**A 0,1875 dólar por milhão de unidades de leitura, um scan desta tabela custa 364,5 × 0,1875 /
1.000.000 = 0,0000683 dólar**, o que não é nada. Uma tela do back office que atualiza a cada minuto o
roda 43.200 vezes num mês de 30 dias: 15.746.400 unidades de leitura, ou **2,95 dólares por mês**. Ainda
pouco, porque esta tabela é pequena: 4.000 clientes e duas semanas de pedidos. Um scan custa o tamanho
da tabela, e a tabela cresce a cada pedido já feito. A mesma tela numa tabela cem vezes maior dá
295 dólares por mês para uma pergunta, e a conta continua crescendo depois que ninguém lembra mais por
quê. A próxima seção responde à mesma pergunta por cerca de um quarenta avos das unidades de leitura.
