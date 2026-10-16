---
title: "ACID: tudo ou nada"
version: 1
---

**Uma transação é uma promessa sobre um grupo de mudanças: ou todas acontecem, ou nenhuma
acontece, e ninguém vê o grupo pela metade.** ACID é o nome dessa promessa, desmontada em quatro
letras por Theo Härder e Andreas Reuter em 1983. Vale conhecer as letras. Vale mais o hábito por
trás delas, e ele começa por uma crença errada.

A crença é que o seu código roda numa transação porque conversa com um banco de dados. A maioria
dos drivers começa em *autocommit*: cada comando é uma transação própria, gravada no instante em
que termina. Dois comandos que andam juntos são duas transações, a menos que alguém diga o
contrário, e o intervalo entre eles é onde caem uma queda, um erro ou um dedo errado no teclado.

Todos os programas desta lição ficam num só diretório:

```sh
mkdir -p ~/patterns/acid-cap
cd ~/patterns/acid-cap
```

## Uma reserva que some

A biblioteca mantém uma fila de reservas para cada título. Uma sócia no balcão pede para passar o
lugar dela na fila de *Dom Casmurro* para uma amiga. Isso é um delete e um insert, e o programa
abaixo faz a operação duas vezes: uma com dois comandos soltos, outra dentro de uma transação. Nas
duas vezes o bibliotecário digita errado o número da carteirinha da amiga.

```schooling-example
{"language": "python", "file": "reserve.py", "parts": [
 {"code": "# reserve.py\nimport sqlite3\n\n\ndef open_library() -> sqlite3.Connection:\n    db = sqlite3.connect(\":memory:\", isolation_level=None)\n    db.execute(\"PRAGMA foreign_keys = ON\")", "note": "`isolation_level=None` desliga o costume do módulo de abrir transações por conta própria, então todo `BEGIN` desta lição é um que você enxerga. No SQLite as chaves estrangeiras vêm desligadas; o pragma as liga para esta conexão."},
 {"code": "    db.executescript(\"\"\"\n        CREATE TABLE members (id TEXT PRIMARY KEY, name TEXT NOT NULL);\n        CREATE TABLE holds (\n            title  TEXT NOT NULL,\n            member TEXT NOT NULL REFERENCES members(id),\n            place  INTEGER NOT NULL CHECK (place > 0)\n        );\n        INSERT INTO members VALUES ('m-001', 'Bia'), ('m-002', 'Caio');\n        INSERT INTO holds VALUES ('Dom Casmurro', 'm-001', 1),\n                                 ('Dom Casmurro', 'm-002', 2);\n    \"\"\")\n    return db", "note": "Dois sócios estão na fila de *Dom Casmurro*: Bia em primeiro, Caio em segundo. Uma reserva precisa citar um sócio que existe, e o lugar dela precisa ser positivo. Essas duas regras são do banco, não do Python."},
 {"code": "\n\ndef move_hold(db, title: str, src: str, dst: str) -> None:\n    place = db.execute(\"SELECT place FROM holds WHERE title = ? AND member = ?\",\n                       (title, src)).fetchone()[0]\n    db.execute(\"DELETE FROM holds WHERE title = ? AND member = ?\", (title, src))\n    db.execute(\"INSERT INTO holds VALUES (?, ?, ?)\", (title, dst, place))", "note": "Passar uma reserva para outro sócio são dois comandos: tirar de um, dar ao outro. Nada aqui os agrupa, então cada um é gravado no instante em que roda."},
 {"code": "\n\ndef move_hold_atomically(db, title: str, src: str, dst: str) -> None:\n    db.execute(\"BEGIN\")\n    try:\n        move_hold(db, title, src, dst)\n    except Exception:\n        db.execute(\"ROLLBACK\")\n        raise\n    db.execute(\"COMMIT\")", "note": "Os mesmos dois comandos dentro de `BEGIN` e `COMMIT`. Se algo levantar exceção no meio, `ROLLBACK` desfaz o que já tinha rodado, e o erro segue para quem chamou."},
 {"code": "\n\ndef queue(db) -> list[tuple]:\n    return db.execute(\"SELECT place, member FROM holds ORDER BY place\").fetchall()"},
 {"code": "\n\nif __name__ == \"__main__\":\n    for move in (move_hold, move_hold_atomically):\n        db = open_library()\n        try:\n            move(db, \"Dom Casmurro\", \"m-001\", \"m-009\")\n        except sqlite3.IntegrityError as err:\n            print(f\"{move.__name__}: {err}\")\n        print(\"  queue now:\", queue(db))", "note": "Cada versão recebe uma biblioteca nova e o mesmo erro no balcão: a reserva vai para `m-009`, um número de carteirinha que ninguém tem."}
]}
```

```
ana@laptop:~/patterns/acid-cap$ python3 reserve.py
move_hold: FOREIGN KEY constraint failed
  queue now: [(2, 'm-002')]
move_hold_atomically: FOREIGN KEY constraint failed
  queue now: [(1, 'm-001'), (2, 'm-002')]
```

As duas versões batem no mesmo erro: o banco recusou uma reserva para um sócio que não existe. O
que muda é o que o erro deixou para trás. **Sem transação, o lugar de Bia sumiu e ninguém ficou com
ele**: o delete já tinha sido gravado quando o insert falhou, então a fila tem só Caio, no lugar 2,
atrás de ninguém. Com a transação, o `ROLLBACK` devolveu o delete e a fila ficou exatamente como
estava. Bia pode tentar de novo com o número certo.

Nada em `move_hold` está errado linha por linha. O defeito está no que falta em volta, e nenhum
teste de um comando isolado o encontraria.

## As quatro letras, neste programa

| letra | a promessa | onde aparece em `reserve.py` |
|---|---|---|
| **A**tomicidade | o grupo acontece inteiro ou não acontece | o `ROLLBACK` desfez o delete quando o insert falhou |
| **C**onsistência | uma transação leva os dados de um estado válido a outro | a chave estrangeira recusou `m-009`; o `CHECK` recusaria um lugar 0 |
| **I**solamento | transações simultâneas não veem as metades umas das outras | não aparece aqui; a próxima seção é sobre isso |
| **D**urabilidade | depois que o `COMMIT` volta, uma queda não o desfaz | ausente: este banco vive na memória e morre com o processo |

**O C é a letra estranha.** Atomicidade, isolamento e durabilidade são coisas que o banco faz por
você. A consistência é sobretudo sua: o banco consegue guardar as regras que você escreveu como
restrições, como a chave estrangeira acima, e nada além disso. Uma regra que só existe no Python,
digamos "um sócio pode reservar no máximo cinco títulos", só se mantém se toda mudança capaz de
quebrá-la rodar dentro de uma transação que a confere. A lição 12 dá a esse tipo de regra uma casa
própria, o agregado.

A durabilidade precisa de um arquivo. Um banco em disco, gravado com as configurações padrão do
SQLite, já garantiu que a mudança está no disco quando o `COMMIT` volta. As duas seções seguintes
usam um arquivo por esse motivo, e porque duas conexões com o mesmo banco em memória não são
possíveis sem trabalho extra.

## Transações na sua linguagem

O módulo `sqlite3` do Python, nas configurações padrão, abre uma transação sozinho antes do
primeiro `INSERT`, `UPDATE` ou `DELETE`, e `with db:` grava no fim do bloco ou desfaz numa exceção.
É cômodo e esconde o `BEGIN`, e por isso esta lição o desliga. O Python 3.12 acrescentou ao
`connect` um argumento `autocommit` que diz a mesma coisa com mais clareza.

| linguagem | o jeito usual | a armadilha |
|---|---|---|
| Java (JDBC) | `conn.setAutoCommit(false)`, depois `commit()` ou `rollback()` | o autocommit fica ligado até você desligar |
| Go (`database/sql`) | `tx, err := db.BeginTx(ctx, nil)`, depois `tx.Commit()`, com `defer tx.Rollback()` | `db.Exec("BEGIN")` no pool pode rodar numa conexão e o comando seguinte em outra |
| TypeScript (`pg`) | `const client = await pool.connect()`, depois `BEGIN` e `COMMIT` nesse client | `pool.query("BEGIN")` tem o mesmo problema do Go: cada consulta pode pegar uma conexão diferente |

A armadilha das duas últimas linhas é a mesma. Uma transação pertence a uma **conexão**, e um pool
distribui conexões por chamada. O `Tx` do Go e o client reservado do `pg` existem para manter todos
os comandos de uma transação numa só delas.
