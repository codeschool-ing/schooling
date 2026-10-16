---
title: Bancos de dados, e a cópia que não enxerga uma remoção
version: 1
---

**O banco do aplicativo é a fonte mais valiosa da Roda Livre e a que mais facilmente se machuca ao ser
lida.** Ele atende o app: iniciar uma viagem, encerrar uma viagem, cobrar um cartão. Milhares de
operações pequenas por dia, cada uma mexendo em poucas linhas e cada uma esperada de volta em
milissegundos. Um banco feito para isso se chama **OLTP**, de processamento de transações online, e
quase todo banco de aplicação é um.

Uma pergunta analítica tem o formato oposto. "Viagens por estação por hora desde janeiro" é uma
consulta que lê todas as linhas da tabela de viagens. A imagem errada é a de que ler é inofensivo
porque não muda nada. Uma consulta que lê todas as linhas ocupa disco, memória e processador que o app
estava usando, e o cliente tentando destravar uma bicicleta na Rua XV espera enquanto ela roda. No
PostgreSQL, que é o banco do app da Roda Livre, uma leitura que fica aberta por uma hora também impede o
banco de limpar as versões antigas das linhas, e as tabelas crescem até a leitura acabar.

Por isso a primeira regra não tem exceção na Roda Livre: **analytics nunca consulta o primário**, a
cópia do banco em que o app escreve. Há dois jeitos de contornar. Uma **réplica de leitura** é uma
segunda cópia que o banco mantém atualizada justamente para isso, alguns segundos atrás do primário; a
aula 9 explica por que ela fica atrás. Ou a cópia é tirada num horário calmo. De um jeito ou de outro, o
time de dados lê uma cópia e o app fica com o banco só para ele.

## Completa ou incremental

Uma cópia pode ser feita de dois jeitos, e a diferença é o que cada um consegue ver.

- Uma **cópia completa** lê todas as linhas, toda vez, e substitui o que tinha sido copiado antes. É
  simples e está sempre certa: o que a fonte tem, a cópia tem. E custa um pouco mais a cada dia que a
  tabela cresce.
- Uma **cópia incremental** lê só as linhas que mudaram desde a última. Ela precisa de uma coluna que o
  app atualize a cada mudança, em geral `updated_at`, e guarda o valor mais recente que já viu. Custa o
  mesmo com mil viagens na tabela ou com dez milhões.

Incremental é para onde todo mundo muda quando a cópia completa fica lenta, e ela tem um ponto cego que
se vê mais fácil construindo uma.

## Uma cópia que guarda uma viagem cancelada

No laboratório, o SQLite faz o papel do banco do app: é um arquivo, vem dentro do Python e fala SQL.
Crie o diretório dos programas desta aula e trabalhe nele:

```sh
mkdir -p ~/roda/sources
cd ~/roda/sources
```

O primeiro programa é o app às 09:00 de 15 de setembro, com quatro viagens, duas ainda abertas:

```python
# sources/app.py
import sqlite3

db = sqlite3.connect("app.db")
db.execute("DROP TABLE IF EXISTS rides")
db.execute("""CREATE TABLE rides (
    ride_id TEXT PRIMARY KEY, bike_id TEXT, station TEXT,
    status TEXT, updated_at TEXT)""")
db.executemany("INSERT INTO rides VALUES (?, ?, ?, ?, ?)", [
    ("R000101", "B017", "ST02", "finished", "2025-09-15 08:10"),
    ("R000102", "B044", "ST05", "finished", "2025-09-15 08:25"),
    ("R000103", "B081", "ST06", "open", "2025-09-15 08:40"),
    ("R000104", "B032", "ST02", "open", "2025-09-15 08:55"),
])
db.commit()
print("app.db holds", db.execute("SELECT count(*) FROM rides").fetchone()[0], "rides")
```

O segundo é o quarto de hora seguinte. Uma viagem aberta termina, uma nova começa, e um cliente cancela
a viagem `R000104` porque a bicicleta estava com o pneu furado. O app apaga viagens canceladas, uma
decisão que o time dele tomou por motivos próprios:

```python
# sources/later.py
import sqlite3

db = sqlite3.connect("app.db")
db.execute("""UPDATE rides SET status = 'finished', updated_at = '2025-09-15 09:05'
              WHERE ride_id = 'R000103'""")
db.execute("""INSERT INTO rides
              VALUES ('R000105', 'B060', 'ST10', 'open', '2025-09-15 09:12')""")
db.execute("DELETE FROM rides WHERE ride_id = 'R000104'")
db.commit()
print("one ride finished, one started, one cancelled and deleted")
```

O terceiro é a cópia incremental de Davi, para um segundo arquivo de banco que faz o papel do banco do
time de dados:

```schooling-example
{"language": "python", "file": "sources/incremental.py", "parts": [
{"code": "# sources/incremental.py\nimport sqlite3\n\nsrc = sqlite3.connect(\"app.db\")\ndst = sqlite3.connect(\"copy.db\")\ndst.execute(\"\"\"CREATE TABLE IF NOT EXISTS rides (\n    ride_id TEXT PRIMARY KEY, bike_id TEXT, station TEXT,\n    status TEXT, updated_at TEXT)\"\"\")\n", "note": "Duas conexões: `app.db` é a fonte, `copy.db` a cópia do time de dados. A tabela é criada na primeira vez e deixada em paz depois."},
{"code": "mark = dst.execute(\"SELECT max(updated_at) FROM rides\").fetchone()[0] or \"\"\n", "note": "A marca d'água: o `updated_at` mais recente que já está na cópia. Na primeira execução a cópia está vazia, o `max` devolve `None`, e o texto vazio vale por \"antes de tudo\"."},
{"code": "rows = src.execute(\"SELECT * FROM rides WHERE updated_at > ?\", (mark,)).fetchall()\ndst.executemany(\"INSERT OR REPLACE INTO rides VALUES (?, ?, ?, ?, ?)\", rows)\ndst.commit()\n", "note": "Só as linhas alteradas depois da marca d'água, gravadas por cima de qualquer versão antiga da mesma viagem. `INSERT OR REPLACE` é o jeito do SQLite de dizer \"insira, ou substitua a linha com esta chave\"."},
{"code": "print(f\"changed since '{mark}': {len(rows)} rows copied\")\n", "note": "O que esta execução copiou."},
{"code": "for name, db in ((\"app.db\", src), (\"copy.db\", dst)):\n    ids = [r[0] for r in db.execute(\"SELECT ride_id FROM rides ORDER BY ride_id\")]\n    print(f\"{name:7}  {len(ids)} rides  {' '.join(ids)}\")\n", "note": "E a comparação que a cópia nunca faz sozinha: as viagens de cada banco, lado a lado."}
]}
```

Rode o app, copie, deixe passar um quarto de hora, e copie de novo:

```
ana@lab:~/roda/sources$ python app.py
app.db holds 4 rides
ana@lab:~/roda/sources$ python incremental.py
changed since '': 4 rows copied
app.db   4 rides  R000101 R000102 R000103 R000104
copy.db  4 rides  R000101 R000102 R000103 R000104
ana@lab:~/roda/sources$ python later.py
one ride finished, one started, one cancelled and deleted
ana@lab:~/roda/sources$ python incremental.py
changed since '2025-09-15 08:55': 2 rows copied
app.db   4 rides  R000101 R000102 R000103 R000105
copy.db  5 rides  R000101 R000102 R000103 R000104 R000105
```

A primeira cópia levou as quatro viagens, porque nada tinha sido visto antes. A segunda pediu as linhas
alteradas depois de `08:55` e recebeu duas: a viagem que terminou e a nova. As duas estão certas.

Depois vêm as duas contagens. **O app tem quatro viagens e a cópia tem cinco.** A viagem `R000104` foi
apagada da fonte, e uma linha apagada não tem `updated_at` para ser mais nova que coisa alguma: ela
simplesmente não está lá para ser encontrada. A cópia vai guardá-la, aberta, enquanto a cópia existir.
Nada falhou, e todo número de viagens abertas construído sobre esta tabela agora está errado por uma.

Há três saídas, e cada uma custa alguma coisa. O app pode parar de apagar e marcar a viagem cancelada,
com uma coluna como `deleted_at`. Isso é uma **remoção lógica** (soft delete): transforma a remoção
numa atualização que a cópia enxerga, mas a mudança é do time do app. O time de dados pode tirar uma
cópia completa por semana e compará-la com a incremental; a aula 7 confere uma cópia contra a fonte. Ou
a cópia pode parar de ler a tabela e ler o registro que o próprio banco faz de cada mudança, que é a
próxima seção.

O mesmo ponto cego tem um gêmeo. Uma cópia incremental confia que o app preenche `updated_at` em toda
mudança; um trecho de código que esquece é uma mudança que a cópia nunca vê, e nada em lugar nenhum
avisa. A aula 7 trata da outra armadilha deste programa, uma mudança que é gravada tarde com um
`updated_at` mais antigo.
