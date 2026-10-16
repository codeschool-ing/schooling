---
title: "Responsabilidade única: um motivo para mudar"
version: 1
---

**O princípio da responsabilidade única diz que um módulo deve ter um motivo para mudar, e um motivo
para mudar é uma pessoa ou um grupo que pede mudanças.** A formulação posterior de Martin deixa as
pessoas explícitas: um módulo deve responder a um ator. Um código que responde a dois atores um dia
vai ser mudado para o primeiro e quebrar para o segundo.

A leitura comum é "uma classe deve fazer uma coisa só", e ela soa igual e leva a outro lugar. *Fazer
uma coisa só* é um bom conselho para uma função, e aplicado a classes produz dezenas de classes de
um método cada, divididas por verbo. O princípio é sobre quem pede. Uma classe com seis métodos que
mudam todos quando o setor de multas muda as regras tem uma responsabilidade. Uma classe com dois
métodos, um do setor de multas e outro do time de estatística, tem duas.

## Dois atores, um auxiliar

Crie `~/patterns/solid-1` e trabalhe ali nesta lição:

```sh
mkdir -p ~/patterns/solid-1
cd ~/patterns/solid-1
```

O balcão de empréstimos calcula multas para o setor de multas, e o número médio de dias que um
empréstimo fica fora para o time de estatística, que usa esse número para decidir quantos exemplares
de um título comprar. Os dois precisam saber quanto tempo um empréstimo durou, então os dois usam um
auxiliar:

```schooling-example
{"language": "python", "file": "desk.py", "parts": [
 {"code": "# desk.py\nfrom datetime import date\n\n\ndef days_counted(lent_on: date, back_on: date) -> int:\n    return (back_on - lent_on).days", "note": "O auxiliar compartilhado: dias de calendário entre o empréstimo e a devolução."},
 {"code": "\n\nclass LoanDesk:\n    LOAN_DAYS = 14\n    DAILY_FINE = 50\n\n    def __init__(self, loans: dict[str, tuple[date, date]]):\n        self.loans = loans", "note": "Cada empréstimo é um título com o dia em que saiu e o dia em que voltou."},
 {"code": "\n    def fine(self, title: str) -> int:\n        lent_on, back_on = self.loans[title]\n        late = days_counted(lent_on, back_on) - self.LOAN_DAYS\n        return max(late, 0) * self.DAILY_FINE", "note": "O método do setor de multas. Catorze dias são grátis; cada dia depois disso custa 50 centavos."},
 {"code": "\n    def average_days_out(self) -> float:\n        days = [days_counted(lent_on, back_on) for lent_on, back_on in self.loans.values()]\n        return round(sum(days) / len(days), 1)", "note": "O método do time de estatística, construído sobre o mesmo auxiliar porque parecia a mesma pergunta."},
 {"code": "\n\nif __name__ == \"__main__\":\n    desk = LoanDesk({\n        \"Dom Casmurro\": (date(2026, 3, 2), date(2026, 3, 21)),\n        \"Iracema\": (date(2026, 3, 4), date(2026, 3, 12)),\n        \"Vidas Secas\": (date(2026, 3, 9), date(2026, 3, 30)),\n    })\n    print(\"fine for Dom Casmurro:\", desk.fine(\"Dom Casmurro\"))\n    print(\"average days out:     \", desk.average_days_out())"}
]}
```

```
ana@laptop:~/patterns/solid-1$ python3 desk.py
fine for Dom Casmurro: 250
average days out:      16.0
```

Dom Casmurro ficou fora 19 dias, cinco deles atrasados, então 250 centavos. Os três empréstimos dão
uma média de 16 dias.

## A mudança que um ator pediu

O setor de multas decide que um domingo, quando a biblioteca está fechada, não deve contar contra
quem pegou o livro: ninguém poderia tê-lo devolvido. Uma pessoa faz a mudança onde a contagem
acontece, que é o lugar óbvio:

```schooling-example
{"language": "python", "file": "desk.py", "parts": [
 {"code": "# desk.py\nfrom datetime import date, timedelta\n\n\ndef days_counted(lent_on: date, back_on: date) -> int:\n    days, day = 0, lent_on\n    while day < back_on:\n        day += timedelta(days=1)\n        if day.weekday() != 6:  # the library is shut on Sundays\n            days += 1\n    return days", "note": "A única mudança: contar cada dia depois do empréstimo, pulando os domingos. `weekday()` é 6 para um domingo."},
 {"code": "\n\nclass LoanDesk:\n    LOAN_DAYS = 14\n    DAILY_FINE = 50\n\n    def __init__(self, loans: dict[str, tuple[date, date]]):\n        self.loans = loans\n\n    def fine(self, title: str) -> int:\n        lent_on, back_on = self.loans[title]\n        late = days_counted(lent_on, back_on) - self.LOAN_DAYS\n        return max(late, 0) * self.DAILY_FINE\n\n    def average_days_out(self) -> float:\n        days = [days_counted(lent_on, back_on) for lent_on, back_on in self.loans.values()]\n        return round(sum(days) / len(days), 1)\n\n\nif __name__ == \"__main__\":\n    desk = LoanDesk({\n        \"Dom Casmurro\": (date(2026, 3, 2), date(2026, 3, 21)),\n        \"Iracema\": (date(2026, 3, 4), date(2026, 3, 12)),\n        \"Vidas Secas\": (date(2026, 3, 9), date(2026, 3, 30)),\n    })\n    print(\"fine for Dom Casmurro:\", desk.fine(\"Dom Casmurro\"))\n    print(\"average days out:     \", desk.average_days_out())", "note": "Todo o resto está como estava."}
]}
```

```
ana@laptop:~/patterns/solid-1$ python3 desk.py
fine for Dom Casmurro: 150
average days out:      14.0
```

A multa caiu para 150, dois domingos a menos, que é o que o setor de multas pediu. A média caiu de
16.0 para 14.0, o que ninguém pediu. **O número do time de estatística mudou por causa de uma decisão
tomada em outro setor, e nenhum teste deles rodou, porque nada deles foi editado.** No trimestre
seguinte eles compram menos exemplares dos títulos populares do que teriam comprado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l03-actors\" aria-label=\"Dois atores e uma classe. O setor de multas pede mudanças em LoanDesk.fine; o time de estatística pede mudanças em LoanDesk.average_days_out. Os dois métodos chamam o mesmo auxiliar, days_counted. O auxiliar é editado para o setor de multas, para pular os domingos, e a mudança atravessa o auxiliar compartilhado até o método do time de estatística, cuja média cai de 16.0 para 14.0 sem ninguém desse time ter pedido.\"><defs><marker id=\"l03-actors-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"53.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">setor de multas</text><rect x=\"20.0\" y=\"173.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">time de estatística</text><rect x=\"225.0\" y=\"30.0\" width=\"230.0\" height=\"210.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><text x=\"340.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">LoanDesk</text><rect x=\"245.0\" y=\"75.0\" width=\"190.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fine()</text><rect x=\"245.0\" y=\"175.0\" width=\"190.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">average_days_out()</text><path d=\"M160.0 70.0 L160.0 90.0 L241.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-actors-dp-ah-paper-dim)\"></path><path d=\"M160.0 190.0 L241.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-actors-dp-ah-paper-dim)\"></path><text x=\"200.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">pede mudanças</text><rect x=\"520.0\" y=\"123.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">days_counted()</text><path d=\"M435.0 90.0 L600.0 90.0 L600.0 119.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-actors-dp-ah-paper-dim)\"></path><path d=\"M435.0 190.0 L600.0 190.0 L600.0 161.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-actors-dp-ah-paper-dim)\"></path><text x=\"600.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">editado para pular domingos,</text><text x=\"600.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">para o setor de multas</text><text x=\"340.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">16.0 vira 14.0, sem pedido</text></svg>", "caption": "Um auxiliar servindo dois atores. Uma mudança que um deles pediu chega ao outro pelo código que compartilham."}
```

## Código igual não é o mesmo motivo

O auxiliar foi compartilhado porque duas contas pareciam iguais: dias entre duas datas. Eram iguais
por acaso. Uma é uma pergunta sobre o que é justo cobrar, do setor de multas; a outra é uma pergunta
sobre quanto tempo os livros ficam fisicamente longe, do time de estatística. No dia em que as
respostas divergiram, o código compartilhado virou um canal pelo qual a mudança de um time vazou
para o do outro.

O conserto é deixar cada ator dono do próprio código: um `fine_days` para o setor de multas e um
`calendar_days` para o time de estatística, mesmo que comecem idênticos. Parece duplicação, e é do
tipo certo. **Dois trechos de código que mudam por motivos diferentes não são duplicatas, por mais
parecidos que sejam hoje.** A próxima seção divide uma classe maior pela mesma linha.
