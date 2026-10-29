---
title: Os passos de cada um, como eles documentam
version: 1
---

**Nada nesta seção foi executado para este curso.** Cada host exige uma conta, e as telas de cada um
mudam mais depressa do que um curso consegue acompanhar. O que está citado aqui é a forma dos passos como
o guia de deploy do Vite e a documentação dos próprios hosts os davam em outubro de 2026; onde uma tela e
este texto discordarem, vale a tela. Os arquivos são a parte que dura, porque moram no seu repositório e
você consegue lê-los daqui a um ano.

Todos começam do mesmo lugar: **o planner enviado para um repositório no GitHub**, com `npm run build`
gravando `dist/`.

## Vercel

1. Entre em vercel.com com a sua conta do GitHub e escolha importar um projeto.
2. Escolha o repositório. A Vercel detecta o Vite e preenche o comando de build, `npm run build`, e a
   pasta de saída, `dist`.
3. Publique. O site sai num endereço terminado em `.vercel.app`.

Daí em diante, um push no branch de produção, o `main` a menos que você mude, atualiza o site, e um push
em qualquer outro branch ganha um preview deployment próprio. O planner não precisa de `vercel.json` para
ser servido; a aula 4 acrescenta um para os endereços dele. A ferramenta de linha de comando da Vercel
publica uma pasta a partir da sua máquina: `npx vercel` para um preview, `npx vercel --prod` para
produção, depois de `npx vercel login`.

## Netlify

1. Entre em netlify.com e escolha importar um projeto existente do Git.
2. Escolha o repositório e o branch, e confira os dois valores que a Netlify detectou.
3. Publique. O site sai num endereço terminado em `.netlify.app`.

Os dois valores também podem morar no repositório, o que é melhor, porque aí são revisados como código e
sobrevivem a uma troca de conta:

```toml
# netlify.toml
[build]
  command = "npm run build"
  publish = "dist"
```

Pull requests ganham um **deploy preview**, e o branch de produção atualiza o site. A ferramenta de linha
de comando é o `netlify-cli`: `npx netlify deploy` envia uma pasta para um endereço de rascunho, e
`npx netlify deploy --prod` para o site.

## Cloudflare Pages

1. No painel da Cloudflare, em **Workers & Pages**, crie um projeto, escolha **Pages** e conecte o
   repositório Git.
2. Escolha o preset do framework para Vite, ou digite você mesmo `npm run build` e `dist`.
3. Salve e publique. O site sai em `<project>.pages.dev`.

Cada push em outro branch ganha um preview em `<hash>.<project>.pages.dev`, mais um apelido com o nome do
branch. A Cloudflare chama o outro caminho de **Direct Upload**, em que você constrói e ela só serve:

```sh
npx wrangler pages project create
npx wrangler pages deploy dist
```

A documentação dela avisa que um projeto criado assim não pode passar para a integração com o Git
depois, então escolha antes do primeiro deploy.

## GitHub Pages

1. No repositório, abra **Settings**, depois **Pages**, e em **Build and deployment** ponha a **Source**
   como **GitHub Actions**.
2. Faça o commit de um workflow que construa o site e entregue `dist/` ao Pages.

Este é o workflow do guia do Vite, com duas mudanças para este curso: o Node 22, como em todo o resto
daqui, e a opção `--base` que a próxima seção explica.

```yaml
# .github/workflows/deploy.yml
name: Deploy static content to Pages

on:
  push:
    branches: ['main']
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: 'pages'
  cancel-in-progress: true

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - name: Set up Node
        uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version: 22
          cache: 'npm'
      - name: Install dependencies
        run: npm ci
      - name: Build
        run: npm run build -- --base=/planner/
      - name: Setup Pages
        uses: actions/configure-pages@45bfe0192ca1faeb007ade9deae92b16b8254a0d # v6.0.0
      - name: Upload artifact
        uses: actions/upload-pages-artifact@fc324d3547104276b827a68afc52ff2a11cc49c9 # v5.0.0
        with:
          path: './dist'
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@368f82528645a54fb793d4d04e342629a3f51346 # v5.0.1
```

Você não precisa acompanhar cada linha ainda; a aula 3 desmonta um workflow, inclusive por que cada
`uses:` cita um commit de quarenta caracteres em vez de uma versão. Em linhas gerais: a cada push no
`main`, uma máquina Ubuntu nova faz o checkout do repositório, instala o Node 22 e as dependências exatas
do lockfile, constrói e passa `dist/` para os dois passos do Pages, que o publicam em
`https://<user>.github.io/planner/`. O bloco `permissions` dá ao workflow o direito de publicar e nada
mais.

## O que os quatro têm em comum

Leia as quatro listas de novo e os mesmos três valores aparecem em todas: **o repositório, o comando
`npm run build` e a pasta `dist`**. Esse é o contrato entre o seu projeto e qualquer host, e é por isso
que o projeto é portátil: nada em `dist/` sabe qual deles o serve. O que não é portátil é o arquivo de
regras, e por isso a aula 4 escreve as regras do planner para cada um deles.
