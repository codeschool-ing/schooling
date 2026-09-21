---
title: Seis classes, e o que cada uma está dizendo
version: 1
---

## `ValueError`

O tipo está certo e o valor não. `int("abc")`, `date(2026, 13, 1)`, uma porcentagem de 150.

**Ele quase sempre quer dizer que o dado veio de fora** — de um arquivo, de um formulário, de um
argumento — então o tratamento em geral nomeia qual campo e qual valor em vez de consertar alguma
coisa.

## `TypeError`

O tipo está errado. `len(5)`, `"a" + 1`, chamar algo que não é chamável, uma função que recebeu três
argumentos quando aceita dois.

**Este em geral é um defeito SEU e não do dado.** Capturá-lo raramente é a resposta; o traceback é.

## `KeyError` e `IndexError`

Uma chave que não está no dicionário, uma posição que não está na sequência. Os dois são
`LookupError` por baixo, então uma cláusula pega os dois.

O `KeyError` põe a chave na mensagem e mais nada, o que confunde na primeira vez: `KeyError: 'porta'`
é a história inteira. E lembre do `.get(chave, padrao)`, que é a versão tolerante da mesma pergunta.

## `FileNotFoundError`, e a família dele

`OSError` é o sistema de arquivos e o sistema operacional, e os filhos úteis são
`FileNotFoundError`, `PermissionError` e `IsADirectoryError`. `except OSError` captura todos eles,
que é o certo quando a sua resposta é a mesma para cada um.

**A mensagem carrega o caminho**, então um tratamento raramente precisa acrescentá-lo — confira
antes de escrever `f"não consegui abrir {caminho}"` em volta de algo que já disse isso.

## `AttributeError`

O objeto não tem tal atributo. `None.strip()` o levanta, e essa é de longe a causa mais comum:
alguma coisa devolveu `None` e você a usou como se não tivesse devolvido.

**`AttributeError: 'NoneType' object has no attribute …` quer dizer "o valor era `None`"**, e a
pergunta é que linha produziu o `None`, e não o que fazer com esta.

## `ZeroDivisionError`, e uma nota sobre o resto

Existem dezenas mais e você não as aprende de uma lista. Você as aprende lendo as que recebe: a
classe diz que tipo, a mensagem diz qual, e a última linha do traceback diz onde.

**Ler um traceback de BAIXO para cima é a habilidade.** A última linha é o erro; a linha acima dela
é onde aconteceu; tudo acima disso é como você chegou lá — e a primeira linha sua nessa lista é onde
olhar.
