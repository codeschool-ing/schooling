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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Uma função parametrizada vira quatro testes independentes. Cada um ganha o próprio nome montado a partir dos seus argumentos e o próprio veredito, então uma falha nomeia a linha que quebrou em vez da função que a contém.\"> <text x=\"160\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">como um laço dentro de um teste só</text> <rect x=\"20\" y=\"36\" width=\"280\" height=\"132\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"160\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">test_slugify</text> <text x=\"160\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">PASSED</text> <text x=\"500\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">parametrizado</text> <rect x=\"340\" y=\"36\" width=\"244\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"462\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">test_slugify[Hello World-hello-world]</text> <text x=\"596\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">PASSED</text> <rect x=\"340\" y=\"78\" width=\"244\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"462\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">test_slugify[ALL CAPS-all-caps]</text> <text x=\"596\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">PASSED</text> <rect x=\"340\" y=\"120\" width=\"244\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"462\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">test_slugify[already-done-already-done]</text> <text x=\"596\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">PASSED</text> <rect x=\"340\" y=\"162\" width=\"244\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"462\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">test_slugify[Trailing -trailing-]</text> <text x=\"596\" y=\"178\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">PASSED</text> <text x=\"360\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Os dois estão verdes hoje. No dia em que uma linha quebrar, um deles nomeia a entrada que quebrou</text> <text x=\"360\" y=\"241\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e o outro nomeia a função que a contém — e para antes de tentar as demais.</text> </svg>", "caption": "Quatro testes, não um. Um laço dentro de um único teste para na primeira falha e relata a função; isto relata a linha."}
```

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
