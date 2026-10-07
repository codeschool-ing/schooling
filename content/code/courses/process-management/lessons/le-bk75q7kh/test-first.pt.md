---
title: Escrevendo o teste primeiro
version: 1
---

Programar com teste primeiro, em geral chamado de **desenvolvimento guiado por testes** ou TDD, inverte a ordem habitual. Antes de escrever o código de um comportamento, você escreve um teste para ele e o vê falhar. Depois escreve o mínimo de código que o faz passar. Depois melhora o código, com o teste protegendo você enquanto isso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 230\" role=\"img\" data-fig=\"l04-tdd\" aria-label=\"Três passos em ciclo: vermelho, escreva um teste que falha; verde, escreva só o código necessário para passar; refatorar, melhore o código com os testes ainda passando; e de volta ao vermelho.\"><defs><marker id=\"pm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><circle cx=\"110.0\" cy=\"90.0\" r=\"34\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"110.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">vermelho</text><text x=\"110.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escreva um teste que falha</text><circle cx=\"310.0\" cy=\"90.0\" r=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\"></circle><text x=\"310.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">verde</text><text x=\"310.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escreva só o código para passar</text><circle cx=\"510.0\" cy=\"90.0\" r=\"34\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"2.2\"></circle><text x=\"510.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">refatorar</text><text x=\"510.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">melhore o código, com os testes passando</text><path d=\"M148.0 90.0 L272.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pm-ah-paper-dim)\"></path><path d=\"M348.0 90.0 L472.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pm-ah-paper-dim)\"></path><path d=\"M510 158 C510 212 110 212 110 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pm-ah-paper-dim)\"></path></svg>", "caption": "O ciclo do teste primeiro. Cada volta leva minutos, e o código nunca está a mais de um passo pequeno de um estado em que todos os testes passam."}
```

A expressão do próprio Beck para os três passos é **vermelho, verde, refatorar**, pelas cores que um executor de testes mostra. Cada volta leva minutos. O ponto é menos os testes em si que o ritmo: o código nunca está a mais de alguns minutos de um estado em que tudo funciona.

## Uma volta, executada de verdade

O exemplo abaixo constrói a fórmula PERT que a aula 9 usa para estimativas — a média ponderada de um valor otimista, um mais provável e um pessimista — em Python. Você não precisa de Python para este curso; se tiver Python 3, pode acompanhar numa pasta vazia. As transcrições são reproduzidas pelo `captures.sh` da aula.

Primeiro o teste, em `test_estimate.py`, antes de existir qualquer código:

```python
import unittest

from estimate import pert


class PertTest(unittest.TestCase):
    def test_weights_the_most_likely_four_times(self):
        self.assertEqual(pert(3, 5, 13), 6.0)


if __name__ == "__main__":
    unittest.main()
```

Rodar falha, e deve falhar. A falha diz exatamente o que está faltando:

```
$ python3 -m unittest test_estimate
E
======================================================================
ERROR: test_estimate (unittest.loader._FailedTest.test_estimate)
----------------------------------------------------------------------
ImportError: Failed to import test module: test_estimate
Traceback (most recent call last):
  File "/usr/lib/python3.13/unittest/loader.py", line 141, in loadTestsFromName
    module = __import__(module_name)
  File "/tmp/estimate/test_estimate.py", line 3, in <module>
    from estimate import pert
ModuleNotFoundError: No module named 'estimate'


----------------------------------------------------------------------
Ran 1 test in 0.000s

FAILED (errors=1)
```

Depois, só o código necessário, em `estimate.py`:

```python
def pert(optimistic, likely, pessimistic):
    return (optimistic + 4 * likely + pessimistic) / 6
```

```
$ python3 -m unittest test_estimate
.
----------------------------------------------------------------------
Ran 1 test in 0.000s

OK
```

## O segundo teste é onde o design acontece

Nada impede alguém de chamar `pert(13, 5, 3)` com os valores na ordem errada, e a função devolveria um número mesmo assim. Escrever primeiro o teste desse caso força uma decisão sobre o que a função deve fazer com um absurdo, antes que qualquer chamador dependa da resposta:

```python
    def test_refuses_an_optimistic_above_the_pessimistic(self):
        with self.assertRaises(ValueError):
            pert(13, 5, 3)
```

```
$ python3 -m unittest test_estimate
F.
======================================================================
FAIL: test_refuses_an_optimistic_above_the_pessimistic (test_estimate.PertTest.test_refuses_an_optimistic_above_the_pessimistic)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/tmp/estimate/test_estimate.py", line 11, in test_refuses_an_optimistic_above_the_pessimistic
    with self.assertRaises(ValueError):
         ~~~~~~~~~~~~~~~~~^^^^^^^^^^^^
AssertionError: ValueError not raised

----------------------------------------------------------------------
Ran 2 tests in 0.001s

FAILED (failures=1)
```

O código que faz os dois passarem:

```schooling-example
{"language": "python", "file": "estimate.py", "parts": [{"code": "def pert(optimistic, likely, pessimistic):", "note": "Os nomes dizem qual valor é qual, então quem lê a assinatura sabe a ordem."}, {"code": "    if not optimistic <= likely <= pessimistic:\n        raise ValueError(\"expected optimistic <= likely <= pessimistic\")", "note": "Foi o segundo teste que pediu isto. Valores na ordem errada são recusados com uma mensagem, em vez de produzirem um número com cara de estimativa."}, {"code": "    return (optimistic + 4 * likely + pessimistic) / 6", "note": "Foi o primeiro teste que pediu isto: o valor mais provável conta quatro vezes, e os seis pesos o dividem de volta numa média."}]}
```

```
$ python3 -m unittest -v test_estimate
test_refuses_an_optimistic_above_the_pessimistic (test_estimate.PertTest.test_refuses_an_optimistic_above_the_pessimistic) ... ok
test_weights_the_most_likely_four_times (test_estimate.PertTest.test_weights_the_most_likely_four_times) ... ok

----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

## O que isso compra, e quanto custa

Um time que trabalha assim termina a cada poucos minutos com uma suíte de testes que descreve o que o código faz, e essa suíte é o que torna barata a mudança tardia que o manifesto prometeu: mude algo, rode os testes, saiba em segundos o que quebrou. O custo também é real. Escrever o teste primeiro é mais lento no primeiro dia, exige um código que possa ser testado em pedaços pequenos, e testes mal escritos — presos a como o código funciona e não ao que ele faz — tornam a mudança mais cara em vez de mais barata. Essa última falha é a que vale procurar numa revisão.
