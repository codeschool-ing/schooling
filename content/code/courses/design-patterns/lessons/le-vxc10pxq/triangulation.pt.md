---
title: "Triangulação: deixe os exemplos forçarem a fórmula"
version: 1
---

**Uma constante que passa num teste é uma afirmação, feita de propósito, de que um exemplo não basta
para conhecer a regra geral.** O segundo exemplo é o que prova isso. Beck chamou isso de triangulação,
pelo truque do agrimensor de fixar um ponto a partir de duas visadas: um teste pode ser satisfeito
por uma resposta que não sabe nada, e dois testes diferentes só podem ser satisfeitos juntos por uma
resposta que sabe alguma coisa.

## O segundo exemplo

A segunda linha da lista é um dia de atraso, 50 centavos. Acrescente em `test_fines.py` e mantenha o
primeiro:

```python
# test_fines.py
import unittest
from datetime import date

from fines import fine


class FineTest(unittest.TestCase):
    def test_three_days_late_costs_150_cents(self):
        self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 19)), 150)

    def test_one_day_late_costs_50_cents(self):
        self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 17)), 50)


if __name__ == "__main__":
    unittest.main()
```

Rode, desta vez sem `-v`: um ponto é um teste que passou e um `F` é uma falha.

```
ana@laptop:~/patterns/tdd$ python3 -m unittest test_fines.py
F.
======================================================================
FAIL: test_one_day_late_costs_50_cents (test_fines.FineTest.test_one_day_late_costs_50_cents)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/tdd/test_fines.py", line 13, in test_one_day_late_costs_50_cents
    self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 17)), 50)
AssertionError: 150 != 50

----------------------------------------------------------------------
Ran 2 tests in 0.001s

FAILED (failures=1)
```

A constante não consegue responder 150 e 50 ao mesmo tempo, então o teste antigo passa e o novo
falha com `150 != 50`. Agora a regra geral é o código mais simples que passa nos dois, e é aquele
que você teria adivinhado: os dias entre as duas datas, vezes 50.

```python
# fines.py
def fine(due, returned):
    return (returned - due).days * 50
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest test_fines.py
..
----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

## O exemplo que ninguém escreveria por último

A terceira linha da lista é um livro devolvido antes do prazo. Se você tivesse digitado a fórmula
logo de cara, este é o caso que você teria menos chance de testar depois, porque a fórmula parece
pronta. Acrescente:

```python
# test_fines.py
import unittest
from datetime import date

from fines import fine


class FineTest(unittest.TestCase):
    def test_three_days_late_costs_150_cents(self):
        self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 19)), 150)

    def test_one_day_late_costs_50_cents(self):
        self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 17)), 50)

    def test_returned_early_costs_nothing(self):
        self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 14)), 0)


if __name__ == "__main__":
    unittest.main()
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest test_fines.py
.F.
======================================================================
FAIL: test_returned_early_costs_nothing (test_fines.FineTest.test_returned_early_costs_nothing)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/tdd/test_fines.py", line 16, in test_returned_early_costs_nothing
    self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 14)), 0)
AssertionError: -100 != 0

----------------------------------------------------------------------
Ran 3 tests in 0.000s

FAILED (failures=1)
```

`-100 != 0`. **A biblioteca ficaria devendo 100 centavos a um membro por ele trazer o livro mais
cedo**, e a fórmula que parecia pronta teria ido para produção com isso. A correção é uma chamada:

```python
# fines.py
def fine(due, returned):
    return max((returned - due).days, 0) * 50
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest test_fines.py
...
----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

A quarta linha, devolvido na data de vencimento, passaria no momento em que fosse escrita: zero dias
vezes 50 dá zero. Um teste que passa na primeira vez que roda não move código nenhum, então não é um
passo de TDD. Mantenha mesmo assim se a fronteira merece registro; quem lê os testes aprende que o
próprio dia do vencimento é de graça.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l13-steps\" aria-label=\"Três voltas do ciclo para a calculadora de multas, da esquerda para a direita no tempo. Volta 1: o teste acrescentado é três dias de atraso custam 150; a execução vermelha disse No module named fines; o código que passou foi return 150. Volta 2: um dia de atraso custa 50; a execução vermelha disse 150 != 50; o código virou os dias entre as datas vezes 50. Volta 3: dois dias adiantado não custa nada; a execução vermelha disse -100 != 0; o código virou o máximo entre os dias e zero, vezes 50. Cada volta acrescenta um teste e muda o código só até onde esse teste exige.\"><defs><marker id=\"l13-steps-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"112.0\" y=\"78.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">teste acrescentado</text><text x=\"112.0\" y=\"138.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">o vermelho disse</text><text x=\"112.0\" y=\"204.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">código que passa</text><text x=\"228.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">volta 1</text><rect x=\"138.0\" y=\"63.0\" width=\"180.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"228.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 dias de atraso → 150</text><rect x=\"138.0\" y=\"123.0\" width=\"180.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"228.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">No module named 'fines'</text><rect x=\"138.0\" y=\"182.0\" width=\"180.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"148.0\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">return 150</text><path d=\"M228.0 93.0 L228.0 123.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l13-steps-dp-ah-paper-dim)\"></path><path d=\"M228.0 153.0 L228.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l13-steps-dp-ah-paper-dim)\"></path><text x=\"424.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">volta 2</text><rect x=\"334.0\" y=\"63.0\" width=\"180.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"424.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 dia de atraso → 50</text><rect x=\"334.0\" y=\"123.0\" width=\"180.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"424.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">150 != 50</text><rect x=\"334.0\" y=\"182.0\" width=\"180.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"344.0\" y=\"196.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">return (returned - due)</text><text x=\"360.0\" y=\"211.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">.days * 50</text><path d=\"M424.0 93.0 L424.0 123.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l13-steps-dp-ah-paper-dim)\"></path><path d=\"M424.0 153.0 L424.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l13-steps-dp-ah-paper-dim)\"></path><text x=\"620.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">volta 3</text><rect x=\"530.0\" y=\"63.0\" width=\"180.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 dias adiantado → 0</text><rect x=\"530.0\" y=\"123.0\" width=\"180.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">-100 != 0</text><rect x=\"530.0\" y=\"182.0\" width=\"180.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"196.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">return max((returned - due)</text><text x=\"556.0\" y=\"211.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">.days, 0) * 50</text><path d=\"M620.0 93.0 L620.0 123.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l13-steps-dp-ah-paper-dim)\"></path><path d=\"M620.0 153.0 L620.0 182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l13-steps-dp-ah-paper-dim)\"></path><path d=\"M140.0 252.0 L700.0 252.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-steps-dp-ah-paper-dim)\"></path><text x=\"420.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">tempo: um teste por volta</text></svg>", "caption": "A fórmula nunca foi projetada de uma vez. Cada exemplo tirou uma coisa que o código anterior errava."}
```

## Três jeitos de chegar ao verde

Beck dá nome a três estratégias, e uma mão experiente alterna entre elas na mesma hora.

| estratégia | o que você escreve para passar | quando cabe |
|---|---|---|
| fingir (fake it) | uma constante, depois trocada aos poucos | você não tem certeza de qual é o código geral |
| triangular | um segundo exemplo que o fingimento não passa | a generalização não é óbvia a partir de um caso |
| implementação óbvia | o código real, direto | você sabe exatamente o que digitar, e acerta |

**A implementação óbvia é permitida; não é o padrão.** Quando você digita a coisa real e o teste
fica vermelho de um jeito que você não esperava, essa surpresa é o sinal para voltar a passos
menores. A expressão de Beck para os passos pequenos é *baby steps*, e o tamanho é uma marcha, não
uma regra: passadas longas em terreno conhecido, uma constante de cada vez onde você continua se
surpreendendo.

O que os passos protegem é o tempo entre duas execuções verdes. Com um teste e três linhas entre
elas, uma execução vermelha tem uma causa possível e você a enxerga. Com dez linhas novas e quatro
testes novos, a mesma execução vermelha vira uma sessão de depuração.
