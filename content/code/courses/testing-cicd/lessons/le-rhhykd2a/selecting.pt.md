---
title: Rodando parte da suíte
version: 1
---

Uma suíte cresce, e logo você quer rodar parte dela: os unitários a cada salvamento, as camadas
lentas antes de um push, um teste só enquanto você o conserta. O pytest dá dois seletores, e vale
conhecer os dois porque um pipeline também os usa.

**Marcadores** selecionam por rótulo. Um marcador é declarado uma vez em `pyproject.toml`, com uma
frase dizendo o que significa:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--strict-markers"
markers = [
    "integration: talks to a real SQLite file",
    "functional: starts the HTTP server",
    "acceptance: a promise the shop makes, checked from outside",
]
```

e preso a um teste ou, com `pytestmark`, a um arquivo inteiro. O `-m` recebe então uma expressão
sobre nomes de marcadores, com `and`, `or` e `not`.

**Palavras-chave** selecionam pelo nome: `-k free` roda todo teste cujo nome contém `free`. Isso faz
dos nomes dos testes parte da interface, mais um motivo para nomeá-los pela regra.

```
ana@laptop:~/shipquote$ python -m pytest --collect-only -q -m "not functional and not acceptance" | tail -1
27/31 tests collected (4 deselected) in 0.14s
ana@laptop:~/shipquote$ python -m pytest -q -k free
.....                                                                    [100%]
5 passed, 26 deselected in 0.69s
ana@laptop:~/shipquote$ python -m pytest -q -m smoke; echo "exit status $?"

31 deselected in 0.14s
exit status 5
```

O primeiro comando pergunta quantos testes uma execução escolheria, sem rodá-los: 27 de 31, quatro
desmarcados. O segundo roda os cinco testes com `free` no nome, e eles vêm de três arquivos.

## O seletor que não seleciona nada

O terceiro comando é o que vale guardar. `smoke` não é um marcador que este projeto declara. O
pytest não rodou nada, imprimiu `31 deselected` e **não reclamou do nome**. A opção
`--strict-markers` da configuração recusa um marcador não declarado *num teste*, e não faz nada
contra um erro de digitação no `-m`.

O que salva é o código de saída. O pytest sai com **5** quando nenhum teste foi coletado, diferente
de 0 para "tudo passou" e de 1 para "algum falhou". Um passo de pipeline que roda `pytest -m smoke`
falha com um 5, desde que ninguém embrulhe o comando em algo que jogue o código fora. A aula 5
mostra como isso acontece com frequência num pipeline, com `|| true` e com pipes.

**Uma execução verde que não rodou nada é o resultado mais perigoso que uma suíte pode dar**,
porque parece exatamente sucesso. Quando uma execução selecionada importa, confira a contagem além
da cor: um pipeline que rodava 31 testes e agora roda 0 quebrou, diga o código de saída o que
disser.

## Primeiro o rápido, depois o resto

O arranjo usual, local e no pipeline, são duas passadas:

1. a camada rápida, `-m "not integration and not functional and not acceptance"`, a cada mudança,
   porque responde em bem menos de um segundo;
2. tudo, antes de a mudança ser compartilhada.

A ordem importa para o retorno, não para o resultado: um erro numa regra de preço aparece na
primeira passada, antes de as camadas lentas começarem. A aula 5 monta exatamente isso no pipeline
do curso.
