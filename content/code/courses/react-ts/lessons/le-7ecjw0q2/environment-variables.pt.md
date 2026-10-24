---
title: Variáveis de ambiente, e o que elas não são
version: 1
---

**Alguns valores mudam entre os lugares onde um app roda**: o nome que ele mostra, o endereço da API, uma
chave de um serviço de mapas. O Vite os lê de **arquivos `.env`** na raiz do projeto e entrega ao código os
que ele pode ver, por `import.meta.env`.

Dois arquivos. O `.env` é lido em todo modo:

```properties
# Read by Vite in every mode. Only variables starting with VITE_ reach the browser.
VITE_PLANNER_NAME=My study planner
PLANNER_OWNER=ana
```

e o `.env.development` só pelo servidor de desenvolvimento, por cima dele:

```properties
# Read by `vite` (the development server) on top of .env.
VITE_PLANNER_NAME=My study planner (development)
```

O TypeScript fica sabendo que variáveis o app lê, no `src/env.d.ts`, para um erro de digitação num nome
ser um erro e o valor ter um tipo:

```ts
// The variables this app reads from import.meta.env, with their types. Vite's own,
// such as MODE and DEV, are already typed by vite/client.
interface ImportMetaEnv {
  readonly VITE_PLANNER_NAME?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
```

Depois o título da semana lê o nome, com um valor de reserva, e durante esta seção o `main.tsx` imprime
tudo o que o código consegue ver:

```
ana@dev:~/planner$ sed -i "s|<h1>Study planner</h1>|<h1>{import.meta.env.VITE_PLANNER_NAME ?? 'Study planner'}</h1>|" src/WeekScreen.tsx && grep -n h1 src/WeekScreen.tsx
15:      <h1>{import.meta.env.VITE_PLANNER_NAME ?? 'Study planner'}</h1>
ana@dev:~/planner$ sed -i '/^const router/i console.log(JSON.stringify(import.meta.env))\n' src/main.tsx && npx tsc -b && echo no errors
no errors
```

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 | sed -n '1,3p'
{"BASE_URL":"/","DEV":true,"MODE":"development","PROD":false,"SSR":false,"VITE_PLANNER_NAME":"My study planner (development)"}
- main:
  - heading "My study planner (development)" [level=1]
```

**O que o navegador recebeu** é a linha acima do retrato. As cinco do próprio Vite: `BASE_URL`, `DEV`,
`MODE`, `PROD` e `SSR`. Depois **`VITE_PLANNER_NAME`, com o valor de desenvolvimento**, porque o servidor
de desenvolvimento lê o `.env.development` por cima do `.env`. **`PLANNER_OWNER` não está lá**: não começa
com `VITE_`, então o Vite nunca a entregou ao código. Esse prefixo é toda a proteção.

Agora o build de produção, e o servidor de preview:

```
ana@dev:~/planner$ npm run build > /dev/null && grep -o 'My study planner[^`]*' dist/assets/index-*.js | sort | uniq -c
      2 My study planner
ana@dev:~/planner$ grep -c PLANNER_OWNER dist/assets/index-*.js
0
ana@dev:~/planner$ look http://localhost:4173/ --today 2026-10-21 | sed -n '1,3p'
{"BASE_URL":"/","DEV":false,"MODE":"production","PROD":true,"SSR":false,"VITE_PLANNER_NAME":"My study planner"}
- main:
  - heading "My study planner" [level=1]
```

- **O valor está no arquivo construído como texto**, duas vezes: uma no título e uma na linha que imprime
  o ambiente. O Vite não procura a variável quando a página roda; **ele escreve o valor no código na hora
  do build**. Mudá-lo significa fazer o build de novo.
- **`PLANNER_OWNER` não está em arquivo construído nenhum.**
- **O servidor de preview mostra `My study planner`**, só do `.env`: o `vite build` roda no modo
  `production`, que não lê o `.env.development`. O `vite build --mode staging` leria um `.env.staging`,
  para um build destinado a outro lugar.

Esse primeiro ponto é o que guardar. **Uma variável `VITE_` é pública**: está num arquivo JavaScript que
todo visitante baixa, e qualquer um pode lê-la. Um segredo, uma senha de banco ou uma chave de API
privada, nunca deve ser uma. Segredos ficam num servidor, onde o navegador não os lê: na API, ou, no
projeto da aula 15, num Server Component, onde uma variável de ambiente sem o prefixo fica no servidor.
Para valores pessoais de uma máquina, o Vite também lê o **`.env.local`**, que o `.gitignore` do modelo já
mantém fora do git, com a linha `*.local`.

O `console.log` era para esta seção, e sai:

```
ana@dev:~/planner$ sed -i '/^console.log(JSON.stringify(import.meta.env))$/,+1d' src/main.tsx && grep -c console.log src/main.tsx
0
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 42ms on 29 files with 116 rules using 4 threads.
no errors
```
