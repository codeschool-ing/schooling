---
title: Construindo a biblioteca
version: 1
---

**Uma biblioteca é construída para outro build ler**, e isso muda o que o build deve produzir. O build de um
app faz os menores arquivos que um navegador consegue rodar. O de uma biblioteca faz JavaScript que o
bundler de quem consome consegue desmontar, declarações de tipo que o editor e o `tsc` dessa pessoa
conseguem ler, e a folha de estilo como um arquivo próprio.

O Vite faz o primeiro, no **modo biblioteca**: dado um ponto de entrada, ele empacota a biblioteca num
único módulo ES, e não num app com um `index.html`:

```typescript
// vite.config.ts
import { defineConfig } from "vite";

export default defineConfig({
  build: {
    lib: { entry: "src/index.ts", formats: ["es"], fileName: "index" },
  },
});
```

O `tsc` faz o segundo. Esta configuração emite só declarações, arquivos `.d.ts`, já que o Vite gravou o
JavaScript:

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "es2023",
    "module": "esnext",
    "moduleResolution": "bundler",
    "lib": ["ES2023", "DOM"],
    "strict": true,
    "skipLibCheck": true,
    "declaration": true,
    "emitDeclarationOnly": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

O `tsc` lê comentários na própria configuração, e é por isso que o arquivo pode levar o nome na primeira
linha como os outros. Depois instale as duas ferramentas, nas versões que o planner usa, e construa:

```
ana@dev:~/planner-ui$ npm install --save-dev --save-exact vite@8.3.5 typescript@6.0.3 2>&1 | tail -1
found 0 vulnerabilities
ana@dev:~/planner-ui$ npm run build > /dev/null && find dist -type f | sort
dist/components.d.ts
dist/format.d.ts
dist/index.d.ts
dist/index.js
dist/tokens.css
dist/types.d.ts
```

**`dist/` é o que quem consome recebe**: um arquivo JavaScript de menos de um kilobyte, um arquivo de
declarações por arquivo-fonte, e a folha de estilo. A ordem do build importa, e o script a diz uma vez: o
Vite esvazia `dist/` antes de gravar, então as declarações e a folha de estilo entram depois dele.

## Olhe antes de publicar

`npm pack` monta exatamente o arquivo que o `npm publish` enviaria. Com `--dry-run` ele só o lista, que é o
jeito mais barato de pegar um arquivo que não devia estar lá, ou um que devia e não está:

```
ana@dev:~/planner-ui$ npm pack --dry-run 2>&1 | grep -E 'notice [0-9.]+k?B|total files'
npm notice 576B dist/components.d.ts
npm notice 59B dist/format.d.ts
npm notice 147B dist/index.d.ts
npm notice 834B dist/index.js
npm notice 1.4kB dist/tokens.css
npm notice 123B dist/types.d.ts
npm notice 528B package.json
npm notice total files: 7
```

Sete arquivos, e nada mais: nada de `src`, nada de `tokens.json`, nada de `node_modules`, porque `files`
cita só `dist`, e o npm sempre acrescenta o `package.json`, um README e uma licença quando houver. Uma
biblioteca que publicou o próprio `.env` ou as fixtures de teste fez isso porque ninguém olhou esta lista.

Faça o commit, com um `.gitignore` para o que é construído:

```
ana@dev:~/planner-ui$ printf 'node_modules\ndist\n*.tgz\n' > .gitignore
```
