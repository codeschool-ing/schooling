---
title: Combinando condições, e o erro que todo mundo encontra
version: 1
---

**Máscaras se combinam com `&`, `|` e `~`, e não com `and`, `or` e `not`, e cada comparação
precisa dos próprios parênteses.** As duas regras vêm do próprio Python e não do NumPy, e as duas
produzem um erro da primeira vez.

Chuva forte num dia quente, escrito do jeito que se fala:

```python
(rain > 20) and (temp > 31)
```

```
ValueError: The truth value of an array with more than one element is ambiguous. Use a.any() or a.all()
```

`and` pergunta ao Python se o lado esquerdo é verdadeiro **como um todo**, e para um array de 365
booleanos não há resposta única: uns são `True` e outros não. O NumPy se recusa a adivinhar, e a
mensagem nomeia os dois jeitos de reduzir um array a um único valor de verdade, `any()` e `all()`,
caso seja isso que você quis. Não é o que você quis aqui. Os operadores elemento a elemento são `&`
para e, `|` para ou, e `~` para não:

```python
both = (rain > 20) & (temp > 31)
both.sum(), dates[both]
```

```
(np.int64(2), array(['2025-08-02', '2025-08-14'], dtype='<U10'))
```

## Por que os parênteses

Tire-os e a expressão ainda é lida, como outra coisa:

```python
rain > 20 & temp > 31
```

```
TypeError: ufunc 'bitwise_and' not supported for the input types, and the inputs could not be safely coerced to any supported types according to the casting rule ''safe''
```

`&` liga mais forte que `>`, então o Python lê `rain > (20 & temp) > 31`, um "e" bit a bit do
inteiro 20 com um array de floats, que o NumPy recusa com outro erro. **Ponha cada comparação nos
próprios parênteses**, sempre, e nenhum dos dois erros acontece.

## Montando uma máscara em passos

Uma condição longa fica mais legível como máscaras com nome, uma por linha, combinadas no fim:

```python
wet = rain > 10
warm = temp > 30.5
weekend = np.isin(np.arange(365) % 7, [3, 4])
(wet & warm & weekend).sum(), (wet & ~weekend).sum()
```

```
(np.int64(5), np.int64(41))
```

`np.isin` pergunta se cada elemento está numa lista. `np.arange(365) % 7` é a posição de cada dia na
semana, e 2025 começou numa quarta-feira, então as posições 3 e 4 são sábado e domingo. Cada máscara
tem um nome que diz o que ela significa, e a linha que as combina se lê como a pergunta.
