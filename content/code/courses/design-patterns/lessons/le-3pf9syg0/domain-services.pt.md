---
title: "Serviços de domínio: regras que não pertencem a nenhum objeto"
version: 1
---

**Um serviço de domínio é uma operação do domínio que não pertence naturalmente a nenhuma entidade
ou objeto de valor, então ganha uma classe ou uma função própria, com nome na linguagem ubíqua.** Ele
guarda regras, não dados sobre um sócio ou um exemplar, e faz parte do modelo tanto quanto `Member`.

A biblioteca fecha no Carnaval. Um livro com devolução na sexta anterior volta na quinta seguinte, e
as bibliotecárias dizem que os dois dias em que a biblioteca ficou fechada não deveriam contar para a
multa: o sócio não teria como devolver. Onde fica essa regra? `Loan` conhece a data de devolução e
nada sobre o calendário. `Member` poderia receber o calendário, mas aí todo sócio carregaria os
feriados da biblioteca por aí. **Quando uma regra precisa de um conhecimento que nenhum objeto
sozinho deveria guardar, a regra ganha casa própria.**

A ideia errada vai no sentido oposto: achar que toda lógica fora de uma entidade é um "serviço", e
que um modelo com um `LendingService` cheio de métodos é um bom projeto. Esse é o *modelo de domínio
anêmico*, nome que Martin Fowler deu a entidades que são sacolas de campos enquanto os serviços fazem
todo o trabalho. A regra dos cinco empréstimos pertence a `Member`, como duas seções atrás mostraram.
Um serviço de domínio é a exceção para as regras que de fato não têm dono.

```schooling-example
{"language": "python", "file": "closures.py", "parts": [
 {"code": "# closures.py\nfrom datetime import date, timedelta\n\nfrom money import Money\n\nDAILY_FINE = Money(50)\n\n\nclass FinePolicy:\n    def __init__(self, closed_days: set[date]):\n        self.closed_days = closed_days", "note": "O serviço de domínio é uma classe com nome nas palavras do domínio, guardando a única coisa que nem `Member` nem `Loan` têm: o calendário de dias fechados da biblioteca."},
 {"code": "\n    def late_days(self, due: date, returned: date) -> int:\n        days = (returned - due).days\n        counted = [due + timedelta(days=n) for n in range(1, days + 1)]\n        return sum(1 for d in counted if d not in self.closed_days)\n\n    def fine_for(self, due: date, returned: date) -> Money:\n        return DAILY_FINE.times(self.late_days(due, returned))", "note": "Todo dia depois da data de devolução conta, a menos que a biblioteca estivesse fechada nesse dia. É pura: datas entram, um número sai, nada é guardado."},
 {"code": "\n\nif __name__ == \"__main__\":\n    carnaval = {date(2026, 2, 16), date(2026, 2, 17)}\n    policy = FinePolicy(closed_days=carnaval)\n    due, back = date(2026, 2, 13), date(2026, 2, 19)\n    print(\"calendar days late:\", (back - due).days)\n    print(\"days the library was open:\", policy.late_days(due, back))\n    print(\"fine:\", policy.fine_for(due, back))\n    print(\"no closures:\", FinePolicy(set()).fine_for(due, back))", "note": "O Carnaval de 2026 caiu em 16 e 17 de fevereiro. Um livro com devolução na sexta, dia 13, volta na quinta, dia 19."}
]}
```

```
ana@laptop:~/patterns/ddd-tactical$ python3 closures.py
calendar days late: 6
days the library was open: 4
fine: BRL 2.00
no closures: BRL 3.00
```

O livro estava seis dias corridos atrasado, e a biblioteca abriu em quatro deles, então a multa é
`BRL 2.00` em vez dos `BRL 3.00` da contagem ingênua. A política recebe o calendário uma vez e
responde para qualquer empréstimo. `Member.give_back` a receberia como argumento e lhe pediria a
multa, em vez de multiplicar dias por 50 centavos sozinho, o que é uma mudança de uma linha no método
da seção de eventos de domínio.

## Serviço de domínio ou serviço de aplicação?

Dois tipos de serviço vivem perto do domínio, e confundi-los é como as regras do domínio acabam
espalhadas pelos controllers:

| | serviço de domínio | serviço de aplicação |
|---|---|---|
| guarda | uma regra de negócio | os passos de um caso de uso |
| exemplo | `FinePolicy.fine_for` | `lend_copy`, da seção de repositórios: carregar, pedir, salvar |
| fala | a linguagem ubíqua | a linguagem do programa: repositórios, transações, eventos |
| sabe de armazenamento | não | sim |
| testável com | valores simples | o repositório em memória |

`handlers.run` e `lend_copy` são serviços de aplicação: eles coordenam, e toda decisão neles é
delegada a um agregado. `FinePolicy` decide algo. Um teste útil é ler o código do serviço para uma
bibliotecária. Se ela reconhecer a regra, é um serviço de domínio; se só ouvir "carregar, salvar,
publicar", é a camada de aplicação.

## Os padrões táticos, juntos

As entidades dão identidade aos sócios e exemplares, os objetos de valor dão regras ao dinheiro, os
agregados traçam a fronteira dentro da qual cada regra é mantida, os repositórios guardam um agregado
de cada vez, os eventos de domínio levam a mudança através das fronteiras, e os serviços de domínio
guardam as poucas regras que ninguém possui. A lição 11 decidiu onde o contexto de empréstimo
termina; esta lição o preencheu. A lição 13 testa o mesmo tipo de código enquanto ele é escrito,
regra por regra.
