---
title: Uma chave de linha para o fluxo de cliques
version: 1
---

**No Bigtable a chave de linha é o único índice, então ela é projetada a partir das perguntas, não dos
dados.** A aula 10 encontrou a mesma inversão nos índices do Firestore, e o gêmeo dela em todo banco
lido por chave: escreva o que vai ser perguntado, com as entradas e o tamanho, e construa a chave de
modo que cada pergunta seja uma sequência contínua de linhas. Uma pergunta que a chave não consegue
transformar numa sequência é uma leitura da tabela inteira.

**O app da Quitanda envia um fluxo de cliques**: cada tela que um cliente abre, com o produto que está
nela, uns quarenta milhões de eventos num dia movimentado. O time de suporte e o serviço de
recomendação fazem três perguntas a ele:

| | a pergunta | recebe | devolve |
|---|---|---|---|
| C1 | os eventos mais recentes de um cliente, do mais novo para o mais antigo | o id do cliente | algumas dezenas de linhas |
| C2 | os eventos de um cliente numa janela de tempo | o id e dois horários | até algumas centenas |
| C3 | todos os eventos do último minuto, de todos os clientes | um horário | dezenas de milhares |

C1 e C2 partem de um cliente. C3 não, e é a que esta seção deixa sem resposta de propósito: uma
pergunta sobre todo mundo de uma vez é uma agregação, e as aulas 13 e 21 a põem no BigQuery e no
Dataflow, alimentados pelo mesmo fluxo. A seção depois desta mostra o que acontece com uma tabela que
tenta responder C3 com a chave.

## cliente#timestamp-invertido

**A chave é o cliente, um separador, e o horário subtraído de uma constante grande.**
`c-17#8207812731000` é o cliente c-17 às 18:47:49 de 16 de outubro: o horário do evento em
milissegundos desde 1970 é 1792187269000, e `10**13` menos isso é o número depois do `#`, completado
até 13 dígitos. Cada pedaço tem sua razão:

- **O cliente primeiro**, para que todas as linhas de um cliente fiquem vizinhas e C1 e C2 nomeiem
  uma sequência contínua. A documentação de esquema do Google chama isso de **promoção de campo**
  (field promotion): um campo que seria uma coluna é levado para a chave, à frente do timestamp,
  porque as leituras partem dele.
- **O `#` depois dele**, para que o prefixo de c-17 não seja também o prefixo de c-170. O bloco abaixo
  mede quanto custa esquecê-lo.
- **O horário invertido**, para que o evento mais novo tenha o menor número e venha primeiro. As
  linhas são lidas na ordem da chave, e C1 quer o mais novo primeiro.
- **Uma largura fixa**, 13 dígitos, porque a ordem é a dos bytes, e `999` vem depois de `1000` como
  texto.

**Uma linha por evento é o projeto alto (tall)**, e é o que o Google recomenda para séries temporais.
A alternativa larga é uma linha por cliente com um qualificador por evento, e ela falha devagar. A
linha cresce enquanto o cliente usar o app, e uma linha tem limite de 256 MB, com o Google
recomendando menos de 100 MB. E uma escrita numa linha é uma escrita num lugar só, por mais células
que acrescente.

## Carregando

A tabela tem uma família, `ev`, que guarda uma versão por coluna, porque um evento é escrito uma vez
e nunca muda:

```
ana@laptop:~/gcp$ cbt createtable clicks families=ev:maxversions=1
ana@laptop:~/gcp$ cbt ls clicks
Family Name	GC Policy		Value Type
-----------	---------		----------
ev		versions() > 1		{}
```

**Os dados vêm de um programa curto** escrito com `google-cloud-bigtable`, a biblioteca Python da
aula 1. Salve como `~/gcp/clicks.py`: o botão de copiar do bloco, depois `nano clicks.py`, colar,
Ctrl+O, Enter e Ctrl+X.

```schooling-example
{"language": "python", "file": "clicks.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Quitanda's app click stream, written to the Bigtable table `clicks`.\n\n    python3 clicks.py load            # three customers, one evening of events\n    python3 clicks.py load 2000       # two thousand customers\n    python3 clicks.py key c-17 18:30  # the row key of c-17 at 18:30\n\nThe same number always writes the same rows. The table must exist, with a family `ev`.\n\"\"\"\nimport random\nimport sys\nfrom datetime import datetime, timedelta, timezone\n\nfrom google.cloud.bigtable.data import BigtableDataClient, RowMutationEntry, SetCell\n\n", "note": "A docstring diz como rodar. **`BigtableDataClient` é o cliente de dados da biblioteca**, a metade que lê e escreve linhas; tabelas e famílias são da API de administração, e é por isso que a tabela é criada antes com o `cbt`."}, {"code": "SAO_PAULO = timezone(timedelta(hours=-3))\nEVENING = datetime(2026, 10, 16, 18, 0, tzinfo=SAO_PAULO)\nSCREENS = ['home', 'search', 'product', 'cart', 'checkout']\nSKUS = ['banana', 'tomato', 'rice-5kg', 'coffee-500g', 'eggs-12', 'milk-1l']\n\n", "note": "O material de onde o gerador tira os dados. Os horários estão no fuso de São Paulo, fixo em três horas atrás do UTC, para que as chaves e os timestamps que o `cbt` imprime batam com o texto."}, {"code": "def key(customer, when):\n    millis = int(when.timestamp() * 1000)\n    return f'{customer}#{10**13 - millis:013d}'\n\n", "note": "**O projeto inteiro está nestas três linhas.** O cliente, um `#`, e o horário em milissegundos subtraído de `10**13`, completado até 13 dígitos para que a ordem dos bytes e a ordem numérica coincidam."}, {"code": "if sys.argv[1] == 'key':\n    hour, minute = map(int, sys.argv[3].split(':'))\n    print(key(sys.argv[2], EVENING.replace(hour=hour, minute=minute)))\n    sys.exit()\n\n", "note": "`key` sozinho imprime uma chave de linha para um horário da noite de 16 de outubro, que é como as leituras por intervalo desta seção calculam onde começar e onde parar."}, {"code": "customers = int(sys.argv[2]) if len(sys.argv) > 2 else 3\nrnd = random.Random(17)\nentries = []\n", "note": "Três clientes por padrão, começando em c-17. Um `Random` com semente faz cada execução escrever as mesmas linhas, e é isso que permite a esta aula imprimi-las."}, {"code": "for n in range(customers):\n    cid = f'c-{17 + n}'\n    when = EVENING + timedelta(seconds=rnd.randint(0, 3000))\n    for _ in range(rnd.randint(3, 6)):\n        when += timedelta(seconds=rnd.randint(5, 240))\n        micros = int(when.timestamp()) * 1_000_000\n        entries.append(RowMutationEntry(key(cid, when), [\n            SetCell('ev', 'screen', rnd.choice(SCREENS), micros),\n            SetCell('ev', 'sku', rnd.choice(SKUS), micros)]))\n\n", "note": "De três a seis eventos por cliente, com intervalos de alguns segundos a quatro minutos. **Cada evento é uma linha**, com duas células na família `ev`, e as duas levam o horário do próprio evento como timestamp, em microssegundos e num número inteiro de segundos."}, {"code": "with BigtableDataClient(project='planner-dev') as client:\n    client.get_table('quitanda', 'clicks').bulk_mutate_rows(entries)\nprint(f'{customers} customers, {len(entries)} events written to clicks')\n", "note": "`bulk_mutate_rows` manda todas as linhas num lote de mutações; cada linha é aplicada de forma atômica e por conta própria, então uma falha é informada por linha, e não para o lote inteiro."}]}
```

```
ana@laptop:~/gcp$ python3 clicks.py load
/home/ana/gcp/clicks.py:43: RuntimeWarning: Connecting to Bigtable emulator at localhost:8086
  with BigtableDataClient(project='planner-dev') as client:
3 customers, 15 events written to clicks
```

**As duas primeiras linhas são a biblioteca dizendo para onde foi**: um `RuntimeWarning` de que ela
achou `BIGTABLE_EMULATOR_HOST` e se conectou ao emulador. Contra o Google ele não aparece. Quinze
eventos, e as chaves deles:

```
ana@laptop:~/gcp$ cbt read clicks columns=ev:screen | grep '^"'
"c-17#8207812731000"
"c-17#8207812843000"
"c-17#8207812911000"
"c-17#8207812987000"
"c-17#8207813172000"
"c-17#8207813251000"
"c-18#8207813469000"
"c-18#8207813637000"
"c-18#8207813780000"
"c-18#8207813990000"
"c-18#8207814220000"
"c-18#8207814260000"
"c-19#8207813418000"
"c-19#8207813630000"
"c-19#8207813788000"
```

**As linhas estão na ordem da chave, e por isso os eventos de cada cliente vêm do mais novo para o
mais antigo.** A primeira linha de c-17 é `…2731000`, às 18:47:49, e a última é `…3251000`, às
18:39:09. Os clientes não se intercalam pelo horário; os eventos de c-19 vêm depois dos de c-18 embora
alguns tenham acontecido antes, porque `c-18#` vem antes de `c-19#` seja o que for que venha depois.

## As duas leituras para as quais a chave foi feita

**C1 é um prefixo com uma contagem, e C2 é um intervalo.** No intervalo, o início e o fim também são
chaves, então `clicks.py key` as calcula; com o horário invertido, o momento mais tarde é o início:

```
ana@laptop:~/gcp$ cbt read clicks prefix=c-17# count=2
----------------------------------------
"c-17#8207812731000"
  "ev:screen"                              @ 2026/10/16-18:47:49.000000
    "product"
  "ev:sku"                                 @ 2026/10/16-18:47:49.000000
    "eggs-12"

----------------------------------------
"c-17#8207812843000"
  "ev:screen"                              @ 2026/10/16-18:45:57.000000
    "cart"
  "ev:sku"                                 @ 2026/10/16-18:45:57.000000
    "milk-1l"

ana@laptop:~/gcp$ python3 clicks.py key c-17 18:46
c-17#8207812840000
ana@laptop:~/gcp$ cbt read clicks start=$(python3 clicks.py key c-17 18:46) end=$(python3 clicks.py key c-17 18:40) columns=ev:screen
----------------------------------------
"c-17#8207812843000"
  "ev:screen"                              @ 2026/10/16-18:45:57.000000
    "cart"

----------------------------------------
"c-17#8207812911000"
  "ev:screen"                              @ 2026/10/16-18:44:49.000000
    "home"

----------------------------------------
"c-17#8207812987000"
  "ev:screen"                              @ 2026/10/16-18:43:33.000000
    "checkout"

----------------------------------------
"c-17#8207813172000"
  "ev:screen"                              @ 2026/10/16-18:40:28.000000
    "search"
```

**`prefix=c-17# count=2` é C1**: os dois eventos mais recentes, na ordem em que estão guardados, sem
ler mais nada. **O intervalo é C2**: da chave de 18:46 até a chave de 18:40, sem incluí-la, o que dá
os quatro eventos entre 18:40 e 18:46, do mais novo para o mais antigo. `end` é exclusivo, como um
intervalo de chaves costuma ser no Bigtable, e é por isso que uma janela que precisa incluir o próprio
18:40 termina um milissegundo antes na chave, na chave de 18:39:59.999.

## O separador, medido

**Com dois mil clientes, o prefixo sem o `#` lê cento e onze clientes.** O mesmo programa, a mesma
semente, um número maior:

```
ana@laptop:~/gcp$ python3 clicks.py load 2000
/home/ana/gcp/clicks.py:43: RuntimeWarning: Connecting to Bigtable emulator at localhost:8086
  with BigtableDataClient(project='planner-dev') as client:
2000 customers, 8999 events written to clicks
ana@laptop:~/gcp$ cbt count clicks
8999
ana@laptop:~/gcp$ cbt read clicks prefix=c-17 columns=ev:screen | grep -c '^"'
497
ana@laptop:~/gcp$ cbt read clicks prefix=c-17# columns=ev:screen | grep -c '^"'
6
```

**8.999 linhas.** `prefix=c-17` casou com c-17, de c-170 a c-179 e de c-1700 a c-1799, 497 linhas que
teriam chegado à tela de um atendente como o histórico de c-17. `prefix=c-17#` casou com as seis que
são. Nada falhou, e a resposta errada parece um cliente muito ativo. Ids de largura fixa, `c-00017`,
são o outro conserto, e o separador custa um byte.

## O que um filtro não economiza

**`include-stats=full` pergunta ao servidor quanto uma leitura custou**, e é como distinguir uma
sequência de chaves de um scan com um filtro por cima:

```
ana@laptop:~/gcp$ cbt read clicks prefix=c-17# include-stats=full | tail -7
====================
rows_seen_count: 6
rows_returned_count: 6
cells_seen_count: 12
cells_returned_count: 12
frontend_server_latency: 0ms

ana@laptop:~/gcp$ cbt read clicks regex='c-17#.*' include-stats=full | tail -7
====================
rows_seen_count: 8999
rows_returned_count: 6
cells_seen_count: 17998
cells_returned_count: 12
frontend_server_latency: 96ms

ana@laptop:~/gcp$ cbt read clicks prefix=c-17# reversed=true count=1
----------------------------------------
"c-17#8207813251000"
  "ev:screen"                              @ 2026/10/16-18:39:09.000000
    "product"
  "ev:sku"                                 @ 2026/10/16-18:39:09.000000
    "rice-5kg"
```

**As mesmas seis linhas, e a segunda leitura olhou as 8.999 para achá-las.** Um `regex` na chave de
linha é um filtro: o servidor percorre cada linha do intervalo que recebeu, aqui a tabela inteira, e
devolve as que casam. O `prefix` disse a ele onde começar e onde parar. No emulador a diferença é de
96 milissegundos; numa tabela de quarenta milhões de linhas por dia é a tabela inteira a cada chamada,
em nós que a próxima seção põe preço.

**E a direção é escolha da leitura.** `reversed=true` lê um intervalo a partir do fim, então o mais
antigo dos eventos de c-17 vem primeiro. O Bigtable ganhou leitura reversa em 2024, e o emulador a
atende. Antes disso, um timestamp invertido era o único jeito de ler do mais novo para o mais antigo;
hoje continua sendo o jeito mais barato para uma leitura que sempre quer o mais novo primeiro, e o
horário normal com `reversed=true` serve a uma tabela lida nos dois sentidos.
