---
title: "MVC: a view observa o modelo"
version: 1
---

**O model-view-controller divide um programa com tela em regras, desenho e entrada, e o movimento
que o define é a view observar o modelo.** Trygve Reenskaug o descreveu no Xerox PARC em 1979, para
o Smalltalk, e a biblioteca de classes do Smalltalk-80 o trouxe pronto. Quando o modelo muda, ele
anuncia a mudança; toda view que se inscreveu se redesenha. O controller nunca manda uma view se
redesenhar. Uma crença comum é que o controller busca os dados e os passa para a view. Essa é a
versão web, que é a próxima seção, e ela perdeu o observer no caminho.

## O modelo

O modelo são as regras da seção anterior, tiradas do laço e com nomes. É o arquivo que todo
programa desta lição importa.

```schooling-example
{"language": "python", "file": "desk_model.py", "parts": [
 {"code": "# desk_model.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\n\nDAILY_FINE = 50  # cents\n\n\n@dataclass\nclass Loan:\n    code: str\n    member: str\n    due: date", "note": "O empréstimo da lição 1, reduzido ao que o balcão precisa: qual item, quem está com ele, quando vence. As multas continuam em centavos inteiros."},
 {"code": "\n\nclass Desk:\n    def __init__(self, codes: list[str], limit: int = 5):\n        self.on_shelf = list(codes)\n        self.loans: dict[str, Loan] = {}\n        self.limit = limit\n        self._watchers = []", "note": "O balcão guarda a estante e os empréstimos. `limit` tem como padrão os cinco da biblioteca; os programas desta lição passam dois para as transcrições ficarem curtas."},
 {"code": "\n    def subscribe(self, watcher) -> None:\n        self._watchers.append(watcher)\n\n    def _changed(self) -> None:\n        for watcher in self._watchers:\n            watcher()", "note": "Qualquer um pode pedir para ser avisado quando o balcão muda. O balcão guarda uma lista de funções e chama cada uma; ele não sabe nem quer saber o que elas fazem. É o observer da lição 6."},
 {"code": "\n    def held_by(self, member: str) -> int:\n        return sum(1 for loan in self.loans.values() if loan.member == member)", "note": "Uma pergunta de que as regras precisam e que uma tela pode querer também. É um método do modelo para ninguém mais ter de contar empréstimos do seu próprio jeito."},
 {"code": "\n    def lend(self, code: str, member: str, on: date) -> Loan:\n        if code not in self.on_shelf:\n            raise ValueError(f\"{code} is not on the shelf\")\n        if self.held_by(member) >= self.limit:\n            raise ValueError(f\"{member} already has {self.limit} loans\")\n        self.on_shelf.remove(code)\n        loan = self.loans[code] = Loan(code, member, on + timedelta(days=14))\n        self._changed()\n        return loan", "note": "As duas regras do empréstimo, e a mudança em si. Uma recusa é uma exceção com uma frase, nunca um `print`: o modelo não tem como saber se suas palavras vão parar num terminal, numa página web ou em lugar nenhum."},
 {"code": "\n    def give_back(self, code: str, on: date) -> int:\n        if code not in self.loans:\n            raise ValueError(f\"{code} is not out on loan\")\n        loan = self.loans.pop(code)\n        self.on_shelf.append(code)\n        self._changed()\n        return max((on - loan.due).days, 0) * DAILY_FINE", "note": "A devolução calcula a multa e a entrega como número. Como uma multa aparece na tela é decisão de outra pessoa."}
]}
```

Leia procurando o que falta. **Não há `print`, nem `input`, nem `sys.stdin` em lugar nenhum do
modelo**, e as recusas são exceções que carregam uma frase. Esses dois fatos são o que permite a um
só modelo servir um terminal, uma página web e um teste sem mudança nenhuma, que é o que o resto da
lição faz.

## A view e o controller

```schooling-example
{"language": "python", "file": "mvc.py", "parts": [
 {"code": "# mvc.py\nimport sys\nfrom datetime import date\nfrom desk_model import Desk", "note": "O modelo é importado, não copiado. Nada em `desk_model.py` vai mudar no resto da lição."},
 {"code": "\n\nclass ShelfView:\n    def __init__(self, desk: Desk):\n        self.desk = desk\n        desk.subscribe(self.render)\n\n    def render(self) -> None:\n        shelf = \", \".join(sorted(self.desk.on_shelf)) or \"empty\"\n        print(f\"  [shelf: {shelf} | out: {len(self.desk.loans)}]\")", "note": "A view guarda uma referência ao modelo e se inscreve nele. Daí em diante o balcão chama `render` depois de cada mudança, e ninguém mais precisa se lembrar de chamar."},
 {"code": "\n    def say(self, text: str) -> None:\n        print(f\"  {text}\")", "note": "A view também imprime as mensagens curtas do controller, para toda linha da tela passar por uma classe só."},
 {"code": "\n\nclass DeskController:\n    def __init__(self, desk: Desk, view: ShelfView, today: date):\n        self.desk, self.view, self.today = desk, view, today", "note": "O controller conhece o modelo e a view. Ele é dono do único pedaço de estado que é da sessão e não da biblioteca: que dia o balcão acha que é."},
 {"code": "\n    def handle(self, line: str) -> None:\n        cmd, *args = line.split()\n        try:\n            if cmd == \"lend\":\n                loan = self.desk.lend(args[0], args[1], self.today)\n                self.view.say(f\"{loan.code} due back {loan.due}\")\n            elif cmd == \"return\":\n                fine = self.desk.give_back(args[0], self.today)\n                self.view.say(f\"fine: {fine} cents\")\n            elif cmd == \"day\":\n                self.today = date.fromisoformat(args[0])\n            else:\n                self.view.say(f\"unknown command {cmd!r}\")\n        except ValueError as err:\n            self.view.say(f\"refused: {err}\")", "note": "Entra a entrada, sai uma chamada ao modelo. O controller interpreta o comando, chama o modelo e transforma uma recusa numa mensagem. Ele nunca desenha a estante: não precisa, porque a view já está observando."},
 {"code": "\n\nif __name__ == \"__main__\":\n    desk = Desk([\"B1\", \"B2\", \"B3\"], limit=2)\n    view = ShelfView(desk)\n    controller = DeskController(desk, view, date(2026, 3, 2))\n    for line in sys.stdin:\n        print(\">\", line.strip())\n        controller.handle(line)", "note": "A montagem: criar o modelo, entregá-lo à view, entregar os dois ao controller, e então alimentar o controller uma linha por vez. Cada comando é repetido depois de `>` para a transcrição se ler como uma conversa."}
]}
```

Salve `desk_model.py` e `mvc.py` lado a lado e mande seis comandos ao balcão, os dois últimos depois
de adiantar o relógio para 20 de março:

```
ana@laptop:~/patterns/presentation$ printf 'lend B1 bia\nlend B2 bia\nlend B3 bia\nday 2026-03-20\nreturn B1\nreturn B1\n' | python3 mvc.py
> lend B1 bia
  [shelf: B2, B3 | out: 1]
  B1 due back 2026-03-16
> lend B2 bia
  [shelf: B3 | out: 2]
  B2 due back 2026-03-16
> lend B3 bia
  refused: bia already has 2 loans
> day 2026-03-20
> return B1
  [shelf: B1, B3 | out: 1]
  fine: 200 cents
> return B1
  refused: B1 is not out on loan
```

Repare na ordem das duas linhas embaixo de cada empréstimo. A estante aparece **antes** da mensagem
do controller. O controller chamou `desk.lend`; dentro dessa chamada, o balcão rodou `_changed`, que
rodou o `render` da view; só depois que `lend` retornou o controller pôde dizer quando o B1 vence.
Essa ordem é o observer trabalhando, e é a marca do MVC original.

As recusas mostram a outra metade. `lend B3 bia` não mudou nada, então o modelo não anunciou nada e
nenhuma linha de estante foi desenhada; o controller transformou a exceção em `refused: …`. A multa
de 200 centavos são quatro dias a 50, a partir do vencimento em 16 de março, e o modelo a calculou
sem saber que ela seria impressa.

## Quem conhece quem

As setas importam mais que os nomes, então aqui estão elas para `mvc.py`:

| classe | guarda referência a | é chamada por |
|---|---|---|
| `Desk` (modelo) | uma lista de funções, e nada mais | o controller, para mudá-lo; a view, para lê-lo |
| `ShelfView` | o modelo | o modelo, via `subscribe`; o controller, via `say` |
| `DeskController` | o modelo e a view | o laço principal, com cada linha de entrada |

**O modelo não aponta para ninguém.** Ele guarda funções, que podem pertencer a uma view de
terminal, a um arquivo de log ou a um teste; `desk_model.py` não importa nada do programa em volta.
A view lê o modelo diretamente, o que é cômodo e é também o ponto fraco do MVC. Toda lógica que
decide a aparência da estante, aqui a ordenação e a palavra `empty`, mora dentro da view, e a view é
a classe mais difícil de testar porque a saída dela é uma tela. O MVP, duas seções adiante, existe
para resolver exatamente isso.

No Smalltalk original cada widget da tela tinha seu próprio par de view e controller, e uma janela
era uma árvore deles. A maioria dos toolkits de desktop desde então fundiu os dois num único objeto
widget que desenha e trata os próprios cliques, e é por isso que "MVC" num framework de desktop
muitas vezes quer dizer "um modelo e alguns widgets". A parte que sobreviveu em todo lugar é o
modelo anunciando suas mudanças.
