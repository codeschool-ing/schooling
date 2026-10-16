---
title: "Eventos de domínio: o que aconteceu, dito pelo modelo"
version: 1
---

**Um evento de domínio é um registro, feito pelo próprio agregado, de que aconteceu algo com que o
negócio se importa.** Um sócio pegar um exemplar é um `LoanStarted`. Uma devolução atrasada é um
`FineCharged`. O agregado registra o evento como parte da mudança; o código de fora reage a ele
depois, sem o agregado saber quem escuta.

A ideia errada é achar que o próprio agregado deveria fazer as reações. `borrow` manda o SMS de
recibo, `give_back` manda o e-mail da multa, e os dois atualizam o contador dos "mais procurados da
semana". Agora o sócio depende de um gateway de SMS e de um servidor de e-mail, um teste da regra dos
cinco empréstimos precisa de dublês para os dois, e acrescentar uma reação significa editar o
agregado. **O trabalho do sócio é dizer o que aconteceu; decidir o que fazer a respeito é de outro
lugar.** É a regra de dependência da lição 4 aplicada ao tempo.

São os mesmos post-its laranja que a lição 11 pôs na parede, e o mesmo tipo de fato que a lição 9
guardou. A diferença é de onde eles vêm: aqui o modelo os levanta enquanto muda. Eis `member.py` de
novo, inteiro, com eventos acrescentados. Substitua o arquivo anterior por este:

```schooling-example
{"language": "python", "file": "member.py", "parts": [
 {"code": "# member.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\n\nfrom money import Money\n\nMAX_LOANS = 5\nFINE_LIMIT = Money(1000)\nDAILY_FINE = Money(50)\nLOAN_DAYS = {\"book\": 14, \"film\": 7}\n\n\nclass Refused(Exception):\n    pass\n\n\n@dataclass\nclass Loan:\n    copy_id: str\n    due: date", "note": "Tudo até `Loan` está como estava na seção de agregados."},
 {"code": "\n\n@dataclass(frozen=True)\nclass LoanStarted:\n    member_id: str\n    copy_id: str\n    due: date\n\n\n@dataclass(frozen=True)\nclass FineCharged:\n    member_id: str\n    copy_id: str\n    amount: Money", "note": "Dois eventos, nomeados no passado como a lição 11 os escreveu na parede, e congelados, porque um fato não muda depois de acontecer. Cada um carrega ids e valores, nunca um `Member`."},
 {"code": "\n\nclass Member:\n    def __init__(self, member_id: str, name: str):\n        self.id = member_id\n        self.name = name\n        self._loans: list[Loan] = []\n        self.owed = Money(0)\n        self._events: list[object] = []\n\n    @property\n    def loans(self) -> tuple[Loan, ...]:\n        return tuple(self._loans)", "note": "`_events` é o campo novo: o que aconteceu com este sócio desde que foi carregado."},
 {"code": "\n    def pull_events(self) -> list[object]:\n        events, self._events = self._events, []\n        return events", "note": "`pull_events` entrega a lista e a esvazia, para o mesmo evento nunca ser entregue duas vezes."},
 {"code": "\n    def borrow(self, copy_id: str, kind: str, today: date) -> Loan:\n        if len(self._loans) >= MAX_LOANS:\n            raise Refused(f\"{self.name} already has {MAX_LOANS} loans\")\n        if self.owed.cents > FINE_LIMIT.cents:\n            raise Refused(f\"{self.name} owes {self.owed}, over the limit of {FINE_LIMIT}\")\n        loan = Loan(copy_id, today + timedelta(days=LOAN_DAYS[kind]))\n        self._loans.append(loan)\n        self._events.append(LoanStarted(self.id, copy_id, loan.due))\n        return loan", "note": "O evento é registrado depois de a mudança dar certo, na linha seguinte. Um empréstimo recusado levanta exceção antes e não registra nada."},
 {"code": "\n    def give_back(self, copy_id: str, on: date) -> Money:\n        loan = next((l for l in self._loans if l.copy_id == copy_id), None)\n        if loan is None:\n            raise Refused(f\"{self.name} has no loan of {copy_id}\")\n        self._loans.remove(loan)\n        fine = DAILY_FINE.times(max((on - loan.due).days, 0))\n        self.owed = self.owed + fine\n        if fine.cents:\n            self._events.append(FineCharged(self.id, copy_id, fine))\n        return fine", "note": "Uma multa de zero não é evento; não aconteceu nada de que alguém precise saber."},
 {"code": "\n    def pay(self, amount: Money) -> None:\n        self.owed = self.owed - amount"}
]}
```

E o código que reage. Ele carrega um sócio pelo repositório da seção anterior, pede que ele faça
algo, salva e publica o que aconteceu:

```schooling-example
{"language": "python", "file": "handlers.py", "parts": [
 {"code": "# handlers.py\nfrom datetime import date\n\nfrom member import FineCharged, LoanStarted, Member\nfrom repositories import InMemoryMembers\n\npopular: dict[str, int] = {}\n\n\ndef send_receipt(event: LoanStarted) -> None:\n    print(f\"  SMS to {event.member_id}: {event.copy_id} is due on {event.due}\")\n\n\ndef count_popular(event: LoanStarted) -> None:\n    popular[event.copy_id] = popular.get(event.copy_id, 0) + 1\n\n\ndef send_fine_notice(event: FineCharged) -> None:\n    print(f\"  e-mail to {event.member_id}: a fine of {event.amount} for {event.copy_id}\")", "note": "Os handlers são funções simples, uma por reação. O sócio não conhece nenhuma delas."},
 {"code": "\n\nHANDLERS = {LoanStarted: [send_receipt, count_popular], FineCharged: [send_fine_notice]}\n\n\ndef publish(events: list[object]) -> None:\n    for event in events:\n        for handle in HANDLERS[type(event)]:\n            handle(event)", "note": "A ligação: quais handlers ouvem qual evento. Acrescentar uma reação é uma linha aqui, e `member.py` não muda."},
 {"code": "\n\ndef run(members: InMemoryMembers, member_id: str, action) -> None:\n    member = members.get(member_id)\n    action(member)\n    events = member.pull_events()\n    members.save(member)\n    publish(events)", "note": "A ordem importa. Os eventos são retirados antes de salvar e publicados depois: o repositório em memória guarda uma cópia profunda, eventos incluídos, e um sócio salvo com os eventos os entregaria de novo no próximo `get`."},
 {"code": "\n\nif __name__ == \"__main__\":\n    members = InMemoryMembers()\n    members.save(Member(\"m-001\", \"Bia\"))\n    print(\"borrow:\")\n    run(members, \"m-001\", lambda m: m.borrow(\"C-0002\", \"film\", date(2026, 3, 2)))\n    print(\"give back late:\")\n    run(members, \"m-001\", lambda m: m.give_back(\"C-0002\", date(2026, 3, 12)))\n    print(\"popular:\", popular)"}
]}
```

```
ana@laptop:~/patterns/ddd-tactical$ python3 handlers.py
borrow:
  SMS to m-001: C-0002 is due on 2026-03-09
give back late:
  e-mail to m-001: a fine of BRL 1.50 for C-0002
popular: {'C-0002': 1}
```

Pegar o filme produziu um `LoanStarted`, e dois handlers o ouviram: um mandou o recibo, o outro
contou o exemplar como procurado. Devolvê-lo em 12 de março, três dias atrasado, produziu um
`FineCharged` de `BRL 1.50`, e o aviso de multa saiu. O contador terminou em 1. O sócio não contém
SMS, nem e-mail, nem contador.

## Salvar primeiro, depois publicar

A ordem em `run` importa, e a transcrição mostra contra o que cada parte protege. Publicar antes de
salvar mandaria a Bia um recibo de um empréstimo que um salvamento fracassado perderia. Publicar
depois de salvar também pode falhar, o que deixa um empréstimo salvo sem recibo; para um recibo isso
é aceitável, e para uma regra de que outro agregado depende não é. Esse segundo caso é onde entra o
*outbox*: os eventos são gravados na mesma transação que o agregado, numa tabela, e uma tarefa
separada os publica e os marca como enviados. É a unidade de trabalho da lição 10 segurando mais uma
lista.

## O que vai num evento

| manter | deixar de fora |
|---|---|
| um nome no passado, da linguagem ubíqua | um nome como `MemberUpdated`, que não diz o que aconteceu em particular |
| ids: o do sócio, o do exemplar | o objeto `Member`, que o handler poderia então mudar |
| os valores que a mudança produziu: a data de devolução, a quantia | valores que um handler poderia buscar sozinho e que podem mudar |
| imutabilidade: `frozen=True` | qualquer coisa que um handler possa ficar tentado a editar |

Os eventos daqui são tratados no mesmo processo, logo depois de salvar. A lição 9 guardou eventos
num armazenamento, reconstruiu estado a partir deles e alimentou projeções com eles, os handlers que
montam os modelos de leitura da lição 8. Um evento de domínio é onde tudo isso começa: o momento em
que o modelo diz *isto aconteceu*.
