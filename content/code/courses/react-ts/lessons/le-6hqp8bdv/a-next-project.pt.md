---
title: Um segundo projeto, com um servidor dentro
version: 1
---

**Tudo o que o planejador fez até aqui acontece no navegador.** O Vite manda JavaScript, o navegador
roda o React, e o React pede os dados à API quando já está rodando. Um **Server Component** inverte
parte disso: o componente roda num servidor, busca lá o que precisa e manda ao navegador o resultado. O
React define o que é um Server Component; para ter um, você precisa de um framework que rode o React
num servidor, e o que a maioria dos projetos usa para isso é o **Next.js**.

O Next.js ganha um projeto próprio, ao lado do `~/planner`, para o planejador do Vite ficar como está.
Da sua pasta pessoal:

```
ana@dev:~$ npx create-next-app@16.4.3 planner-next --ts --app --empty --no-tailwind --no-eslint --no-biome --no-react-compiler --no-src-dir --no-rspack --no-agents-md --import-alias "@/*" --use-npm --disable-git --no-agent-feedback
npm warn exec The following package was not found and will be installed: create-next-app@16.4.3

Using defaults for unprovided options:

  --cache-components      Cache Components (use --no-cache-components for No Cache Components)

Creating a new Next.js app in /home/ana/planner-next.

Using npm.

Initializing project with template: app-empty 


Installing dependencies:
- next
- react
- react-dom

Installing devDependencies:
- @types/node
- @types/react
- @types/react-dom
- typescript


added 30 packages, and audited 31 packages in 8s

6 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities

Generating route types...
✓ Types generated successfully

Skipping git initialization.

Success! Created planner-next at /home/ana/planner-next
```

As flags respondem a toda pergunta que o `create-next-app` faria: TypeScript, o **App Router** (a pasta
`app/`, que é onde moram os Server Components), e um modelo vazio, sem Tailwind, sem linter e sem
arquivos extras, para que o `app/` comece com dois arquivos pequenos e nada mais. Uma opção ficou no
padrão, e ele avisa: **Cache Components**, que esta aula encontra na segunda seção. O que saiu:

```
ana@dev:~/planner-next$ cat package.json next.config.ts && ls app
{
  "name": "planner-next",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "16.4.3",
    "react": "19.3.0",
    "react-dom": "19.3.0"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "typescript": "^5"
  }
}
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  cacheComponents: true,
  partialPrefetching: true,
};

export default nextConfig;
layout.tsx
page.tsx
```

Duas coisas a corrigir antes de tudo:

- **Versões.** `next`, `react` e `react-dom` estão exatos, mas os quatro pacotes de desenvolvimento são
  faixas, como `^5`. Uma faixa é uma instalação diferente num dia diferente. Fixe-os nas versões que o
  planejador usa, com `save-exact` ligado para este projeto como a aula 1 ligou para o outro:

```
ana@dev:~/planner-next$ printf 'save-exact=true\n' > .npmrc && npm install --save-dev @types/node@22.20.5 @types/react@19.3.0 @types/react-dom@19.3.0 typescript@6.0.3

added 3 packages, changed 2 packages, and audited 34 packages in 2s

8 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner-next$ grep -A 5 devDependencies package.json
  "devDependencies": {
    "@types/node": "22.20.5",
    "@types/react": "19.3.0",
    "@types/react-dom": "19.3.0",
    "typescript": "6.0.3"
  }
```

- **Telemetria.** O Next.js manda dados anônimos de uso aos seus criadores a menos que você diga que
  não, e avisa disso na primeira vez que roda numa máquina. O `npx next telemetry disable` desliga isso
  para o seu usuário. As transcrições deste curso foram gravadas com ela desligada, e por isso esse
  primeiro aviso não aparece nelas.

Inicie o servidor de desenvolvimento, num terminal próprio como o do Vite. Ele escuta na porta 3000,
então não colide com o planejador do Vite na 5173 nem com a API na 3001:

```

> planner-next@0.1.0 dev
> next dev

▲ Next.js 16.4.3 (Turbopack)
- Local:         http://localhost:3000
- Network:       http://192.0.2.2:3000
✓ Ready in 362ms
✓ Running next.config.ts took 35ms
- Cache Components enabled
- Partial Prefetching enabled
```

O **Turbopack** é o bundler do Next.js, que faz o papel que o Vite faz no outro projeto. As duas últimas
linhas repetem o que o `next.config.ts` ligou. Depois, a página:

```
ana@dev:~/planner-next$ look http://localhost:3000/
[HMR] connected
- main: Hello world!
- alert
```

`[HMR] connected` é o recarregamento a quente do servidor de desenvolvimento, a mesma coisa que o Vite
faz. O `alert` vazio no fim é do Next.js: ele usa essa região para anunciar a página nova a um leitor de
tela depois de uma navegação que não recarrega a página, coisa que um link comum faz sozinho.
