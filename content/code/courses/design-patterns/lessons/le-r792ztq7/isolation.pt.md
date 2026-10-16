---
title: "Isolamento: dois balcões, um exemplar"
version: 1
---

**Isolamento é a letra sobre duas transações rodando ao mesmo tempo, e a falha que ele existe para
impedir tem nome: a atualização perdida.** Duas pessoas leem o mesmo valor, cada uma decide algo a
partir dele, e cada uma grava de volta um resultado. A segunda gravação substitui a primeira em
silêncio, e nenhuma das duas fez nada de errado sozinha.

A ideia errada aqui é achar que a atomicidade resolve. O trabalho de cada balcão no programa abaixo
é curto, e cada comando dá certo. A biblioteca termina mesmo assim com dois empréstimos para um
exemplar, porque o problema não é um comando que falha no meio. São dois trabalhos corretos que se
sobrepõem.

Sobrou um exemplar de *Vidas Secas*. Bia está no balcão A e Caio no balcão B, e os dois pedem o
livro no mesmo instante. O programa encena os dois balcões três vezes: sem transação, com um
`BEGIN` simples e com `BEGIN IMMEDIATE`:

```schooling-example
{"language": "python", "file": "desks.py", "parts": [
 {"code": "# desks.py\nimport os\nimport sqlite3\n\nPATH = \"desks.db\"\n\n\ndef fresh_library() -> None:\n    if os.path.exists(PATH):\n        os.remove(PATH)\n    db = sqlite3.connect(PATH, isolation_level=None)\n    db.executescript(\"\"\"\n        CREATE TABLE items (title TEXT PRIMARY KEY, available INTEGER NOT NULL);\n        CREATE TABLE loans (title TEXT NOT NULL, member TEXT NOT NULL);\n        INSERT INTO items VALUES ('Vidas Secas', 1);\n    \"\"\")\n    db.close()", "note": "Desta vez um arquivo, porque dois balcões precisam de duas conexões com o mesmo banco. Toda execução começa com um exemplar de *Vidas Secas* e nenhum empréstimo."},
 {"code": "\n\ndef desk() -> sqlite3.Connection:\n    return sqlite3.connect(PATH, isolation_level=None, timeout=0.1)", "note": "Cada balcão é uma conexão própria. `timeout=0.1` faz um balcão que encontra o banco travado desistir depois de um décimo de segundo, em vez dos cinco do padrão."},
 {"code": "\n\ndef copies(db) -> int:\n    return db.execute(\"SELECT available FROM items WHERE title = 'Vidas Secas'\").fetchone()[0]\n\n\ndef lend(db, member: str, seen: int) -> None:\n    db.execute(\"UPDATE items SET available = ? WHERE title = 'Vidas Secas'\", (seen - 1,))\n    db.execute(\"INSERT INTO loans VALUES ('Vidas Secas', ?)\", (member,))", "note": "Este é o formato do defeito: ler um número, decidir em Python, gravar de volta o número calculado. `lend` grava `seen - 1`, diga a linha o que disser a essa altura."},
 {"code": "\n\ndef report(label: str) -> None:\n    db = desk()\n    n = db.execute(\"SELECT count(*) FROM loans\").fetchone()[0]\n    print(f\"{label}: available={copies(db)}, loans={n}\")\n    db.close()"},
 {"code": "\n\ndef no_transaction() -> None:\n    a, b = desk(), desk()\n    seen_a = copies(a)\n    seen_b = copies(b)\n    if seen_a > 0:\n        lend(a, \"Bia\", seen_a)\n    if seen_b > 0:\n        lend(b, \"Caio\", seen_b)", "note": "Sem transação. Os dois balcões são intercalados à mão, numa só thread, para a execução imprimir sempre a mesma coisa: os dois leem, depois os dois gravam."},
 {"code": "\n\ndef plain_begin() -> None:\n    a, b = desk(), desk()\n    a.execute(\"BEGIN\")\n    seen_a = copies(a)\n    b.execute(\"BEGIN\")\n    seen_b = copies(b)\n    lend(a, \"Bia\", seen_a)\n    try:\n        lend(b, \"Caio\", seen_b)\n    except sqlite3.OperationalError as err:\n        print(\"  desk B writes:\", err)\n    try:\n        a.execute(\"COMMIT\")\n    except sqlite3.OperationalError as err:\n        print(\"  desk A commits:\", err)\n    b.execute(\"ROLLBACK\")\n    a.execute(\"COMMIT\")", "note": "Um `BEGIN` simples não trava nada até a primeira escrita. Os dois balcões leem dentro das suas transações, o balcão A grava, e então cada um fica esperando o outro."},
 {"code": "\n\ndef begin_immediate() -> None:\n    a, b = desk(), desk()\n    a.execute(\"BEGIN IMMEDIATE\")\n    seen_a = copies(a)\n    try:\n        b.execute(\"BEGIN IMMEDIATE\")\n    except sqlite3.OperationalError as err:\n        print(\"  desk B begins:\", err)\n    lend(a, \"Bia\", seen_a)\n    a.execute(\"COMMIT\")\n    b.execute(\"BEGIN IMMEDIATE\")\n    if copies(b) > 0:\n        lend(b, \"Caio\", copies(b))\n    else:\n        print(\"  desk B: no copy left for Caio\")\n    b.execute(\"COMMIT\")", "note": "`BEGIN IMMEDIATE` pega a trava de escrita antes da leitura. O balcão B nem consegue começar até o A terminar, e quando começa lê o número que o A deixou."},
 {"code": "\n\nif __name__ == \"__main__\":\n    for run in (no_transaction, plain_begin, begin_immediate):\n        fresh_library()\n        print(run.__name__)\n        run()\n        report(\"  result\")"}
]}
```

```
ana@laptop:~/patterns/acid-cap$ python3 desks.py
no_transaction
  result: available=0, loans=2
plain_begin
  desk B writes: database is locked
  desk A commits: database is locked
  result: available=0, loans=1
begin_immediate
  desk B begins: database is locked
  desk B: no copy left for Caio
  result: available=0, loans=1
```

**A primeira execução é a atualização perdida, e nada nela levantou erro.** Os dois balcões viram
um exemplar, os dois emprestaram, e a contagem diz 0 enquanto a tabela de empréstimos diz 2. O 0
gravado pelo balcão A foi substituído pelo 0 do balcão B, calculado a partir de um número que já
tinha deixado de ser verdade. Um relatório que comparasse empréstimos com estoque acharia isso
semanas depois.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" data-fig=\"l10-lost-update\" aria-label=\"Uma linha do tempo da atualização perdida em desks.py, lida de cima para baixo. O balcão A à esquerda, a linha de items no meio, o balcão B à direita. Primeiro o balcão A lê available 1. Depois o balcão B lê available 1. Depois o balcão A grava 0 e registra um empréstimo para Bia. Depois o balcão B grava 0, calculado a partir do 1 que leu antes, e registra um empréstimo para Caio. A linha termina com available 0 e dois empréstimos para um exemplar, e nenhum passo levantou erro.\"><defs><marker id=\"l10-lost-update-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l10-lost-update-dp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"55.0\" y=\"15.0\" width=\"150.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">balcão A (Bia)</text><rect x=\"265.0\" y=\"15.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">linha de items</text><rect x=\"495.0\" y=\"15.0\" width=\"150.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">balcão B (Caio)</text><path d=\"M130.0 47.0 L130.0 72.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M130.0 98.0 L130.0 182.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M130.0 208.0 L130.0 288.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M570.0 47.0 L570.0 127.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M570.0 153.0 L570.0 237.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M570.0 263.0 L570.0 288.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M350.0 47.0 L350.0 72.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M350.0 98.0 L350.0 127.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M350.0 153.0 L350.0 176.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M350.0 214.0 L350.0 231.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M350.0 269.0 L350.0 288.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M28.0 66.0 L28.0 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l10-lost-update-dp-ah-paper-dim)\"></path><text x=\"28.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo</text><path d=\"M278.0 85.0 L200.0 85.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-lost-update-dp-ah-paper-dim)\"></path><text x=\"239.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">lê 1</text><rect x=\"280.0\" y=\"74.0\" width=\"140.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">available = 1</text><rect x=\"62.0\" y=\"74.0\" width=\"136.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SELECT</text><path d=\"M422.0 140.0 L500.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-lost-update-dp-ah-paper-dim)\"></path><text x=\"461.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">lê 1</text><rect x=\"280.0\" y=\"129.0\" width=\"140.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">available = 1</text><rect x=\"502.0\" y=\"129.0\" width=\"136.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SELECT</text><path d=\"M200.0 195.0 L278.0 195.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-lost-update-dp-ah-phosphor)\"></path><text x=\"239.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">grava 1 - 1</text><rect x=\"280.0\" y=\"178.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"189.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">available = 0</text><text x=\"350.0\" y=\"200.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">empréstimos: 1</text><rect x=\"62.0\" y=\"184.0\" width=\"136.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">UPDATE + INSERT</text><path d=\"M500.0 250.0 L422.0 250.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-lost-update-dp-ah-phosphor)\"></path><text x=\"461.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">grava 1 - 1</text><rect x=\"280.0\" y=\"233.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"244.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">available = 0</text><text x=\"350.0\" y=\"255.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">empréstimos: 2</text><rect x=\"502.0\" y=\"239.0\" width=\"136.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">UPDATE + INSERT</text><text x=\"350.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">um exemplar, dois empréstimos, nenhum erro</text></svg>", "caption": "A atualização perdida. O balcão B grava um número calculado a partir de um valor que o balcão A já tinha mudado."}
```

A segunda execução é o SQLite se recusando a perder a atualização, e pagando por isso. O balcão A
tem o direito de gravar e quer confirmar; o balcão B segura uma leitura que ainda não soltou. O
SQLite, no modo de journal padrão, não deixa A confirmar por cima da leitura de B, e não deixa B
gravar enquanto A grava, então cada balcão recebeu `database is locked` até o balcão B desfazer a
transação. **Correto, e ninguém foi atendido até um dos lados desistir.** Um programa de verdade
teria de capturar esse erro e repetir a transação inteira, lendo de novo.

A terceira execução pega a trava de escrita antes de ler. O `BEGIN IMMEDIATE` do balcão B é
recusado na hora, antes de ler qualquer coisa. Quando ele tenta de novo, depois de o balcão A
confirmar, lê 0 e avisa Caio que não há exemplar. É o comportamento que a biblioteca queria desde o
início: um empréstimo, e uma recusa verdadeira.

## Níveis de isolamento, e por que o SQLite parece rígido

O padrão SQL nomeia quatro níveis, do mais fraco ao mais forte: *read uncommitted*, *read
committed*, *repeatable read* e *serializable*. Cada um proíbe mais maneiras de duas transações
enxergarem o trabalho uma da outra. O SQLite tem um só escritor por vez, então as transações dele
se comportam como serializáveis, e é por isso que a segunda execução recusou em vez de perder algo.

Os servidores costumam vir com algo mais fraco, e a diferença importa exatamente para este programa:

| banco | nível padrão | o que a leitura seguida de escrita de `lend` faz dentro de uma transação |
|---|---|---|
| SQLite | serializable | é recusada com `database is locked`, como na segunda execução |
| PostgreSQL | read committed | **perde a atualização**, como na primeira execução, a menos que a leitura diga `FOR UPDATE` |
| MySQL (InnoDB) | repeatable read | também perde: o segundo `UPDATE` espera o primeiro e depois o sobrescreve |

Então "coloquei numa transação" protege você no SQLite e não protege num PostgreSQL deixado no
padrão. No PostgreSQL, `SELECT available FROM items WHERE title = $1 FOR UPDATE` trava a linha no
momento da leitura, que é o que o `BEGIN IMMEDIATE` fez aqui para o arquivo inteiro. Subir o nível
para `REPEATABLE READ` faz o PostgreSQL abortar a segunda transação com um erro de serialização,
que, como na segunda execução, o seu código então precisa repetir.

## A correção que não segura trava enquanto o Python pensa

O defeito mora na ida e volta: o número viaja até o Python, alguém decide, e ele volta. Coloque a
decisão no próprio comando e a ida e volta desaparece:

```sql
UPDATE items SET available = available - 1
 WHERE title = 'Vidas Secas' AND available > 0;
```

O banco confere e muda a linha num passo só. Se o exemplar acabou, o comando muda zero linhas, e o
programa lê isso no `rowcount` do cursor e recusa. Funciona igual em qualquer nível de isolamento
de qualquer banco da tabela acima, o que faz dele a primeira coisa a usar quando a regra cabe num
`WHERE`. A unidade de trabalho da próxima seção usa essa forma.
