---
title: "Modelos de leitura: tabelas com a forma da tela"
version: 1
---

**Um modelo de leitura é uma estrutura feita para uma tela, mantida em dia aplicando a ela os
eventos do lado da escrita, de modo que responder à tela é uma consulta direta e não um cálculo.** O
trabalho que a classe tensionada fazia a cada exibição de página, percorrer todos os exemplares de
todos os títulos, é feito uma vez por evento, por um pequeno trecho de código chamado projetor. A
consulta que sobra é curta o bastante para ser lida de relance.

O hábito a desaprender é a normalização. Num modelo de escrita, guardar o nome do autor ao lado de
cada contagem seria um defeito: duas cópias de um fato que podem se desencontrar. Num modelo de
leitura é esse o objetivo, porque o modelo de leitura é derivado. Se ele se desencontrar, é
reconstruído a partir dos eventos, e nada do que a biblioteca sabe se perde.

```schooling-example
{"language": "python", "file": "read_model.py", "parts": [
 {"code": "# read_model.py\nimport sqlite3\nfrom datetime import date\nfrom commands import (CopyLent, CopyReturned, TitleReserved, Lending, LendCopy,\n                      ReturnCopy, Reserve, handle)", "note": "O lado da leitura importa os tipos de evento e, para a demonstração lá embaixo, o lado da escrita. O projetor em si só precisa dos eventos."},
 {"code": "\nCATALOGUE = {\"T1\": (\"Dom Casmurro\", \"Machado de Assis\", 2),\n             \"T2\": (\"Vidas Secas\", \"Graciliano Ramos\", 1),\n             \"T3\": (\"A Hora da Estrela\", \"Clarice Lispector\", 1)}", "note": "Nomes, autores e número de exemplares: dados que só interessam às telas. Eles vão para o modelo de leitura e nunca para `Lending`."},
 {"code": "\n\nclass Availability:\n    def __init__(self, catalogue: dict[str, tuple[str, str, int]]):\n        self.db = sqlite3.connect(\":memory:\")\n        self.db.execute(\"CREATE TABLE availability (title_id TEXT PRIMARY KEY,\"\n                        \" title TEXT, author TEXT, on_shelf INTEGER, waiting INTEGER)\")\n        self.db.executemany(\"INSERT INTO availability VALUES (?, ?, ?, ?, 0)\",\n                            [(t, name, author, n) for t, (name, author, n) in catalogue.items()])", "note": "Uma tabela de verdade no SQLite, mantida em memória: uma linha por título, com o autor copiado e as contagens guardadas, não calculadas. É isso que *desnormalizado* quer dizer aqui, e é de propósito."},
 {"code": "\n    def apply(self, event) -> None:\n        match event:\n            case CopyLent(title_id=t, was_reserved=r):\n                shelf, wait = -1, (-1 if r else 0)\n            case CopyReturned(title_id=t):\n                shelf, wait = 1, 0\n            case TitleReserved(title_id=t):\n                shelf, wait = 0, 1\n            case _:\n                return\n        self.db.execute(\"UPDATE availability SET on_shelf = on_shelf + ?,\"\n                        \" waiting = waiting + ? WHERE title_id = ?\", (shelf, wait, t))", "note": "O projetor. Cada evento vira um `UPDATE` de dois contadores, e um evento que não lhe interessa é ignorado. O `match` desmonta o evento pela classe e pelos campos."},
 {"code": "\n    def available_now(self) -> list[tuple]:\n        return self.db.execute(\"SELECT title, author, on_shelf FROM availability\"\n                               \" WHERE on_shelf > 0 ORDER BY title\").fetchall()\n\n    def waiting_for(self, title_id: str) -> int:\n        return self.db.execute(\"SELECT waiting FROM availability WHERE title_id = ?\",\n                               (title_id,)).fetchone()[0]", "note": "A consulta que o balcão roda. Nenhum join e nenhum laço sobre exemplares: a resposta foi calculada quando os eventos chegaram."},
 {"code": "\n\nclass MemberLoans:\n    def __init__(self, catalogue: dict[str, tuple[str, str, int]]):\n        self.names = {t: name for t, (name, _, _) in catalogue.items()}\n        self.by_member: dict[str, dict[str, str]] = {}\n\n    def apply(self, event) -> None:\n        match event:\n            case CopyLent(copy_id=c, title_id=t, member=m, due=due):\n                self.by_member.setdefault(m, {})[c] = f\"{self.names[t]}, due {due:%d/%m}\"\n            case CopyReturned(copy_id=c, member=m):\n                self.by_member[m].pop(c)\n\n    def of(self, member: str) -> list[str]:\n        return sorted(self.by_member.get(member, {}).values())", "note": "Um segundo modelo de leitura a partir dos mesmos eventos, com outra forma: um dicionário por membro, com as linhas já formatadas. Nada impede um terceiro."},
 {"code": "\n\nif __name__ == \"__main__\":\n    lending = Lending({\"C1\": \"T1\", \"C2\": \"T1\", \"C3\": \"T2\", \"C4\": \"T3\"})\n    shelf, loans = Availability(CATALOGUE), MemberLoans(CATALOGUE)\n    lending.listeners += [shelf.apply, loans.apply]\n    day = date(2026, 3, 2)\n    for command in [LendCopy(\"C1\", \"bia\", day), LendCopy(\"C4\", \"bia\", day),\n                    LendCopy(\"C3\", \"caio\", day), Reserve(\"T2\", \"dani\"),\n                    ReturnCopy(\"C4\", date(2026, 3, 10))]:\n        handle(lending, command)\n    for row in shelf.available_now():\n        print(row)\n    print(\"bia:\", loans.of(\"bia\"))\n    print(\"waiting for T2:\", shelf.waiting_for(\"T2\"))\n    handle(lending, ReturnCopy(\"C3\", date(2026, 3, 16)))\n    handle(lending, LendCopy(\"C3\", \"dani\", date(2026, 3, 16)))\n    print(\"waiting for T2:\", shelf.waiting_for(\"T2\"), \"| dani:\", loans.of(\"dani\"))", "note": "Os dois modelos de leitura ouvem o modelo de escrita. Cinco comandos, a tela, depois o Caio devolve *Vidas Secas* e a Dani, primeira da fila, o leva."}
]}
```

```
ana@laptop:~/patterns/cqrs$ python3 read_model.py
('A Hora da Estrela', 'Clarice Lispector', 1)
('Dom Casmurro', 'Machado de Assis', 1)
bia: ['Dom Casmurro, due 16/03']
waiting for T2: 1
waiting for T2: 0 | dani: ['Vidas Secas, due 30/03']
```

*Vidas Secas* não aparece nas duas primeiras linhas porque seu único exemplar está emprestado; a
Bia devolveu *A Hora da Estrela* em 10 de março, então ele voltou. Os empréstimos da Bia mostram
uma linha. A reserva da Dani pôs a contagem de espera em 1, e a última linha a mostra voltando a 0
quando a Dani levou o exemplar.

## O evento tinha de dizer

Essa última linha só funciona porque `CopyLent` carrega `was_reserved`. Sem ele, o projetor veria "o
C3 foi emprestado à dani" e não teria como saber se uma reserva foi consumida: a fila mora no modelo
de escrita, que o projetor não pode ler. **Um modelo de leitura só consegue mostrar o que os eventos
dizem.** Quando uma tela precisa de um fato, a correção está no evento. Acrescentar um campo a um
evento é uma decisão de projeto sobre o vocabulário do lado da escrita, e a lição 9 a trata com o
cuidado que ela pede quando os eventos ficam guardados por anos.

## Um modelo de escrita, muitos de leitura

`MemberLoans` lê os mesmos eventos que `Availability` e mantém uma forma totalmente diferente: por
membro, indexado por exemplar, com o vencimento já formatado como `16/03`. Uma terceira tela, "mais
emprestados do ano", seria um terceiro projetor contando `CopyLent` por título, e **acrescentá-lo não
toca em `Lending`**. Compare com a classe tensionada, onde a mesma tela queria dizer um contador novo
dentro de `lend`.

Cada modelo de leitura é escolhido para a sua tela, e eles não precisam usar a mesma tecnologia. A
tabela de disponibilidade poderia ficar no SQLite ou no PostgreSQL, o modelo de uma tela de busca num
índice de texto completo, e a página do membro num armazenamento chave-valor indexado por membro. O
projetor é o único código que conhece os eventos e o armazenamento.

## Testar um projetor

Um projetor é uma função de eventos para estado, o que o torna uma das coisas mais fáceis de testar
num sistema: crie um `Availability`, chame `apply` com uma lista de eventos escrita à mão, e
consulte. Sem modelo de escrita, sem regras, sem relógio. O lado da escrita se testa ao contrário,
mandando comandos e conferindo os eventos que ele publicou, e entre os dois os tipos de evento são o
contrato. As fixtures da lição 3 de `testing-cicd` encaixam bem aqui: uma fixture de eventos é um
cenário.
