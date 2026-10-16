---
title: A ordem das somas, e o último dígito de um total
version: 1
---

**A soma de ponto flutuante não é associativa: `(a + b) + c` pode diferir de `a + (b + c)`.** Cada
soma arredonda o resultado para o float representável mais próximo, e quais arredondamentos
acontecem depende da ordem. A aula 3 prometeu a consequência: a mesma soma, feita em outra ordem,
pode imprimir outro último dígito, e nada está errado.

O caso extremo cabe em três números:

```python
np.array([1e16, 1.0, -1e16]).sum(), np.array([1e16, -1e16, 1.0]).sum()
```
```
(np.float64(0.0), np.float64(1.0))
```

Na primeira ordem, `1e16 + 1.0` volta a arredondar para `1e16`, porque um float desse tamanho não
tem espaço para o dígito das unidades, e o 1 se perde antes da subtração. Na segunda, os dois
números grandes se anulam primeiro e o 1 sobrevive. Os mesmos três números, respostas `0.0` e
`1.0`.

## Uma soma longa, de três jeitos

Dados reais não são tão extremos, e o efeito está lá nos últimos dígitos. Dez décimos, somados do
jeito que um laço simples soma, um depois do outro:

```python
import math

tenths = np.full(10, 0.1)
total = 0.0
for x in tenths:
    total += x
total, tenths.sum(), sum(tenths.tolist()), math.fsum(tenths)
```
```
(np.float64(0.9999999999999999), np.float64(1.0), 1.0, 1.0)
```

O laço acumula um erro de arredondamento a cada passo e termina um pouco abaixo de 1. Os outros três
dão `1.0`, cada um por um motivo. O `sum` do NumPy soma o array em pedaços e depois soma os totais
dos pedaços, um método chamado **soma em pares** que mantém o erro pequeno em arrays longos. O
`sum` embutido do Python compensa os bits perdidos desde o Python 3.12. `math.fsum` acompanha cada
bit perdido e devolve o total corretamente arredondado, ao custo de velocidade.

As temperaturas do ano, repetidas mil vezes, somadas por um laço e pelo NumPy:

```python
long = np.tile(temp, 1000)
running = 0.0
for x in long.tolist():
    running += x
running, long.sum(), math.fsum(long)
```
```
(10927899.99999855, np.float64(10927900.0), 10927900.0)
```

365.000 somas seguidas, e o total do laço se desviou por cerca de um milionésimo, enquanto os outros
dois concordam.

## A precisão acaba mais rápido no `float32`

Um `float32` guarda uns sete dígitos significativos. Um total corrente guardado em `float32`, que é
o que o `cumsum` faz passo a passo, não tem mais espaço para os decimais de cada dia novo quando
chega às centenas de milhares:

```python
long_rain = np.tile(np.nan_to_num(rain), 1000).astype(np.float32)
np.cumsum(long_rain)[-1], long_rain.sum()
```
```
(np.float32(1.712768e+06), np.float32(1.7128e+06))
```

`np.nan_to_num` troca `nan` por 0, uma escolha feita para esta demonstração e não para se fazer em
silêncio com dados reais. O total passo a passo perdeu uns 32 milímetros em 1,7 milhão; a soma em
pares dos mesmos números `float32`, não. Para totais que importam, fique no `float64`.

## O que fazer

- **Compare floats com tolerância**, `np.isclose`, nunca com `==`. Dois cálculos corretos do mesmo
  total podem diferir no último dígito.
- **Arredonde para mostrar, não para calcular.** Arredonde uma vez, no fim, na precisão que o número
  merece: chuva em décimos de milímetro.
- **Dinheiro não é float.** Conte centavos em inteiros, que somam exato em qualquer ordem.
