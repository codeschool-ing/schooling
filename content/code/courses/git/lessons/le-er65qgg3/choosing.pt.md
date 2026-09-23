---
title: Escolhendo, e escrevendo
version: 1
---

| | feature branches | trunk based | Git Flow |
|---|---|---|---|
| um branch vive | alguns dias | algumas horas | features por dias, releases por uma semana |
| o trabalho chega ao `main` | quando revisado | pelo menos todo dia | só quando lançado |
| trabalho inacabado | fica no branch dele | entra, atrás de uma flag | fica no branch dele |
| serve para | a maioria das equipes e produtos | publicações frequentes, checks fortes | versões numeradas entregues a clientes |
| o risco | branches que vivem demais | um `main` quebrado se os checks forem fracos | cerimônia, e merges feitos duas vezes |

## A pergunta que decide

**Com que frequência o que está no `main` chega a quem o usa?**

- Muitas vezes por dia, automaticamente: trunk based é o encaixe natural, e feature branches bem curtos
  são o jeito suave de chegar lá.
- Quando alguém decide, algumas vezes por semana: feature branches.
- Como versões numeradas, com as antigas ainda sendo mantidas: Git Flow, ou uma versão mais leve dele,
  só com branches de release.

Uma equipe nova sem motivo forte deve começar com feature branches curtos. É a forma em volta da qual
todo serviço de hospedagem é construído, ensina revisão desde o primeiro dia, e passar dela para trunk
based é questão de encurtar os branches.

## Escreva

O fluxo é um acordo, e um acordo que não está escrito são vários acordos, um por pessoa. Um arquivo
curto no repositório, em geral `CONTRIBUTING.md`, que responda a cinco perguntas evita mais discussão
que qualquer ferramenta:

1. De onde um branch parte, e como ele se chama?
2. Quanto tempo um branch deve viver?
3. O que tem de acontecer antes do merge de um pull request: aprovações, checks?
4. Qual botão de merge: merge commit, squash ou rebase?
5. Como uma release é feita, e quem a faz?

Essas perguntas já apareceram neste curso: o merge ou rebase da aula 6, os botões e os branches
protegidos da aula 8, as tags da aula 7. Um fluxo é essas respostas, escolhidas uma vez, juntos.
