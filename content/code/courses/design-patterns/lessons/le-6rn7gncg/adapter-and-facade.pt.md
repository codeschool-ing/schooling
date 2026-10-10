---
title: "Adapter e facade: o formato do código dos outros"
version: 1
---

**Um adapter faz uma interface parecer outra que o seu código já espera; uma facade põe uma
interface simples na frente de vários objetos para quem chama lidar com uma coisa em vez de cinco.**
Os dois são padrões estruturais sobre uma fronteira, e os dois embrulham outros objetos, e por isso
são confundidos. A diferença é a pergunta que cada um responde. Um adapter responde "isto faz o que
eu preciso, mas fala a língua errada". Uma facade responde "este subsistema é demais para todo
chamador entender".

## Um adapter: traduzindo na fronteira

A biblioteca quer preencher os dados de um livro a partir de um serviço de catálogo nacional. O
serviço vem com um cliente que outra pessoa escreveu, e a ideia de livro dele não é a nossa: ele
responde com um status e um registro, chama o título de `ttl` e escreve os autores com o sobrenome
primeiro.

```schooling-example
{"language": "python", "file": "adapter.py", "parts": [
 {"code": "# adapter.py\nfrom dataclasses import dataclass\nfrom typing import Protocol\n\n\n@dataclass(frozen=True)\nclass Book:\n    isbn: str\n    title: str\n    author: str\n\n\nclass Catalogue(Protocol):\n    def find(self, isbn: str) -> Book | None: ...", "note": "O nosso lado. O resto do programa trabalha com `Book` e pede um a um `Catalogue`; nunca viu o formato do serviço."},
 {"code": "\n\nclass OpenShelfClient:\n    _RECORDS = {\n        \"9786555550123\": {\"ttl\": \"Vidas Secas\", \"auth\": [\"Ramos, Graciliano\"]},\n        \"9786555550147\": {\"ttl\": \"Dom Casmurro\", \"auth\": [\"Assis, Machado de\"]},\n    }\n\n    def lookup(self, code: str) -> dict:\n        record = self._RECORDS.get(code.replace(\"-\", \"\"))\n        return {\"status\": \"ok\", \"record\": record} if record else {\"status\": \"not_found\"}", "note": "O lado deles, no lugar de um cliente que você não pode mudar. Os dados são dois registros inventados; um cliente de verdade faria uma chamada de rede."},
 {"code": "\n\nclass OpenShelfCatalogue:\n    def __init__(self, client: OpenShelfClient):\n        self._client = client\n\n    def find(self, isbn: str) -> Book | None:\n        answer = self._client.lookup(isbn)\n        if answer[\"status\"] != \"ok\":\n            return None\n        record = answer[\"record\"]\n        surname, given = record[\"auth\"][0].split(\", \")\n        return Book(isbn, record[\"ttl\"], f\"{given} {surname}\")", "note": "O adapter. Ele implementa o nosso protocolo e guarda o cliente deles, e toda diferença entre os dois mundos é traduzida aqui e em nenhum outro lugar."},
 {"code": "\n\nif __name__ == \"__main__\":\n    catalogue: Catalogue = OpenShelfCatalogue(OpenShelfClient())\n    print(catalogue.find(\"978-65-5555-012-3\"))\n    print(catalogue.find(\"978-65-5555-099-9\"))", "note": "Quem chama vê um `Catalogue`. Uma string de status, um `ttl` e um autor com sobrenome primeiro nunca chegam até ele."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 adapter.py
Book(isbn='978-65-5555-012-3', title='Vidas Secas', author='Graciliano Ramos')
None
```

**O adapter é onde o modelo estrangeiro para.** Quando o serviço renomear `ttl` para `title`, um
método muda. Sem ele, `record["ttl"]` estaria espalhado por toda função que mostra um livro, e a
renomeação seria uma busca pelo programa inteiro. A lição 11 dá um nome próprio a uma versão maior
disso, a camada anticorrupção, e a constrói entre duas partes da biblioteca.

## Uma facade: uma porta para um subsistema

Emprestar um livro mexe com vários objetos: o catálogo para encontrá-lo, as reservas para conferir
que ninguém mais está esperando, o registro para anotar o empréstimo, a impressora para o
comprovante. Toda tela que empresta alguma coisa teria de conhecer os quatro e chamá-los na ordem
certa.

```schooling-example
{"language": "python", "file": "facade.py", "parts": [
 {"code": "# facade.py\nfrom datetime import date, timedelta\n\nfrom adapter import Catalogue, OpenShelfCatalogue, OpenShelfClient", "note": "A facade reaproveita o adapter de `adapter.py`, então mantenha os dois arquivos no mesmo diretório."},
 {"code": "\n\nclass Ledger:\n    def __init__(self):\n        self.loans = {}\n\n    def record(self, member: str, isbn: str, due: date) -> None:\n        self.loans[isbn] = (member, due)\n\n\nclass Reservations:\n    def __init__(self, waiting: dict[str, list[str]]):\n        self._waiting = waiting\n\n    def first_in_line(self, isbn: str) -> str | None:\n        queue = self._waiting.get(isbn, [])\n        return queue[0] if queue else None\n\n\nclass SlipPrinter:\n    def issue(self, text: str) -> None:\n        print(f\"slip: {text}\")", "note": "Três subsistemas pequenos. Cada um é simples; o que não é simples é saber qual chamar, quando, e o que fazer com cada resposta."},
 {"code": "\n\nclass LendingDesk:\n    LOAN_DAYS = 14\n\n    def __init__(self, catalogue: Catalogue, ledger: Ledger,\n                 reservations: Reservations, printer: SlipPrinter):\n        self._catalogue, self._ledger = catalogue, ledger\n        self._reservations, self._printer = reservations, printer\n\n    def lend(self, member: str, isbn: str, today: date) -> str:\n        book = self._catalogue.find(isbn)\n        if book is None:\n            return f\"no such book: {isbn}\"\n        waiting = self._reservations.first_in_line(isbn)\n        if waiting not in (None, member):\n            return f\"{book.title} is reserved for {waiting}\"\n        due = today + timedelta(days=self.LOAN_DAYS)\n        self._ledger.record(member, isbn, due)\n        self._printer.issue(f\"{member} has {book.title} until {due}\")\n        return \"lent\"", "note": "A facade. O seu único método guarda a ordem dos passos e as regras entre eles, e quem quer emprestar um livro chama `lend` e mais nada."},
 {"code": "\n\nif __name__ == \"__main__\":\n    desk = LendingDesk(OpenShelfCatalogue(OpenShelfClient()), Ledger(),\n                       Reservations({\"978-65-5555-012-3\": [\"Caio\"]}), SlipPrinter())\n    today = date(2026, 5, 4)\n    print(desk.lend(\"Bia\", \"978-65-5555-014-7\", today))\n    print(desk.lend(\"Bia\", \"978-65-5555-012-3\", today))\n    print(desk.lend(\"Caio\", \"978-65-5555-012-3\", today))\n    print(desk.lend(\"Bia\", \"978-65-5555-099-9\", today))", "note": "Quatro pedidos pela mesma porta: um empréstimo comum, um livro que outra pessoa reservou, o mesmo livro para quem o reservou, e um ISBN que ninguém conhece."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 facade.py
slip: Bia has Dom Casmurro until 2026-05-18
lent
Vidas Secas is reserved for Caio
slip: Caio has Vidas Secas until 2026-05-18
lent
no such book: 978-65-5555-099-9
```

## Como distinguir os dois

| | adapter | facade |
|---|---|---|
| embrulha | um objeto | vários objetos |
| a sua interface é | uma que quem chama já espera | uma nova, mais simples |
| por que existe | as interfaces não combinam | o subsistema é demais para conhecer |
| nesta lição | `OpenShelfCatalogue` | `LendingDesk` |

Uma facade não esconde o subsistema de quem precisa dele: `Ledger` continua lá para o relatório
mensal que lê todos os empréstimos. Ela dá uma porta ao caso comum. **O risco de uma facade é crescer
até virar uma classe que faz tudo**, então mantenha-a coordenando, e deixe cada regra no subsistema
que é dono dela. As portas e adaptadores da lição 4 são o mesmo adapter na escala de uma aplicação
inteira: todo sistema de fora chega ao núcleo por um deles.
