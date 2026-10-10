---
title: "Invariantes e fronteiras: um agregado por transação"
version: 1
---

**Duas regras decidem onde um agregado termina. Mude um agregado por transação, e refira-se a outros
agregados pelo id, nunca guardando o objeto.** Juntas, elas mantêm cada agregado pequeno o bastante
para ser travado por pouco tempo, e obrigam a uma decisão sobre toda regra que atravessa dois deles:
ela precisa ser verdade a cada instante, ou basta que fique verdade logo?

A ideia errada é achar que uma regra que envolve duas coisas significa que as duas pertencem a um só
agregado. "Um exemplar está com um sócio de cada vez" envolve um exemplar e um sócio. Ponha os
exemplares dentro dos sócios e o exemplar precisa ser procurado dentro de quem o tiver; ponha os
sócios dentro dos exemplares e Bia fica espalhada por cinco agregados. Nenhum dos dois funciona. **O
exemplar é um agregado próprio, com regra própria, e emprestar é uma conversa entre dois
agregados.**

## Dois agregados, um depois do outro

Eis o exemplar, guardando o id do sócio em vez do sócio, e um `lend` que muda primeiro o exemplar e
depois o sócio:

```schooling-example
{"language": "python", "file": "copies.py", "parts": [
 {"code": "# copies.py\nfrom member import Member, Refused\n\n\nclass Copy:\n    def __init__(self, copy_id: str, isbn: str, kind: str):\n        self.id = copy_id\n        self.isbn = isbn\n        self.kind = kind\n        self.on_loan_to: str | None = None\n\n    def check_out(self, member_id: str) -> None:\n        if self.on_loan_to is not None:\n            raise Refused(f\"copy {self.id} is out to {self.on_loan_to}\")\n        self.on_loan_to = member_id\n\n    def check_in(self) -> None:\n        self.on_loan_to = None", "note": "Um exemplar é um agregado próprio: tem id próprio e regra própria, a de estar com um sócio de cada vez. Ele se refere ao sócio pelo id, como string, nunca guardando o `Member`."},
 {"code": "\n\ndef lend(copy: Copy, member: Member, today) -> None:\n    copy.check_out(member.id)\n    try:\n        member.borrow(copy.id, copy.kind, today)\n    except Refused:\n        copy.check_in()\n        raise", "note": "Emprestar mexe em dois agregados, um depois do outro. Se o sócio recusar, o exemplar volta: uma correção, feita por código, depois de a primeira mudança já ter acontecido."},
 {"code": "\n\nif __name__ == \"__main__\":\n    from datetime import date\n    day = date(2026, 3, 2)\n    bia, caio = Member(\"m-001\", \"Bia\"), Member(\"m-002\", \"Caio\")\n    for n in range(1, 6):\n        lend(Copy(f\"C-{n:04d}\", \"978-65-5555-001-6\", \"book\"), bia, day)\n    extra = Copy(\"C-0100\", \"978-65-5555-002-3\", \"book\")\n    for who in (bia, caio, bia):\n        try:\n            lend(extra, who, day)\n            print(f\"{extra.id} lent to {who.name}\")\n        except Refused as err:\n            print(f\"refused for {who.name}: {err}\")\n        print(f\"  {extra.id} on loan to: {extra.on_loan_to}\")", "note": "Bia já tem cinco empréstimos. O mesmo exemplar extra é oferecido a Bia, a Caio e a Bia de novo."}
]}
```

```
ana@laptop:~/patterns/ddd-tactical$ python3 copies.py
refused for Bia: Bia already has 5 loans
  C-0100 on loan to: None
C-0100 lent to Caio
  C-0100 on loan to: m-002
refused for Bia: copy C-0100 is out to m-002
  C-0100 on loan to: m-002
```

Bia já tem cinco empréstimos. Quando o exemplar extra é oferecido a ela, o exemplar sai no nome
dela, o sócio recusa, e o exemplar volta: `on loan to: None`. Caio fica com ele. Quando Bia pede de
novo, o próprio exemplar recusa, porque está com `m-002`. Cada agregado manteve a própria regra;
nenhum precisou conhecer a do outro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l12-boundaries\" aria-label=\"Dois agregados, cada um dentro de uma fronteira tracejada. À esquerda, o agregado Member: a raiz Member, com os campos id, name e owed, guarda uma lista de objetos Loan, cada um com copy_id e due, desenhada com um losango cheio do lado de Member. À direita, o agregado Copy: uma única raiz Copy com id, kind e on_loan_to. Uma seta tracejada marcada &quot;pelo id&quot; vai do copy_id de Loan até Copy, e outra do on_loan_to de Copy de volta a Member. O código de fora, embaixo, tem setas cheias só para as duas raízes, nunca para um Loan.\"><defs><marker id=\"l12-boundaries-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l12-boundaries-dp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M20 14 L350 14 L350 214 L20 214 Z\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"185.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">agregado Member</text><path d=\"M470 14 L700 14 L700 214 L470 214 Z\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"585.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">agregado Copy</text><rect x=\"40.0\" y=\"50.0\" width=\"130.0\" height=\"125.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«raiz»</text><text x=\"105.0\" y=\"75.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Member</text><path d=\"M40.0 87.0 L170.0 87.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"48.0\" y=\"98.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">id</text><text x=\"48.0\" y=\"112.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">name</text><text x=\"48.0\" y=\"127.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">owed: Money</text><path d=\"M40.0 138.5 L170.0 138.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"48.0\" y=\"149.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">borrow()</text><text x=\"48.0\" y=\"164.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">give_back()</text><rect x=\"220.0\" y=\"70.0\" width=\"110.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"275.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Loan</text><path d=\"M220.0 92.5 L330.0 92.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"228.0\" y=\"103.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">copy_id</text><text x=\"228.0\" y=\"118.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">due</text><path d=\"M170.0 100.0 L220.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M170.0 100.0 L179.0 105.5 L188.0 100.0 L179.0 94.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><text x=\"275.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">0..5, dentro</text><rect x=\"520.0\" y=\"60.0\" width=\"140.0\" height=\"111.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"71.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«raiz»</text><text x=\"590.0\" y=\"85.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Copy</text><path d=\"M520.0 97.0 L660.0 97.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"528.0\" y=\"108.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">id</text><text x=\"528.0\" y=\"122.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">kind</text><text x=\"528.0\" y=\"137.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">on_loan_to</text><path d=\"M520.0 148.5 L660.0 148.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"528.0\" y=\"159.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">check_out()</text><path d=\"M330.0 92.0 L517.0 92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l12-boundaries-dp-ah-phosphor)\"></path><text x=\"420.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pelo id</text><path d=\"M520.0 158.0 L173.0 158.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l12-boundaries-dp-ah-phosphor)\"></path><text x=\"420.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pelo id</text><rect x=\"260.0\" y=\"255.0\" width=\"200.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">código de fora: balcão, casos de uso</text><path d=\"M300.0 255.0 L300.0 240.0 L105.0 240.0 L105.0 217.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-boundaries-dp-ah-paper-dim)\"></path><path d=\"M420.0 255.0 L420.0 240.0 L590.0 240.0 L590.0 217.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-boundaries-dp-ah-paper-dim)\"></path><text x=\"175.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">só pelas raízes</text></svg>", "caption": "Cada agregado guarda a própria regra atrás da raiz. Entre agregados há ids, nunca referências aos objetos."}
```

## Instantânea ou eventual

Veja o que `lend` fez quando Bia foi recusada: por um momento, o exemplar dizia estar com ela
enquanto ela não tinha esse empréstimo. Neste programa o momento dura duas linhas. Com cada agregado
salvo na própria transação, o momento poderia incluir uma queda, e a correção nunca rodaria. Então
toda regra que atravessa uma fronteira recebe uma de duas respostas:

| a regra precisa valer | como | na biblioteca |
|---|---|---|
| a cada instante | os dois pertencem a um agregado só, afinal, ou uma transação muda os dois e você aceita a trava maior | raro; nada no empréstimo precisa disso |
| logo | mudar um agregado, registrar um evento, deixar um handler mudar o outro, e consertar quando falhar | o exemplar e o sócio; a contagem de "disponível" do catálogo |

**A maioria das regras que atravessam uma fronteira são regras de "logo", depois que alguém pergunta
ao negócio.** Uma bibliotecária não precisa que o exemplar e o sócio concordem no mesmo
milissegundo; ela precisa que nenhum exemplar seja emprestado duas vezes e nenhum empréstimo exista
sem exemplar, e um minuto de discordância que uma tarefa conserta está bem. É a escolha por operação
da lição 10, feita no tamanho de um agregado. As duas próximas seções lhe dão maquinário: o
repositório salva um agregado numa transação, e os eventos de domínio levam a mudança ao próximo.

## Por que pelo id

`Copy.on_loan_to` é a string `m-002`, e `Loan.copy_id` é a string `C-0100`. Guardar os objetos
deixaria um código ir de um exemplar até o sócio dele e mudá-lo, fora da raiz dele e fora da
transação dele, que é exatamente a segunda porta que a seção anterior fechou. Um id é também o que
sobrevive ao armazenamento: carregar um sócio não exige carregar todo exemplar que ele tem, e todo
sócio que pegou esses exemplares, até a biblioteca inteira estar na memória.

*Implementing Domain-Driven Design*, de Vaughn Vernon (2013), enuncia essas regras com mais clareza,
e acrescenta uma terceira que vale repetir aqui: projete agregados pequenos. O sócio acima guarda
empréstimos e mais nada. Reservas, pagamentos e histórico podem ser, cada um, um agregado próprio,
ligado pelo id do sócio.
