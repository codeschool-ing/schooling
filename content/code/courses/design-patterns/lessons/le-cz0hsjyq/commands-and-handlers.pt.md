---
title: Comandos, handlers e os eventos que eles publicam
version: 1
---

**No lado da escrita, toda mudança chega como um comando, um objeto que nomeia uma coisa que alguém
quer feita, e um handler decide se a faz.** O handler confere as regras contra o modelo de escrita,
faz a mudança ou recusa, e quando dá certo publica um evento dizendo o que aconteceu. Três tipos de
objeto, e a gramática os distingue: um comando está no imperativo, `LendCopy`; um evento está no
passado, `CopyLent`; um handler é um verbo do modelo.

A crença a largar é que comandos são um jeito de chamar métodos com mais cerimônia. Um comando é
dado. Ele pode ser registrado, enfileirado, repetido, conferido quanto a permissão ou mandado pela
rede antes de alguém tratá-lo, o que uma chamada de método não pode. E um evento não é um comando
disfarçado: um comando pode ser recusado, enquanto um evento relata um fato que já é verdade.

```schooling-example
{"language": "python", "file": "commands.py", "parts": [
 {"code": "# commands.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\n\n\n@dataclass(frozen=True)\nclass LendCopy:\n    copy_id: str\n    member: str\n    on: date\n\n\n@dataclass(frozen=True)\nclass ReturnCopy:\n    copy_id: str\n    on: date\n\n\n@dataclass(frozen=True)\nclass Reserve:\n    title_id: str\n    member: str", "note": "Um comando é um pedido no imperativo, carregado como dado: empreste este exemplar a este membro neste dia. Congelado, porque um pedido que muda no caminho até o handler é outro pedido."},
 {"code": "\n\n@dataclass(frozen=True)\nclass CopyLent:\n    copy_id: str\n    title_id: str\n    member: str\n    due: date\n    was_reserved: bool\n\n\n@dataclass(frozen=True)\nclass CopyReturned:\n    copy_id: str\n    title_id: str\n    member: str\n    fine: int\n\n\n@dataclass(frozen=True)\nclass TitleReserved:\n    title_id: str\n    member: str", "note": "Eventos são o que aconteceu, no passado, com tudo de que um leitor vai precisar: `CopyLent` carrega o título e se o empréstimo consumiu uma reserva, para uma tela nunca ter de perguntar ao modelo de escrita."},
 {"code": "\n\nclass Lending:\n    LIMIT = 5\n    DAILY_FINE = 50  # cents\n\n    def __init__(self, copies: dict[str, str]):\n        self.title_of = dict(copies)\n        self.holder: dict[str, tuple[str, date]] = {}\n        self.waiting: dict[str, list[str]] = {}\n        self.listeners = []", "note": "O modelo de escrita. Ele guarda o que as regras verificam e nada mais: a que título pertence cada exemplar, quem está com cada exemplar e até quando, e a fila de cada título. Não há nome nem autor em lugar nenhum."},
 {"code": "\n    def _publish(self, event) -> None:\n        for listener in self.listeners:\n            listener(event)", "note": "Depois de uma mudança, o modelo conta a quem estiver ouvindo o que aconteceu. Ele não sabe quem são; o balcão da lição 7 fazia o mesmo com `subscribe`."},
 {"code": "\n    def lend(self, cmd: LendCopy) -> None:\n        title_id = self.title_of[cmd.copy_id]\n        queue = self.waiting.get(title_id, [])\n        if cmd.copy_id in self.holder:\n            raise ValueError(f\"{cmd.copy_id} is already out\")\n        if queue and queue[0] != cmd.member:\n            raise ValueError(f\"{title_id} is reserved for {queue[0]}\")\n        if sum(1 for m, _ in self.holder.values() if m == cmd.member) >= self.LIMIT:\n            raise ValueError(f\"{cmd.member} is at the limit\")\n        was_reserved = bool(queue)\n        if was_reserved:\n            queue.pop(0)\n        due = cmd.on + timedelta(days=14)\n        self.holder[cmd.copy_id] = (cmd.member, due)\n        self._publish(CopyLent(cmd.copy_id, title_id, cmd.member, due, was_reserved))", "note": "O handler de `LendCopy`: todas as regras, depois a mudança, depois o evento. Uma recusa é lançada antes de qualquer mudança, então um comando recusado não publica nada."},
 {"code": "\n    def give_back(self, cmd: ReturnCopy) -> None:\n        if cmd.copy_id not in self.holder:\n            raise ValueError(f\"{cmd.copy_id} is not out\")\n        member, due = self.holder.pop(cmd.copy_id)\n        fine = max((cmd.on - due).days, 0) * self.DAILY_FINE\n        self._publish(CopyReturned(cmd.copy_id, self.title_of[cmd.copy_id], member, fine))", "note": "A multa é calculada aqui, porque depende do vencimento que só o lado da escrita guarda, e viaja no evento para nenhum leitor ter de calculá-la de novo."},
 {"code": "\n    def reserve(self, cmd: Reserve) -> None:\n        queue = self.waiting.setdefault(cmd.title_id, [])\n        if cmd.member in queue:\n            raise ValueError(f\"{cmd.member} is already waiting for {cmd.title_id}\")\n        queue.append(cmd.member)\n        self._publish(TitleReserved(cmd.title_id, cmd.member))", "note": "Reservar duas vezes é recusado, uma regra para a qual a classe tensionada nunca teve espaço."},
 {"code": "\n\nHANDLERS = {LendCopy: Lending.lend, ReturnCopy: Lending.give_back, Reserve: Lending.reserve}\n\n\ndef handle(model: Lending, command) -> None:\n    HANDLERS[type(command)](model, command)", "note": "Despacho pelo tipo do comando. `handle` devolve `None`: um comando não responde nada, e quem quer saber o resultado pergunta a um modelo de leitura."},
 {"code": "\n\nif __name__ == \"__main__\":\n    lending = Lending({\"C1\": \"T1\", \"C2\": \"T1\", \"C3\": \"T2\", \"C4\": \"T3\"})\n    lending.listeners.append(lambda e: print(type(e).__name__, *(f\"{k}={v}\" for k, v in vars(e).items())))\n    day = date(2026, 3, 2)\n    for command in [LendCopy(\"C3\", \"caio\", day), Reserve(\"T2\", \"bia\"),\n                    ReturnCopy(\"C3\", date(2026, 3, 19)), LendCopy(\"C3\", \"dani\", date(2026, 3, 19)),\n                    LendCopy(\"C3\", \"bia\", date(2026, 3, 19))]:\n        try:\n            handle(lending, command)\n        except ValueError as err:\n            print(\"refused:\", err)", "note": "O ouvinte aqui só imprime cada evento, uma linha por evento com seus campos."}
]}
```

O segundo empréstimo do C3 é o interessante. O Caio o devolve em 19 de março, três dias atrasado,
então a multa é de 150 centavos. A Dani então pede o exemplar e é recusada, porque a Bia reservou o
título antes. A Bia o leva, e o evento dela diz `was_reserved=True`:

```
ana@laptop:~/patterns/cqrs$ python3 commands.py
CopyLent copy_id=C3 title_id=T2 member=caio due=2026-03-16 was_reserved=False
TitleReserved title_id=T2 member=bia
CopyReturned copy_id=C3 title_id=T2 member=caio fine=150
refused: T2 is reserved for bia
CopyLent copy_id=C3 title_id=T2 member=bia due=2026-04-02 was_reserved=True
```

A recusa não imprimiu evento nenhum. **Um comando recusado não deixa rastro no modelo de escrita e
não conta nada a nenhum ouvinte**, porque toda regra é conferida antes da primeira atribuição. Essa
ordem é o principal dever do handler, e é a mesma ordem que o `Loan.give_back` da lição 1 seguia.

## Por que o modelo de escrita encolheu

Compare `Lending` com o `Library` tensionado. Os nomes e autores sumiram, e os dois métodos de
consulta também. O que sobra são as três estruturas que as regras leem e os três handlers que as
mudam. Quando o conselho acrescenta uma regra, digamos que um membro com multa em aberto não pode
pegar livros, a mudança cai num handler e nos testes dele, e o código de nenhuma tela está por perto.

**Eventos são projetados para quem os lê.** `CopyLent` carrega `title_id` embora o exemplar o
indique, e `was_reserved` embora em princípio um leitor pudesse deduzi-lo. Um modelo de leitura que
precisasse consultar `Lending` para entender um evento reconstruiria o acoplamento que a divisão
removeu. A próxima seção mostra por que `was_reserved` tinha de estar ali: sem ele, a contagem da
fila na tela só conseguiria subir.

## Handlers em outras formas

A tabela de despacho `HANDLERS` mapeia o tipo de um comando para uma função, que é tudo o que um
*command bus* de framework faz, mais middleware de log, permissões e transações em volta de cada
chamada. Em Java isso costuma ser uma interface `CommandHandler<C>` com uma classe por comando,
registrada num contexto Spring. Em TypeScript é uma união discriminada de tipos de comando e um
`switch` no campo `type`, e em Go um type switch, `switch c := cmd.(type)`. O `match` do Python, que a
próxima seção usa nos eventos, serviria aqui também.

Um handler que não devolve nada deixa algumas pessoas inquietas: como a tela mostra "o B1 vence no
dia 16"? Duas respostas honestas. A tela pergunta depois a um modelo de leitura, que é o assunto das
duas próximas seções. Ou o handler devolve uma confirmação, um id ou um vencimento, o que dobra a
separação entre comando e consulta do jeito que a seção anterior permitiu. O que ele não deve
devolver é a próxima visão da tela, pelo motivo que aquela seção deu.
