---
title: Atualizando, e o que uma atualização para o 22 pediria
version: 1
---

**O `ng update` faz dois trabalhos: move os pacotes do Angular para uma versão nova, juntos, e roda as
migrações que essa versão traz para reescrever o seu código.** Chamado sem argumentos, ele só olha:

```
ana@dev:~/planner$ npx ng update
Using package manager: npm
Collecting installed dependencies...
Found 15 dependencies.
    We analyzed your package.json, there are some packages to update:
    
      Name                       Version                  Command to update
     ------------------------------------------------------------------------
      @angular/cli               21.2.28 -> 22.2.5        ng update @angular/cli
      @angular/core              21.2.25 -> 22.2.4        ng update @angular/core
    
    There might be additional packages which don't provide 'ng update' capabilities that are outdated.
    You can update the additional packages by running the update command of your package manager.
```

Ele achou o Angular 22 no registro e lista os dois comandos que levariam até ele. Dois pacotes, não
dez: `ng update @angular/core` leva junto todo pacote do framework, e `@angular/cli` traz o
`@angular/build`. As duas últimas linhas são honestas sobre o resto: Vitest, TypeScript e os outros
se atualizam com o npm, e o `npm outdated` os lista.

## O calendário

A aula 1 citou quando cada major foi lançado. O registro guarda a hora de publicação de cada versão
de cada pacote, e é daqui que vieram aquelas datas:

```
ana@dev:~/planner$ npm view @angular/core time --json | grep -E '"2[0-2]\.0\.0"'
  "20.0.0": "2025-05-28T13:53:18.215Z",
  "21.0.0": "2025-11-19T18:07:38.390Z",
  "22.0.0": "2026-06-03T13:04:10.790Z",
```

Maio ou junho, depois novembro, todo ano: o padrão é regular o bastante para um time pôr a
atualização no plano antes de a versão existir.

## A atualização que este curso não faz

Peça o 22, e a primeira resposta é sobre os seus arquivos, não sobre o Angular:

```
ana@dev:~/planner$ npx ng update @angular/core@22 @angular/cli@22 2>&1 | tail -5
Error: Repository is not clean. Please commit or stash any changes before updating.
```

O `ng update` se recusa a rodar num repositório com mudanças não commitadas, porque as migrações estão
para editar o seu código e o único jeito limpo de ver o que fizeram é um diff contra um commit. O
`git status` lista o que esta aula mudou desde o primeiro commit; faça o commit, e peça de novo:

```
ana@dev:~/planner$ git status --short
 M src/app/app.html
 M src/app/app.spec.ts
?? public/courses.json
?? src/app/week-summary/
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "The CLI: serve, generate, build, test"
ana@dev:~/planner$ npx ng update @angular/core@22 @angular/cli@22 2>&1 | tail -5
Node.js version v22.22.0 detected.
The Angular CLI requires a minimum Node.js version of v22.22.3 or v24.15.0 or v26.0.0.

Please update your Node.js version or visit https://nodejs.org/ for additional instructions.
```

Desta vez ele vai até instalar uma cópia temporária da CLI nova para rodar as migrações, e essa cópia
confere o Node em que está rodando.

Então o primeiro passo de uma ida para o 22 nem está neste projeto: é um Node mais novo, 22.22.3 ou
posterior, para todo curso da trilha `frontend` de uma vez, decidido onde o Node da trilha é
decidido. Nada foi mudado: a CLI temporária recusou antes de escrever qualquer coisa.

Quando o dia chegar, a atualização em si é um comando por pacote, rodado numa árvore limpa para que as
edições das migrações sejam a única coisa no próximo diff:

```sh
npx ng update @angular/core@22 @angular/cli@22
git diff
```

Leia o diff antes de commitar. Uma migração que reescreveu cinquenta arquivos fez exatamente o que
disse, e é você quem vai ter de explicar por que o código mudou.

## Ficando no 21

O Angular 21 tem suporte de longo prazo até maio de 2027. Dentro de um major, os patches continuam
vindo, correções de segurança entre eles, e nomear o major traz o mais novo dele:

```
ana@dev:~/planner$ npx ng update @angular/core@21 @angular/cli@21
The installed Angular CLI version is outdated.
Installing a temporary Angular CLI versioned 21 to perform the update.
Using package manager: npm
Collecting installed dependencies...
Found 15 dependencies.
Fetching dependency metadata from registry...
Package '@angular/core' is already up to date.
    Updating package.json with dependency @angular/build @ "21.2.29" (was "21.2.28")...
    Updating package.json with dependency @angular/cli @ "21.2.29" (was "21.2.28")...
UPDATE package.json (779 bytes)
❯ Cleaning node modules directory
✔ Cleaning node modules directory
❯ Installing packages
✔ Installing packages
```

No dia da gravação havia o que fazer. O framework, o `@angular/core`, ainda era o 21 mais novo, mas
a CLI e o sistema de build tinham passado de 21.2.28 para 21.2.29 desde que o projeto foi criado. O
comando escreveu os números novos no `package.json`, instalou de novo, e o lockfile acompanhou:

```
ana@dev:~/planner$ git diff --stat
 package-lock.json | 68 +++++++++++++++++++++++++++----------------------------
 package.json      |  4 ++--
 2 files changed, 36 insertions(+), 36 deletions(-)
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Angular 21, latest patch"
```

Leia o diff, e rode o `ng test` antes de commitar. O resto deste curso roda com a CLI e o sistema de
build em 21.2.29.
