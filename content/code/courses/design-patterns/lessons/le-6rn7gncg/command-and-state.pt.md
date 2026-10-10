---
title: "Command e state: pedidos como objetos, comportamento que muda com a situação"
version: 1
---

**Command transforma um pedido num objeto, para ele poder ser guardado, enfileirado, registrado e
desfeito; state dá a um objeto um comportamento diferente para cada situação em que ele pode estar,
delegando a um objeto que representa a situação.** Os dois trocam algo que costuma ficar implícito,
uma chamada de método ou um emaranhado de `if status == ...`, por algo que você pode nomear e
segurar.

## Command: um pedido que se guarda

Uma chamada de método acontece e some. Se o balcão quer desfazer a última coisa que fez, precisa de
um registro do que foi e de como revertê-lo. Command faz de cada ação um objeto com `execute` e
`undo`, e o balcão guarda uma lista deles.

```schooling-example
{"language": "python", "file": "command.py", "parts": [
 {"code": "# command.py\nfrom typing import Protocol\n\n\nclass Command(Protocol):\n    def execute(self) -> None: ...\n    def undo(self) -> None: ...\n\n\nclass Shelf:\n    def __init__(self, titles: list[str]):\n        self.available = set(titles)\n        self.on_loan: dict[str, str] = {}\n\n    def report(self) -> str:\n        return f\"available {sorted(self.available)}, on loan {self.on_loan}\"", "note": "A interface do comando, e a estante sobre a qual os comandos agem. A estante são dados simples; ela não sabe nada de desfazer."},
 {"code": "\n\nclass Lend:\n    def __init__(self, shelf: Shelf, title: str, member: str):\n        self.shelf, self.title, self.member = shelf, title, member\n\n    def execute(self) -> None:\n        self.shelf.available.remove(self.title)\n        self.shelf.on_loan[self.title] = self.member\n\n    def undo(self) -> None:\n        del self.shelf.on_loan[self.title]\n        self.shelf.available.add(self.title)\n\n    def __str__(self) -> str:\n        return f\"lend {self.title} to {self.member}\"\n\n\nclass Return:\n    def __init__(self, shelf: Shelf, title: str):\n        self.shelf, self.title, self.member = shelf, title, \"\"\n\n    def execute(self) -> None:\n        self.member = self.shelf.on_loan.pop(self.title)\n        self.shelf.available.add(self.title)\n\n    def undo(self) -> None:\n        self.shelf.available.remove(self.title)\n        self.shelf.on_loan[self.title] = self.member\n\n    def __str__(self) -> str:\n        return f\"return {self.title}\"", "note": "Um comando carrega tudo o que é preciso para fazer a ação e para revertê-la. `Return` descobre com que membro o livro estava quando roda, e guarda isso para o `undo`."},
 {"code": "\n\nclass Desk:\n    def __init__(self):\n        self.history: list[Command] = []\n\n    def run(self, command: Command) -> None:\n        command.execute()\n        self.history.append(command)\n        print(\"did:  \", command)\n\n    def undo_last(self) -> None:\n        command = self.history.pop()\n        command.undo()\n        print(\"undid:\", command)", "note": "O invocador. Ele roda comandos e se lembra deles, e desfazer é tirar o último da lista. Ele não faz ideia do que emprestar ou devolver significa."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = Shelf([\"Dom Casmurro\", \"Vidas Secas\"])\n    desk = Desk()\n    desk.run(Lend(shelf, \"Dom Casmurro\", \"Bia\"))\n    desk.run(Lend(shelf, \"Vidas Secas\", \"Caio\"))\n    desk.run(Return(shelf, \"Dom Casmurro\"))\n    print(shelf.report())\n    desk.undo_last()\n    desk.undo_last()\n    print(shelf.report())", "note": "Três ações, depois duas desfeitas em ordem inversa. A estante termina como estava depois do primeiro empréstimo."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 command.py
did:   lend Dom Casmurro to Bia
did:   lend Vidas Secas to Caio
did:   return Dom Casmurro
available ['Dom Casmurro'], on loan {'Vidas Secas': 'Caio'}
undid: return Dom Casmurro
undid: lend Vidas Secas to Caio
available ['Vidas Secas'], on loan {'Dom Casmurro': 'Bia'}
```

Desfazer é o uso clássico, e não o único. Uma lista de objetos comando pode ser enfileirada para
depois, gravada num log e reexecutada, mandada para outro processo, ou agrupada num comando maior
que roda ou desfaz vários juntos. **Quando um pedido vira objeto, tudo o que você faz com objetos dá
para fazer com pedidos.** A lição 8 se apoia nisso ao separar comandos de consultas, e a lição 9
guarda o registro do que aconteceu como a verdade do sistema.

## State: um objeto, regras diferentes em cada situação

Um exemplar de livro pode estar na estante, emprestado, ou na estante de reservas esperando o membro
que o reservou. O que `lend` deve fazer depende inteiramente de qual. Escrito com um campo de status,
cada método vira uma escada de `if self.status == ...`, e acrescentar uma situação significa editar
cada escada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l06-state\" aria-label=\"Um diagrama de estados de um exemplar de livro com três estados: Available, OnLoan e OnHold. De Available, lend vai para OnLoan e reserve vai para OnHold. De OnLoan, give_back vai para Available quando ninguém espera e para OnHold quando alguém espera; reserve fica em OnLoan e guarda quem espera. De OnHold, lend pelo membro para quem está guardado vai para OnLoan. Todo outro pedido num estado é recusado.\"><defs><marker id=\"l06-state-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"25.0\" y=\"92.0\" width=\"150.0\" height=\"46.0\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Available</text><rect x=\"285.0\" y=\"92.0\" width=\"150.0\" height=\"46.0\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">OnLoan</text><text x=\"360.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">guarda quem espera</text><rect x=\"545.0\" y=\"92.0\" width=\"150.0\" height=\"46.0\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">OnHold</text><text x=\"620.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">para um membro</text><path d=\"M175.0 104.0 L283.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-state-dp-ah-paper-dim)\"></path><text x=\"229.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lend</text><path d=\"M283.0 128.0 L177.0 128.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-state-dp-ah-paper-dim)\"></path><text x=\"229.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">give_back</text><text x=\"229.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">ninguém espera</text><path d=\"M435.0 115.0 L543.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-state-dp-ah-paper-dim)\"></path><text x=\"489.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">give_back</text><text x=\"489.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">alguém espera</text><path d=\"M100.0 92.0 L100.0 46.0 L620.0 46.0 L620.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-state-dp-ah-paper-dim)\"></path><text x=\"360.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">reserve</text><path d=\"M620.0 138.0 L620.0 190.0 L360.0 190.0 L360.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-state-dp-ah-paper-dim)\"></path><text x=\"490.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">lend</text><text x=\"490.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">pelo membro para quem está guardado</text><text x=\"100.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">qualquer outro pedido:</text><text x=\"100.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">Refused, com o motivo</text></svg>", "caption": "Um exemplar, três situações. Cada seta é um método que leva o exemplar adiante; cada seta que falta é uma recusa com motivo."}
```

```schooling-example
{"language": "python", "file": "state.py", "parts": [
 {"code": "# state.py\nclass Refused(Exception):\n    pass", "note": "Uma exceção para toda recusa, levando o motivo em palavras."},
 {"code": "\n\nclass Available:\n    def lend(self, copy, member):\n        copy.state = OnLoan(member)\n\n    def give_back(self, copy):\n        raise Refused(\"it is already on the shelf\")\n\n    def reserve(self, copy, member):\n        copy.state = OnHold(member)\n\n    def __str__(self):\n        return \"available\"\n\n\nclass OnLoan:\n    def __init__(self, member, waiting=None):\n        self.member, self.waiting = member, waiting\n\n    def lend(self, copy, member):\n        raise Refused(f\"it is out with {self.member}\")\n\n    def give_back(self, copy):\n        copy.state = OnHold(self.waiting) if self.waiting else Available()\n\n    def reserve(self, copy, member):\n        if self.waiting:\n            raise Refused(f\"{self.waiting} reserved it first\")\n        copy.state = OnLoan(self.member, waiting=member)\n\n    def __str__(self):\n        extra = f\", {self.waiting} waiting\" if self.waiting else \"\"\n        return f\"on loan to {self.member}{extra}\"\n\n\nclass OnHold:\n    def __init__(self, member):\n        self.member = member\n\n    def lend(self, copy, member):\n        if member != self.member:\n            raise Refused(f\"it is held for {self.member}\")\n        copy.state = OnLoan(member)\n\n    def give_back(self, copy):\n        raise Refused(\"it was never lent\")\n\n    def reserve(self, copy, member):\n        raise Refused(f\"it is held for {self.member}\")\n\n    def __str__(self):\n        return f\"on hold for {self.member}\"", "note": "Cada situação é uma classe com os mesmos três métodos. Um método leva o exemplar ao próximo estado ou recusa, e as regras de uma situação ficam juntas."},
 {"code": "\n\nclass Copy:\n    def __init__(self, title):\n        self.title, self.state = title, Available()\n\n    def lend(self, member):\n        self.state.lend(self, member)\n\n    def give_back(self):\n        self.state.give_back(self)\n\n    def reserve(self, member):\n        self.state.reserve(self, member)", "note": "O contexto. Ele guarda o estado atual e repassa cada chamada a ele, e não contém nenhum `if` sobre status."},
 {"code": "\n\nif __name__ == \"__main__\":\n    copy = Copy(\"Torto Arado\")\n    steps = [(\"lend\", \"Bia\"), (\"reserve\", \"Caio\"), (\"lend\", \"Duda\"), (\"give_back\",),\n             (\"lend\", \"Duda\"), (\"lend\", \"Caio\"), (\"give_back\",), (\"give_back\",)]\n    for action, *who in steps:\n        label = f\"{action} {' '.join(who)}\".strip()\n        try:\n            getattr(copy, action)(*who)\n            print(f\"{label:<14} -> {copy.state}\")\n        except Refused as err:\n            print(f\"{label:<14} refused: {err}\")", "note": "Um dia na vida de um exemplar, incluindo três pedidos que as regras recusam."}
]}
```

```
ana@laptop:~/patterns/gof$ python3 state.py
lend Bia       -> on loan to Bia
reserve Caio   -> on loan to Bia, Caio waiting
lend Duda      refused: it is out with Bia
give_back      -> on hold for Caio
lend Duda      refused: it is held for Caio
lend Caio      -> on loan to Caio
give_back      -> available
give_back      refused: it is already on the shelf
```

Toda recusa diz o motivo, e cada motivo mora na única classe onde se aplica. Uma quarta situação,
digamos um exemplar mandado para conserto, é uma classe nova mais as transições até ela, e as três
classes existentes só mudam onde uma transição leva à nova.

## State e strategy têm a mesma forma

Os dois são um contexto que guarda um objeto atrás de uma interface e delega a ele. A diferença é
quem troca o objeto. **Uma strategy é escolhida de fora e fica até alguém trocá-la; um state se
substitui como resultado das chamadas que trata.** `WaitingList` nunca muda a própria ordenação, e o
estado de `Copy` nunca é definido por quem chama.

Para um punhado de estados e poucos métodos, um dicionário de transições permitidas ou um `match`
costuma ser mais claro do que uma classe por estado. O padrão merece o lugar quando cada estado tem
comportamento próprio de verdade, como `OnLoan` tem com o membro que espera, e quando estados vão
sendo acrescentados com o tempo.
