---
title: Dois decoradores, e duas ordens diferentes
version: 1
---

```python
@cronometrado
@repetir(vezes=3)
def buscar(url):
    ...
```

é

```python
buscar = cronometrado(repetir(vezes=3)(buscar))
```

**Eles se APLICAM de baixo para cima**: o mais perto do `def` envolve primeiro, e o de cima envolve
aquele.

**Eles RODAM de cima para baixo**: uma chamada entra no wrapper do `cronometrado`, que chama o
wrapper do `repetir`, que chama o `buscar`.

Essas são duas ordens diferentes, e as duas estão corretas ao mesmo tempo — o wrapper mais de fora
é o último aplicado e o primeiro em que se entra.

## E é por isso que a ordem importa

```python
@cronometrado
@repetir(vezes=3)     # a cronometragem mede as três tentativas

@repetir(vezes=3)
@cronometrado         # a cronometragem mede cada tentativa em separado
```

Os mesmos dois decoradores, sentidos diferentes. Nenhum está errado; eles respondem perguntas
diferentes, e a pilha é onde a resposta é decidida.

## A que está sempre errada

```python
@app.route("/linhas")
@exige_login
def linhas(): ...
```

contra

```python
@exige_login
@app.route("/linhas")     # o framework registrou a função DESPROTEGIDA
def linhas(): ...
```

Um decorador que REGISTRA a função precisa ser o mais de fora, porque ele registra o que lhe for
entregue — e o que lhe é entregue é o que estiver abaixo dele. A segunda versão protege uma função
que ninguém chama e serve uma que não está protegida.

**Essa é uma forma de defeito real em código web**, e ela é silenciosa.

## E o conselho

Dois é uma pilha que alguém consegue ler. Três é uma pilha que alguém vai errar. Se a ordem importa
e não é óbvia, um comentário ao lado custa uma linha — e um decorador único que faz as duas coisas
costuma ser a resposta honesta.
