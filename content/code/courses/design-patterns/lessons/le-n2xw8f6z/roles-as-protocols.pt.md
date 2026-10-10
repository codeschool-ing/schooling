---
title: Papéis como protocolos pequenos
version: 1
---

**Uma interface de papel é um protocolo pequeno com o nome do que um tipo de cliente faz com um
objeto: buscar, emprestar, abastecer o acervo.** Uma classe pode fazer vários papéis, e cada cliente
depende daquele de que precisa. A classe continua inteira; só as declarações são divididas.

Uma preocupação comum é que segregar interfaces significa dividir a classe também: um
`SearchService`, um `LendingService` e um `StockService`, cada um com um pedaço dos dados do
catálogo. Às vezes isso está certo, e quem decide é o princípio da responsabilidade única. A
segregação de interfaces não pede isso. Os títulos da biblioteca e quem os pegou são um conjunto só
de dados, e uma classe pode guardá-lo mostrando uma cara diferente a cada cliente.

## Três papéis, uma biblioteca

```schooling-example
{"language": "python", "file": "roles.py", "parts": [
 {"code": "# roles.py\nfrom typing import Protocol\n\n\nclass Searching(Protocol):\n    def search(self, words: str) -> list[str]: ...\n\n\nclass Lending(Protocol):\n    def lend(self, title: str, member: str) -> None: ...\n\n\nclass Stocking(Protocol):\n    def add_title(self, title: str) -> None: ...", "note": "Três papéis, cada um com o nome de uma atividade. Os nomes são o que um leitor vê na assinatura de um cliente, então dizem o que o cliente faz."},
 {"code": "\n\nclass Library:\n    def __init__(self):\n        self._borrower: dict[str, str | None] = {}\n\n    def search(self, words: str) -> list[str]:\n        return [t for t in self._borrower if words.lower() in t.lower()]\n\n    def lend(self, title: str, member: str) -> None:\n        if self._borrower[title] is not None:\n            raise ValueError(f\"{title!r} is already out\")\n        self._borrower[title] = member\n\n    def add_title(self, title: str) -> None:\n        self._borrower.setdefault(title, None)", "note": "Uma classe, um dicionário de títulos, e os métodos dos três papéis. Ela não cita nenhum dos protocolos; ter os métodos basta."},
 {"code": "\n\ndef back_office(stock: Stocking, titles: list[str]) -> None:\n    for title in titles:\n        stock.add_title(title)\n\n\ndef desk(lending: Lending, title: str, member: str) -> None:\n    lending.lend(title, member)\n    print(f\"lent {title} to {member}\")\n\n\ndef kiosk(catalogue: Searching, words: str) -> None:\n    print(f\"{words!r}:\", catalogue.search(words))", "note": "Cada cliente declara um papel. O quiosque não consegue mais alcançar `lend` nem por acidente, e uma mudança em `lend` não pode dizer respeito a ele."},
 {"code": "\n\nclass OneTitle:\n    def search(self, words: str) -> list[str]:\n        return [\"Vidas Secas\"]", "note": "O substituto que falhou na primeira seção, agora com três linhas e aceito."},
 {"code": "\n\nif __name__ == \"__main__\":\n    library = Library()\n    back_office(library, [\"Vidas Secas\", \"Memórias Póstumas de Brás Cubas\", \"Vidas Paralelas\"])\n    desk(library, \"Vidas Secas\", \"Bia\")\n    kiosk(library, \"vidas\")\n    kiosk(OneTitle(), \"anything\")", "note": "O mesmo objeto `library` é passado aos três clientes, e cada um vê só o seu papel."}
]}
```

```
ana@laptop:~/patterns/solid-2$ python3 roles.py
lent Vidas Secas to Bia
'vidas': ['Vidas Secas', 'Vidas Paralelas']
'anything': ['Vidas Secas']
```

A biblioteca recebe os títulos, empresta um e responde a uma busca; depois o quiosque recebe o
substituto e funciona com ele do mesmo jeito. **A dependência inteira do quiosque é um método, então
o dublê de teste inteiro dele é um método.**

## De quem é um papel

Repare onde os protocolos poderiam morar. `Searching` é o que o quiosque precisa, então pertence ao
quiosque: escrito por quem escreve o quiosque, mudado quando as necessidades do quiosque mudam. A
classe `Library` o satisfaz sem importá-lo, em Python, Go e TypeScript, porque essas linguagens
verificam o formato. Esse arranjo, em que o cliente define a interface e o implementador por acaso
se encaixa, é prática comum em Go. O `io.Reader` da biblioteca padrão tem um método, `Read`, e
milhares de tipos o satisfazem sem citá-lo; a frase de Rob Pike para isso é "quanto maior a
interface, mais fraca a abstração".

| linguagem | uma classe fazendo três papéis | onde o papel costuma ser declarado |
|---|---|---|
| Python | tem os métodos; `Protocol`s descrevem os papéis | em qualquer lugar; melhor perto do cliente |
| Go | tem os métodos; `interface`s pequenas descrevem os papéis | no pacote do cliente |
| TypeScript | tem os métodos; `interface`s descrevem os papéis | em qualquer lugar; verificado pelo formato |
| Java | `class Library implements Searching, Lending, Stocking` | ao lado da classe, já que ela precisa citá-los |

Java é a exceção, porque uma classe precisa citar cada interface que implementa. Ainda vale a pena
dividir os papéis lá; o custo é que `Library` tem de importar os três, então a seta de dependência
vai da classe para cada papel. Essa seta, e para que lado ela deveria apontar, é o assunto da
próxima seção.

## Quão pequeno é pequeno o bastante

Os papéis aqui têm um método cada porque cada cliente chama um. Se o balcão também recebe livros de
volta, `Lending` ganha `give_back` também, já que o mesmo cliente chama os dois e eles mudam juntos.
Separar `lend` e `give_back` em dois protocolos daria dois nomes às necessidades de um cliente e não
compraria nada. Um papel é o conjunto de métodos que um tipo de cliente usa, seja qual for o tamanho.
