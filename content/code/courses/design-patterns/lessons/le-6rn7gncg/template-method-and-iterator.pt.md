---
title: "Template method e iterator: passos fixos, e percorrer uma coleção"
version: 1
---

**Template method fixa o roteiro de um algoritmo numa classe base e deixa as subclasses
preencherem passos específicos; iterator dá um jeito de percorrer uma coleção um elemento por vez
sem saber como ela está guardada.** O primeiro é um dos poucos padrões GoF construídos sobre herança,
e o segundo é tão útil que toda linguagem moderna o absorveu.

## Template method: o roteiro não se negocia

A lição 2 apresentou o template method como um dos usos honestos da herança, então isto é um lembrete
com os relatórios da biblioteca, e não uma segunda lição. Todo relatório tem um título, um
sublinhado, as suas linhas e um rodapé. O que são as linhas e o que o rodapé diz muda.

```schooling-example
{"language": "python", "file": "template.py", "parts": [
 {"code": "# template.py\nfrom abc import ABC, abstractmethod\n\n\nclass Report(ABC):\n    def render(self) -> str:\n        rows = self.rows()\n        lines = [self.title(), \"-\" * len(self.title())]\n        lines += [self.format_row(row) for row in rows] or [\"  (nothing to report)\"]\n        lines.append(self.footer(rows))\n        return \"\\n\".join(lines)", "note": "A classe base é dona de `render`, o template. Ela chama os passos numa ordem fixa e trata o caso vazio uma vez, para todo relatório."},
 {"code": "\n    @abstractmethod\n    def title(self) -> str: ...\n\n    @abstractmethod\n    def rows(self) -> list[tuple]: ...", "note": "Dois passos que todo relatório precisa fornecer, marcados como abstratos, então uma subclasse que esqueça um nem chega a ser construída."},
 {"code": "\n    def format_row(self, row: tuple) -> str:\n        return \"  \" + \" | \".join(str(cell) for cell in row)\n\n    def footer(self, rows: list[tuple]) -> str:\n        return f\"{len(rows)} rows\"", "note": "Dois ganchos com padrão. Uma subclasse só os sobrescreve se quiser outra coisa."},
 {"code": "\n\nclass OverdueReport(Report):\n    def __init__(self, loans: list[tuple[str, str, int]]):\n        self._loans = loans\n\n    def title(self) -> str:\n        return \"Overdue loans\"\n\n    def rows(self) -> list[tuple]:\n        return [loan for loan in self._loans if loan[2] > 0]\n\n    def footer(self, rows: list[tuple]) -> str:\n        return f\"fines due: {sum(days * 50 for _, _, days in rows)} cents\"\n\n\nclass PopularReport(Report):\n    def __init__(self, counts: dict[str, int]):\n        self._counts = counts\n\n    def title(self) -> str:\n        return \"Most borrowed this month\"\n\n    def rows(self) -> list[tuple]:\n        return sorted(self._counts.items(), key=lambda kv: -kv[1])[:2]\n\n\nif __name__ == \"__main__\":\n    loans = [(\"Bia\", \"Dom Casmurro\", 4), (\"Caio\", \"Vidas Secas\", 0), (\"Duda\", \"Quincas Borba\", 9)]\n    print(OverdueReport(loans).render())\n    print(PopularReport({\"Torto Arado\": 11, \"Vidas Secas\": 7, \"Dom Casmurro\": 9}).render())", "note": "Um relatório sobrescreve o rodapé e o outro fica com o padrão. Nenhum dos dois pode mudar a ordem dos passos."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 template.py
Overdue loans
-------------
  Bia | Dom Casmurro | 4
  Duda | Quincas Borba | 9
fines due: 650 cents
Most borrowed this month
------------------------
  Torto Arado | 11
  Dom Casmurro | 9
2 rows
```

**A classe base chama a subclasse, e não o contrário**: a inversão de controle da lição 5, dentro de
uma hierarquia de classes. Essa também é a fraqueza dele. Uma subclasse de `Report` depende de
quando e em que ordem `render` chama os seus métodos, que é a classe base frágil da lição 2. Se as
variações se multiplicarem, passe os passos como strategies, que é o mesmo roteiro construído por
composição.

## Iterator: percorrer sem saber a forma

A estante guarda os livros num dicionário indexado pela classificação. O código que imprime a lista
da estante não deveria saber disso, nem mudar se a estante passar a ser uma lista ordenada ou um
cursor de banco. Ele só deveria conseguir pedir o próximo livro.

```schooling-example
{"language": "python", "file": "iterator.py", "parts": [
 {"code": "# iterator.py\nclass MarkWalker:\n    def __init__(self, marks: list[str]):\n        self._marks, self._next = sorted(marks), 0\n\n    def __iter__(self):\n        return self\n\n    def __next__(self) -> str:\n        if self._next == len(self._marks):\n            raise StopIteration\n        self._next += 1\n        return self._marks[self._next - 1]", "note": "A forma do GoF, escrita por extenso: um objeto que lembra onde está e entrega um elemento a cada chamada a `__next__`, levantando `StopIteration` no fim."},
 {"code": "\n\nclass Shelf:\n    def __init__(self):\n        self._books: dict[str, str] = {}\n\n    def put(self, mark: str, title: str) -> None:\n        self._books[mark] = title\n\n    def __iter__(self):\n        for mark in MarkWalker(list(self._books)):\n            yield mark, self._books[mark]\n\n    def section(self, prefix: str):\n        return ((mark, title) for mark, title in self if mark.startswith(prefix))", "note": "A estante entrega um iterador quando pedem. Um gerador faz isso em três linhas: `yield` transforma o método num objeto iterador com o `__next__` pronto."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = Shelf()\n    shelf.put(\"869.3 RAM\", \"Vidas Secas\")\n    shelf.put(\"869.3 ASS\", \"Dom Casmurro\")\n    shelf.put(\"791 MEI\", \"Cidade de Deus\")\n    for mark, title in shelf:\n        print(mark, title)\n    walker = iter(shelf)\n    print(\"by hand:\", next(walker), next(walker))\n    print(\"section 869:\", [title for _, title in shelf.section(\"869\")])", "note": "Um laço `for` pede um iterador com `iter()` e chama `next()` nele até `StopIteration`. Feitas à mão, as mesmas duas chamadas mostram o que o laço faz."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 iterator.py
791 MEI Cidade de Deus
869.3 ASS Dom Casmurro
869.3 RAM Vidas Secas
by hand: ('791 MEI', 'Cidade de Deus') ('869.3 ASS', 'Dom Casmurro')
section 869: ['Dom Casmurro', 'Vidas Secas']
```

O laço imprimiu na ordem da classificação, embora os livros tenham entrado em outra ordem e o
dicionário guarde a ordem de inserção. Ninguém fora de `Shelf` sabe que há um dicionário, nem que
`MarkWalker` existe. `section` filtra de forma preguiçosa: produz cada resultado quando pedem, então
uma estante de um milhão de livros seria percorrida uma vez, sem ser copiada para uma lista antes.

Na maior parte deste curso você vai escrever o gerador e nunca a classe. `MarkWalker` está aqui
porque é o que um gerador escreve por você, e porque é o que o livro GoF descreve: em C++, em 1994,
não havia `yield`. O Java tem `Iterator` com `hasNext` e `next` e o `for` aprimorado que os chama; o
JavaScript tem o mesmo protocolo com `[Symbol.iterator]` e `function*`; o Go acrescentou iteradores
com range sobre funções no Go 1.23. O padrão virou recurso de linguagem nas quatro.
