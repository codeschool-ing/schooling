---
title: Uma reescreve o arquivo; a outra relata o que achou
version: 2
---

```sh
black app/          # changes bytes, says almost nothing
ruff check app/     # says a lot, changes nothing
```

**Um formatador decide como o código é disposto.** Onde a linha quebra, qual caractere de aspas,
como uma chamada longa é arrumada. Não há resposta certa para nada disso, e é por isso que entregar
a um programa não custa nada e resolve de vez.

**Um linter decide se o código contém algo suspeito.** Um import que ninguém usa, um `try` que
captura tudo, um argumento padrão que é uma lista. Esses têm resposta certa, então a ferramenta os
relata e deixa o conserto com você.

## Por que são duas ferramentas e não uma

```localised
o black reescreveu 22 linhas do módulo da demonstração.
o ruff relatou os mesmos 4 achados antes e depois.
```

**Disposição não é evidência.** Um achado que mudasse quando o arquivo foi reformatado seria um
achado sobre a formatação, e nenhuma das duas ferramentas valeria a pena rodar. Mantê-las
separadas é o que faz a saída de cada uma querer dizer alguma coisa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 252\" role=\"img\" aria-label=\"Um formatador decide coisas que não têm resposta certa e reescreve o arquivo. Um linter decide coisas que têm resposta certa e as relata sem tocar em nada. Mantê-los separados é o que faz a saída de cada um querer dizer alguma coisa.\"> <text x=\"192\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">black — muda bytes, quase não fala</text> <rect x=\"20\" y=\"36\" width=\"344\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"192\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">onde a linha quebra</text> <rect x=\"20\" y=\"78\" width=\"344\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"192\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">qual caractere de aspas</text> <rect x=\"20\" y=\"120\" width=\"344\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"192\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">como uma chamada longa é arrumada</text> <text x=\"192\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sem resposta certa: entregar a um programa resolve de vez</text> <text x=\"548\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">ruff check — fala muito, não muda nada</text> <rect x=\"376\" y=\"36\" width=\"344\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"548\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um import que ninguém usa</text> <rect x=\"376\" y=\"78\" width=\"344\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"548\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um try que pega tudo</text> <rect x=\"376\" y=\"120\" width=\"344\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"548\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um argumento padrão que é uma lista</text> <text x=\"548\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">estes têm resposta certa: ele relata e deixa o conserto com você</text> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">22 linhas do módulo de demonstração foram reescritas.</text> <text x=\"360\" y=\"229\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">O ruff relatou os mesmos quatro achados antes e depois.</text> </svg>", "caption": "Disposição não é evidência. Um achado que mudasse quando o arquivo fosse reformatado seria um achado sobre a formatação."}
```

Também quer dizer que elas rodam em momentos diferentes. O formatador roda ao salvar e em todo
arquivo, sem nenhum pensamento envolvido. O linter roda e produz uma lista que alguém lê.

## A sobreposição, e como tratá-la

O `ruff` tem regras sobre espaço em branco e comprimento de linha — a família `E`, herdada do
`pycodestyle` — e um formatador já decide tudo isso. Rodar os dois quer dizer o linter reclamando
de linhas que o formatador escolheu.

```toml
[tool.ruff.lint]
ignore = ["E501"]         # line length: the formatter's job
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
