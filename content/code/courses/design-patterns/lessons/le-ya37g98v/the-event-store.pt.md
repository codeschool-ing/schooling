---
title: "O event store: uma tabela que só cresce"
version: 1
---

**Um event store é uma lista de eventos que só recebe acréscimos, agrupada em streams, um stream por
coisa cujo histórico você guarda, com um número de versão por stream que faz escritores
concorrentes descobrirem uns aos outros.** É só isso. Produtos como o EventStoreDB acrescentam
assinaturas, cluster e ferramentas, e muitos sistemas guardam seus eventos numa tabela comum do
PostgreSQL; por baixo, os dois são a tabela abaixo.

O erro a evitar é tratar o store como uma fila de mensagens. Uma fila esquece a mensagem depois de
entregá-la. Um store guarda todo evento enquanto o sistema existir, porque os eventos são os dados:
apague um e o saldo de algum membro muda em silêncio.

```schooling-example
{"language": "python", "file": "store.py", "parts": [
 {"code": "# store.py\nimport json\nimport sqlite3\n\n\nclass ConcurrencyError(Exception):\n    pass", "note": "SQLite e JSON, os dois na biblioteca padrão. A única exceção que o store lança é própria, para quem chama distinguir um conflito de qualquer outro erro de banco."},
 {"code": "\n\nclass EventStore:\n    def __init__(self, path: str):\n        self.db = sqlite3.connect(path)\n        self.db.executescript(\"\"\"\n            CREATE TABLE IF NOT EXISTS events (\n                position INTEGER PRIMARY KEY AUTOINCREMENT,\n                stream TEXT NOT NULL,\n                version INTEGER NOT NULL,\n                type TEXT NOT NULL,\n                data TEXT NOT NULL,\n                UNIQUE (stream, version));", "note": "Uma tabela. `position` ordena todos os eventos do store; `stream` e `version` ordenam os eventos de uma coisa, aqui um membro. `UNIQUE (stream, version)` é todo o controle de concorrência, como o fim do programa mostra."},
 {"code": "            CREATE TRIGGER IF NOT EXISTS events_are_history\n                BEFORE UPDATE ON events\n                BEGIN SELECT RAISE(ABORT, 'events are append-only'); END;\n            CREATE TRIGGER IF NOT EXISTS events_stay\n                BEFORE DELETE ON events\n                BEGIN SELECT RAISE(ABORT, 'events are append-only'); END;\"\"\")", "note": "Só acréscimos como promessa do banco, não como hábito do código: um `UPDATE` ou um `DELETE` nesta tabela é recusado venha de quem vier, inclusive de um script digitado num prompt."},
 {"code": "\n    def version(self, stream: str) -> int:\n        row = self.db.execute(\"SELECT max(version) FROM events WHERE stream = ?\", (stream,)).fetchone()\n        return row[0] or 0", "note": "A versão de um stream é o número de eventos nele."},
 {"code": "\n    def append(self, stream: str, expected: int, events: list[dict]) -> None:\n        try:\n            with self.db:\n                for i, event in enumerate(events, start=expected + 1):\n                    data = {k: v for k, v in event.items() if k != \"type\"}\n                    self.db.execute(\"INSERT INTO events (stream, version, type, data) VALUES (?, ?, ?, ?)\",\n                                    (stream, i, event[\"type\"], json.dumps(data)))\n        except sqlite3.IntegrityError:\n            raise ConcurrencyError(f\"{stream} is past version {expected}\") from None", "note": "Acrescentar diz qual versão quem chama viu por último. Se outra pessoa acrescentou nesse meio-tempo, o próximo número de versão já está ocupado, o insert bate na restrição de unicidade, e o lote inteiro é desfeito pelo `with self.db`. É concorrência otimista: nada é travado, e quem perde fica sabendo."},
 {"code": "\n    def read(self, stream: str, after: int = 0) -> list[dict]:\n        rows = self.db.execute(\"SELECT type, data FROM events WHERE stream = ? AND version > ?\"\n                               \" ORDER BY version\", (stream, after))\n        return [{\"type\": t, **json.loads(d)} for t, d in rows]", "note": "Ler um stream, opcionalmente depois de uma versão, o que a seção de snapshots usa."},
 {"code": "\n    def read_all(self, after: int = 0) -> list[tuple[int, dict]]:\n        rows = self.db.execute(\"SELECT position, stream, type, data FROM events\"\n                               \" WHERE position > ? ORDER BY position\", (after,))\n        return [(p, {\"type\": t, \"stream\": s, **json.loads(d)}) for p, s, t, d in rows]", "note": "Ler todos os streams na ordem em que as coisas aconteceram, a partir de uma posição. Projeções leem assim."},
 {"code": "\n\nif __name__ == \"__main__\":\n    store = EventStore(\":memory:\")\n    store.append(\"member-bia\", 0, [\n        {\"type\": \"MemberJoined\", \"name\": \"Bia\", \"on\": \"2026-03-01\"},\n        {\"type\": \"CopyLent\", \"copy\": \"C3\", \"title\": \"T2\", \"due\": \"2026-03-16\"},\n    ])\n    store.append(\"member-bia\", 2, [\n        {\"type\": \"CopyReturned\", \"copy\": \"C3\", \"on\": \"2026-03-19\", \"fine\": 150},\n    ])\n    for event in store.read(\"member-bia\"):\n        print(event)\n    print(\"version:\", store.version(\"member-bia\"))\n    try:\n        store.append(\"member-bia\", 2, [{\"type\": \"FinePaid\", \"amount\": 150}])\n    except ConcurrencyError as err:\n        print(\"refused:\", err)\n    try:\n        store.db.execute(\"UPDATE events SET data = '{}' WHERE version = 3\")\n    except sqlite3.DatabaseError as err:\n        print(\"refused:\", err)", "note": "Dois acréscimos ao stream da Bia, a leitura de volta, e depois duas coisas que o store recusa: um acréscimo de quem viu a versão 2 depois que ela virou 3, e uma edição do histórico. O store fica em memória, então o programa pode rodar de novo e de novo; dê a ele um nome de arquivo e ele guarda os eventos."}
]}
```

```
ana@laptop:~/patterns/events$ python3 store.py
{'type': 'MemberJoined', 'name': 'Bia', 'on': '2026-03-01'}
{'type': 'CopyLent', 'copy': 'C3', 'title': 'T2', 'due': '2026-03-16'}
{'type': 'CopyReturned', 'copy': 'C3', 'on': '2026-03-19', 'fine': 150}
version: 3
refused: member-bia is past version 2
refused: events are append-only
```

Os três eventos voltam em ordem, como dicionários com seu tipo. O stream da Bia está na versão 3.
Depois vêm as duas recusas: um acréscimo que esperava a versão 2 perdeu a corrida, e o `UPDATE` foi
barrado pelo trigger com a frase que lhe deram.

## Um stream por coisa

Quais eventos andam juntos é uma decisão de projeto. Aqui o stream é um membro, `member-bia`, porque
as regras que esta lição confere são sobre um membro: o que ela tem e o que ela deve. Uma biblioteca
poderia também manter um stream por exemplar, ou pela fila de reservas de cada título. **O stream é
a fronteira de uma decisão**: toda regra que precisa ver um conjunto consistente de fatos lê um
stream e acrescenta a ele com uma versão esperada. A lição 12 chama essa fronteira de agregado e
discute onde traçá-la; esta lição toma os membros como fronteira e segue em frente.

## Concorrência otimista, pela restrição de unicidade

Dois atendentes servem a Bia ao mesmo tempo. Os dois leem o stream dela na versão 2, os dois decidem
que ela pode pegar o livro, os dois acrescentam. Sem verificação, ela acaba com um empréstimo que as
regras teriam recusado. Com a verificação, o primeiro acréscimo grava a versão 3; o segundo tenta
gravar a versão 3 também, o índice único recusa, e esse atendente recebe `ConcurrencyError`. **Quem
perdeu relê o stream, que agora contém o empréstimo do outro atendente, e roda as regras de novo.**
Nada ficou travado enquanto os dois decidiam.

É o mesmo compare-and-set que a lição 8 disse que um comando pode legitimamente combinar com uma
resposta: a verificação e a escrita acontecem numa instrução só, então nada consegue passar entre
elas.

## Na sua linguagem

| | como o mesmo store costuma ser escrito |
|---|---|
| Java | uma entidade JPA ou JDBC puro sobre PostgreSQL, com a mesma restrição de unicidade; ou o cliente do EventStoreDB, cujo `appendToStream` recebe uma revisão esperada |
| Go | `database/sql` com a mesma tabela; o código de erro de violação de unicidade mapeado para um sentinela `ErrConcurrency` |
| TypeScript | um cliente PostgreSQL para Node e o mesmo `INSERT`; o código de erro `23505` é a violação de unicidade |
| Python | a tabela acima, ou o mesmo SQL contra PostgreSQL com `psycopg` |

Em todas as linhas a garantia vem do índice único do banco, não da linguagem. É de propósito: uma
verificação no código da aplicação seria a corrida de ler-depois-escrever da seção de comando e
consulta da lição 8.
