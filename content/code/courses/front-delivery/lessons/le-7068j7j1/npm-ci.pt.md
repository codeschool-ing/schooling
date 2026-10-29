---
title: npm ci, e o lockfile em que ele confia
version: 1
---

**`npm ci` instala exatamente o que o `package-lock.json` registra, e se recusa a rodar se o lockfile e o
`package.json` discordarem.** O `npm install` faz outra coisa: lê o `package.json`, resolve os intervalos
para a versão mais nova que caiba e grava o lockfile para combinar. É o que você quer ao acrescentar uma
dependência no seu computador. É a coisa errada numa máquina cujo trabalho é conferir o que você
commitou, porque ela pode instalar em silêncio algo que você nunca teve.

| | `npm install` | `npm ci` |
|---|---|---|
| lê | o `package.json`, e o lockfile como dica | o lockfile, e o `package.json` só para conferir que concordam |
| grava o lockfile | sim, quando algo muda | nunca |
| `node_modules` | atualiza o que está lá | apaga e começa de novo |
| uma discordância | resolvida em silêncio | um erro, e nada é instalado |

## Vendo ele recusar

Mude uma versão no `package.json` à mão sem avisar o npm, que é como um lockfile fica desatualizado na
vida real (um merge, uma edição com pressa), e peça ao `npm ci` para instalar:

```
ana@dev:~/planner$ sed -i 's/"typescript": "6.0.3"/"typescript": "6.0.2"/' package.json
ana@dev:~/planner$ npm ci
npm error code EUSAGE
npm error
npm error `npm ci` can only install packages when your package.json and package-lock.json or npm-shrinkwrap.json are in sync. Please update your lock file with `npm install` before continuing.
npm error
npm error Invalid: lock file's typescript@6.0.3 does not satisfy typescript@6.0.2
npm error
npm error Clean install a project
npm error
npm error Usage:
npm error npm ci
npm error
npm error Options:
npm error [--install-strategy <hoisted|nested|shallow|linked>] [--legacy-bundling]
npm error [--global-style] [--omit <dev|optional|peer> [--omit <dev|optional|peer> ...]]
npm error [--include <prod|dev|optional|peer> [--include <prod|dev|optional|peer> ...]]
npm error [--strict-peer-deps] [--foreground-scripts] [--ignore-scripts] [--no-audit]
npm error [--no-bin-links] [--no-fund] [--dry-run]
npm error [-w|--workspace <workspace-name> [-w|--workspace <workspace-name> ...]]
npm error [-ws|--workspaces] [--include-workspace-root] [--install-links]
npm error
npm error aliases: clean-install, ic, install-clean, isntall-clean
npm error
npm error Run "npm help ci" for more info
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-23T22_52_02_174Z-debug-0.log
```

**O `npm ci` parou antes de instalar qualquer coisa**, e citou os dois lados da discordância: a versão que
o `package.json` pede e a que o lockfile tem. No CI isso é um build vermelho com o motivo no log, que é
exatamente onde você quer descobrir. Ponha o `package.json` de volta:

```
ana@dev:~/planner$ git checkout package.json
Updated 1 path from the index
ana@dev:~/planner$ npm ci

added 18 packages, and audited 19 packages in 1s

9 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

O `npm ci` apagou o `node_modules` e instalou todo pacote de novo a partir do lockfile, nas versões que
ele registra, sem perguntar ao registry quais versões são as mais novas.

## A regra do lockfile

Como o CI confia nele, **o lockfile vai para o commit, e só muda pelo npm**: `npm install <pacote>` para
acrescentar ou atualizar, `npm uninstall` para remover, e o resultado commitado no mesmo commit do
`package.json`. Um pull request que muda um sem o outro falha no `npm ci`, que é o CI fazendo o trabalho
dele. Nunca edite o `package-lock.json` à mão, e nunca o apague para um erro sumir: um lockfile apagado é
gerado de novo com as versões que forem as mais novas naquele dia, o que é o oposto de fixar.
