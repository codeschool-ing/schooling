---
title: Uma regra de multa nova, sem nada editado
version: 1
---

**Fechar um módulo contra um tipo de mudança pede três peças: um protocolo dizendo do que o módulo
precisa, implementações dele em código próprio, e um lugar que decide qual implementação vai
onde.** Um caso novo é então uma implementação nova e uma linha nesse lugar. O módulo que faz o
trabalho nunca é aberto.

Às vezes se espera que o princípio aberto/fechado signifique que *nenhum* arquivo muda quando um
caso entra. Algo sempre muda, porque algo tem de dizer que o caso novo existe. A questão é qual
arquivo: uma lista curta de ligações, sem lógica nenhuma, em vez da função de que todo mundo
depende.

## O protocolo e duas regras

As regras são as que a lição 2 construiu, reescritas aqui para o diretório desta lição ficar
completo:

```python
# policies.py
from typing import Protocol


class FinePolicy(Protocol):
    def fine(self, days_late: int) -> int: ...


class PerDay:
    def __init__(self, cents: int):
        self.cents = cents

    def fine(self, days_late: int) -> int:
        return max(days_late, 0) * self.cents


class GraceDays:
    def __init__(self, free: int, then: FinePolicy):
        self.free = free
        self.then = then

    def fine(self, days_late: int) -> int:
        return self.then.fine(days_late - self.free)
```

## O módulo fechado

Esta é a função que substituiu a cadeia de `if`. Ela imprime a folha de cobrança que o balcão
entrega, e pede a cada categoria de membro a regra numa tabela, em vez de perguntar que categoria
tem:

```schooling-example
{"language": "python", "file": "charges.py", "parts": [
 {"code": "# charges.py\nfrom policies import FinePolicy", "note": "A única coisa que ele importa é o protocolo. Nenhuma classe de regra é citada neste arquivo."},
 {"code": "\n\ndef charge_sheet(loans: list[tuple[str, str, int]], rules: dict[str, FinePolicy]) -> None:\n    total = 0\n    for title, kind, days_late in loans:\n        cents = rules[kind].fine(days_late)", "note": "Uma consulta substitui a cadeia inteira. Uma categoria sem regra levanta `KeyError` aqui, em voz alta, em vez de chegar ao fim e imprimir `None`."},
 {"code": "        total += cents\n        print(f\"{title:<20}{kind:<9}{days_late:>3} days late {cents:>6}\")\n    print(f\"{'total':<44}{total:>6}\")", "note": "Layout e totais, que não ligam para qual foi a regra."}
]}
```

## As ligações

Um arquivo curto diz que regra cada categoria de membro recebe, e roda a folha:

```python
# main.py
from charges import charge_sheet
from policies import GraceDays, PerDay

standard = PerDay(50)
rules = {
    "adult": standard,
    "student": GraceDays(3, standard),
}
charge_sheet([
    ("Dom Casmurro", "adult", 5),
    ("Iracema", "student", 5),
    ("O Cortiço", "adult", 40),
], rules)
```

```
ana@laptop:~/patterns/solid-1$ python3 main.py
Dom Casmurro        adult      5 days late    250
Iracema             student    5 days late    100
O Cortiço           adult     40 days late   2000
total                                         2350
```

## As multas de crianças têm teto

A biblioteca cria a categoria infantil, com a regra de que nenhuma multa de criança passa de 1000
centavos, por mais atrasado que o livro esteja. Essa regra é uma classe nova num arquivo novo,
construída como `GraceDays`, em volta de outra regra:

```python
# capped.py
from policies import FinePolicy


class Capped:
    def __init__(self, most: int, then: FinePolicy):
        self.most = most
        self.then = then

    def fine(self, days_late: int) -> int:
        return min(self.then.fine(days_late), self.most)
```

E as ligações aprendem sobre ela. Este é o `main.py` inteiro de novo, com um import, uma entrada na
tabela e um empréstimo a mais:

```python
# main.py
from capped import Capped
from charges import charge_sheet
from policies import GraceDays, PerDay

standard = PerDay(50)
rules = {
    "adult": standard,
    "student": GraceDays(3, standard),
    "child": Capped(1000, standard),
}
charge_sheet([
    ("Dom Casmurro", "adult", 5),
    ("Iracema", "student", 5),
    ("O Cortiço", "adult", 40),
    ("O Menino Maluquinho", "child", 40),
], rules)
```

```
ana@laptop:~/patterns/solid-1$ python3 main.py
Dom Casmurro        adult      5 days late    250
Iracema             student    5 days late    100
O Cortiço           adult     40 days late   2000
O Menino Maluquinho child     40 days late   1000
total                                         3350
```

Quarenta dias de atraso custam a um adulto 2000 centavos e a uma criança 1000, o teto. **`charges.py`
e `policies.py` não foram abertos, então todo teste que passava contra eles continua descrevendo os
dois exatamente.** O comportamento novo mora em `capped.py`, que pode ser testado sozinho com nada
além de inteiros, e em três linhas de ligação.

## O mesmo formato nas outras linguagens

O protocolo é a parte que mais varia entre linguagens. Em Java, `FinePolicy` é uma `interface` e
`Capped` diz `implements FinePolicy`; em Go e TypeScript, `Capped` satisfaz a interface por ter o
método, como aqui. Como `FinePolicy` tem um método só, as quatro linguagens também poderiam usar uma
função simples: um `func(int) int` em Go, uma lambda em Java, uma arrow function em TypeScript. A
tabela de regras guardaria funções, e `charges.py` chamaria `rules[kind](days_late)`. O princípio
não liga para qual: o código fechado depende de um formato, e os casos novos chegam como coisas novas
desse formato.

`main.py` é o único arquivo que conhece todas as regras pelo nome. A lição 5 dá um nome a esse
arquivo, composition root, e faz dele a casa deliberada exatamente desse tipo de mudança.
