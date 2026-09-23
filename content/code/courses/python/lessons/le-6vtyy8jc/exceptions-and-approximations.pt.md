---
title: `raises` com um `match`, e o float que nunca é igual
version: 2
---

```python
def test_unknown_currency():
    with pytest.raises(KeyError, match="unknown currency"):
        rate("XYZ")
```

**O bloco afirma que o código levantou.** Sem o `pytest.raises` a exceção escapa e o teste dá
erro, que parece um teste quebrado em vez de um comportamento provado.

## `match` não é opcional na prática

```python
with pytest.raises(KeyError):        # ANY KeyError passes
    rate("XYZ")
```

Um erro de digitação no próprio teste levanta `KeyError` também, e uma busca em dicionário três
quadros abaixo, que não tem nada a ver com o caso, igualmente. `match` recebe uma expressão
regular procurada na mensagem:

```sh
E       AssertionError: Regex pattern did not match.
E         Expected regex: 'no such currency'
E         Actual message: "'unknown currency XYZ'"
```

## Olhar a exceção

```python
with pytest.raises(ValueError) as e:
    parse("nonsense")
assert e.value.field == "amount"
```

`e.value` é o objeto da exceção, disponível depois do bloco. As asserções vão **fora** do `with`,
porque dentro dele nada depois da linha que levanta roda.

## O float que nunca é igual

```python
def test_float():
    assert 0.1 + 0.2 == 0.3          # fails
```

Ponto flutuante binário não consegue guardar `0.1`, então a soma é `0.30000000000000004`. Isso é
aritmética e não um defeito, e chega em todo teste que soma dinheiro, tira média de uma coluna ou
converte uma taxa.

```python
def test_float_approx():
    assert 0.1 + 0.2 == pytest.approx(0.3)
```

`approx` compara dentro de uma tolerância — relativa de `1e-6` por padrão, e `abs=` ou `rel=`
quando você precisa da sua. Ele também relata melhor:

```sh
E       assert 0.30000000000000004 == 0.4 ± 4.0e-07
```

A asserção comum imprimiu `assert (0.1 + 0.2) == 0.3` e escondeu o valor que importava.

## E para o que o `approx` não serve

Dinheiro. Um preço é centavo inteiro e compara exatamente; recorrer a uma tolerância ali é
concordar de antemão em errar por um centavo. `approx` é para medidas, taxas e qualquer coisa que
passou por uma divisão.
