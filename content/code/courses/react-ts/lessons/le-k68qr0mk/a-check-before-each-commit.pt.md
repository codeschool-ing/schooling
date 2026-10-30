---
title: Uma checagem antes de cada commit
version: 1
---

**Toda checagem deste curso é um comando, e um comando que alguém precisa lembrar de rodar.** O jeito de
parar de depender da memória é juntar os comandos num só, e fazer o git rodá-lo. Dois scripts no
`package.json`:

```
ana@dev:~/planner$ npm pkg set scripts.format="prettier --write ." scripts.check="prettier --check . && npm run lint && tsc -b && npm test" && grep -A 9 "\"scripts\"" package.json
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "lint": "oxlint",
    "preview": "vite preview",
    "test": "vitest run",
    "format": "prettier --write .",
    "check": "prettier --check . && npm run lint && tsc -b && npm test"
  },
  "dependencies": {
ana@dev:~/planner$ chmod +x .git/hooks/pre-commit
```

- **`format`** reescreve tudo no layout do Prettier.
- **`check`** é toda checagem do curso, em ordem de velocidade: o layout, o linter, os tipos, os testes.
  O `&&` para na primeira que falhar.

```schooling-figure
{"svg": "<svg data-fig=\"check\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"O npm run check roda quatro passos em ordem, cada um parando o resto quando falha: prettier --check para o layout, oxlint para erros prováveis, tsc -b para os tipos, vitest run para o comportamento. O hook pre-commit do git o roda antes de todo commit, e a CI roda o mesmo comando a cada push.\"><rect x=\"14\" y=\"40\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"94.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">prettier --check</text><text x=\"94\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">layout</text><line x1=\"176\" y1=\"65\" x2=\"188\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"188.0,65.0 180.5,68.2 180.5,61.8\" fill=\"var(--wire)\"></polygon><text x=\"182\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&amp;&amp;</text><rect x=\"190\" y=\"40\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">oxlint</text><text x=\"270\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">erros prováveis</text><line x1=\"352\" y1=\"65\" x2=\"364\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"364.0,65.0 356.5,68.2 356.5,61.8\" fill=\"var(--wire)\"></polygon><text x=\"358\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&amp;&amp;</text><rect x=\"366\" y=\"40\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"446.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">tsc -b</text><text x=\"446\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tipos</text><line x1=\"528\" y1=\"65\" x2=\"540\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"540.0,65.0 532.5,68.2 532.5,61.8\" fill=\"var(--wire)\"></polygon><text x=\"534\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&amp;&amp;</text><rect x=\"542\" y=\"40\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"622.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">vitest run</text><text x=\"622\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">comportamento</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">npm run check</text><text x=\"200\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">antes de todo commit: .git/hooks/pre-commit</text><text x=\"540\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a cada push: a CI, que ninguém pula</text></svg>", "caption": "O mais rápido primeiro; a primeira falha para o resto.", "same": ["layout"]}
```

O git roda um **hook** em certos momentos, se houver em `.git/hooks` um script com o nome certo e
executável. O `pre-commit` roda antes de um commit ser feito, e uma falha impede o commit.
`.git/hooks/pre-commit`:

```sh
#!/bin/sh
# Runs before every `git commit`; a failure stops the commit.
exec npm run check
```

O `chmod +x` o tornou executável. Agora tente commitar um arquivo escrito sem cuidado:

```
ana@dev:~/planner$ printf 'export const late    =   true\n' > src/late.ts && git add -A && git commit -q -m 'Format the code' 2>&1 | tail -n 6
> planner@0.0.0 check
> prettier --check . && npm run lint && tsc -b && npm test

Checking formatting...
[warn] src/late.ts
[warn] Code style issues found in the above file. Run Prettier with --write to fix.
```

**O commit foi barrado** na primeira checagem: o Prettier achou o arquivo novo sem formatação. Nada foi
commitado. Formate, e commite de novo:

```
ana@dev:~/planner$ npm run format > /dev/null && git add -A && git commit -q -m "Format the code" 2> /dev/null && git log --format=%s
Format the code
Add ESLint and Prettier
The planner, as lesson 22 left it
ana@dev:~/planner$ git rm -q src/late.ts && git commit -q -m "Remove an example" 2> /dev/null && git log --format=%s | head -n 1
Remove an example
```

O hook rodou todas as checagens de novo e todas passaram, então desta vez o commit foi feito. O arquivo
de exemplo então sai, pelo mesmo hook.

Três coisas a saber sobre hooks:

- **Eles não são compartilhados.** O `.git/hooks` não faz parte do que o `git push` envia, então o clone
  de um colega não tem nenhum dos seus. Ferramentas como Husky e Lefthook guardam o hook no repositório e
  o instalam no `npm install`.
- **Dá para pulá-los**, com `git commit --no-verify`, por qualquer pessoa com pressa. Um hook é uma
  conveniência para quem está commitando, não uma garantia.
- **A garantia é o CI**: o mesmo `npm run check`, rodado num servidor a cada push, onde ninguém consegue
  pulá-lo. O hook pega os problemas um minuto depois de serem feitos; o CI garante que nenhum deles chegue
  à branch principal.
