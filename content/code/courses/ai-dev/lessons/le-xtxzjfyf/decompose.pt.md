---
title: Um passo por vez
version: 2
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

A ana devolve o `parse_price` ao que era e pede só os passos:

```
ana@dev:~/shop$ git checkout -q shop/money.py && git status --short
?? comma.diff
?? error.txt
?? prompts/
?? scratch/
ana@dev:~/shop$ python scratch/assist.py ask "We need parse_price to accept a decimal comma. Do not write code yet: list the steps, with the tests first." --open shop/money.py CONVENTIONS.md > /dev/null
context sent (511 of 3000 tokens):
    137  shop/money.py
    374  CONVENTIONS.md
---
ana@dev:~/shop$ cat -n scratch/reply.txt
     1	Here are the steps to update the `parse_price` function to accept a decimal comma:
     2	
     3	### Step 1: Write a test that fails without the change
     4	
     5	* Name: `test_parse_price_with_comma`
     6	* Description: A price with a decimal comma should still be parsed correctly.
     7	* Expected outcome: The test should fail because the `parse_price` function doesn't currently accept a decimal comma.
     8	
     9	### Step 2: Update the test to verify the correct behavior
    10	
    11	* Name: `test_parse_price_with_comma`
    12	* Description: A price with a decimal comma should be parsed correctly.
    13	* Expected outcome: The test should pass, verifying that the updated `parse_price` function correctly handles decimal commas.
    14	
    15	### Step 3: Update the `parse_price` function to accept a decimal comma
    16	
    17	* The updated function should check if the input string contains a comma, and if so, replace it with a dot before parsing the price.
    18	* The updated function should also handle the case where the input string has a comma but no decimal part.
    19	
    20	### Step 4: Review the updated code and ensure it follows the convention rules
    21	
    22	* Verify that the updated `parse_price` function meets the rule that errors are exceptions with a name, and that no function is longer than about 40 lines.
    23	* Verify that the updated code still follows the rule about text being produced by `shop.money.format_price` and parsed by `shop.money.parse_price`.
```

**Um plano é barato de ler e barato de corrigir**, e este precisa de correção. Ele põe um teste
primeiro, e o passo 3 é a ideia certa: trocar a vírgula por um ponto antes de interpretar. Mas os
passos 1 e 2 são o mesmo teste escrito duas vezes, o teste tem nome e nenhum caso, e o passo 4 é o
`CONVENTIONS.md` lido de volta. Nada nele diz que entradas decidem se a mudança funcionou. Isso levou
dez segundos para ler e custa uma frase para consertar; a mesma lacuna achada num diff seria um diff
para desfazer.

## Os testes, à mão

Os casos são a parte do plano que importa, então a ana os escreve ela mesma e decide os valores
esperados. Ela acrescenta um que o plano nunca mencionou, porque sabe como um brasileiro escreve mil:
`1.234,56` tem um ponto e uma vírgula, e nenhuma regra diz qual dos dois é o separador decimal, então
ele precisa ser recusado em vez de adivinhado:

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

Rodados antes da mudança, eles devem falhar, e falham (a última regra da aula 5, seção 05). O que
passa é o `12.90`, que a função antiga já lia:

```
ana@dev:~/shop$ python -m pytest -q tests/test_comma.py | tail -n 3
FAILED tests/test_comma.py::test_a_comma_or_a_dot_is_the_decimal_separator[ 12,90 ]
FAILED tests/test_comma.py::test_a_price_with_both_a_dot_and_a_comma_is_refused
4 failed, 1 passed in 0.73s
```

## A mudança

A função da aula 5, seção 05, ainda está em `scratch/parse_price.py`. Trocada, contra os testes
novos:

```
ana@dev:~/shop$ python scratch/swap.py shop/money.py scratch/parse_price.py && python -m pytest -q tests/test_comma.py | tail -n 3
swap: parse_price replaced in shop/money.py
=========================== short test summary info ============================
FAILED tests/test_comma.py::test_a_comma_or_a_dot_is_the_decimal_separator[12.90]
1 failed, 4 passed in 0.71s
```

Quatro de cinco, e o que falha é o ponto, como o teste do próprio projeto já dizia. **Um dos quatro
passa pelo motivo errado.** O `1.234,56` é recusado, como o teste exige, mas só porque a função o
divide na vírgula e `int("1.234")` por acaso falha; nada nela decidiu que um preço com os dois
separadores é ambíguo. Um teste confere o que acontece, não por quê, o que é mais um motivo para ler
uma mudança que passa.

Os testes agora existem antes do código que precisa atendê-los, e dizem exatamente o que está errado.
A aula 5, seção 06, manda isso de volta.
