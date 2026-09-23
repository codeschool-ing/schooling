---
title: `print`, e o `input` que sempre devolve uma string
version: 2
---

O `print` recebe quantas coisas você der, põe um espaço entre elas e uma quebra de linha no fim.

```python
print("Hello,", "Ada")
```
```
Hello, Ada
```

Não é preciso converter nada. `print(2 + 2)` imprime `4`; o `print` transforma em texto o que quer
que receba, na saída.

## Dois argumentos que valem saber

`sep` é o que vai entre:

```python
print("2026", "09", "21", sep="-")
```
```
2026-09-21
```

`end` é o que vai no fim, e `end=""` é como se imprime várias coisas numa linha só de dentro de um
laço:

```python
print("working", end="")
print("...", end="")
print(" done")
```
```
working... done
```

## O `input` lê uma linha, e ela é sempre uma string

```python
age = input("How old are you? ")
```

O texto que você passa é o prompt. O que volta é **sempre uma `str`**, mesmo quando a pessoa digitou
algarismos — que é por que isto não faz o que parece:

```python
age = input("How old are you? ")
print(age + 1)
```
```
TypeError: can only concatenate str (not "int") to str
```

Leia o traceback: `str` e `int` não são coisas que o `+` saiba juntar. O conserto é converter, e
converter onde dê para ver:

```python
age = int(input("How old are you? "))
```

**E o `int()` recusa o que não é número**, com um `ValueError` nomeando o que recebeu. Isso é matéria
da aula 8, e é o comportamento certo: um programa que transformasse `"doze"` em `0` em silêncio seria
pior.

## O print não é como se olha uma coisa depois

O `print` é como se vê alguma coisa agora, enquanto se escreve. É a ferramenta certa para isso e
quase todo programador Python usa todo dia.

Ele não é um jeito de registrar o que aconteceu — isso é *logging*, e não está neste curso. E ele não
é como uma função devolve um valor para quem a chamou, que é a distinção a que a aula 5 dedica uma
seção, por ser a que os iniciantes mais trocam de lugar.
