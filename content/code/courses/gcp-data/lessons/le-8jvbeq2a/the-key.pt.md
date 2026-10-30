---
title: A chave primária, e o hotspot que um contador cria
version: 1
---

**O Spanner mantém toda tabela ordenada pela chave primária e a corta em faixas de chaves, chamadas
splits, que ele espalha pelos seus servidores.** Um split é uma sequência contígua de linhas, de uma
chave a outra, e cada split é atendido por um servidor de cada vez, que recebe as escritas dele. Quando
um split fica grande ou ocupado demais, o Spanner o corta em dois e pode levar as metades para
servidores diferentes. É assim que um banco se espalha por muitas máquinas: por faixa de chave, com as
fronteiras escolhidas e movidas pelo Spanner, sozinho, conforme os dados e a carga mudam.

**A ideia errada é que qualquer chave única serve, como serve no PostgreSQL.** Num banco de um
servidor, uma chave que conta, 1, 2, 3, é a melhor chave que existe: compacta, ordenada e barata de
indexar. No Spanner é a pior. Toda linha nova tem uma chave maior que todas as existentes, então toda
inserção cai bem no fim da tabela, no último split, num servidor, enquanto os outros esperam trabalho.
Isso é um **hotspot**, e ele limita a taxa de escrita da tabela inteira ao que um servidor aguenta, por
mais nós que a instância pague.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Uma tabela cortada em quatro splits por faixa de chave, cada um atendido por um servidor diferente, de A a D. Em cima, com um contador como chave, toda linha nova tem a maior chave e todas chegam ao split 4, no servidor D, enquanto A, B e C não recebem escrita. Embaixo, com um UUID ou uma sequência bit-reversed, as linhas novas chegam aos quatro splits.\" data-fig=\"l09-hotspot\"><defs><marker id=\"ah-l09-hotspot\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">chave = um contador: 1, 2, 3 …</text><rect x=\"30\" y=\"60\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"107\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 1</text><text x=\"107\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">servidor A</text><rect x=\"195\" y=\"60\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"272\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 2</text><text x=\"272\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">servidor B</text><rect x=\"360\" y=\"60\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 3</text><text x=\"437\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">servidor C</text><rect x=\"525\" y=\"60\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"602\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 4</text><text x=\"602\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">servidor D</text><line x1=\"560\" y1=\"140\" x2=\"560\" y2=\"110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><line x1=\"582\" y1=\"140\" x2=\"582\" y2=\"110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><line x1=\"604\" y1=\"140\" x2=\"604\" y2=\"110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><line x1=\"626\" y1=\"140\" x2=\"626\" y2=\"110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><text x=\"30\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">menores chaves</text><text x=\"690\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">toda linha nova: a maior chave, um servidor</text><text x=\"30\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">chave = UUID v4 ou sequência bit-reversed</text><rect x=\"30\" y=\"205\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"107\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 1</text><text x=\"107\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">servidor A</text><rect x=\"195\" y=\"205\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"272\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 2</text><text x=\"272\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">servidor B</text><rect x=\"360\" y=\"205\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 3</text><text x=\"437\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">servidor C</text><rect x=\"525\" y=\"205\" width=\"155\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">split 4</text><text x=\"602\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">servidor D</text><line x1=\"107\" y1=\"285\" x2=\"107\" y2=\"255\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><line x1=\"272\" y1=\"285\" x2=\"272\" y2=\"255\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><line x1=\"437\" y1=\"285\" x2=\"437\" y2=\"255\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><line x1=\"602\" y1=\"285\" x2=\"602\" y2=\"255\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l09-hotspot)\"></line><text x=\"360\" y=\"297\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">as linhas novas caem em todo split</text></svg>", "caption": "Os mesmos quatro splits, dois tipos de chave. Qual split atende quais chaves está desenhado só para ilustrar; o emulador não tem split nenhum.", "same": ["split 1", "split 2", "split 3", "split 4"]}
```

## Medido na ordem das chaves, que é de onde os splits são cortados

**O emulador não tem splits**, então o que dá para medir aqui é aquilo de que os splits são cortados: a
ordem das chaves. O programa abaixo grava 800 linhas em cada uma das três tabelas só de chave do
schema, depois mais 200, e pergunta onde as 200 linhas novas ficam na ordem da tabela, quarto por
quarto. No Spanner os quartos seriam as vizinhanças que splits diferentes cobrem, e a pergunta é se as
linhas novas caem em todos eles ou num só.

```schooling-example
{"language": "python", "file": "keys.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Where do new rows land in a table's key order? Three tables, three kinds of key.\n\nEach table gets 800 rows, then 200 more, and the program counts how many of the\n200 fall in each quarter of the table's key order as it stands afterwards.\n\"\"\"\nfrom google.cloud import spanner\n\ndb = spanner.Client(project='planner-dev').instance('quitanda').database('shop')\n\n", "note": "O cliente acha o emulador por `SPANNER_EMULATOR_HOST`, das variáveis da aula 1, e a instância e o banco são os que a seção anterior criou."}, {"code": "NEXT_KEY = {\n    'ByCounter': 'n',\n    'ByUuid': 'GENERATE_UUID()',\n    'BySequence': 'GET_NEXT_SEQUENCE_VALUE(SEQUENCE OrderSeq)',\n}\n\n", "note": "**Os três tipos de chave, como expressões SQL.** `n` é o próprio contador, de 1 a 1.000. `GENERATE_UUID()` é o UUID versão 4 do Spanner. A sequência é a bit-reversed que o schema declarou."}, {"code": "def insert(table, first, last):\n    sql = (f'INSERT INTO {table} (Id) SELECT {NEXT_KEY[table]} '\n           f'FROM UNNEST(GENERATE_ARRAY({first}, {last})) AS n THEN RETURN Id')\n    return db.run_in_transaction(lambda t: [row[0] for row in t.execute_sql(sql)])\n\n", "note": "**Um `INSERT … SELECT` grava um lote inteiro**, uma linha por número de `GENERATE_ARRAY`, e `THEN RETURN Id` devolve as chaves que gravou. DML roda dentro de uma transação de leitura e escrita, que `run_in_transaction` abre e confirma."}, {"code": "for table in NEXT_KEY:\n    insert(table, 1, 800)\n    new = set(insert(table, 801, 1000))\n    with db.snapshot() as snap:\n        keys = [row[0] for row in snap.execute_sql(f'SELECT Id FROM {table} ORDER BY Id')]\n    quarters = [sum(k in new for k in keys[q * 250:(q + 1) * 250]) for q in range(4)]\n    print(f'{table:<11} lowest key {str(keys[0]):<36}  new rows per quarter {quarters}')\n", "note": "**800 linhas antigas, depois 200 novas**, depois a tabela inteira em ordem de chave, que é a ordem em que o Spanner a guarda. Cada quarto são 250 chaves seguidas, e a contagem é quantas linhas novas caíram nele."}]}
```

```
ana@laptop:~/gcp$ python3 keys.py
ByCounter   lowest key 1                                     new rows per quarter [0, 0, 0, 200]
ByUuid      lowest key 00001fbc-2bb1-4ca4-a8e9-776be37d8b7c  new rows per quarter [49, 54, 48, 49]
BySequence  lowest key 9007199254740992                      new rows per quarter [50, 50, 50, 50]
```

**O contador pôs as 200 linhas novas no último quarto**, depois de toda chave que existia. As outras
duas as espalharam pelos quatro. Um UUID versão 4 são 122 bits aleatórios, então as linhas novas dele
caem onde o acaso mandar, e as contagens mudam um pouco a cada execução. Uma **sequência bit-reversed**
é um contador cujos bits são escritos na ordem inversa, de modo que números seguidos caem longe um do
outro: 1, 2 e 3 viram números no meio da faixa, a um quarto do caminho e a três quartos. Valores
seguidos se espalham por igual por construção, que são os 50, 50, 50, 50.

## As três saídas, e quanto cada uma custa

| chave | onde as linhas novas caem | quanto custa |
|---|---|---|
| um contador, ou um timestamp primeiro | o fim da tabela, um split | a taxa de escrita de um servidor |
| um UUID versão 4, `GENERATE_UUID()` | em qualquer lugar | 36 bytes como texto, e nenhuma ordem para ler |
| uma sequência bit-reversed | espalhadas por igual | um número que não significa nada, também sem ordem |

**As duas saídas abrem mão da ordem de criação**, e essa é a troca. Uma consulta pelos "últimos
pedidos" não pode mais ler o fim da faixa de chaves; ela precisa de um índice numa coluna como `Day`,
que é uma segunda tabela que o Spanner mantém ordenada por essa coluna. Um índice cuja chave começa
com um timestamp é um hotspot próprio, então a página "Schema design best practices" do Google sugere
pôr algo antes do timestamp num índice também, como o cliente.

**A outra saída é escolher uma chave que não seja a ordem de criação.** A tabela `Orders` da Quitanda
tem chave `(CustomerId, OrderId)`, então a primeira parte da chave é o cliente: pedidos de muitos
clientes caem em muitos lugares, e os pedidos de um cliente ficam juntos, o que a próxima seção
transforma em vantagem. Nesta aula `CustomerId` é um `c-17` legível; em produção seria um UUID, para
que os clientes novos também se espalhem.

**O emulador não consegue mostrar nada disso dando errado.** Um hotspot é uma medida da carga num
servidor, e há um servidor e nenhuma carga. No Google Cloud, o Key Visualizer do console desenha as
faixas de chave de uma tabela ao longo do tempo, coloridas pelo quanto cada uma está ocupada, e uma
chave de contador aparece lá como uma linha clara ao longo da borda de cima. Essa é a ferramenta para
olhar numa instância real, e ela não foi usada aqui.
