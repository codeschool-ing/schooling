---
title: Sort keys e os blocos que uma consulta nunca lê
version: 1
---

**Uma sort key é a ordem em que as linhas de uma tabela são gravadas, e o valor dela são os blocos
que ela deixa uma consulta pular.** O Redshift não tem índices no sentido em que o PostgreSQL tem. O
que ele tem é o zone map de cada bloco, o mínimo e o máximo, e um zone map só ajuda quando as linhas
estão ordenadas: numa tabela gravada em ordem aleatória, todo bloco tem um pouco de todo dia, a faixa
dele cobre o mês inteiro, e um filtro num dia precisa ler todos.

O modelo abaixo mede isso com os mesmos dez mil pedidos de antes, cortados em blocos, em três ordens.
**Como o anterior, é um modelo da aritmética e não o Redshift.** Salve-o como `~/aws/zonemaps.py`:

```schooling-example
{"language": "python", "file": "zonemaps.py", "parts": [{"code": "import random\n\nROWS_PER_BLOCK = 250\nrng = random.Random(14)\nrows = [(f'2026-10-{rng.randint(1, 31):02d}', f'c-{rng.randint(1, 500):02d}')\n        for _ in range(10_000)]\n\n\n", "note": "Dez mil pedidos de novo, cada um com uma data de outubro de 2026 e um cliente, em ordem nenhuma em particular. Um bloco aqui tem 250 linhas; um bloco de verdade do Redshift é 1 MB de uma coluna e tem muito mais, e o que importa é a contagem de blocos, não o tamanho deles."}, {"code": "def blocks(ordered):\n    return [ordered[i:i + ROWS_PER_BLOCK] for i in range(0, len(ordered), ROWS_PER_BLOCK)]\n\n\n", "note": "Corta uma tabela, na ordem dada, em blocos de 250 linhas."}, {"code": "def read(table, column, value):\n    \"\"\"Blocks whose zone map, the min and max of the column, admits the value.\"\"\"\n    hits = 0\n    for block in table:\n        values = [row[column] for row in block]\n        if min(values) <= value <= max(values):\n            hits += 1\n    return hits\n\n\n", "note": "**O zone map trabalhando.** Para cada bloco, o menor e o maior valor da coluna; um bloco só é lido se o valor puder estar dentro dessa faixa."}, {"code": "layouts = {\n    'no sort key': rows,\n    'SORTKEY (dt, customer_id)': sorted(rows),\n    'SORTKEY (customer_id, dt)': sorted(rows, key=lambda r: (r[1], r[0])),\n}\n", "note": "As mesmas linhas gravadas em três ordens: como chegaram, ordenadas por data e depois cliente, e ordenadas por cliente e depois data. O Python ordena uma tupla pelo primeiro elemento primeiro, que é exatamente o que uma sort key compound faz."}, {"code": "print(f'{\"\":<27}{\"dt = 2026-10-05\":>21}{\"customer_id = c-17\":>21}')\nfor name, ordered in layouts.items():\n    table = blocks(ordered)\n    by_day, by_customer = read(table, 0, '2026-10-05'), read(table, 1, 'c-17')\n    print(f'{name:<27}{by_day:>8} of {len(table)} blocks{by_customer:>8} of {len(table)} blocks')\n", "note": "Para cada layout, quantos dos 40 blocos um filtro num dia lê, e quantos um filtro num cliente lê."}]}
```

```
ana@laptop:~/aws$ python3 zonemaps.py
                                 dt = 2026-10-05   customer_id = c-17
no sort key                      40 of 40 blocks      40 of 40 blocks
SORTKEY (dt, customer_id)         2 of 40 blocks      36 of 40 blocks
SORTKEY (customer_id, dt)        40 of 40 blocks       1 of 40 blocks
```

**Sem sort key, os dois filtros leram os 40 blocos.** Ordenado primeiro por data, o filtro num dia leu
2 blocos, e o filtro num cliente ainda leu 36: dentro dos blocos de um dia os clientes estão todos
misturados de novo. Ordenado primeiro por cliente, os dois resultados se invertem. Essa é a regra de
uma **sort key compound**: ela ajuda muito um filtro na primeira coluna, na segunda coluna só dentro
de cada valor da primeira, e na terceira quase nada. Então a primeira coluna é aquela pela qual a
maioria das consultas filtra por faixa, e na Quitanda essa coluna é a data: quase todo relatório
pergunta por um dia, uma semana ou um mês. É por isso que o `orders.sql` diz
`COMPOUND SORTKEY (dt, customer_id)`.

## Interleaved, e quando ela é a resposta errada

**Uma sort key interleaved dá peso igual a cada uma das suas colunas**, de modo que um filtro em
qualquer uma delas pula blocos mais ou menos tão bem quanto um filtro em outra. Parece o melhor
negócio e em geral não é. A documentação da AWS lista os custos. A carga fica mais lenta, e a tabela
precisa de um `VACUUM REINDEX` para continuar ordenada, que é caro. E ela não deve ser usada numa
coluna cujos valores só crescem, como uma data ou uma coluna de identidade, porque as linhas novas
caem todas no mesmo canto da ordem. Os pedidos da Quitanda são exatamente essa tabela, e a chave
compound em `dt` é a melhor escolha para eles. Uma chave interleaved é para uma tabela filtrada por
várias colunas sem favorita e carregada raramente.

## As linhas que chegam depois

**Linhas acrescentadas depois que uma tabela foi ordenada são gravadas numa região não ordenada no
fim dela**, e os zone maps desses blocos cobrem o que quer que as linhas novas tragam. Uma carga
noturna dos pedidos de um dia, em ordem de data, mantém a tabela quase ordenada sozinha. Uma carga que
insere as correções do mês passado não mantém, e o Redshift ordena a tabela de novo em segundo plano
com um `VACUUM` automático, ou quando alguém roda `VACUUM SORT ONLY`. Nada disso foi rodado; é o
comportamento que a AWS documenta, e o modelo acima é o motivo de ele importar.
