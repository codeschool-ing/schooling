---
title: O que um dtype guarda, e o que ele em silêncio não guarda
version: 1
---

**Um dtype é uma promessa sobre quantos bits cada número recebe, e o NumPy cumpre a promessa mesmo
quando o número não cabe.** Um `int` do Python cresce o quanto precisar; um `int8` tem oito bits e
guarda de -128 a 127, e a aritmética que passa da borda dá a volta:

```python
small = np.array([120, 125, 127], dtype=np.int8)
small + 5
```
```
array([ 125, -126, -124], dtype=int8)
```

`127 + 5` virou `-124`, sem erro e sem aviso. Isso não é um defeito do NumPy: é o que um
registrador de 8 bits faz, e o NumPy o expõe porque conferir cada soma custaria a velocidade para a
qual o array existe. A defesa é conhecer a faixa do que você guarda. `np.iinfo` diz:

```python
np.iinfo(np.int8), np.iinfo(np.int64).max
```
```
(iinfo(min=-128, max=127, dtype=int8), 9223372036854775807)
```

O inteiro padrão, `int64`, chega a nove quintilhões, o que nada neste curso se aproxima. Os tipos
pequenos importam quando a memória importa, e a aula 20 os usa de propósito.

## Floats são aproximações

`float64` guarda uns 15 dígitos decimais significativos, e a maioria das frações decimais não é
exata em binário:

```python
x = np.array([0.1, 0.2])
x.sum(), x.sum() == 0.3, np.isclose(x.sum(), 0.3)
```
```
(np.float64(0.30000000000000004), np.False_, np.True_)
```

**Nunca compare floats com `==`.** `np.isclose` compara dentro de uma tolerância, e é o teste que
toda aula depois desta usa. `float32` reduz a memória à metade e guarda uns 7 dígitos, o que basta
para um gráfico e não basta para dinheiro; este curso conta reais em centavos inteiros quando
precisa deles exatos.

## Convertendo, e o que se perde

`astype` cria um array novo de outro tipo. De float para inteiro ele **trunca em direção ao zero**,
não arredonda:

```python
temps = np.array([29.9, 30.5, -0.7])
temps.astype(int), np.round(temps).astype(int)
```
```
(array([29, 30,  0]), array([30, 30, -1]))
```

E `nan` não tem forma inteira nenhuma. Uma coluna float com um valor faltante não pode virar uma
coluna inteira. O NumPy não recusa: avisa, e escreve no lugar um inteiro que não quer dizer nada,
aqui o menor `int64` que existe:

```python
rain[:5], rain[np.isnan(rain)][:1].astype(int)
```
```
/tmp/ipykernel_11181/698349897.py:1: RuntimeWarning: invalid value encountered in cast
  rain[:5], rain[np.isnan(rain)][:1].astype(int)
(array([ 0. ,  6.8,  7.9, 15.7,  0. ]), array([-9223372036854775808]))
```

É por isso que o pandas, na aula 12, tem tipos inteiros que guardam um valor faltante. No NumPy
puro, uma coluna com buracos continua float.
