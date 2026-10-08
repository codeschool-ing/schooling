---
title: Git Flow: branches de develop, release e hotfix
version: 2
---

O Git Flow foi descrito em 2010 para um tipo específico de software: **produtos entregues como versões
numeradas**, em que a versão 1.1 é preparada, testada e lançada como uma unidade, e a versão 1.0
continua recebendo correções enquanto isso. Software de computador, apps de celular esperando a
revisão de uma loja, bibliotecas.

## As faixas

- **`main`** tem só versões lançadas. Todo commit nele é uma release, e recebe tag.
- **`develop`** é onde o trabalho terminado se junta para a próxima release.
- Branches **`feature/…`** começam no `develop` e voltam para ele.
- Branches **`release/…`** começam no `develop` quando uma versão está sendo preparada: só entram
  correções, depois ele entra no `main`, recebe a tag e volta para o `develop`.
- Branches **`hotfix/…`** começam no `main` para uma correção urgente numa versão lançada, e entram no
  `main` e no `develop`.

Aqui está um pequeno app de pedidos mantido assim: duas funcionalidades, uma release 1.1 e um hotfix
1.1.1. Um programa curto faz o histórico dele, e vale a pena lê-lo antes de rodar, porque cada bloco
nele é uma das faixas acima sendo usada:

```bash
#!/usr/bin/env bash
# make-app.sh: a small ordering app, kept the Git Flow way by Ana and Bruno.
# Every date and every name is written down, so the ids match the lesson's.
set -e
if [ -e ~/app ]; then
  echo "~/app already exists. Move it aside or delete it, then run this again." >&2
  exit 1
fi
mkdir ~/app && cd ~/app && git init -q -b main

when()  { export GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1"; }
ana()   { export GIT_AUTHOR_NAME='Ana Souza' GIT_COMMITTER_NAME='Ana Souza' \
                 GIT_AUTHOR_EMAIL=ana@example.com GIT_COMMITTER_EMAIL=ana@example.com; }
bruno() { export GIT_AUTHOR_NAME='Bruno Lima' GIT_COMMITTER_NAME='Bruno Lima' \
                 GIT_AUTHOR_EMAIL=bruno@example.com GIT_COMMITTER_EMAIL=bruno@example.com; }
commit() { git add -A && git commit -q -m "$1"; }
# finish BRANCH INTO: merge a finished branch, always with a merge commit
finish() { git switch -q "$2" && git merge -q --no-ff --no-edit "$1"; }

ana; when 2026-06-01T09:00:00-03:00
printf 'Padaria Sol ordering app\n' > README.md; commit 'Start the ordering app'
git tag -a v1.0 -m 'First release'
git switch -q -c develop

when 2026-06-03T10:00:00-03:00
git switch -q -c feature/basket develop
printf 'basket\n' > basket.txt; commit 'Add a basket'
when 2026-06-04T10:00:00-03:00
finish feature/basket develop; git branch -q -d feature/basket

bruno; when 2026-06-05T11:00:00-03:00
git switch -q -c feature/pickup develop
printf 'pickup\n' > pickup.txt; commit 'Let customers choose a pickup time'
when 2026-06-08T11:00:00-03:00
finish feature/pickup develop; git branch -q -d feature/pickup

ana; when 2026-06-09T09:00:00-03:00
git switch -q -c release/1.1 develop
sed -i 's/app/app, version 1.1/' README.md; commit 'Prepare release 1.1'
when 2026-06-10T09:00:00-03:00
finish release/1.1 main; git tag -a v1.1 -m 'Release 1.1'
finish release/1.1 develop; git branch -q -d release/1.1

bruno; when 2026-06-11T16:00:00-03:00
git switch -q -c hotfix/1.1.1 main
printf 'pickup, not before 06:00\n' > pickup.txt; commit 'Refuse pickup times before we open'
when 2026-06-11T17:00:00-03:00
finish hotfix/1.1.1 main; git tag -a v1.1.1 -m 'Release 1.1.1'
finish hotfix/1.1.1 develop; git branch -q -d hotfix/1.1.1
```

O `finish` é o movimento que o Git Flow repete: trocar para o branch em que o trabalho entra e fazer
o merge ali com `--no-ff`, para que o commit de merge mostre onde o trabalho se juntou. A release e o
hotfix são finalizados duas vezes cada. Salve o programa como `~/make-app.sh`, do jeito que você
salvou o da aula 3, e rode:

```bash
cd ~ && bash ~/make-app.sh && cd ~/app
```

Depois pergunte o que ele fez:

```
ana@vm:~/app$ git branch
* develop
  main
ana@vm:~/app$ git log --oneline --graph --all
*   59d24ca Merge branch 'hotfix/1.1.1' into develop
|\  
* \   28f0220 Merge branch 'release/1.1' into develop
|\ \  
| | | *   aea0ad6 Merge branch 'hotfix/1.1.1'
| | | |\  
| | | |/  
| | |/|   
| | * | e0d054e Refuse pickup times before we open
| | |/  
| | *   c912762 Merge branch 'release/1.1'
| | |\  
| | |/  
| |/|   
| * | f641244 Prepare release 1.1
|/ /  
* |   e601e60 Merge branch 'feature/pickup' into develop
|\ \  
| * | 8d10f6a Let customers choose a pickup time
|/ /  
* |   086b150 Merge branch 'feature/basket' into develop
|\ \  
| |/  
|/|   
| * e6d8bcd Add a basket
|/  
* 3e9c870 Start the ordering app
ana@vm:~/app$ git tag
v1.0
v1.1
v1.1.1
```

São seis branches de trabalho, três releases, e **seis commits de merge para duas funcionalidades,
uma release e uma correção**. Tudo é rastreável: cada tag marca exatamente o que foi entregue, e o `main` nunca tem
nada que não foi lançado. O custo é igualmente visível: toda release e todo hotfix entram duas vezes,
o gráfico dá trabalho para ler, e quem desenvolve tem de lembrar de qual branch cada tipo de mudança
parte.

## Quando serve, e quando não

Serve quando **existem versões de verdade**: quando clientes rodam a 1.1 enquanto a 1.2 é preparada, e
uma correção na 1.1 não pode esperar as funcionalidades da 1.2. É pesado para um site ou uma aplicação
web publicada muitas vezes por dia, em que não existe *versão 1.1* em sentido nenhum — só o que está
rodando agora. A maioria das equipes web que adotaram o Git Flow nos anos 2010 já passou para uma das
duas formas mais simples, e o artigo que o descreveu ganhou uma nota em 2020 dizendo exatamente isso.

A lição que vale guardar não são as faixas. É a pergunta que elas respondem: **como o seu software
chega a quem o usa?** Um fluxo que combina com a resposta parece leve; um que não combina parece
cerimônia.
