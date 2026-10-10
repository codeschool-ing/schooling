---
title: Quando um laço continua laço
version: 1
---

**Nem tudo se vetoriza, e algumas coisas que se vetorizam não deveriam.** A regra prática não é
"nunca escreva um laço"; é "nunca percorra os elementos de um array grande quando existe uma
operação sobre o array inteiro". Três casos em que o laço, ou algo parecido, fica.

## `np.vectorize` é um laço com boas maneiras

`np.vectorize` embrulha uma função Python comum para que ela aceite arrays. Parece a resposta para
"como vetorizo a minha função", e não é: a documentação diz que é um laço, e o relógio concorda.

```python
def describe(mm):
    if mm == 0:
        return "dry"
    return "light" if mm < 10 else "heavy"

describe_all = np.vectorize(describe)
describe_all(rain[:5])
```
```
array(['dry', 'light', 'light', 'heavy', 'dry'], dtype='<U5')
```

A chuva repetida mil vezes, como na primeira seção, com os dias sem leitura como zero:

```python
big_rain = np.tile(np.nan_to_num(rain), 1000)
big_rain.shape
```
```
(365000,)
```

```python
slow = %timeit -o -q describe_all(big_rain)
fast = %timeit -o -q np.select([big_rain == 0, big_rain < 10], ["dry", "light"], "heavy")
round(slow.average * 1000, 1), round(fast.average * 1000, 1)
```

```
(123.7, 6.8)
```

`np.select` é o `np.where` para mais de duas escolhas: uma lista de condições, uma lista de
valores e um padrão, conferidos em ordem, em código compilado. A versão vetorizada ganha com folga.
`np.vectorize` é uma comodidade para aplicar uma função a arrays de qualquer formato; não torna a
função rápida.

## Quando cada valor depende do anterior

A maior sequência de dias secos do ano. O comprimento da sequência de cada dia é o do dia anterior
mais um, ou zero depois de chuva: **cada valor depende do anterior**, e esse é o caso para o qual o
NumPy não tem uma operação única. Um laço diz isso com clareza:

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "longest = current = 0\n",
      "note": "Dois contadores: a melhor sequência até agora, e a que termina hoje."
    },
    {
      "code": "for mm in np.nan_to_num(rain):\n",
      "note": "Um dia por vez. Um dia sem leitura conta como seco aqui, uma escolha que se deve dizer."
    },
    {
      "code": "    current = current + 1 if mm == 0 else 0\n",
      "note": "Um dia seco estende a sequência de hoje; qualquer chuva a zera. Esta linha precisa do valor de ontem, que é o que nenhuma operação única de array dá."
    },
    {
      "code": "    longest = max(longest, current)\n",
      "note": "Guarda a melhor sequência vista."
    },
    {
      "code": "longest\n",
      "note": "Catorze dias seguidos sem chuva."
    }
  ],
  "output": "14\n"
}
```

Existem truques vetorizados para sequências, feitos com `diff` e `cumsum`, e são difíceis de ler e
fáceis de errar. Com 365 valores o laço não leva tempo mensurável. **A clareza vence até o tamanho a
fazer perder**, e a aula 17 encontra a mesma troca no pandas, em que o `apply` é o laço.

## Quando os temporários não cabem

`big * 9 / 5 + 32` cria um array novo inteiro para `big * 9`, outro para a divisão e um terceiro para
a soma. Para 365.000 floats são três arrays de 2,9 MB e ninguém percebe. Para um array que ocupa
metade da sua memória, os temporários não cabem. Operadores no lugar reaproveitam o mesmo bloco:

```python
f = big.copy()
f *= 9
f /= 5
f += 32
np.isclose(f, big * 9 / 5 + 32).all()
```
```
np.True_
```

`*=` escreve o resultado no próprio `f`. É mais feio e só vale a pena quando a memória é o
problema; a aula 20 é sobre o dia em que ela é.
