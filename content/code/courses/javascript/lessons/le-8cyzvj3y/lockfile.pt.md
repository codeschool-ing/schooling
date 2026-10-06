---
title: O lockfile
version: 1
---

**Uma faixa diz o que você aceita. O lockfile diz o que foi escolhido.** Duas pessoas rodando
`npm install` com uma semana de diferença, contra o mesmo `^1.1.0`, podem receber versões
diferentes, porque uma nova pode ter sido publicada no meio. O lockfile é o que faz as duas
receberem a mesma.

Um segundo projeto, com o mesmo `.npmrc`, instala `shelf-format`, um pacote que por sua vez depende
de `shelf-slug`:

```
ana@dev:~/js/lock$ npm install shelf-format

added 2 packages in 624ms
ana@dev:~/js/lock$ npm ls --all
lock@1.0.0 /home/ana/js/lock
└─┬ shelf-format@1.0.0
  └── shelf-slug@1.2.0

```

Dois pacotes foram adicionados para um pedido. O `npm ls --all` mostra por quê: `shelf-slug` é
dependência de uma dependência, uma dependência **transitiva**. A maior parte do que está num
`node_modules` de verdade chegou assim. Um projeto com dez dependências diretas costuma ter algumas
centenas de pacotes instalados.

## package-lock.json

O npm escreveu `package-lock.json` ao lado do `package.json`:

```
ana@dev:~/js/lock$ cat package-lock.json
{
  "name": "lock",
  "version": "1.0.0",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": {
      "name": "lock",
      "version": "1.0.0",
      "dependencies": {
        "shelf-format": "^1.0.0"
      }
    },
    "node_modules/shelf-format": {
      "version": "1.0.0",
      "resolved": "http://127.0.0.1:4873/shelf-format/-/shelf-format-1.0.0.tgz",
      "integrity": "sha512-0Vcw5LvPhGg6uGZF6jMysJ3ZpK/Q9PJ3Ih7gpf7kUaLjtTDJkHnHVxqvg9urwC6CI+pRO7/X2KRo3JOAA+YSuA==",
      "license": "MIT",
      "dependencies": {
        "shelf-slug": "^1.1.0"
      }
    },
    "node_modules/shelf-slug": {
      "version": "1.2.0",
      "resolved": "http://127.0.0.1:4873/shelf-slug/-/shelf-slug-1.2.0.tgz",
      "integrity": "sha512-iios4bq90H+XUxwYltuRkxPOddIfhlfPiUifTJRj7/DrD9E4CEk3cc5KqI6G9RejgMyl/r8RPxtObpyoB2dflg==",
      "license": "MIT"
    }
  }
}
```

Todo pacote instalado tem uma entrada com três coisas: a **versão** exata, o endereço de onde foi
**resolvido** e um hash de **integridade** do arquivo baixado. O hash é o que faz do lockfile mais
que uma lista. A próxima instalação confere o arquivo que baixa contra ele, e um arquivo que mudou
desde então, mesmo com o mesmo nome e a mesma versão, é recusado.

**Faça commit do lockfile.** É dele que o servidor de build e a próxima pessoa a clonar o projeto
vão instalar.

## npm ci

O `npm install` lê o `package.json`, pode escolher versões novas dentro das faixas e atualiza o
lockfile. O **`npm ci`** não faz nenhuma das duas coisas. Ele apaga o `node_modules`, instala
exatamente o que o lockfile nomeia e não muda arquivo nenhum:

```
ana@dev:~/js/lock$ rm -rf node_modules
ana@dev:~/js/lock$ npm ci

added 2 packages in 307ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"O package.json guarda uma faixa, ^1.1.0, que é o que o projeto aceita. O npm install resolve isso para uma versão e escreve essa versão, seu endereço e seu hash de integridade no package-lock.json, depois enche o node_modules. O npm ci lê só o lockfile, instala exatamente o que ele nomeia e recusa quando o lockfile e o package.json discordam.\"><defs><marker id=\"lock-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"lock-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"180\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">package.json</text><text x=\"110.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&quot;shelf-slug&quot;: &quot;^1.1.0&quot;</text><rect x=\"270\" y=\"40\" width=\"200\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">package-lock.json</text><text x=\"370.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shelf-slug 1.2.0 + sha512</text><rect x=\"540\" y=\"40\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">node_modules/</text><text x=\"620.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shelf-slug 1.2.0</text><path d=\"M200 72 L266 72\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#lock-ah-phosphor)\"></path><path d=\"M470 72 L536 72\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#lock-ah-amber)\"></path><text x=\"233\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">install</text><text x=\"503\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ci</text><text x=\"110\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o que você aceita</text><text x=\"370\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o que foi escolhido</text><text x=\"620\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o que está lá</text><rect x=\"170\" y=\"154\" width=\"380\" height=\"44\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o npm ci recusa se esses dois discordam,</text><text x=\"360\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">em vez de escolher de novo</text></svg>", "caption": "A faixa diz o que você aceita; o lockfile diz o que foi escolhido."}
```

Isso faz do `npm ci` o comando para tudo que é automatizado: um servidor de build, um deploy, uma
rodada de testes. Se os dois arquivos discordam, ele para em vez de adivinhar. Aqui a ana edita a
faixa à mão e deixa o lockfile para trás:

```
ana@dev:~/js/lock$ npm pkg set dependencies.shelf-slug=^2.0.0
ana@dev:~/js/lock$ npm ci 2>&1 | head -n 6
npm error code EUSAGE
npm error
npm error `npm ci` can only install packages when your package.json and package-lock.json or npm-shrinkwrap.json are in sync. Please update your lock file with `npm install` before continuing.
npm error
npm error Invalid: lock file's shelf-slug@1.2.0 does not satisfy shelf-slug@2.0.0
npm error Missing: shelf-slug@1.2.0 from lock file
```

A correção é rodar `npm install`, olhar o que mudou no lockfile e fazer commit dos dois arquivos
juntos. Uma mudança de lockfile num pull request merece leitura, porque é a lista do código que vai
rodar no próximo deploy.
