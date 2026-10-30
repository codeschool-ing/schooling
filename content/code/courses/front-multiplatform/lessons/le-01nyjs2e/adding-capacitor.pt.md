---
title: Acrescentando o Capacitor ao planner
version: 1
---

**O Capacitor são dois pacotes npm e um arquivo de configuração**, acrescentados ao projeto que você
já tem. Nada do planner se move: `src/`, `public/` e `npm run build` ficam exatamente como a aula 1 os
deixou, e o Capacitor se senta ao lado deles. Comece de uma árvore limpa, para o `git status` mostrar
só o que o Capacitor acrescenta. A aula 1 instalou o Playwright e salvou o `look.mjs` depois do commit
dela, então faça o commit disso primeiro:

```
ana@dev:~/planner$ git status --short
 M package-lock.json
 M package.json
?? look.mjs
ana@dev:~/planner$ git add look.mjs package.json package-lock.json
ana@dev:~/planner$ git commit -q -m "Look at the planner from the terminal"
```

## Os dois pacotes

**`@capacitor/core` é a parte que o seu app importa**, a metade JavaScript da ponte, então é uma
dependência comum. **`@capacitor/cli` é o comando `cap`** que você roda no terminal, e nada no app o
importa, então ele entra com `-D`. Os dois na mesma versão, a atual quando este curso foi gravado, e
os dois fixados:

```
ana@dev:~/planner$ npm install -E @capacitor/core@8.5.3

added 2 packages, and audited 23 packages in 440ms

found 0 vulnerabilities
ana@dev:~/planner$ npm install -E -D @capacitor/cli@8.5.3
npm warn deprecated uuid@7.0.3: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).

added 95 packages, and audited 118 packages in 2s

3 moderate severity vulnerabilities

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

A linha de descontinuação e as três vulnerabilidades moderadas estão em pacotes de que a ferramenta de
linha de comando depende, não em nada que o app entrega: um pacote `-D` roda no seu computador e nunca
chega ao celular. O `npm audit` as lista. **Não rode `npm audit fix --force`** num projeto como este:
ele tem permissão para mover pacotes entre versões maiores, e é assim que dois pacotes do Capacitor
acabam em versões que não combinam.

## `cap init`

O `npx cap init` pede três coisas, e elas podem ser dadas na própria linha:

```
ana@dev:~/planner$ npx cap init "Study planner" com.example.studyplanner --web-dir dist
✔ Creating capacitor.config.ts in /home/ana/planner in 1.61ms
[success] capacitor.config.ts created!

Next steps: 
https://capacitorjs.com/docs/getting-started#where-to-go-next
ana@dev:~/planner$ cat capacitor.config.ts
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.example.studyplanner',
  appName: 'Study planner',
  webDir: 'dist'
};

export default config;
```

- **`appName`** é o que o celular mostra embaixo do ícone, e pode ser mudado depois.
- **`appId`** é a identidade do app nas duas lojas, escrita ao contrário como um domínio:
  `com.example.studyplanner`. **Escolha uma vez.** Uma loja trata um app com outro `appId` como um app
  diferente, sem avaliações, sem instalações e sem caminho de atualização a partir do antigo. Use um
  domínio que você controla. `com.example` é reservado para exemplos, e o Google Play o recusa no
  envio, o que serve para um curso e é errado para qualquer coisa que você publique.
- **`webDir`** é a pasta que o Capacitor copia para os projetos nativos, e para o Vite ela é a `dist`.
  Uma pasta errada é a primeira falha mais comum: o app abre numa tela branca, porque a pasta que ele
  copiou não tem `index.html`.

O arquivo é TypeScript porque o comando `cap` o lê com tipos: uma opção escrita errada nele é um erro
no seu editor antes de ser um mistério num celular. Ele cresce na aula 4, quando os plugins tiram as
configurações dele, e na última seção desta aula.
