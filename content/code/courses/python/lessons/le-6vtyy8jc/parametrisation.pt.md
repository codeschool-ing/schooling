---
title: Uma função e uma tabela de linhas
version: 1
---

```python
@pytest.mark.parametrize("titulo,esperado", [
    ("Hello World", "hello-world"),
    ("ALL CAPS", "all-caps"),
    ("already-done", "already-done"),
    ("Trailing ", "trailing-"),
])
def test_slugify(titulo, esperado):
    assert slugify(titulo) == esperado
```

```sh
test_slug.py::test_slugify[Hello World-hello-world] PASSED               [ 25%]
test_slug.py::test_slugify[ALL CAPS-all-caps] PASSED                     [ 50%]
test_slug.py::test_slugify[already-done-already-done] PASSED             [ 75%]
test_slug.py::test_slugify[Trailing -trailing-] PASSED                   [100%]
```

**Quatro testes, não um.** Cada linha roda por conta própria, ganha um nome próprio montado a
partir dos argumentos, e falha por conta própria — então um relatório nomeia a linha que quebrou em
vez da função que a contém.

## Que é o ponto, e o laço não é

```python
def test_slugify():
    for titulo, esperado in CASOS:      # um teste
        assert slugify(titulo) == esperado
```

Um laço para na primeira linha ruim e não conta nada sobre o resto. O decorador é a mesma tabela
com cada linha relatada à parte, e essa diferença é a razão inteira de escrever assim.

## Rodar uma linha

```sh
pytest "test_slug.py::test_slugify[ALL CAPS-all-caps]"
```

O id entre colchetes é um endereço de verdade. Ponha aspas — colchetes e espaços pertencem ao seu
shell caso contrário.

## Nomear as linhas

```python
@pytest.mark.parametrize("valor,esperado", [
    pytest.param("", "", id="vazio"),
    pytest.param("  ", "", id="so-espacos"),
])
```

Quando os argumentos são longos ou não imprimíveis o id gerado fica ilegível, e `id=` o substitui.
Uma linha que merece um nome em geral merece um comentário também.

## Empilhar

```python
@pytest.mark.parametrize("codigo", ["BRL", "USD"])
@pytest.mark.parametrize("valor", [0, 1, 1000])
def test_conversao(codigo, valor):
    ...
```

Dois decoradores produzem toda combinação — seis testes aqui. **Isso multiplica**, então três
deles é uma suíte que ninguém quis escrever.

## E o que não pertence à tabela

Uma linha que precisa da própria montagem, uma linha cuja asserção é outra frase, uma linha que na
verdade está testando outra coisa. Quando o corpo ganha um `if` sobre qual linha é, a tabela
deixou de ser uma tabela.
