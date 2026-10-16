---
title: Números que chegaram como texto
version: 1
---

**Uma coluna numérica que volta como `str` tem pelo menos um valor que não é número, e o
`pd.to_numeric` é como você descobre qual.** A aula 10 encontrou o caso em que o culpado era um
marcador conhecido. Aqui ele é desconhecido, que é o caso comum.

Um relatório de medição com as docas em funcionamento, digitado por uma pessoa:

```python
report = pd.Series(["14", "20", "12", "n/a", "17", "1O", "10"])
report.dtype
```

```
<StringDtype(na_value=nan)>
```

`astype(int)` falha no primeiro valor ruim e para ali, o que diz que algo está errado e não quanto:

```python
report.astype(int)
```

```
ValueError: invalid literal for int() with base 10: 'n/a'
```

`pd.to_numeric` com `errors="coerce"` converte o que consegue e transforma o resto em `NaN`, para
você ver todas as falhas de uma vez:

```python
docks = pd.to_numeric(report, errors="coerce")
docks.tolist(), report[docks.isna()].tolist()
```

```
([14.0, 20.0, 12.0, nan, 17.0, nan, 10.0], ['n/a', '1O'])
```

Dois valores falharam: o marcador, e `1O`, um um seguido da **letra** O, que parece dez e não é.
**Nunca force e siga em frente.** Forçar é um jeito de listar os problemas, e a segunda linha, o texto
original dos valores que falharam, é a lista. Uns são valores faltantes e outros são erros de
digitação com uma resposta certa que ainda dá para recuperar; só uma pessoa lendo sabe dizer qual é
qual.

O dtype que sai é `float64`, porque `NaN` é um float. Uma coluna de inteiros com faltantes tem uma
casa melhor, a última seção desta aula.
