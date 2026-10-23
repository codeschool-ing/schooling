---
title: npm ci, a instalação que faz deploy
version: 1
---

**O `npm install` lê o `package.json` e pode mudar o lockfile; o `npm ci` lê o lockfile e se recusa a
mudar qualquer coisa.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois comandos e três coisas no disco. O npm install lê o package.json, escreve o package-lock.json e preenche o node_modules. O npm ci lê só o package-lock.json, recusa se ele não bater com o package.json, apaga o node_modules e instala exatamente o que o lockfile lista.\"><rect x=\"30\" y=\"100\" width=\"170\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">package.json</text><text x=\"115\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as faixas que você pede</text><rect x=\"275\" y=\"100\" width=\"170\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">package-lock.json</text><text x=\"360\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as versões exatas instaladas</text><rect x=\"520\" y=\"100\" width=\"170\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">node_modules/</text><text x=\"605\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o código que roda</text><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">npm install</text><path d=\"M115 98 C 115 60, 360 60, 360 96\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><line x1=\"360\" y1=\"90\" x2=\"360\" y2=\"97\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"360.0,97.0 356.9,89.6 363.1,89.6\" fill=\"var(--amber)\"></polygon><path d=\"M115 98 C 115 40, 605 40, 605 96\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><line x1=\"605\" y1=\"90\" x2=\"605\" y2=\"97\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"605.0,97.0 601.9,89.6 608.1,89.6\" fill=\"var(--amber)\"></polygon><text x=\"238\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">escreve o que resolveu</text><text x=\"480\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">preenche</text><text x=\"30\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">npm ci</text><path d=\"M360 156 C 360 200, 605 200, 605 160\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"605\" y1=\"166\" x2=\"605\" y2=\"157\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"605.0,157.0 608.1,164.4 601.9,164.4\" fill=\"var(--phosphor)\"></polygon><text x=\"483\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">apaga, depois instala exatamente isto</text><path d=\"M115 156 C 115 196, 360 196, 360 160\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"238\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">só compara: recusa se forem diferentes</text></svg>", "caption": "No notebook, o npm install muda o lockfile. Onde um deploy é montado, o npm ci o lê e não muda nada."}
```

No seu notebook, o primeiro é como você acrescenta e atualiza. Num servidor de build, num contêiner,
em qualquer lugar onde um deploy é montado, o segundo é o que deve rodar, porque ele instala
exatamente o que foi testado e nada mais.

O `npm ci` apaga o `node_modules` primeiro, tenha o que tiver, e instala só a partir do lockfile:

```
ana@dev:~/server/links$ npm ci

added 66 packages, and audited 67 packages in 484ms

29 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

Os mesmos 66 pacotes, a árvore registrada no `package-lock.json`, em menos de um segundo.

## Quando os dois arquivos discordam

O lockfile precisa descrever o que o `package.json` pede. Mude uma faixa à mão sem instalar, e eles
deixam de bater:

```
ana@dev:~/server/links$ npm pkg set dependencies.express='^4.21.0'
ana@dev:~/server/links$ npm ci 2>&1 | head -6
npm error code EUSAGE
npm error
npm error `npm ci` can only install packages when your package.json and package-lock.json or npm-shrinkwrap.json are in sync. Please update your lock file with `npm install` before continuing.
npm error
npm error Invalid: lock file's express@5.3.0 does not satisfy express@4.22.3
npm error Invalid: lock file's accepts@2.0.0 does not satisfy accepts@1.3.8
ana@dev:~/server/links$ npm pkg set dependencies.express='^5.3.0'
```

**O `npm ci` recusou, e disse qual era a diferença.** Num servidor de build essa recusa é a ideia: um
lockfile que não bate com o `package.json` significa que alguém mudou um sem o outro, e instalar
mesmo assim faria deploy de versões que ninguém testou. A correção é no notebook, com `npm install`,
e um commit dos dois arquivos. Aqui, a mudança é desfeita pondo a faixa de volta.

## Uma instalação de produção

O `--omit=dev` deixa as ferramentas de desenvolvimento de fora, como a seção sobre os tipos de
dependência mostrou com o `npm ls`:

```
ana@dev:~/server/links$ npm ci --omit=dev

added 65 packages, and audited 66 packages in 502ms

28 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/server/links$ npm run format

> links@0.1.0 format
> prettier --write server.js src test

sh: 1: prettier: not found
```

Um pacote a menos, o Prettier, e o `npm run format` agora falharia por falta dele, o que em produção
é o resultado certo. Este é o comando com que os gerenciadores de processos da aula 10 e as imagens
do curso `docker` são montados.
