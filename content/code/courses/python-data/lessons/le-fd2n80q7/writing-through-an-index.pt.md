---
title: Escrevendo por um índice, e a escrita que some
version: 1
---

**Atribuir a um índice muda o array no lugar: `rain[rain < 0.5] = 0` põe em zero toda leitura
pequena no próprio `rain`.** É uma das linhas mais úteis do NumPy. A armadilha está um passo ao lado:
atribuir ao resultado de um índice, em vez de através dele, muda uma cópia que é jogada fora na hora.

Trabalhe numa cópia da chuva, para que o original fique como o arquivo o tem:

```python
r = rain.copy()
r[r < 0.5] = 0.0
(r == 0).sum(), (rain == 0).sum()
```

```
(np.int64(197), np.int64(192))
```

`r[r < 0.5] = 0.0` se lê "onde `r` está abaixo de meio milímetro, ponha zero". Cinco leituras
estavam acima de zero e abaixo de meio milímetro, então `r` tem cinco zeros a mais que `rain`. Os
seis `nan` ficam intactos, porque `nan < 0.5` é `False`.

O mesmo mecanismo preenche os dias faltantes, se você decidiu com o quê:

```python
r[np.isnan(r)] = 0.0
np.isnan(r).sum(), r.sum().round(1)
```

```
(np.int64(0), np.float64(1711.5))
```

## Dois índices seguidos

Agora a armadilha. Limite os dias de chuva forte do primeiro trimestre a 30 milímetros, escrito como
duas seleções, uma depois da outra:

```python
r2 = rain.copy()
r2[:90][r2[:90] > 30] = 30.0
r2[:90].max()
```

```
np.float64(30.0)
```

Funcionou: `r2[:90]` é uma **fatia**, uma view, então a atribuição pela máscara escreveu nos bytes do
próprio `r2`. Agora a mesma ideia com a primeira seleção feita por máscara, os dias de chuva forte,
seguida de uma fatia deles:

```python
r3 = rain.copy()
r3[r3 > 20][:3] = 0.0
np.nanmax(r3[:90]), (r3 > 20).sum()
```

```
(np.float64(45.9), np.int64(20))
```

**Nada mudou.** `r3[r3 > 20]` é uma **cópia**, como a última seção disse, e `[:3] = 0.0` escreveu
nessa cópia, que ninguém guardou. Nenhum erro, nenhum aviso: o código se lê como uma atribuição e não
é uma. A regra que evita isso é **indexar uma vez, com tudo, do lado esquerdo do `=`**: um só par de
colchetes no array que você quer mudar.

O pandas encontrou exatamente esse problema e passou anos avisando sobre ele como
`SettingWithCopyWarning`; o pandas 3 mudou as regras para que a segunda forma nunca escreva. A aula
11 é essa história.
