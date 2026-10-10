---
title: "Agregados: uma porta para um grupo de objetos"
version: 1
---

**Um agregado é um grupo de objetos que precisa se manter consistente junto, com um deles, a raiz,
como única porta: tudo o que está fora fala com a raiz, e a raiz guarda as regras.** Uma sócia e os
empréstimos dela são um agregado. A regra "no máximo cinco empréstimos" é sobre os empréstimos
juntos, então nenhum empréstimo sozinho consegue mantê-la. A sócia consegue, desde que todo
empréstimo novo precise passar por ela.

A ideia errada é achar que a regra pode morar em qualquer serviço que acrescente empréstimos. O
balcão confere a contagem antes de acrescentar um empréstimo; depois a renovação online, escrita mais
tarde, acrescenta um empréstimo sem conferir; depois um script de migração importa empréstimos
direto para a lista. Cada caminho é razoável e um deles quebra a regra. **Uma invariante mantida por
todo chamador é uma invariante mantida por nenhum.** Ponha a regra onde a lista está, e deixe a lista
inalcançável a não ser por ela.

Eis a sócia como agregado, usando o `Money` da seção anterior:

```schooling-example
{"language": "python", "file": "member.py", "parts": [
 {"code": "# member.py\nfrom dataclasses import dataclass\nfrom datetime import date, timedelta\n\nfrom money import Money\n\nMAX_LOANS = 5\nFINE_LIMIT = Money(1000)\nDAILY_FINE = Money(50)\nLOAN_DAYS = {\"book\": 14, \"film\": 7}\n\n\nclass Refused(Exception):\n    pass", "note": "As regras do empréstimo, como constantes ao lado da classe que as guarda. `Money` vem da seção anterior."},
 {"code": "\n\n@dataclass\nclass Loan:\n    copy_id: str\n    due: date", "note": "Um `Loan` não tem id próprio: dentro do sócio ele é distinguido pelo exemplar a que se refere. Nada fora do agregado guarda um `Loan`."},
 {"code": "\n\nclass Member:\n    def __init__(self, member_id: str, name: str):\n        self.id = member_id\n        self.name = name\n        self._loans: list[Loan] = []\n        self.owed = Money(0)\n\n    @property\n    def loans(self) -> tuple[Loan, ...]:\n        return tuple(self._loans)", "note": "A raiz. A lista de empréstimos é privada, e `loans` entrega uma tupla, então ninguém consegue acrescentar à lista sem passar por `borrow`."},
 {"code": "\n    def borrow(self, copy_id: str, kind: str, today: date) -> Loan:\n        if len(self._loans) >= MAX_LOANS:\n            raise Refused(f\"{self.name} already has {MAX_LOANS} loans\")\n        if self.owed.cents > FINE_LIMIT.cents:\n            raise Refused(f\"{self.name} owes {self.owed}, over the limit of {FINE_LIMIT}\")\n        loan = Loan(copy_id, today + timedelta(days=LOAN_DAYS[kind]))\n        self._loans.append(loan)\n        return loan", "note": "As duas invariantes são conferidas aqui, antes de qualquer mudança: no máximo cinco empréstimos, e nada novo enquanto se devem mais de 1000 centavos."},
 {"code": "\n    def give_back(self, copy_id: str, on: date) -> Money:\n        loan = next((l for l in self._loans if l.copy_id == copy_id), None)\n        if loan is None:\n            raise Refused(f\"{self.name} has no loan of {copy_id}\")\n        self._loans.remove(loan)\n        fine = DAILY_FINE.times(max((on - loan.due).days, 0))\n        self.owed = self.owed + fine\n        return fine\n\n    def pay(self, amount: Money) -> None:\n        self.owed = self.owed - amount", "note": "Devolver remove o empréstimo e soma a multa num só método, para os dois nunca se desencontrarem."},
 {"code": "\n\nif __name__ == \"__main__\":\n    bia = Member(\"m-001\", \"Bia\")\n    day = date(2026, 3, 2)\n    for n in range(1, 7):\n        try:\n            loan = bia.borrow(f\"C-{n:04d}\", \"film\" if n == 2 else \"book\", day)\n            print(\"lent\", loan.copy_id, \"due\", loan.due)\n        except Refused as err:\n            print(\"refused:\", err)\n    print(\"fine:\", bia.give_back(\"C-0002\", date(2026, 4, 1)))\n    try:\n        bia.borrow(\"C-0007\", \"book\", date(2026, 4, 1))\n    except Refused as err:\n        print(\"refused:\", err)\n    bia.pay(Money(1150))\n    print(\"lent\", bia.borrow(\"C-0007\", \"book\", date(2026, 4, 1)).copy_id, \"| loans:\", len(bia.loans))", "note": "Seis pedidos, um deles um filme; uma devolução atrasada; uma recusa por causa da multa; um pagamento; e o empréstimo que agora cabe."}
]}
```

```
ana@laptop:~/patterns/ddd-tactical$ python3 member.py
lent C-0001 due 2026-03-16
lent C-0002 due 2026-03-09
lent C-0003 due 2026-03-16
lent C-0004 due 2026-03-16
lent C-0005 due 2026-03-16
refused: Bia already has 5 loans
fine: BRL 11.50
refused: Bia owes BRL 11.50, over the limit of BRL 10.00
lent C-0007 | loans: 5
```

Cinco empréstimos saem, um deles um filme com devolução em 9 de março em vez de 16, e o sexto é
recusado. O filme volta em 1º de abril, 23 dias atrasado, e a multa é `BRL 11.50`. Com isso devido,
o próximo empréstimo é recusado, porque 1150 centavos passam do limite de 1000. Bia paga, e o
empréstimo que tinha sido recusado agora sai, levando-a de volta a cinco.

## As regras da raiz

As regras de Evans para agregados são curtas, e `member.py` cumpre cada uma:

- o código de fora guarda referência só para a raiz. Nada fora do arquivo guarda um `Loan`; `loans`
  entrega uma tupla, uma fotografia em que não se acrescenta nada;
- toda mudança passa por um método da raiz, e o método confere as invariantes antes de mudar
  qualquer coisa. `borrow` confere os dois limites antes do `append`;
- um objeto dentro do agregado só precisa de identidade lá dentro. Um `Loan` é distinguido pelo
  `copy_id`, o que basta dentro de um sócio;
- o agregado é carregado e salvo inteiro. Um repositório só de empréstimos seria uma segunda porta, e
  a regra vazaria por ela. A seção de repositórios mostra o sócio salvo como uma peça só.

O sublinhado do Python em `_loans` é uma convenção, como a lição 1 disse, e a tupla é a parte que faz
o trabalho: um código que escreve `bia.loans.append(...)` falha na hora, porque tupla não tem
`append`. O `List.copyOf` ou o `Collections.unmodifiableList` do Java, devolver uma cópia da slice no
Go e o `ReadonlyArray` do TypeScript são o mesmo movimento.

## Fábricas, em poucas palavras

Quando criar um agregado exige mais do que um construtor deveria fazer, como conferir se um número
de carteirinha está livre ou dar a um sócio novo uma cota de boas-vindas, a criação ganha uma casa
própria: uma **fábrica** (*factory*). Em Python costuma ser uma função ou um método de classe,
`Member.join(...)`, que faz as conferências e devolve uma raiz válida. O sentido é o mesmo da raiz:
ninguém consegue obter um agregado num estado que quebra as regras dele, nem no nascimento. O factory
method da lição 6 é o mesmo padrão visto pelo lado do GoF.

## De que tamanho?

Pequeno. Um agregado é a unidade de consistência, então tudo dentro dele é travado, carregado e
salvo junto. Uma sócia que contivesse os empréstimos, as reservas, o histórico de pagamentos e todo
exemplar que já tocou seria um modelo correto e lento, e duas bibliotecárias editando partes
diferentes dela colidiriam. A próxima seção é sobre traçar essa linha, e sobre o que fazer com as
regras que a atravessam.
