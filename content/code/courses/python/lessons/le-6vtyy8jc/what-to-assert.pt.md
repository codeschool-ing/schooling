---
title: Um comportamento, um nome que diz qual, e a asserção que não prova nada
version: 1
---

```python
def test_slugify_funciona():                      # o que quebrou?
def test_pontuacao_e_removida_de_um_slug():       # este aqui
```

**O nome é o que você lê às cinco e meia com a CI vermelha.** Um bom nome é uma frase sobre o
sistema, então a saída da suíte vira uma lista de fatos e uma falha nomeia um deles sem ninguém
abrir arquivo.

## Um comportamento por teste

```python
def test_slugify():                             # seis fatos
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
def test_total_roda():
    resultado = total([(2, 10.0)], 0.1)
    assert resultado is not None
```

Toda linha do módulo roda. A cobertura relata cem por cento. E `is not None` é verdade sobre quase
todo valor que existe, então o teste passa seja lá o que a aritmética fez — que é o módulo em que a
demonstração desta aula acha um imposto dobrado.

**Afirme a resposta, não o fato de ter havido uma.**

## Comportamento, não implementação

```python
def test_notificar(mocker):
    ...
    assert mailer.send.called          # que um auxiliar foi chamado
```

```python
def test_notificar():
    ...
    assert enviados == [("a@b.c", "Welcome")]   # o que o sistema fez
```

O primeiro fica vermelho quando você renomeia o auxiliar e verde quando a mensagem está errada.
**Um teste acoplado à implementação encarece a refatoração e não acha nada**, que é o pior das duas
metades.

## O que um bom teste afirma

O valor que volta. O estado que mudou. A exceção levantada para uma entrada ruim. A borda — uma
lista vazia, um zero, um elemento só, o último dia do mês. Essas são as entradas em que o código
foi escrito a partir de um retrato do caso comum.
