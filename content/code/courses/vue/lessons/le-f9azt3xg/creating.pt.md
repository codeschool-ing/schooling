---
title: Criando o projeto, e um Node mais novo
version: 1
---

**O Nuxt tem o próprio gerador de projetos, o `create-nuxt`, e ele roda do jeito que o `create-vue`
rodou na aula 1**, pelo `npm create` com a versão fixada. Pare o servidor de desenvolvimento do planner
se ele estiver rodando e, a partir de `~/vue`:

```
ana@dev:~/vue$ npm create nuxt@4.0.1 -- planner-nuxt --template minimal --packageManager npm --no-gitInit --no-install

> npx
> create-nuxt planner-nuxt --template minimal --packageManager npm --no-gitInit --no-install

┌  Welcome to Nuxt!
◇ Creating project in planner-nuxt
● Downloading minimal template...
◆ Downloaded minimal template
● Skipping install dependencies step.
◇ Created your project from the minimal template
Next steps:,› cd planner-nuxt,› npm install,› npm run dev
│
└  ✨ Happy building!
```

`--template minimal` é o ponto de partida mais enxuto que o Nuxt oferece, `--no-gitInit` deixa o
controle de versão com você, e `--no-install` impede que ele instale, porque o próximo passo instala com
as versões fixadas. Sem as opções, ele faz as mesmas perguntas uma a uma. O template é baixado do
repositório do Nuxt no momento em que você roda o comando, então ele é o que o Nuxt publica naquele dia;
todo arquivo dele que esta aula mantém aparece inteiro abaixo. Eis o que ele criou:

```
ana@dev:~/vue/planner-nuxt$ find . -type f | sort
./.gitignore
./README.md
./app/app.vue
./nuxt.config.ts
./package.json
./public/favicon.ico
./public/robots.txt
./tsconfig.json
ana@dev:~/vue/planner-nuxt$ cat package.json
{
  "name": "planner-nuxt",
  "type": "module",
  "private": true,
  "scripts": {
    "build": "nuxt build",
    "dev": "nuxt dev",
    "generate": "nuxt generate",
    "preview": "nuxt preview",
    "postinstall": "nuxt prepare"
  },
  "dependencies": {
    "nuxt": "^4.6.2",
    "vue": "^3.5.44",
    "vue-router": "^5.4.0"
  }
}
```

Oito arquivos, e nenhum `node_modules` ainda. As versões são intervalos, `^4.6.2`, como eram as do
`create-vue`.

## Instalando, e um aviso para ler

Fixe-as exatamente, como na aula 1:

```
ana@dev:~/vue/planner-nuxt$ npm install --save-exact nuxt@4.6.2 vue@3.5.44 vue-router@5.4.0
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: 'nuxt@4.6.2',
npm warn EBADENGINE   required: { node: '^22.22.3 || ^24.15.0 || >=26.0.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: '@nuxt/nitro-server@4.6.2',
npm warn EBADENGINE   required: { node: '^22.22.3 || ^24.15.0 || >=26.0.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: '@nuxt/vite-builder@4.6.2',
npm warn EBADENGINE   required: { node: '^22.22.3 || ^24.15.0 || >=26.0.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: '@nuxt/vite-server@4.6.2',
npm warn EBADENGINE   required: { node: '^22.22.3 || ^24.15.0 || >=26.0.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: 'cssnano@9.9.0',
npm warn EBADENGINE   required: { node: '^22.22.3 || ^24.15.0 || >=26.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: 'postcss-calc@11.2.3',
npm warn EBADENGINE   required: { node: '^22.22.3 || ^24.15 || >=26.0' },
npm warn EBADENGINE   current: { node: 'v22.22.0', npm: '10.9.4' }
npm warn EBADENGINE }
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me

added 550 packages, and audited 552 packages in 16s

132 packages are looking for funding
  run `npm fund` for details

7 high severity vulnerabilities

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

**A instalação funcionou, e seis pacotes disseram que não dão suporte ao Node que a rodou.** O
`EBADENGINE` é o npm lendo o campo `engines` de cada pacote, as versões do Node em que os autores
testam, e comparando com a sua:

```
ana@dev:~/vue/planner-nuxt$ node --version
v22.22.0
ana@dev:~/vue/planner-nuxt$ npm view nuxt@4.6.2 engines.node
^22.22.3 || ^24.15.0 || >=26.0.0
```

`^22.22.3` quer dizer 22.22.3 ou qualquer 22 posterior. O curso de javascript instalou o 22.22.0 em
janeiro, e o Nuxt 4.6 precisa de pelo menos três versões de correção a mais. O npm só avisa, então tudo
bem pode funcionar, e também pode falhar em algum canto que ninguém testou; a leitura honesta do aviso é
*atualize o Node*. Aqui isso é barato, porque o Node mora numa pasta sua, `~/.local/node`, e os links em
`~/.local/bin` apontam para dentro dela. O 22 mais novo no dia desta gravação é o 22.23.4, uma versão de
segurança. Baixe, confira com os checksums que o Node publica e ponha no lugar do antigo:

```
ana@dev:~$ curl -fsSLO https://nodejs.org/dist/v22.23.4/node-v22.23.4-linux-x64.tar.xz
ana@dev:~$ curl -fsSL https://nodejs.org/dist/v22.23.4/SHASUMS256.txt | grep ' node-v22.23.4-linux-x64.tar.xz$' | sha256sum -c
node-v22.23.4-linux-x64.tar.xz: OK
ana@dev:~$ rm -rf ~/.local/node && mkdir ~/.local/node
ana@dev:~$ tar -xJf node-v22.23.4-linux-x64.tar.xz -C ~/.local/node --strip-components=1
ana@dev:~$ rm node-v22.23.4-linux-x64.tar.xz
ana@dev:~$ node --version
v22.23.4
ana@dev:~$ npm --version
10.9.9
```

**`OK` é a linha a procurar**: o arquivo que você baixou tem o SHA-256 que o nodejs.org lista para ele,
então é o arquivo que o Node lançou. No macOS o arquivo é `node-v22.23.4-darwin-arm64.tar.gz` (ou
`-darwin-x64` num Mac Intel) e o comando é `shasum -a 256 -c`; no Windows, o instalador do nodejs.org
substitui a versão antiga para você. Toda aula daqui em diante roda no 22.23.4, inclusive o planner do
Vite, cujo próprio `engines` aceita essa versão. Instale de novo, para o npm registrar o Node novo:

```
ana@dev:~/vue/planner-nuxt$ npm install

> postinstall
> nuxt prepare

◆ Types generated in .nuxt.

added 3 packages, and audited 555 packages in 2s

133 packages are looking for funding
  run `npm fund` for details

7 high severity vulnerabilities

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

Agora sem avisos. O `nuxt prepare`, o script de `postinstall`, gravou os tipos gerados em `.nuxt`; a
seção de importações automáticas olha lá dentro.

## Sete vulnerabilidades de alta gravidade

Essa linha está nas duas instalações, e merece o minuto que leva para ler:

```
ana@dev:~/vue/planner-nuxt$ npm audit
# npm audit report

node-forge  *
Severity: high
node-forge RSA PKCS#1 v1.5 signature verification accepts extra nested DigestAlgorithm elements - https://github.com/advisories/GHSA-86w9-cpqp-85rv
fix available via `npm audit fix --force`
Will install nuxt@4.1.3, which is a breaking change
node_modules/node-forge
  listhen  >=0.3.0
  Depends on vulnerable versions of node-forge
  node_modules/listhen
    nitropack  >=0.5.4
    Depends on vulnerable versions of listhen
    node_modules/nitropack
      @nuxt/nitro-server  >=3.20.0
      Depends on vulnerable versions of nitropack
      Depends on vulnerable versions of nuxt
      node_modules/@nuxt/nitro-server
        nuxt  3.20.0 - 3.21.11 || >=4.2.0
        Depends on vulnerable versions of @nuxt/nitro-server
        Depends on vulnerable versions of @nuxt/vite-builder
        Depends on vulnerable versions of @nuxt/vite-server
        node_modules/nuxt
          @nuxt/vite-builder  3.20.0 - 3.21.11 || >=4.2.0
          Depends on vulnerable versions of nuxt
          node_modules/@nuxt/vite-builder
          @nuxt/vite-server  >=4.6.0
          Depends on vulnerable versions of nuxt
          node_modules/@nuxt/vite-server

7 high severity vulnerabilities

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force
```

**É um alerta só, contado sete vezes**: o `node-forge`, e os seis pacotes entre ele e o `nuxt`, cada um
listado porque depende do de baixo. O alerta trata da conferência de assinaturas RSA. O pacote que usa
o `node-forge` aqui é o `listhen`, a parte do Nitro que abre a porta do servidor de desenvolvimento, e
ele o usa para *criar* um certificado quando você pede HTTPS ao servidor de desenvolvimento, coisa que o
planner nunca faz; nada no planner confere assinatura com ele. Então a exposição é quase nenhuma, por
enquanto. O que não fazer é o comando que ele sugere: `npm audit fix --force` instalaria o Nuxt
**4.1.3**, voltando para antes de uma correção que o 4.6.2 traz para um alerta sobre as regras de rota do
próprio Nuxt, que cobre todo Nuxt até o 4.6.1, só para tirar um aviso sobre um caminho de código que
você não usa. O certo é esperar o Nitro atualizar o `node-forge` e rodar `npm audit` de novo quando você
atualizar o Nuxt.

## A configuração, e a primeira página

Os dois arquivos de conteúdo do template:

```
ana@dev:~/vue/planner-nuxt$ cat nuxt.config.ts app/app.vue
// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true }
})
<template>
  <div>
    <NuxtRouteAnnouncer />
    <NuxtWelcome />
  </div>
</template>
```

O `nuxt.config.ts` é para o Nuxt o que o `vite.config.js` era para o Vite, e o Nuxt repassa a opção
`vite` dele para o Vite. O `compatibilityDate` mantém os padrões do Nuxt e do Nitro como eram naquela
data, para que uma atualização que mude um deles não mude o seu projeto sem você saber. Dê a ele o título
do planner, um idioma para a página, como a aula 1 deu ao `index.html`, e desligue as ferramentas de
desenvolvimento, como a aula 1 tirou as do Vue:

```typescript
// nuxt.config.ts: the study planner, made by Nuxt.
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  // Off, as lesson 1 left Vue's: a button and requests of their own in every page.
  devtools: { enabled: false },
  app: {
    head: { htmlAttrs: { lang: 'en' }, title: 'Study planner' },
  },
})
```

Não há mais `index.html` para editar: o Nuxt escreve ele mesmo o HTML da página, e o `app.head` é como
você põe algo no `<head>` dela. Inicie o servidor de desenvolvimento:

```
ana@dev:~/vue/planner-nuxt$ npm run dev

> dev
> nuxt dev

● Starting Nuxt...
● Nuxt 4.6.2 (with Nitro 2.13.5, Vite 8.3.5 and Vue 3.5.44)

  ➜ Local:    http://localhost:3000/
  ➜ Network:  use --host to expose

● Setting up modules
● Preparing app
● Generating types
● Bundling app
✔ Vite client built in 53ms
✔ Vite server built in 26ms
● Building server
[nitro] ✔ Nuxt Nitro server built in 1357ms
◆ Ready in 2.76s  → http://localhost:3000/
  config 255ms · modules 68ms · app 333ms · types 313ms · bundle 247ms · server 1.54s
(node:9550) [UNDICI-EHPA] Warning: EnvHttpProxyAgent is experimental, expect them to change at any time.
(Use node --trace-warnings ... to show where the warning was created)
```

**Porta `3000`, não `5173`**, e mais passos do que o servidor de desenvolvimento do Vite dá, porque o
Nuxt gera as rotas e os tipos, monta um servidor e o inicia antes de servir qualquer coisa. As duas
últimas linhas são do computador da gravação: ele chega à internet por um proxy, e o Node avisa. O seu
não vai imprimi-las. A página de boas-vindas:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text body
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of body
Welcome to Nuxt!
4.6.2
Get started

Remove this welcome page by replacing <NuxtWelcome/> in app.vue with your own code.

Documentation

We highly recommend you take a look at the Nuxt documentation to level up.

Modules

Discover our list of modules to supercharge your Nuxt project.

Examples

Explore different way of using Nuxt features and get inspired.

Deploy

Learn how to deploy your Nuxt project on different providers.

Nuxt GitHub Repository
Nuxt Discord Server
Nuxt on X
Nuxt Bluesky
Nuxt Linkedin
```

Duas coisas nessa transcrição são novas. O `look` recebe `--text body`, porque uma aplicação Nuxt não é
montada em `#app`. E ela **não tem `--clock`**, e daqui em diante nenhuma transcrição deste curso tem:
uma página do Nuxt é desenhada também pelo servidor, e o relógio do servidor não pode ser ajustado pelo
navegador. No computador da gravação, o servidor e o navegador foram os dois ajustados para 21 de outubro
de 2026, 10:00, nestas transcrições, para que batam com as anteriores; no seu computador o planner vai
mostrar a semana em que você está, e as datas nas suas transcrições serão as suas. A linha do
`<Suspense>` é informação, não aviso: o Nuxt envolve toda página no `<Suspense>` da aula 15, e o Vue diz
em desenvolvimento que ele é experimental.
