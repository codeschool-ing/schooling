---
title: A asserção é reescrita, e os dois valores são impressos
version: 2
---

```python
def test_keeps_punctuation():
    assert slugify("Hello, World") == "hello-world"
```

```sh
=================================== FAILURES ===================================
____________________________ test_keeps_punctuation ____________________________

    def test_keeps_punctuation():
>       assert slugify("Hello, World") == "hello-world"
E       AssertionError: assert 'hello,-world' == 'hello-world'
E
E         - hello-world
E         + hello,-world
E         ?      +

test_slug.py:8: AssertionError
```

**Um `assert` pelado no Python não conta nada** — ele levanta `AssertionError` sem mensagem.
Então o `pytest` reescreve as asserções dos seus arquivos de teste enquanto os importa, segurando
os operandos, e imprime os dois quando um falha.

Essa reescrita é o motivo de um `assert` pelado bastar aqui, e ela acontece só nos arquivos que o
`pytest` coletou — uma asserção no código da sua aplicação continua tão pelada quanto foi escrita.

## Lendo o bloco

`>` marca a linha que falhou. As linhas `E` são a explicação: a comparação desenhada, depois um
diff em que `-` é o esperado e `+` é o que chegou, com uma linha `?` apontando o caractere que
difere. A última linha é a localização.

## E o resumo lá embaixo

```sh
=========================== short test summary info ============================
FAILED test_slug.py::test_keeps_punctuation - AssertionError: assert 'hello,...
========================= 1 failed, 1 passed in 0.02s ==========================
```

**Leia o relatório de baixo para cima.** Numa suíte com trinta falhas o topo da saída é a
primeira, que raramente é a interessante, e o resumo dá todos os nomes em quatro linhas.

## O que ele não vai imprimir

```python
def test_float():
    assert 0.1 + 0.2 == 0.3
```

```sh
E       assert (0.1 + 0.2) == 0.3
```

Aqui a reescrita mostra a expressão em vez do valor dela, e `0.30000000000000004` — que é a
resposta de verdade e a razão inteira de o teste falhar — não aparece. É para esse caso que o
`approx` existe, duas seções adiante.
