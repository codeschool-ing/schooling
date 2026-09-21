---
title: Uma reescreve o arquivo; a outra relata o que achou
version: 1
---

```sh
black app/          # muda bytes, quase não fala
ruff check app/     # fala muito, não muda nada
```

**Um formatador decide como o código é disposto.** Onde a linha quebra, qual caractere de aspas,
como uma chamada longa é arrumada. Não há resposta certa para nada disso, e é por isso que entregar
a um programa não custa nada e resolve de vez.

**Um linter decide se o código contém algo suspeito.** Um import que ninguém usa, um `try` que
captura tudo, um argumento padrão que é uma lista. Esses têm resposta certa, então a ferramenta os
relata e deixa o conserto com você.

## Por que são duas ferramentas e não uma

```text
o black reescreveu 22 linhas do módulo da demonstração.
o ruff relatou os mesmos 4 achados antes e depois.
```

**Disposição não é evidência.** Um achado que mudasse quando o arquivo foi reformatado seria um
achado sobre a formatação, e nenhuma das duas ferramentas valeria a pena rodar. Mantê-las
separadas é o que faz a saída de cada uma querer dizer alguma coisa.

Também quer dizer que elas rodam em momentos diferentes. O formatador roda ao salvar e em todo
arquivo, sem nenhum pensamento envolvido. O linter roda e produz uma lista que alguém lê.

## A sobreposição, e como tratá-la

O `ruff` tem regras sobre espaço em branco e comprimento de linha — a família `E`, herdada do
`pycodestyle` — e um formatador já decide tudo isso. Rodar os dois quer dizer o linter reclamando
de linhas que o formatador escolheu.

```toml
[tool.ruff.lint]
ignore = ["E501"]         # comprimento de linha: trabalho do formatador
```

A convenção é deixar o formatador ganhar: desligue as regras que são sobre disposição e fique com
as que são sobre significado.

## E o `ruff format`

```sh
ruff format app/
```

O `ruff` também é um formatador, e ele mira produzir o que o `black` produz. No módulo da
demonstração desta aula as duas saídas são **byte por byte idênticas**, que é a promessa que ele
faz e uma que você pode conferir com `diff` no seu próprio código antes de trocar.
