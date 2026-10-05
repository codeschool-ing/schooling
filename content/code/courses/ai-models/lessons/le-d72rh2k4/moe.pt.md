---
title: Especialistas, e dois tamanhos por modelo
version: 1
---

O cartão da Llama 4 dá a cada modelo duas contagens de parâmetros:

```
ana@desk:~/desk$ sources lines llama4-card 23 42 | grep -E "Llama 4|Activated|Total|>[0-9]+M<"
  23|     <td>Llama 4 Scout (17Bx16E) </td>
  26|     <td>17B (Activated)
  27|         109B (Total)
  31|     <td>10M</td>
  36|     <td>Llama 4 Maverick (17Bx128E)</td>
  37|     <td>17B (Activated)
  38|         400B (Total)
  42|     <td>1M</td>
```

**Scout: 17 bilhões ativados, 109 bilhões no total. Maverick: 17 bilhões ativados, 400 bilhões no
total.** Isso é uma **mistura de especialistas** (*mixture of experts*). Em vez de um bloco
feed-forward grande por camada, o modelo tem vários menores, os especialistas (16 no Scout, 128 no
Maverick), e um pequeno roteador que manda cada token por apenas alguns deles. Todo especialista
precisa ficar na memória, porque qualquer token pode precisar de qualquer um; só os escolhidos são
calculados para cada token.

Então um modelo de mistura de especialistas tem **dois tamanhos que respondem a duas perguntas da
aula 3**:

- **o total decide se ele cabe**: a memória precisa guardar todos os especialistas;
- **a parte ativa decide com que velocidade ele gera**: a seção 05 da aula 3 disse que velocidade é
  largura de banda dividida pelos bytes lidos por token, e só os especialistas ativos são lidos.

O `lab/moe.py` aplica a aritmética da aula 3 aos dois, em 4 bits e com os mesmos 1.000 GB/s supostos:

```python
# Llama 4's two models, from the card: billions of parameters in all, and the
# billions each token is actually computed with.
MODELS = {"Llama 4 Scout": (109, 17), "Llama 4 Maverick": (400, 17)}
BANDWIDTH = 1000  # GB/s, the same assumption as lesson 3

for name, (total, active) in MODELS.items():
    held, read = total / 2, active / 2  # gigabytes at 4 bits: half a byte per parameter
    print(f"{name:17} holds {held:5.1f} GB, reads {read:4.1f} GB a token, "
          f"ceiling about {BANDWIDTH / read:3.0f} tokens a second")
```

```
ana@desk:~/desk$ python lab/moe.py
Llama 4 Scout     holds  54.5 GB, reads  8.5 GB a token, ceiling about 118 tokens a second
Llama 4 Maverick  holds 200.0 GB, reads  8.5 GB a token, ceiling about 118 tokens a second
```

O mesmo teto de velocidade para os dois, uns 118 tokens por segundo, porque os dois calculam com 17
bilhões de parâmetros por token, e **quase quatro vezes a memória** para o Maverick, porque ele guarda
400 bilhões. Compare com a Llama 3.1 70B densa da aula 3: 35 GB em 4 bits e um teto de 28 tokens por
segundo. O Scout guarda mais e roda mais rápido.

Essa é a troca que os especialistas fazem: mais memória por mais conhecimento, e a velocidade de um
modelo bem menor. É por isso que contagens de parâmetros deixaram de ser um número só, e por que "um
modelo de 17B" numa manchete pode ser algo que precisa de 200 GB para carregar.
