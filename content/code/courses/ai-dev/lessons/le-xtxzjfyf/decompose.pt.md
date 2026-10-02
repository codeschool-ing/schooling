---
title: Um passo por vez
version: 1
---

"Acrescente suporte a vírgula no parser de preço" é uma tarefa de três partes: decidir o que ela
deve fazer, escrever os testes que dizem isso, mudar o código. Pedir tudo numa requisição traz as
três de uma vez, misturadas, e os testes que chegam junto com a mudança têm o problema da aula 4
seção 04: foram escritos a partir da mudança. **Pedir um passo por vez deixa você conferir cada passo
antes de o próximo ser construído em cima dele.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A ordem da aula 5. Pedir um plano; escrever os testes a partir dele, à mão; rodá-los e vê-los falhar; pedir a mudança; rodar os testes. Quando um falha, mandar a falha de volta e pedir de novo; quando todos passam, parar.\"><defs><marker id=\"st-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"50\" width=\"124\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pedir um plano</text><text x=\"76.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">modelo</text><path d=\"M140 76 L152 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><rect x=\"154\" y=\"50\" width=\"124\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"216.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">escrever os testes</text><text x=\"216.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">você</text><path d=\"M280 76 L292 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><rect x=\"294\" y=\"50\" width=\"124\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"356.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">vê-los falhar</text><text x=\"356.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pytest</text><path d=\"M420 76 L432 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><rect x=\"434\" y=\"50\" width=\"124\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"496.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pedir a mudança</text><text x=\"496.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">modelo</text><path d=\"M560 76 L572 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><rect x=\"574\" y=\"50\" width=\"124\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"636.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">rodar os testes</text><text x=\"636.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pytest</text><path d=\"M636 104 L636 160 L496 160 L496 106\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><text x=\"566\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um teste falha: mande a falha de volta</text><path d=\"M698 76 L698 30 L640 30\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"560\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">todos passam: pare</text></svg>", "caption": "Cada passo é conferido antes de o próximo ser construído em cima dele, e os testes existem antes do código que julgam."}
```

## Um plano, e nenhum código

A ana recomeça do `parse_price` original e pede só os passos:

```
ana@dev:~/shop$ git checkout -q shop/money.py && git status --short
?? comma.diff
?? error.txt
?? lab/
?? prompts/
ana@dev:~/shop$ assist ask "We need parse_price to accept a decimal comma. Do not write code yet: list the steps, with the tests first." --open shop/money.py CONVENTIONS.md 2>/dev/null
1. Write the tests first, from what the change must do: '12,90' and '12,9' parse like '12.90' and '12.9', the existing dot keeps working, and '1.234,56' is refused, because a dot and a comma in one price leave no way to tell which is the decimal separator.
2. Change parse_price to read a comma as the decimal separator, keeping the arithmetic in integers as CONVENTIONS.md requires.
3. Run the whole suite, not only the new tests.

```

O plano, escrito pelo curso, põe os testes primeiro e nomeia o caso de que ninguém tinha falado:
`1.234,56`, em que um ponto e uma vírgula no mesmo preço não deixam saber qual é o separador
decimal. **Um plano é barato de ler e barato de corrigir.** Se ele tivesse dito "converta para
float", seria uma frase a riscar em vez de um diff a desfazer.

## Os testes, a partir do plano, à mão

A ana escreve ela mesma os testes, a partir da lista de casos do plano, decidindo os valores
esperados:

```python
import pytest

from shop.money import parse_price


@pytest.mark.parametrize("text", ["12,90", "12.90", "12,9", " 12,90 "])
def test_a_comma_or_a_dot_is_the_decimal_separator(text):
    assert parse_price(text) == 1290


def test_a_price_with_both_a_dot_and_a_comma_is_refused():
    with pytest.raises(ValueError):
        parse_price("1.234,56")
```

Rodados antes da mudança, eles deviam falhar, e falham (a última regra da aula 5 seção 05):

```
ana@dev:~/shop$ python -m pytest -q tests/test_comma.py 2>&1 | tail -3
FAILED tests/test_comma.py::test_a_comma_or_a_dot_is_the_decimal_separator[ 12,90 ]
FAILED tests/test_comma.py::test_a_price_with_both_a_dot_and_a_comma_is_refused
4 failed, 1 passed in 0.54s
```

## A mudança

O diff da aula 5 seção 03, aplicado:

```
ana@dev:~/shop$ git apply comma.diff && python -m pytest -q tests/test_comma.py
....F                                                                    [100%]
=================================== FAILURES ===================================
_____________ test_a_price_with_both_a_dot_and_a_comma_is_refused ______________

    def test_a_price_with_both_a_dot_and_a_comma_is_refused():
>       with pytest.raises(ValueError):
E       Failed: DID NOT RAISE ValueError

tests/test_comma.py:12: Failed
=========================== short test summary info ============================
FAILED tests/test_comma.py::test_a_price_with_both_a_dot_and_a_comma_is_refused
1 failed, 4 passed in 0.52s
```

Quatro de cinco. A vírgula funciona, o ponto continua funcionando, e `1.234,56` é aceito quando o
plano dizia que devia ser recusado. O diff de uma linha troca a vírgula por ponto e divide no
primeiro ponto, então lê `1.234,56` como uma unidade e vinte e três centavos, em silêncio. **O teste
escrito a partir do plano pegou o que o diff escrito a partir do erro não considerou.** É esse o valor
da ordem: o requisito existia, como teste, antes do código que tinha de cumpri-lo.
