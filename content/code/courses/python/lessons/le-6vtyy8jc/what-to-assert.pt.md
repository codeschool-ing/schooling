---
title: Um comportamento, um nome que diz qual, e a asserção que não prova nada
version: 2
---

```python
def test_slugify_works():                       # what broke?
def test_punctuation_is_removed_from_a_slug():  # this one
```

**O nome é o que você lê às cinco e meia com a CI vermelha.** Um bom nome é uma frase sobre o
sistema, então a saída da suíte vira uma lista de fatos e uma falha nomeia um deles sem ninguém
abrir arquivo.

## Um comportamento por teste

```python
def test_slugify():                             # six facts
    assert slugify("Hello World") == "hello-world"
    assert slugify("ALL CAPS") == "all-caps"
    assert slugify("Hello, World") == "hello-world"
    assert slugify("") == ""
    ...
```

A primeira linha que falha esconde as cinco abaixo dela, então você conserta uma, roda de novo,
acha a seguinte, e aprende o estado da função uma ida e volta por vez. Parametrização, duas seções
adiante, é como esta tabela vira seis testes com uma função.

## A asserção que não prova nada

```python
def test_total_runs():
    result = total([(2, 10.0)], 0.1)
    assert result is not None
```

Toda linha do módulo roda. A cobertura relata cem por cento. E `is not None` é verdade sobre quase
todo valor que existe, então o teste passa seja lá o que a aritmética fez — que é o módulo em que a
demonstração desta aula acha um imposto dobrado.

**Afirme a resposta, não o fato de ter havido uma.**

## Comportamento, não implementação

```python
def test_notify(mocker):
    ...
    assert mailer.send.called          # that a helper was called
```

```python
def test_notify():
    ...
    assert sent == [("a@b.c", "Welcome")]   # what the system did
```

O primeiro fica vermelho quando você renomeia o auxiliar e verde quando a mensagem está errada.
**Um teste acoplado à implementação encarece a refatoração e não acha nada**, que é o pior das duas
metades.

## O que um bom teste afirma

O valor que volta. O estado que mudou. A exceção levantada para uma entrada ruim. A borda — uma
lista vazia, um zero, um elemento só, o último dia do mês. Essas são as entradas em que o código
foi escrito a partir de um retrato do caso comum.
