---
title: Quatro projetos, lado a lado
version: 1
---

**Esta aula constrói as mesmas duas páginas do planner quatro vezes, uma em cada meta-framework,
numa pasta só deles: `~/meta`.** A lista de cursos em `/` e as sessões de um curso em
`/courses/<slug>`, lidas no servidor do mesmo `courses.json` da aula 1. Mais nada: nenhum
formulário e nenhum botão, porque o que se compara é como cada um roteia, renderiza e manda uma
página, não como ele trata um clique. Os cursos dos frameworks existem para isso.

| meta-framework | versão | o seu framework de interface | criado com |
|---|---|---|---|
| Next.js | 16.4.3 | React 19.3 | `create-next-app` |
| Nuxt | 4.6.2 | Vue 3.5 | `create-nuxt` |
| SvelteKit | 3.1.0 | Svelte 5.57 | `sv` |
| Angular SSR | 21.2 | Angular 21.2 | o Angular CLI |

Os quatro projetos ocupam cerca de 1,1 GB de disco juntos, quase tudo nos seus `node_modules`. As
aulas 2, 3 e 4 os usam, e `~/meta` pode ser apagado depois disso.

## Angular 21, não 22

A versão mais nova do Angular é a 22, e ela recusa o Node que esta trilha instalou:

```
ana@dev:~$ npx --yes @angular/cli@22.2.4 version
Node.js version v22.22.0 detected.
The Angular CLI requires a minimum Node.js version of v22.22.3 or v24.15.0 or v26.0.0.

Please update your Node.js version or visit https://nodejs.org/ for additional instructions.
```

**O Angular 22 pede o Node 22.22.3 ou mais novo, e o Node da trilha é o 22.22.0.** Instalar um
segundo Node para um framework é exatamente o que este curso não faz, então esta aula usa o Angular
21, cujo CLI aceita qualquer Node a partir do 22.12. O Angular 21 continua com suporte do time do
Angular, e tudo o que esta aula mostra funciona do mesmo jeito no 22. Se você instalou um Node 22
mais novo que o da trilha, o Angular 22 vai rodar para você; os arquivos da aula não mudam.

## Criando os projetos

Cada um é criado pelo seu próprio programa, com as opções que dão o menor projeto: TypeScript,
nenhuma biblioteca de estilo, nenhum linter, nenhum repositório Git próprio. Digite isto numa pasta
nova:

```sh
mkdir ~/meta && cd ~/meta
npx create-next-app@16.4.3 next --ts --app --empty --no-tailwind --no-eslint --no-react-compiler --no-src-dir --import-alias "@/*" --use-npm --disable-git --no-agents-md --no-agent-feedback
npm create nuxt@4.0.1 nuxt -- --template minimal --packageManager npm --no-gitInit --modules=
npx sv@1.1.1 create svelte --template minimal --types ts --add sveltekit-adapter="adapter:node" --install npm
npx @angular/cli@21.2.28 new angular --ssr --defaults --skip-git --skip-tests --style=css --ai-config=none --skip-install
```

Cada um imprime um relatório de progresso com símbolos coloridos e termina com os próximos passos
que sugere; esses relatórios não estão reproduzidos aqui. Três deles instalaram os seus pacotes. A
linha do Angular dizia `--skip-install`, porque a sua instalação precisa de mais um passo antes:

```
ana@dev:~/meta$ cd angular
ana@dev:~/meta/angular$ npm install
npm error Cannot read properties of null (reading 'edgesOut')
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-23T23_00_25_914Z-debug-0.log
ana@dev:~/meta/angular$ echo legacy-peer-deps=true > .npmrc
ana@dev:~/meta/angular$ npm install

added 422 packages, and audited 423 packages in 17s

102 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

**O npm que vem com o Node 22.22.0 para nas dependências deste projeto com um `TypeError` de dentro
do próprio npm.** É um bug no jeito como esse npm resolve *peer dependencies*, pacotes que uma
biblioteca espera que você tenha instalado ao lado dela. `legacy-peer-deps=true` no `.npmrc` do
próprio projeto manda o npm instalar o que o `package.json` lista e deixar as peer dependencies com
você, o que aqui é seguro: o CLI já escreveu todos os pacotes do Angular no `package.json`. O
arquivo vale para todo `npm install` posterior naquela pasta, e para nada fora dela.

## Versões exatas, de novo

Os programas que criaram os projetos escreveram faixas no `package.json`, como `^4.6.2` e `~5.9.2`,
que deixam uma instalação futura pegar uma versão mais nova. `pin.mjs` troca cada faixa pela versão
que o npm de fato instalou, lida do `package-lock.json`. Salve em `~/meta`:

```javascript
// pin.mjs: replace each version range in package.json with the version installed.
import { readFileSync, writeFileSync } from "node:fs";

const pkg = JSON.parse(readFileSync("package.json", "utf8"));
const lock = JSON.parse(readFileSync("package-lock.json", "utf8"));
for (const field of ["dependencies", "devDependencies"]) {
  for (const name of Object.keys(pkg[field] ?? {})) {
    pkg[field][name] = lock.packages[`node_modules/${name}`].version;
  }
}
writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
```

Depois rode-o em cada projeto, deixe o npm registrar a mudança no lockfile, e copie os dados do
planner para cada um. O Angular serve os seus dados a partir de `public/`, como o planner faz; os
outros três os leem da própria pasta do projeto:

```
ana@dev:~/meta$ for d in next nuxt svelte angular; do (cd $d && node ../pin.mjs && npm install --silent); done
◆ Types generated in .nuxt.
ana@dev:~/meta$ grep -h -E '"(next|nuxt|@sveltejs/kit|@angular/core)":' */package.json
    "@angular/core": "21.2.25",
    "next": "16.4.3",
    "nuxt": "4.6.2",
    "@sveltejs/kit": "3.1.0",
ana@dev:~/meta$ for d in next nuxt svelte; do cp ~/planner/public/courses.json $d/; done
ana@dev:~/meta$ cp ~/planner/public/courses.json angular/public/
ana@dev:~/meta$ du -sh */node_modules
317M	angular/node_modules
491M	next/node_modules
231M	nuxt/node_modules
107M	svelte/node_modules
```

As versões da tabela lá em cima são as que essas linhas imprimiram. O Next.js e o Angular podem
mandar estatísticas anônimas de como as suas ferramentas são usadas; `npx next telemetry disable`
em `next` e `npx ng analytics disable` em `angular` desligam isso, e o criador do Nuxt já tinha
deixado desligado neste projeto. Nada nesta aula depende disso.
