---
title: "Unidade de trabalho: uma transação por tarefa de negócio"
version: 1
---

**Uma unidade de trabalho é um objeto que junta as mudanças que uma tarefa de negócio faz e grava
todas numa só transação, no fim.** O código de negócio diz *o que* mudou; a unidade de trabalho
decide *quando* isso chega ao banco e garante que chegue inteiro. Martin Fowler deu nome a ela em
*Patterns of Enterprise Application Architecture*, em 2002, e todo ORM que você provavelmente vai
usar é construído em volta de uma.

O hábito que ela substitui é abrir transação onde quer que alguém precise de uma. Uma função de
serviço começa uma transação, chama um auxiliar, e o auxiliar, escrito para outro chamador, faz
commit. O commit encerra cedo a transação de fora, e tudo o que vem depois roda solto. Imagine um
empréstimo de três livros montado com um `lend_one` que faz commit a cada livro: quando o terceiro
não tem exemplar, os dois primeiros já foram emprestados, e a sócia sai com uma cesta que não
pediu. **A fronteira da transação pertence ao caso de uso, e só um trecho de código deve ser dono
dela.**

Eis uma unidade de trabalho pequena o bastante para ler de uma vez. Ela conhece um tipo de mudança,
um empréstimo, e reaproveita o `UPDATE` condicional da seção anterior:

```schooling-example
{"language": "python", "file": "uow.py", "parts": [
 {"code": "# uow.py\nimport os\nimport sqlite3\n\nPATH = \"uow.db\"\n\n\nclass NoCopyLeft(Exception):\n    pass\n\n\nclass UnitOfWork:\n    def __init__(self, path: str):\n        self.path = path\n        self.loans: list[tuple[str, str]] = []\n\n    def __enter__(self) -> \"UnitOfWork\":\n        self.db = sqlite3.connect(self.path, isolation_level=None, timeout=1)\n        return self\n\n    def lend(self, title: str, member: str) -> None:\n        self.loans.append((title, member))", "note": "A unidade de trabalho guarda uma lista do que o código de negócio pediu. Pedir ainda não grava nada."},
 {"code": "\n    def commit(self) -> None:\n        self.db.execute(\"BEGIN IMMEDIATE\")\n        try:\n            for title, member in self.loans:\n                cur = self.db.execute(\n                    \"UPDATE items SET available = available - 1\"\n                    \" WHERE title = ? AND available > 0\", (title,))\n                if cur.rowcount == 0:\n                    raise NoCopyLeft(title)\n                self.db.execute(\"INSERT INTO loans VALUES (?, ?)\", (title, member))\n        except Exception:\n            self.db.execute(\"ROLLBACK\")\n            raise\n        self.db.execute(\"COMMIT\")\n        self.loans.clear()", "note": "`commit` é o único lugar que sabe de transações. Ele pega a trava de escrita, aplica cada mudança com o `UPDATE` condicional da seção anterior, e ou grava todas ou desfaz todas."},
 {"code": "\n    def __exit__(self, *exc) -> None:\n        self.loans.clear()\n        self.db.close()", "note": "Sair do bloco `with` descarta tudo o que não foi gravado. Esquecer o `commit` então não grava nada, que é o lado seguro de esquecer."},
 {"code": "\n\ndef checkout(uow: UnitOfWork, member: str, titles: list[str]) -> None:\n    for title in titles:\n        uow.lend(title, member)\n    uow.commit()", "note": "O código de negócio. Ele diz o que é um empréstimo no balcão, um sócio e alguns títulos, e nunca menciona SQL, `BEGIN` nem conexão."},
 {"code": "\n\ndef setup() -> None:\n    if os.path.exists(PATH):\n        os.remove(PATH)\n    db = sqlite3.connect(PATH)\n    db.executescript(\"\"\"\n        CREATE TABLE items (title TEXT PRIMARY KEY, available INTEGER NOT NULL);\n        CREATE TABLE loans (title TEXT NOT NULL, member TEXT NOT NULL);\n        INSERT INTO items VALUES ('Dom Casmurro', 2), ('Vidas Secas', 1), ('Iracema', 0);\n    \"\"\")\n    db.close()\n\n\ndef show(label: str) -> None:\n    db = sqlite3.connect(PATH)\n    loans = db.execute(\"SELECT title, member FROM loans\").fetchall()\n    stock = db.execute(\"SELECT title, available FROM items ORDER BY title\").fetchall()\n    print(f\"{label}\\n  loans: {loans}\\n  stock: {stock}\")\n    db.close()"},
 {"code": "\n\nif __name__ == \"__main__\":\n    setup()\n    with UnitOfWork(PATH) as uow:\n        try:\n            checkout(uow, \"Bia\", [\"Dom Casmurro\", \"Vidas Secas\", \"Iracema\"])\n        except NoCopyLeft as err:\n            print(\"basket refused, no copy of\", err)\n    show(\"after Bia's basket\")\n\n    with UnitOfWork(PATH) as uow:\n        uow.lend(\"Dom Casmurro\", \"Caio\")\n    show(\"after Caio's, never committed\")\n\n    with UnitOfWork(PATH) as uow:\n        checkout(uow, \"Caio\", [\"Dom Casmurro\", \"Vidas Secas\"])\n    show(\"after Caio's, committed\")", "note": "Três passagens pelo balcão: a cesta de Bia inclui *Iracema*, que não tem exemplar; a primeira tentativa de Caio registra um empréstimo e nunca grava; a segunda é uma cesta que cabe."}
]}
```

```
ana@laptop:~/patterns/acid-cap$ python3 uow.py
basket refused, no copy of Iracema
after Bia's basket
  loans: []
  stock: [('Dom Casmurro', 2), ('Iracema', 0), ('Vidas Secas', 1)]
after Caio's, never committed
  loans: []
  stock: [('Dom Casmurro', 2), ('Iracema', 0), ('Vidas Secas', 1)]
after Caio's, committed
  loans: [('Dom Casmurro', 'Caio'), ('Vidas Secas', 'Caio')]
  stock: [('Dom Casmurro', 1), ('Iracema', 0), ('Vidas Secas', 0)]
```

A cesta de Bia pedia três títulos, e *Iracema* não tinha nenhum. Os dois empréstimos anteriores
nunca foram gravados: o estoque continua 2 para *Dom Casmurro* e 1 para *Vidas Secas*, e a tabela de
empréstimos está vazia. A primeira visita de Caio registrou um empréstimo e saiu do bloco sem
`commit`, e também nada foi gravado. A segunda visita cabe, e as duas mudanças chegam juntas: dois
empréstimos, e as duas contagens de estoque baixam um.

`checkout` tem quatro linhas e seria igual contra PostgreSQL, um arquivo JSON ou um dublê num
teste. É esse o ganho de projeto. A regra *uma cesta é emprestada inteira ou não é* está escrita uma
vez, em `commit`, e nenhuma função que registra um empréstimo consegue quebrá-la fazendo commit
cedo, porque nenhuma delas faz commit.

## As que você já usa

A versão de Fowler acompanha três listas, os objetos novos, os alterados e os removidos, e monta o
SQL na hora do commit. As ferramentas abaixo fazem isso por você, com outros nomes:

| linguagem | a unidade de trabalho | o commit |
|---|---|---|
| Python | a `Session` do SQLAlchemy | `session.commit()`; `session.add(obj)` registra |
| Java | o `EntityManager` do JPA e o seu contexto de persistência | o commit da transação descarrega toda entidade alterada |
| C# | o `DbContext` do Entity Framework | `SaveChanges()` |
| TypeScript | o `EntityManager` do TypeORM, o `$transaction` do Prisma | o fim do callback |
| Go | nenhuma na biblioteca padrão | você passa um `*sql.Tx`, ou uma struct pequena como a de cima, pela cadeia de chamadas |

A linha do Go é a mais franca. Sem ORM, uma unidade de trabalho é um valor que você entrega ao
código que precisa dele, e o código que a criou chama `Commit`. A injeção pelo construtor da lição 5
é o jeito usual de entregá-la.

## Onde uma começa e termina

Uma unidade de trabalho por caso de uso: uma requisição, um comando, uma tarefa agendada. O código
da borda a abre, o código do meio registra mudanças, e a borda faz commit ou deixa tudo ser
descartado. Os handlers de comando da lição 8 são os donos naturais, já que um comando já é uma
tarefa de negócio. Duas consequências seguem daí, e as duas voltam na lição 12:

- uma unidade de trabalho que cresce para cobrir várias coisas sem relação é uma transação que
  segura travas por mais tempo e falha por mais motivos; mantenha-a na única coisa que o caso de uso
  muda;
- o código de negócio que registra mudanças pode ser testado contra um dublê que as anota e não
  grava nada, o mesmo movimento que a lição 12 faz com um repositório em memória.
