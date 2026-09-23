---
title: Escrevendo um comentário que vale ler
version: 1
---

A Ana tem três coisas a dizer sobre o #31, e elas não são igualmente graves. A primeira coisa que um bom
comentário faz é **dizer de que tipo ele é**, para o Bruno saber o que tem de mudar antes do merge e o que
fica a critério dele:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Quatro tipos de comentário de revisão, do mais grave ao menos grave. Bloqueia: um horário vazio ainda é enviado, pôr required? É corrigido antes do merge. Pergunta: dá para escolher 03:00, quando estamos fechados? É respondida antes do merge. Nit: Place order diz mais que Order. Quem escreveu decide. Deixar passar: eu teria usado uma lista de horários. Nunca é escrito.\"><defs><marker id=\"ld-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">gravidade</text><text x=\"150\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o comentário</text><text x=\"520\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que acontece com ele</text><rect x=\"20\" y=\"42\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">bloqueia</text><rect x=\"150\" y=\"42\" width=\"350\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"162\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Um horário vazio ainda é enviado. Pôr required?</text><path d=\"M506 60 L516 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"520\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">corrigido antes do merge</text><rect x=\"20\" y=\"104\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">pergunta</text><rect x=\"150\" y=\"104\" width=\"350\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"162\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Dá para escolher 03:00, quando estamos fechados?</text><path d=\"M506 122 L516 122\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"520\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">respondida antes do merge</text><rect x=\"20\" y=\"166\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">nit</text><rect x=\"150\" y=\"166\" width=\"350\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"162\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nit: Place order diz mais que Order.</text><path d=\"M506 184 L516 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"520\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">quem escreveu decide</text><rect x=\"20\" y=\"228\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"75\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">deixar passar</text><rect x=\"150\" y=\"228\" width=\"350\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"162\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Eu teria usado uma lista de horários.</text><path d=\"M506 246 L516 246\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"520\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nunca escrito</text></svg>", "caption": "Dizer quão grave é um comentário deixa quem escreveu gastar a tarde na primeira linha, não na terceira.", "same": ["nit"]}
```

Muitas equipes usam exatamente essas palavras como prefixo, em inglês: `blocking:`, `question:`, `nit:`
(de *nitpick*, um detalhe miúdo). As palavras importam menos que o hábito: **quem lê nunca deveria ter de
adivinhar o quanto você se importa.**

## O que vai num comentário

Compare dois comentários na mesma linha:

> Isto está errado.

> **blocking:** com o campo vazio, o *Order* ainda envia, então podemos receber um pedido sem horário.
> Pôr `required` no input evitaria isso.

O segundo faz quatro coisas que o primeiro não faz:

- **Diz o que acontece**, não o que quem revisa sente sobre isso. O Bruno confere a afirmação em dez
  segundos.
- **Diz por que importa**: um pedido sem horário, que a padaria não consegue atender.
- **Sugere uma correção**, que o Bruno pode aceitar ou fazer de outro jeito.
- **É sobre o código.** *"Você esqueceu a validação"* é o mesmo fato apontado para uma pessoa; *"o input
  não tem validação"* é apontado para a linha.

## Perguntas são perguntas de verdade

*"Dá para escolher 03:00?"* é uma pergunta porque a Ana não sabe a resposta. Talvez o servidor recuse, e
aí a resposta é uma linha e nada muda. Perguntar não é uma ordem suavizada: se você tem certeza, diga, e
se não tem, pergunte de verdade. **Uma pergunta que é uma exigência disfarçada** (*"Por que você não usou
uma lista?"*) faz quem escreveu adivinhar qual das duas ela é, e essa é a parte desconfortável da revisão
para a maioria das pessoas.

## Diga o que está bom, com precisão

*"LGTM"* (*looks good to me*, "parece bom para mim") é uma aprovação perfeitamente boa. Mas quando algo
numa mudança está bem feito, quem revisa e diz isso com precisão ensina tanto quanto quem aponta uma
falha: *"Pôr o link na página inicial foi uma boa; eu não teria pensado nisso."* Isso também deixa o
comentário que bloqueia mais fácil de ler, porque mostra que quem revisou leu tudo.
