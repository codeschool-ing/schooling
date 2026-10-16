---
title: Tabela única para a Quitanda
version: 1
---

**O instinto relacional dá à Quitanda três tabelas, `customers`, `orders` e `order_lines`, e no
DynamoDB isso são três idas e voltas para uma tela.** Não há join, então "um pedido com suas linhas"
vira uma leitura do pedido, depois uma leitura das linhas, e a aplicação costura as duas. O projeto de
tabela única (*single-table design*) faz a costura uma vez, quando os dados são escritos: todo tipo de
item que é lido junto vai para uma tabela, sob chaves construídas para que a leitura seja uma `query`.

**As chaves são sobrecarregadas.** `pk` e `sk` guardam tipos diferentes de valor para tipos diferentes
de item, e um prefixo no valor diz qual: `CUSTOMER#`, `ORDER#`, `LINE#`. É por isso que os atributos se
chamam `pk` e `sk` e não `customer_id` e `order_date`, que seriam falsos para metade dos itens. Os três
tipos da Quitanda:

| item | `pk` | `sk` | atributos próprios |
|---|---|---|---|
| perfil | `CUSTOMER#c-17` | `PROFILE` | `name`, `district` |
| pedido | `CUSTOMER#c-17` | `ORDER#2026-10-05#o-10002` | `order_id`, `order_day`, `total_cents`, `line_count` |
| linha do pedido | `CUSTOMER#c-17` | `ORDER#2026-10-05#o-10002#LINE#1` | `product`, `qty`, `price_cents` |

Os três dividem a chave de partição do cliente, então **um cliente, todos os pedidos dele e todas as
linhas são uma coleção de itens**, ordenada por `sk`. E cada padrão de acesso da seção anterior vira uma
leitura:

| | a leitura |
|---|---|
| A1, o perfil | `get-item` com `pk = CUSTOMER#c-17` e `sk = PROFILE` |
| A2, pedidos num intervalo de datas | `query` com `pk = CUSTOMER#c-17` e `sk BETWEEN ORDER#2026-10-01 AND ORDER#2026-10-08` |
| A3, um pedido e suas linhas | `query` com `pk = CUSTOMER#c-17` e `begins_with(sk, ORDER#2026-10-05#o-10002)` |
| A4, o pedido mais recente | `query` em `begins_with(sk, ORDER#)`, do mais novo, um item |
| A5, um dia de todos os clientes | nenhuma: um scan, até a lição 10 |

## Carregando

**Os dados vêm de um programa curto**, escrito com o boto3, a biblioteca Python da AWS. Salve-o como
`~/aws/seed.py` do jeito que a lição 1 salvou o `prices.py`: o botão de copiar no bloco, depois
`nano seed.py`, colar, Ctrl+O, Enter e Ctrl+X.

```schooling-example
{"language": "python", "file": "seed.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Load Quitanda's customers, orders and order lines into the table `quitanda`.\n\n    python3 seed.py         # three customers, c-17 to c-19\n    python3 seed.py 4000    # four thousand\n\nThe same number always writes the same items. The table must exist.\n\"\"\"\nimport random\nimport sys\n\nimport boto3\n\n", "note": "A docstring diz como rodá-lo. Sem argumento ele escreve três clientes, poucos o bastante para ler cada item; a lição 10 o roda com um número maior para ter uma tabela que valha um scan."}, {"code": "NAMES = ['Ana', 'Bruno', 'Carla', 'Diego', 'Elisa', 'Fábio', 'Gabi', 'Heitor']\nDISTRICTS = ['Pinheiros', 'Mooca', 'Lapa', 'Tatuapé', 'Santana', 'Butantã']\nPRODUCTS = [('banana', 690), ('tomato', 899), ('rice-5kg', 2790),\n            ('coffee-500g', 3450), ('eggs-12', 1590), ('milk-1l', 549)]\n\n", "note": "O material de que o gerador tira os dados. Os preços são centavos inteiros, como dinheiro é em todo este curso."}, {"code": "customers = int(sys.argv[1]) if len(sys.argv) > 1 else 3\nrnd = random.Random(17)\ntable = boto3.resource('dynamodb').Table('quitanda')\norder_no, written = 10000, {'PROFILE': 0, 'ORDER': 0, 'LINE': 0}\n\n", "note": "**O boto3 veio com o moto**, então não há nada a instalar, e ele lê as mesmas variáveis que a linha de comando: `AWS_ENDPOINT_URL` o manda para o moto. Um `Random` com semente fixa faz toda execução escrever os mesmos itens, e é isso que deixa esta lição imprimi-los."}, {"code": "with table.batch_writer() as batch:\n    for n in range(customers):\n        cid = f'c-{17 + n}'\n        pk = f'CUSTOMER#{cid}'\n        batch.put_item(Item={'pk': pk, 'sk': 'PROFILE', 'customer_id': cid,\n                             'name': rnd.choice(NAMES), 'district': rnd.choice(DISTRICTS)})\n        written['PROFILE'] += 1\n", "note": "`batch_writer` junta os puts e os manda de 25 em 25, em requisições `BatchWriteItem`, o máximo que a API aceita de uma vez. O perfil é o primeiro item da coleção de cada cliente: chave de partição `CUSTOMER#<id>`, chave de ordenação `PROFILE`."}, {"code": "        days = sorted(rnd.sample(range(1, 15), rnd.randint(1, 4)))\n        for day in days:\n            order_no += 1\n            oid, date = f'o-{order_no}', f'2026-10-{day:02d}'\n            order_sk = f'ORDER#{date}#{oid}'\n", "note": "De um a quatro pedidos por cliente, em dias de outubro de 2026. **A chave de ordenação do pedido começa pela data**, `ORDER#2026-10-05#o-10002`, então os pedidos de um cliente ficam em ordem de data, e o id do pedido depois dela separa dois pedidos do mesmo dia. Os ids de pedido têm cinco dígitos desde o começo, para que um id nunca seja o começo de outro."}, {"code": "            lines = rnd.sample(PRODUCTS, rnd.randint(1, 3))\n            total = 0\n            for i, (product, price) in enumerate(lines, start=1):\n                qty = rnd.randint(1, 3)\n                total += qty * price\n                batch.put_item(Item={'pk': pk, 'sk': f'{order_sk}#LINE#{i}',\n                                     'product': product, 'qty': qty, 'price_cents': price})\n                written['LINE'] += 1\n", "note": "**A chave de ordenação de uma linha é a do pedido, mais `#LINE#` e um número**, então as linhas ficam logo depois do pedido e uma query pelo prefixo do pedido devolve os dois."}, {"code": "            order = {'pk': pk, 'sk': order_sk, 'order_id': oid, 'order_day': date,\n                     'total_cents': total, 'line_count': len(lines)}\n            if day == 14:\n                order['pending_since'] = date\n            batch.put_item(Item=order)\n            written['ORDER'] += 1\n\n", "note": "O próprio pedido leva o total, o dia e o id como atributos comuns além de dentro da chave, porque a lição 10 cria índices sobre eles. Um pedido de 14 de outubro ainda não foi entregue e leva `pending_since`; a última seção desta lição o usa."}, {"code": "print(f\"{customers} customers: {written['PROFILE']} profiles, {written['ORDER']} orders, \"\n      f\"{written['LINE']} order lines, {sum(written.values())} items\")\n", "note": "Uma contagem do que foi escrito, por tipo, para que a execução diga o que fez."}]}
```

```
ana@laptop:~/aws$ python3 seed.py
3 customers: 3 profiles, 9 orders, 18 order lines, 30 items
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --query 'Items[].[pk.S,sk.S]' --output text
CUSTOMER#c-17	ORDER#2026-10-03#o-10001
CUSTOMER#c-17	ORDER#2026-10-03#o-10001#LINE#1
CUSTOMER#c-17	ORDER#2026-10-03#o-10001#LINE#2
CUSTOMER#c-17	ORDER#2026-10-03#o-10001#LINE#3
CUSTOMER#c-17	ORDER#2026-10-05#o-10002
CUSTOMER#c-17	ORDER#2026-10-05#o-10002#LINE#1
CUSTOMER#c-17	ORDER#2026-10-05#o-10002#LINE#2
CUSTOMER#c-17	ORDER#2026-10-05#o-10002#LINE#3
CUSTOMER#c-17	ORDER#2026-10-12#o-10003
CUSTOMER#c-17	ORDER#2026-10-12#o-10003#LINE#1
CUSTOMER#c-17	ORDER#2026-10-12#o-10003#LINE#2
CUSTOMER#c-17	PROFILE
CUSTOMER#c-18	ORDER#2026-10-06#o-10004
CUSTOMER#c-18	ORDER#2026-10-06#o-10004#LINE#1
CUSTOMER#c-18	ORDER#2026-10-09#o-10005
CUSTOMER#c-18	ORDER#2026-10-09#o-10005#LINE#1
CUSTOMER#c-18	PROFILE
CUSTOMER#c-19	ORDER#2026-10-03#o-10006
CUSTOMER#c-19	ORDER#2026-10-03#o-10006#LINE#1
CUSTOMER#c-19	ORDER#2026-10-03#o-10006#LINE#2
CUSTOMER#c-19	ORDER#2026-10-10#o-10007
CUSTOMER#c-19	ORDER#2026-10-10#o-10007#LINE#1
CUSTOMER#c-19	ORDER#2026-10-10#o-10007#LINE#2
CUSTOMER#c-19	ORDER#2026-10-11#o-10008
CUSTOMER#c-19	ORDER#2026-10-11#o-10008#LINE#1
CUSTOMER#c-19	ORDER#2026-10-14#o-10009
CUSTOMER#c-19	ORDER#2026-10-14#o-10009#LINE#1
CUSTOMER#c-19	ORDER#2026-10-14#o-10009#LINE#2
CUSTOMER#c-19	ORDER#2026-10-14#o-10009#LINE#3
CUSTOMER#c-19	PROFILE
```

**Trinta itens, e os doze primeiros são um cliente.** O moto lista a tabela inteira em ordem de chave,
uma conveniência do dicionário dele; a AWS devolveria as três coleções na ordem dos hashes, cada uma
ainda ordenada por dentro. A ordem dentro da coleção é a da chave de ordenação, byte a byte. Cada pedido
é seguido logo pelas próprias linhas, porque `ORDER#2026-10-03#o-10001` é prefixo de
`ORDER#2026-10-03#o-10001#LINE#1` e um prefixo vem antes de tudo que o estende. Os pedidos seguem a data
porque a data vem primeiro na chave. E `PROFILE` vem por último, depois de todo pedido, porque `P` é uma letra posterior a `O`. Nada num perfil o põe em primeiro;
se precisasse ser, a chave de ordenação dele teria de começar por um caractere que venha antes de `O`.

**O projeto está nas strings, e as strings são permanentes.** Nada no DynamoDB sabe que `#` separa
campos, que a data é ano-mês-dia ou que o id do pedido tem cinco dígitos. Isso são convenções desta
tabela, garantidas pelo único programa que a escreve, e mudar uma delas depois significa reescrever todo
item que segue a antiga. É a regra da lição 1 sobre chaves do S3, pelo mesmo motivo: uma chave é a única
alça que as leituras têm.

**Uma tabela não quer dizer um tipo de item por tela.** O projeto de tabela única é uma escolha feita
para os padrões que leem tipos diferentes de item juntos. Dados que nunca são lidos com mais nada não
ganham nada dividindo uma tabela, e algumas equipes os mantêm à parte exatamente pelos motivos que um
projetista relacional teria: backups separados, permissões separadas, capacidade separada.
