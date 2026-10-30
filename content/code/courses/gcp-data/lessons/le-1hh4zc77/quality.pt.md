---
title: Varreduras de perfil e de qualidade de dados
version: 1
---

**Um pipeline que roda verde pode carregar bobagem.** O job noturno da aula 24 confere que rodou, não
que os pedidos que carregou fazem sentido: uma coluna de totais que de repente está 5% vazia, um id
de pedido que aparece duas vezes, um preço negativo. Nada disso faz um `LOAD` ou um `SELECT` falhar,
e tudo isso chega a um dashboard. O Dataplex tem dois tipos de varredura para isso, e eles respondem
a perguntas diferentes.

**Uma varredura de perfil (data profile) descreve uma tabela**: para cada coluna, a fatia de nulos, o
número de valores distintos, o mínimo e o máximo, os valores mais comuns, a média de um número. Ela
não julga nada. **Uma varredura de qualidade (data quality) julga uma tabela contra regras**: cada
regra é uma condição que toda linha deveria cumprir, com um limite para a fatia de linhas que precisa
cumpri-la, e a varredura diz aprovado ou reprovado por regra e para o todo. O perfil é o que você lê
antes de saber quais deveriam ser as regras; as regras são o que roda toda noite depois.

## As regras, e o limite que as torna práticas

**Uma regra é avaliada por linha e julgada sobre todas elas.** O Dataplex oferece um punhado de tipos prontos. Vale conhecê-los pelo nome, porque cobrem quase tudo o que alguém escreve:

| regra | a condição em cada linha |
|---|---|
| não nulo | a coluna tem valor |
| faixa | o valor está entre um mínimo e um máximo |
| conjunto | o valor é um de uma lista |
| regex | o valor casa com um padrão |
| unicidade | nenhuma outra linha tem o mesmo valor |
| condição de linha | uma expressão SQL sobre a linha é verdadeira |
| condição de tabela | uma expressão SQL sobre a tabela inteira é verdadeira, como uma contagem de linhas |

**Toda regra tem um limite**, a fatia de linhas que precisa passar para a regra passar, e **o limite é
o que transforma uma regra em algo que pode rodar toda noite**. Uma regra a 100% reprova na primeira
linha estranha, o que é certo para uma chave que precisa ser única e errado para um telefone digitado
por um cliente. A varredura também aceita um **filtro de linhas**, e uma opção **incremental** que só
julga as linhas mais novas que a última execução, numa coluna que a varredura recebe para observar.

## A mesma aritmética, no seu laptop

O Dataplex roda as varreduras em tabelas do BigQuery, e nenhum emulador responde por nenhum dos dois.
**O que vem a seguir é um modelo da ideia, não o Dataplex**: o mesmo perfil e os mesmos quatro tipos
de regra, calculados pelo DuckDB, o motor que a aula 1 instalou, num CSV pequeno o bastante para ler
inteiro. Salve vinte pedidos da Quitanda como `orders.csv`:

```
order_id,customer_id,total_cents,phone
o-10001,c-40,1380,+55 11 94361-8085
o-10002,c-36,690,+55 11 93095-8819
o-10003,c-18,1290,+55 11 98038-4972
o-10004,c-40,,+55 11 94308-1471
o-10005,c-38,1380,+55 11 93362-3120
o-10006,c-23,23490,+55 11 97368-6968
o-10007,c-24,690,+55 11 91497-5808
o-10008,c-34,899,+55 11 99347-1718
o-10009,c-37,690,98607-6138
o-10010,c-27,4290,+55 11 98078-4288
o-10011,c-18,2790,+55 11 94233-7296
o-10012,c-30,1290,+55 11 91965-2628
o-10013,c-19,-500,+55 11 99928-9989
o-10014,c-39,690,+55 11 91770-7664
o-10014,c-39,690,+55 11 91770-7664
o-10015,c-23,3450,+55 11 92484-9907
o-10016,c-27,899,+55 11 97672-1737
o-10017,c-30,23490,+55 11 92226-1663
o-10018,c-28,899,+55 11 94926-2339
o-10019,c-23,1290,+55 11 98123-4567
```

E o programa, `~/gcp/scan.py`:

```schooling-example
{"language": "python", "file": "scan.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"A data profile and a data quality check of one CSV, the way Dataplex scans compute them.\n\n    python3 scan.py profile orders.csv\n    python3 scan.py quality orders.csv\n\nA MODEL OF THE IDEA, NOT DATAPLEX: the same arithmetic, run by DuckDB on your laptop.\n\"\"\"\nimport sys\n\nimport duckdb\n\n", "note": "**A última linha da docstring é a que importa**: o DuckDB faz a aritmética que as varreduras do Dataplex fazem, num arquivo em vez de numa tabela do BigQuery."}, {"code": "mode, path = sys.argv[1], sys.argv[2]\ndb = duckdb.connect()\ndb.execute(f\"CREATE VIEW t AS SELECT * FROM read_csv('{path}', header=true)\")\nrows = db.execute('SELECT count(*) FROM t').fetchone()[0]\n\n", "note": "O DuckDB lê o CSV como uma view, `t`, e adivinha o tipo de cada coluna pelos valores, então `total_cents` é um número e o vazio é um nulo."}, {"code": "if mode == 'profile':\n    print(f'{rows} rows')\n    for (col,) in db.execute(\"SELECT column_name FROM (DESCRIBE t)\").fetchall():\n        nulls, distinct, low, high = db.execute(\n            f'SELECT count(*) FILTER (WHERE \"{col}\" IS NULL), count(DISTINCT \"{col}\"), '\n            f'min(\"{col}\"), max(\"{col}\") FROM t').fetchone()\n        print(f'  {col:<12} null {nulls / rows:6.1%}  distinct {distinct:>3}  min {low}  max {high}')\n    sys.exit()\n\n", "note": "**O perfil**: para cada coluna, a fatia de nulos, a contagem de distintos, o mínimo e o máximo. Um perfil não julga nada; só descreve."}, {"code": "RULES = [\n    ('order_id is unique',       'order_id', 'count(*) OVER (PARTITION BY order_id) = 1', 1.00),\n    ('total_cents is not null',  'total_cents', 'total_cents IS NOT NULL', 1.00),\n    ('total_cents in 1..500000', 'total_cents', 'total_cents BETWEEN 1 AND 500000', 0.90),\n    ('phone looks Brazilian',    'phone', \"regexp_full_match(phone, '\\\\+55 11 9\\\\d{4}-\\\\d{4}')\", 0.95),\n]\n", "note": "**As regras**, cada uma com um nome, uma coluna, uma condição sobre uma linha e um limite. A unicidade é uma janela: uma linha passa se o id dela aparece uma vez na tabela inteira. O padrão do telefone é o formato de celular de São Paulo, escrito como expressão regular."}, {"code": "failed = 0\nfor name, col, predicate, threshold in RULES:\n    passed = db.execute(f'SELECT count(*) FILTER (WHERE ok) FROM (SELECT {predicate} AS ok FROM t)').fetchone()[0]\n    ratio = passed / rows\n    verdict = 'PASS' if ratio >= threshold else 'FAIL'\n    failed += verdict == 'FAIL'\n    print(f'{verdict}  {name:<26} {passed}/{rows} = {ratio:.1%}, threshold {threshold:.0%}')\nprint(f'{len(RULES) - failed} of {len(RULES)} rules passed')\n", "note": "Cada regra conta as linhas cuja condição é verdadeira, divide por todas as linhas, e passa se a fatia alcança o limite. Um nulo deixa a condição nem verdadeira nem falsa, então conta como falha, que é também o que o Dataplex faz a não ser que a regra mande ignorar nulos."}]}
```

```
ana@laptop:~/gcp$ python3 scan.py profile orders.csv
20 rows
  order_id     null   0.0%  distinct  19  min o-10001  max o-10019
  customer_id  null   0.0%  distinct  13  min c-18  max c-40
  total_cents  null   5.0%  distinct   9  min -500  max 23490
  phone        null   0.0%  distinct  19  min +55 11 91497-5808  max 98607-6138
```

**O perfil aponta os problemas sem dar nome a eles.** `total_cents` está 5,0% nulo, um valor em
vinte; o mínimo é -500, que nenhum preço deveria ser; `order_id` tem 19 valores distintos em 20
linhas, então um id se repete; e o maior `phone` vem depois de todo número que começa com `+`, que é o
que um telefone sem o código do país faz. Uma pessoa lendo isso escreve as regras:

```
ana@laptop:~/gcp$ python3 scan.py quality orders.csv
FAIL  order_id is unique         18/20 = 90.0%, threshold 100%
FAIL  total_cents is not null    19/20 = 95.0%, threshold 100%
PASS  total_cents in 1..500000   18/20 = 90.0%, threshold 90%
PASS  phone looks Brazilian      19/20 = 95.0%, threshold 95%
2 of 4 rules passed
```

**Duas regras reprovaram e duas passaram, e as duas que passaram o fizeram exatamente no limite.** A
regra de unicidade achou 18 de 20 linhas únicas, porque o `o-10014` repetido faz duas linhas que não
são, e com limite de 100% isso reprova. A regra de não nulo achou 19 de 20 e reprova pelo mesmo
motivo. A regra de faixa passou com 90% porque o limite dela é 90%: o total nulo e o -500 falharam na
condição, e duas falhas em vinte eram permitidas. **A regra do telefone passou com 95% tendo um número
ruim.** É o limite fazendo o que foi configurado para fazer, e é também como um declínio lento passa
despercebido, e é por isso que os resultados de uma varredura são guardados e comparados de uma noite
para a outra, e não só lidos como aprovado ou reprovado.

## Quanto custam as varreduras de verdade

**Os dois tipos de varredura são cobrados como processamento premium do Dataplex**, em DCU-hora, uma
unidade que a página chama de abstrata: o que uma varredura consome depende das linhas, das colunas,
dos bytes que ela lê e das regras, e a página não dá um número fixo por varredura. De
cloud.google.com/dataplex/pricing, lido em 2026-10-30, São Paulo: **US$ 0,141282 por DCU-hora** para o
processamento premium, e US$ 0,095246 para o processamento standard, o nível que cobre a descoberta. A
cobrança é por segundo com mínimo de um minuto por varredura, e o nível standard tem 100 DCU-horas por
mês grátis, o premium nenhuma. Se uma varredura noturna dos pedidos da Quitanda levasse meia DCU-hora,
uma suposição e não um número da página:

```
ana@laptop:~/gcp$ python3 -c 'print(round(0.5 * 30 * 0.141282, 2))'
2.12
```

**Uns 2,12 dólares por mês para uma tabela varrida toda noite.** As alavancas que a página cita são as
mesmas que barateiam a varredura em qualquer lugar: varrer só as linhas novas com a opção incremental,
filtrar linhas, amostrar uma porcentagem, e varrer só as colunas que têm regras. Uma varredura que lê
uma tabela particionada inteira toda noite para julgar um dia dela paga por todos os dias a cada vez.
