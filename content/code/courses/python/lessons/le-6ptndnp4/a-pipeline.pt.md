---
title: Geradores ponta com ponta
version: 1
---

```python
def linhas(caminho):
    with open(caminho, encoding="utf-8") as f:
        for linha in f:
            yield linha.rstrip("\n")

def erros(linhas):
    for linha in linhas:
        if " ERROR " in linha:
            yield linha

def duracoes(linhas):
    for linha in linhas:
        m = DURACAO.search(linha)
        if m:
            yield int(m["ms"])

total = sum(duracoes(erros(linhas(caminho))))
```

Quatro estágios, um valor por vez, do começo ao fim. Nada é construído em lugar nenhum, e a coisa
toda custa a memória de uma linha, seja qual for o arquivo.

## Leia de dentro para fora, ou de baixo para cima

O `linhas` produz, o `erros` filtra, o `duracoes` transforma, o `sum` consome. **Cada estágio
recebe um iterável e produz um iterável**, que é o que os torna componíveis em qualquer ordem que
faça sentido.

Este é o pipeline do `linux-terminal` num processo só — `grep` e depois `sed` e depois `awk`, com
a mesma propriedade: nenhum estágio espera o anterior terminar.

## Nada roda até a última linha

As três chamadas constroem três objetos geradores e não fazem nada. O `sum` puxa, que puxa, que
puxa, que lê uma linha do arquivo. **Tire o `sum` e o arquivo nunca é aberto.**

## Onde pôr a leitura

```python
def duracoes(linhas):        # recebe linhas, e não um caminho
```

Cada estágio recebe um ITERÁVEL em vez de um nome de arquivo, que é o que o torna testável com uma
lista de três strings e reaproveitável em outra fonte. Só o primeiro estágio sabe de um arquivo.

## E onde a preguiça acaba

```python
maiores = sorted(duracoes(erros(linhas(caminho))), reverse=True)[:10]
```

O `sorted` precisa de tudo, então isto guarda toda duração em memória — os inteiros, e não as
linhas, o que em geral está bem. O `heapq.nlargest(10, …)` é a versão que guarda dez.

**Saber qual linha do seu pipeline é a que acumula** é a habilidade prática aqui, e quase sempre é
a ordenação.
