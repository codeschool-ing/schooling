---
title: O que é um branch: um nome para um commit
version: 1
---

**A imagem de sempre de um branch é uma cópia do projeto**, uma pasta paralela em que você trabalha
sem atrapalhar o original. Essa imagem prevê que criar um branch demora, ocupa espaço e duplica os
arquivos. Nada disso acontece:

```
ana@vm:~/site$ git branch
* main
ana@vm:~/site$ cat .git/HEAD
ref: refs/heads/main
ana@vm:~/site$ cat .git/refs/heads/main
6555c9b314e48ad30e5c97a2ec1c8657347caa91
ana@vm:~/site$ git branch opening-hours
ana@vm:~/site$ git branch
* main
  opening-hours
ana@vm:~/site$ cat .git/refs/heads/opening-hours
6555c9b314e48ad30e5c97a2ec1c8657347caa91
```

O `git branch` lista os branches e marca com asterisco aquele em que você está. Há um, `main`, e o
arquivo por trás dele tem quarenta caracteres: **o id do commit para o qual o branch aponta**,
`6555c9b`, o commit mais novo da semana da aula 3. O `git branch opening-hours` criou um segundo
branch, e o arquivo dele tem os mesmos quarenta caracteres. É só isso. Um branch é um nome para um
commit, guardado num arquivo de 41 bytes.

## O HEAD é como o Git sabe onde você está

O outro arquivo, `.git/HEAD`, não tem um id de commit. Ele diz `ref: refs/heads/main`: **você está no
`main`**. É isso que o `HEAD` quis dizer em todos os comandos até aqui. Ele nomeia o branch em que
você está, e, através do branch, um commit.

Essa indireção é o que faz um branch andar. **Quando você faz um commit, o Git cria o commit novo e
leva até ele o branch que o `HEAD` nomeia.** Todos os outros branches ficam exatamente onde estavam.
Dois branches criados a partir do mesmo commit parecem idênticos até o primeiro commit em qualquer um
deles, e aí simplesmente apontam para lugares diferentes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Três commits em linha. O branch main aponta para o do meio, 6555c9b. O branch opening-hours aponta para o mais novo, 9677eef, que foi feito nele. O HEAD aponta para opening-hours, e é assim que o Git sabe qual branch o próximo commit move.\"><defs><marker id=\"bp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M289 130 L153 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bp-ah)\"></path><path d=\"M449 130 L313 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bp-ah)\"></path><circle cx=\"140\" cy=\"130\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"140\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">eadf998</text><circle cx=\"300\" cy=\"130\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"300\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6555c9b</text><circle cx=\"460\" cy=\"130\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"460\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9677eef</text><rect x=\"277.0\" y=\"80\" width=\"46\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><path d=\"M300 100 L300 118\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"401.0\" y=\"80\" width=\"118\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">opening-hours</text><path d=\"M460 100 L460 118\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"425\" y=\"22\" width=\"70\" height=\"20\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">HEAD</text><path d=\"M460 42 L460 78\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bp-ah)\"></path><text x=\"505\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o HEAD nomeia o branch em que você está</text><text x=\"40\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um branch é um nome</text><text x=\"40\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">para um commit</text></svg>", "caption": "Nada é copiado quando um branch é criado. Um branch é um ponteiro, e um commit move o ponteiro que o HEAD nomeia."}
```

## Por que isso importa para o seu jeito de trabalhar

Como um branch não custa nada, ele é usado para tudo. O hábito na maioria das equipes é **um branch
por trabalho**: o horário de domingo num, os preços novos noutro, um teste de cores num terceiro.
Cada um pode receber commits, ficar pela metade e ser retomado, sem que os outros dois percebam. O
`main` guarda só o que está pronto, e o trabalho entra nele por merge, que é a terceira seção desta
aula.

Os nomes são texto livre. `opening-hours` e `menu-prices` dizem qual é o trabalho; a aula 12 mostra a
convenção de pôr também o número do ticket no nome, para que dê para rastrear um branch até o motivo
de ele existir.
