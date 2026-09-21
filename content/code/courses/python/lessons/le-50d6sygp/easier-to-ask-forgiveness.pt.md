---
title: Tente, em vez de conferir antes
version: 1
---

Dois jeitos de escrever a mesma coisa:

```python
# olhe antes de pular
if os.path.exists(caminho):
    texto = open(caminho).read()

# é mais fácil pedir perdão que permissão
try:
    texto = open(caminho).read()
except FileNotFoundError:
    texto = ""
```

O segundo é o pythônico, e a razão não é gosto.

## A conferência tem uma corrida dentro

Entre o `exists(caminho)` e o `open(caminho)` o arquivo pode ser apagado, renomeado ou trocado. A
conferência respondeu com verdade sobre um momento que já passou, e o `open` falha do mesmo jeito —
então você precisava do `except` de qualquer forma, e a conferência não comprou nada além de uma
segunda pergunta.

**Qualquer coisa fora do seu programa — um arquivo, uma rede, outro processo — pode mudar entre a
conferência e o uso.** O try é a única coisa que testa o estado no instante em que você o usa.

## Ele também costuma ser mais rápido

A conferência custa uma consulta em toda chamada, e a exceção custa só quando acontece. Para o caso
comum em que quase sempre dá certo, o try vence — e onde quase sempre falha, a diferença raramente
importa.

## Onde conferir É melhor

```python
if not linhas:          # perguntando sobre o seu próprio dado
    return 0
```

Quando a coisa sobre a qual você pergunta é sua, está em memória, e não muda embaixo de você, um
`if` é mais claro. Ninguém escreve `try: linhas[0] except IndexError` para descobrir se uma lista
está vazia.

A linha é: **pergunte sobre os seus próprios valores; tente os que pertencem ao mundo.**

## O caso a observar

```python
try:
    valor = config["porta"]
except KeyError:
    valor = 5432
```

Correto, e `config.get("porta", 5432)` diz isso numa linha. Quando a biblioteca padrão já tem a
versão tolerante — `.get`, `.pop` com padrão, `next(it, None)` — é essa que se usa. Tratar a exceção
é para quando não existe um método desses.
