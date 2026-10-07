---
title: O que dispara uma execução
version: 2
---

Um **gatilho** (*trigger*) é o evento que faz a CI começar uma execução. O hook do laboratório tem
exatamente um: um push na `main`. Um push em qualquer outro branch é recebido e ignorado:

```
ana@laptop:~/shipquote$ git switch -q -c try-new-rounding && git push -u origin try-new-rounding 2>&1 | grep -E "^remote: ci|->"
remote: ci: try-new-rounding is not main, nothing to run        
 * [new branch]      try-new-rounding -> try-new-rounding
```

O branch chegou ao remoto, e o hook disse que não tinha nada para rodar. `git switch main` traz
você de volta, e o resto da aula conta com isso. Se isso está certo depende
da equipe: algumas querem cada branch conferido, para um problema aparecer antes de alguém abrir um
pull request; outras guardam os runners para os branches que estão para entrar.

## Os eventos que vale conhecer

Serviços de CI hospedados oferecem o mesmo pequeno conjunto de gatilhos, com nomes diferentes:

| evento | roda quando | uso típico |
|---|---|---|
| push | commits chegam a um branch | conferir a `main` depois de cada merge |
| pull request | um pull request é aberto ou atualizado | conferir uma mudança **antes** do merge |
| tag | uma tag é enviada | montar e publicar um release |
| agendamento | um relógio manda, escrito como cron | testes de contrato toda noite (aula 2), suítes lentas |
| manual | alguém aperta um botão ou chama uma API | um deploy, uma reconstrução avulsa |
| outro workflow | um pipeline chama este | reaproveitar um conjunto de verificações em vários lugares |

## Os gatilhos deste repositório

O repositório onde este curso é publicado roda as verificações em dois eventos, e pode ser chamado
por um terceiro:

```yaml
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

  # The release calls this workflow rather than repeating its steps. A release
  # that ran "the same checks" written out a second time would be one edit away
  # from running different ones, and the edit nobody makes to both is exactly
  # the failure this repository keeps meeting.
  workflow_call:
```

`pull_request` para a `main` confere cada mudança proposta antes do merge; `push` na `main` confere o
resultado depois do merge, porque duas mudanças que passaram cada uma ainda podem conflitar quando
juntas. `workflow_call` deixa outro workflow rodar este, e o release faz exatamente isso:

```yaml
on:
  push:
    tags: ['v*']
```

Uma tag que começa com `v` dispara o release, e o primeiro ato do release é chamar as mesmas
verificações da `main`. A aula 6 lê os dois arquivos inteiros; a aula 7 explica por que um release é
uma tag.

## Estreitando um gatilho

Rodar tudo a cada mudança fica caro, então os serviços deixam um gatilho nomear os caminhos que
importam: uma mudança só em `docs/` não precisa dos testes Go. É útil e tem uma armadilha que o
próprio workflow deste repositório documenta. **Um workflow filtrado por caminhos que não roda não
relata nada**, e uma verificação obrigatória que nunca relata bloqueia um merge para sempre. Por isso
este repositório decide dentro do workflow, num primeiro job que compara os arquivos mudados e deixa
os outros se pularem, o que aparece como *skipped*, um estado que uma verificação obrigatória
aceita. Ele também falha para o lado aberto: quando não consegue dizer o que mudou, roda tudo,
porque um detector que erra deveria gastar um runner, e não pular uma suíte.
