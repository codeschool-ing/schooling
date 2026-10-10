---
title: "Factory e builder: fazer objetos sem dizer como"
version: 1
---

**Uma factory decide que classe construir para quem chama não precisar decidir; um builder monta
um objeto complicado passo a passo para quem chama não precisar de um construtor com doze
argumentos.** Os dois são padrões criacionais, e os dois respondem à mesma queixa: a linha que cria
um objeto sabe demais.

Crie `~/patterns/gof` e trabalhe nele durante a lição inteira:

```sh
mkdir -p ~/patterns/gof
cd ~/patterns/gof
```

## Uma factory: o tipo decide a classe

O acervo da biblioteca chega como linhas de uma planilha, e cada linha diz que tipo de item é. Em
algum lugar uma string tem de virar uma classe. Sem factory, esse `if` cai em qualquer função que
por acaso leia as linhas, e na seguinte, e na outra depois dela.

```schooling-example
{"language": "python", "file": "factory.py", "parts": [
 {"code": "# factory.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\n\n\n@dataclass\nclass Book:\n    title: str\n    loan_days: int = 14\n\n\n@dataclass\nclass Film:\n    title: str\n    minutes: int\n    loan_days: int = 7", "note": "Dois tipos de item e um empréstimo, como dataclasses pequenas. O que interessa no arquivo é o código abaixo deles."},
 {"code": "\n\nKINDS = {\"book\": Book, \"film\": Film}\n\n\ndef item_from_row(row: dict):\n    fields = dict(row)\n    kind = fields.pop(\"kind\")\n    if kind not in KINDS:\n        raise ValueError(f\"unknown kind {kind!r}\")\n    return KINDS[kind](**fields)", "note": "A factory é um dicionário e uma função. Acrescentar um tipo é uma linha em `KINDS`, e nenhum chamador muda."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Loan:\n    title: str\n    due: date\n\n    @classmethod\n    def for_item(cls, item, lent_on: date) -> \"Loan\":\n        return cls(item.title, lent_on + timedelta(days=item.loan_days))", "note": "Um construtor com nome é a outra factory do dia a dia. `Loan.for_item` se lê melhor do que calcular a data de devolução em cada lugar que cria um empréstimo, e é um factory method no sentido simples: um método cujo trabalho é criar."},
 {"code": "\n\nif __name__ == \"__main__\":\n    rows = [{\"kind\": \"book\", \"title\": \"Quincas Borba\"},\n            {\"kind\": \"film\", \"title\": \"Cidade de Deus\", \"minutes\": 130},\n            {\"kind\": \"vinyl\", \"title\": \"Clube da Esquina\"}]\n    for row in rows:\n        try:\n            item = item_from_row(row)\n        except ValueError as err:\n            print(\"refused:\", err)\n            continue\n        print(item, \"->\", Loan.for_item(item, date(2026, 5, 4)).due)", "note": "As linhas poderiam vir de um arquivo; aqui são uma lista. A terceira é de um tipo que a factory não conhece, e ela diz isso pelo nome."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 factory.py
Book(title='Quincas Borba', loan_days=14) -> 2026-05-18
Film(title='Cidade de Deus', minutes=130, loan_days=7) -> 2026-05-11
refused: unknown kind 'vinyl'
```

O filme vence uma semana depois de 4 de maio e o livro duas, e nem o laço nem `Loan` perguntaram qual
era qual.

O **Factory Method** do livro GoF é algo mais estreito: uma classe base chama `self.make_item(row)` e
deixa cada subclasse decidir que classe isso devolve. Ele aparece em frameworks, onde você herda de
alguma coisa e sobrescreve o único método que cria os seus objetos. Em código de aplicação, o
dicionário e o método de classe acima fazem o mesmo trabalho com menos maquinaria, e a biblioteca
padrão do Python está cheia do segundo tipo: `date.fromisoformat`, `dict.fromkeys`,
`int.from_bytes`.

## Um builder: um objeto, muitas partes opcionais

A busca no catálogo tem filtro por autor, filtro por ano, uma chave "só disponíveis", uma ordem e um
limite, e qualquer combinação pode ser pedida. Um construtor com tudo isso fica ilegível onde é
chamado: `Search(None, 1950, True, "year", None)` não diz nada a quem lê depois.

```schooling-example
{"language": "python", "file": "builder.py", "parts": [
 {"code": "# builder.py\nimport sqlite3\nfrom dataclasses import dataclass\n\n\n@dataclass(frozen=True)\nclass Query:\n    sql: str\n    params: tuple", "note": "O que o builder produz: uma consulta pronta e congelada. Nada a altera depois de construída."},
 {"code": "\n\nclass QueryBuilder:\n    ORDERS = (\"title\", \"year\")\n\n    def __init__(self):\n        self._where, self._params = [], []\n        self._order = \"title\"\n\n    def by_author(self, author: str) -> \"QueryBuilder\":\n        self._where.append(\"author = ?\")\n        self._params.append(author)\n        return self\n\n    def published_before(self, year: int) -> \"QueryBuilder\":\n        self._where.append(\"year < ?\")\n        self._params.append(year)\n        return self\n\n    def available_only(self) -> \"QueryBuilder\":\n        self._where.append(\"on_loan = 0\")\n        return self", "note": "Cada passo registra uma parte e devolve o próprio builder, que é o que permite encadear as chamadas."},
 {"code": "\n    def order_by(self, column: str) -> \"QueryBuilder\":\n        if column not in self.ORDERS:\n            raise ValueError(f\"cannot order by {column!r}\")\n        self._order = column\n        return self", "note": "Um passo pode conferir a entrada assim que ela chega. Ordenar por uma coluna que ninguém permitiu é recusado aqui, bem antes de chegar ao banco."},
 {"code": "\n    def build(self) -> Query:\n        sql = \"SELECT title, year FROM items\"\n        if self._where:\n            sql += \" WHERE \" + \" AND \".join(self._where)\n        sql += f\" ORDER BY {self._order}\"\n        return Query(sql, tuple(self._params))", "note": "`build` transforma as partes reunidas no produto. Os valores viajam como parâmetros, nunca colados no texto do SQL."},
 {"code": "\n\nif __name__ == \"__main__\":\n    db = sqlite3.connect(\":memory:\")\n    db.execute(\"CREATE TABLE items (title, author, year, on_loan)\")\n    db.executemany(\"INSERT INTO items VALUES (?, ?, ?, ?)\", [\n        (\"Dom Casmurro\", \"Machado de Assis\", 1899, 1),\n        (\"Quincas Borba\", \"Machado de Assis\", 1891, 0),\n        (\"Memórias Póstumas de Brás Cubas\", \"Machado de Assis\", 1881, 0),\n        (\"Vidas Secas\", \"Graciliano Ramos\", 1938, 0)])\n    q = (QueryBuilder().by_author(\"Machado de Assis\")\n         .available_only().order_by(\"year\").build())\n    print(q.sql)\n    print(q.params)\n    for row in db.execute(q.sql, q.params):\n        print(row)", "note": "Um banco SQLite em memória com quatro livros, para a consulta aparecer funcionando e não só impressa."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 builder.py
SELECT title, year FROM items WHERE author = ? AND on_loan = 0 ORDER BY year
('Machado de Assis',)
('Memórias Póstumas de Brás Cubas', 1881)
('Quincas Borba', 1891)
```

Dom Casmurro está emprestado, então voltam dois dos três livros de Machado, do mais antigo para o
mais novo. A chamada se lê como uma frase, e cada parte é opcional.

## Quando o Python não precisa de um

**Em Python, argumentos nomeados com valores padrão substituem a maioria dos builders.**
`search(author="Machado de Assis", available=True, order="year")` é tão legível quanto a cadeia, e
uma dataclass com valores padrão dá o mesmo para dados simples. Um builder merece o lugar quando os
passos fazem trabalho de verdade, como `order_by` faz ao validar, ou quando o objeto é montado em
vários lugares antes de ficar pronto, do jeito que uma requisição é montada pelo middleware.

| linguagem | a forma comum |
|---|---|
| Java | builders por toda parte: `HttpRequest.newBuilder()`, `StringBuilder`, o `@Builder` do Lombok |
| Go | "functional options": `NewServer(addr, WithTimeout(5*time.Second))` |
| TypeScript | um objeto de opções: `search({ author: "Machado de Assis", available: true })` |
| Python | argumentos nomeados; um builder para consultas e documentos montados em passos |

O Java se apoia em builders porque não tem argumentos nomeados, então um builder é o jeito de o Java
ter parâmetros nomeados e opcionais. É um padrão fazendo o trabalho de uma linguagem, um tema ao
qual a última seção de leitura desta lição volta.
