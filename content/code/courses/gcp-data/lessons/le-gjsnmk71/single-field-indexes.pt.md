---
title: Toda consulta lê um índice, e a maioria dos índices já está lá
version: 1
---

**O Firestore responde a toda consulta a partir de um índice, e recusa qualquer consulta que nenhum
índice consiga responder.** Não há scan para recorrer. Parece o banco mais rígido deste curso, e para a
maioria das consultas é o mais tranquilo, porque o Firestore constrói os índices sozinho: para todo
campo de todo documento, um índice ascendente, um descendente e, para um array, um índice
`array-contains`. Uma consulta sobre um campo lê um deles, em ordem, e para quando tem o que pediu.

**A ideia errada é que índices são algo que se acrescenta por velocidade.** No PostgreSQL uma consulta
sem índice ainda roda, devagar. No Firestore o índice é o que torna a consulta possível, e o custo dele
é pago em toda escrita: um documento gravado é uma entrada em todo índice que cobre um dos seus campos,
e por isso o armazenamento é cobrado com as entradas de índice incluídas. Os automáticos se chamam
**índices de campo único** (*single-field indexes*), e esta seção não usa outra coisa.

## Seis perguntas, pelo nome

```schooling-example
{"language": "python", "file": "query.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Run one of Quitanda's queries by name and print what it returns.\n\n    python3 query.py NAME\n\"\"\"\nimport sys\n\nfrom google.cloud import firestore\nfrom google.cloud.firestore_v1.base_query import FieldFilter\n\ndb = firestore.Client(project='planner-dev')\norders = db.collection_group('orders')\nDESC = firestore.Query.DESCENDING\n\n", "note": "**`collection_group('orders')` é toda coleção chamada `orders`**, debaixo de todo cliente, lida como uma só. `FieldFilter` é como a biblioteca atual escreve um `where`."}, {"code": "QUERIES = {\n    'one-customer': db.collection('customers').document('c-17').collection('orders'),\n    'pending': orders.where(filter=FieldFilter('status', '==', 'pending')),\n    'big': orders.where(filter=FieldFilter('total_cents', '>=', 10000)).order_by('total_cents', direction=DESC),\n    'coffee': orders.where(filter=FieldFilter('products', 'array_contains', 'coffee-500g')),\n", "note": "**Quatro perguntas sobre um campo cada.** Os pedidos de um cliente, pelo caminho; os pendentes; os de 100,00 ou mais, o maior primeiro; os que têm café."}, {"code": "    'pending-biggest': orders.where(filter=FieldFilter('status', '==', 'pending')).order_by('total_cents', direction=DESC),\n    'lapa-late-october': orders.where(filter=FieldFilter('district', '==', 'Lapa'))\n                               .where(filter=FieldFilter('day', '>=', '2026-10-20')),\n}\n\n", "note": "**Duas perguntas sobre dois campos cada**: uma igualdade ordenada por outro campo, e uma igualdade com uma faixa em outro campo. A próxima seção trata dessas duas."}, {"code": "for doc in QUERIES[sys.argv[1]].limit(5).stream():\n    o = doc.to_dict()\n    print(f\"{doc.reference.path:<32} {o['day']} {o['status']:<9} {o['total_cents']:>6} {','.join(o['products'])}\")\n", "note": "**No máximo cinco documentos por consulta**, cada um impresso com o caminho completo, que mostra de qual subcoleção de cliente ele veio."}]}
```

**Quatro dessas consultas são sobre um campo cada**, então os índices de campo único as cobrem:

```
ana@laptop:~/gcp$ python3 query.py one-customer
customers/c-17/orders/o-10001    2026-10-06 delivered   6149 tomato,eggs-12,banana
customers/c-17/orders/o-10002    2026-10-10 pending     4287 eggs-12,tomato
customers/c-17/orders/o-10003    2026-10-12 delivered   3450 coffee-500g
ana@laptop:~/gcp$ python3 query.py pending
customers/c-17/orders/o-10002    2026-10-10 pending     4287 eggs-12,tomato
customers/c-18/orders/o-10006    2026-10-29 pending     7049 banana,eggs-12,tomato
customers/c-23/orders/o-10014    2026-10-09 pending    12449 eggs-12,tomato,rice-5kg
customers/c-26/orders/o-10020    2026-10-07 pending     9960 rice-5kg,eggs-12
customers/c-30/orders/o-10029    2026-10-04 pending     9929 coffee-500g,rice-5kg,tomato
ana@laptop:~/gcp$ python3 query.py big
customers/c-23/orders/o-10016    2026-10-27 delivered  20040 eggs-12,coffee-500g,rice-5kg
customers/c-33/orders/o-10042    2026-10-14 delivered  15810 coffee-500g,eggs-12,banana
customers/c-18/orders/o-10004    2026-10-04 delivered  15600 banana,eggs-12,coffee-500g
customers/c-34/orders/o-10046    2026-10-25 pending    14730 coffee-500g,rice-5kg,eggs-12
customers/c-33/orders/o-10040    2026-10-04 delivered  13740 eggs-12,coffee-500g,banana
ana@laptop:~/gcp$ python3 query.py coffee
customers/c-17/orders/o-10003    2026-10-12 delivered   3450 coffee-500g
customers/c-18/orders/o-10004    2026-10-04 delivered  15600 banana,eggs-12,coffee-500g
customers/c-18/orders/o-10005    2026-10-18 delivered  12210 coffee-500g,rice-5kg,eggs-12
customers/c-19/orders/o-10007    2026-10-18 cancelled   6900 coffee-500g
customers/c-20/orders/o-10008    2026-10-26 delivered  12148 coffee-500g,tomato
```

**`one-customer` é a leitura mais barata do Firestore**: uma coleção nomeada pelo caminho completo,
lida na ordem dos documentos. As outras três são consultas de **collection group**,
`collection_group('orders')`, que leem toda coleção chamada `orders` onde quer que esteja, debaixo de
qualquer cliente. `pending` é uma igualdade num campo, `big` uma faixa e uma ordem no mesmo campo, e
`coffee` lê o índice `array-contains` de `products`, onde cada elemento do array é uma entrada própria.

**Cada resposta para em cinco por causa do `limit(5)`**, e isso não é enfeite: o Firestore cobra uma
leitura por documento devolvido, então uma consulta que diz o seu limite diz o seu preço. Uma consulta
sem limite devolve tudo o que casa, e paga por tudo.

## O que o emulador não pediu

**No Google Cloud, essas três consultas de collection group teriam falhado da primeira vez.** O
Firestore mantém índices de campo único automaticamente para consultas numa coleção; para o escopo de
**collection group**, a documentação dele diz que o índice de campo único precisa ser ligado campo a
campo, e uma consulta que precisa de um é recusada com uma mensagem que traz um link para criá-lo. O
emulador respondeu às três sem nada disso. É o primeiro sinal do que a próxima seção encontra: o
emulador no modo padrão não confere índice nenhum.

**E as duas consultas que sobram precisam de mais do que um índice de campo único.** `pending-biggest`
é uma igualdade em `status` ordenada por `total_cents`, e `lapa-late-october` uma igualdade em
`district` com uma faixa em `day`. O índice de nenhum dos campos sozinho guarda as linhas na ordem de
que a consulta precisa, que é o assunto da próxima seção.

## Quando um índice automático é o padrão errado

**Todo campo é indexado, a menos que você diga o contrário**, e dois tipos de campo ficam melhor sem.
Um campo de texto grande, como as notas do entregador, cria entradas de índice que ninguém vai
consultar, e elas são armazenamento na conta. E um campo cujo valor cresce a cada escrita, um timestamp
ou um contador, é o hotspot da aula 9 de novo: a documentação do Firestore põe um limite de cerca de
500 escritas por segundo numa coleção cujos documentos têm um valor indexado sequencial, porque toda
entrada nova cai no fim do índice daquele campo.

**A saída é uma isenção de índice** (*index exemption*), uma configuração por campo que desliga ou muda
os índices automáticos dele. No Google Cloud é um comando, mostrado aqui e **não executado**, porque
os comandos de índice vão para o serviço de administração do Firestore, que não tem emulador:

```sh
gcloud firestore indexes fields update notes --collection-group=orders --disable-indexes
```

**Uma isenção é uma decisão sobre consultas que você não vai fazer**: um campo com os índices
desligados não pode ser filtrado nem ordenado, e o Firestore recusa a consulta em vez de ler todo
documento. Essa é a troca de que a seção inteira tratou. O Firestore nunca varre, então toda consulta
custa o que devolve; o preço é que uma pergunta para a qual ninguém indexou não tem resposta até
alguém indexar.
