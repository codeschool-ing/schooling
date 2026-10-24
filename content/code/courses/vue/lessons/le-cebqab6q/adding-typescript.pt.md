---
title: TypeScript, adicionado ao planner
version: 1
---

**O TypeScript confere o código do planner antes de ele rodar, contra tipos que você escreve: que uma
sessão tem um `minutes` que é um número, que o `toggle` recebe um id, que uma prop marcada como
obrigatória é passada.** O Vue 3 é escrito em TypeScript, e o projeto padrão do `create-vue`, que a aula
1 contornou, é um projeto TypeScript. Esta aula converte o planner, arquivo por arquivo, e lê o que o
verificador encontra.

A ideia errada mais comum é que o TypeScript faz o código rodar de outro jeito. Não faz: **o Vite remove
os tipos e roda o JavaScript que está por baixo**, exatamente como antes. O que muda é que um programa
separado, o `vue-tsc`, lê o projeto inteiro e aponta cada lugar em que o código contradiz os tipos. O
servidor de desenvolvimento não roda esse programa; a penúltima seção desta aula trata de onde ele roda.

## Três pacotes e uma configuração

Pare o servidor de desenvolvimento e instale o compilador, o verificador do Vue para arquivos `.vue` e
as configurações recomendadas pelo Vue, fixados nas versões que o `create-vue` 3.24.0 escolhe. O
`--save-dev` registra os três em `devDependencies`, ao lado do Vite, porque eles servem para construir
o planner e nunca chegam a um navegador:

```
ana@dev:~/vue/planner$ npm install --save-dev --save-exact typescript@6.0.3 vue-tsc@3.3.13 @vue/tsconfig@0.9.1

added 10 packages, and audited 92 packages in 1s

24 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

O `tsconfig.json` diz quais arquivos são conferidos e com que rigor:

```json
{
  "extends": "@vue/tsconfig/tsconfig.dom.json",
  "include": ["env.d.ts", "src/**/*.ts", "src/**/*.vue"],
  "compilerOptions": {
    "lib": ["ES2023", "DOM", "DOM.Iterable"],
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

O `extends` herda as configurações do Vue, que ligam o `strict`, o modo em que um valor cujo tipo não
dá para deduzir é um erro em vez de um `any` silencioso. O `lib` acrescenta o ES2023, porque o planner
usa o `toSorted`, que a aula 3 escolheu e que chegou nessa edição; sem isso o verificador não saberia
que o método existe. E o `env.d.ts`, de uma linha, conta ao verificador o que o Vite acrescenta ao
JavaScript, como o `import.meta.env` (aula 17):

```
ana@dev:~/vue/planner$ echo '/// <reference types="vite/client" />' > env.d.ts
```

Por último, um script no `package.json`, ao lado de `dev` e `build`, que roda o verificador sem
escrever nenhum arquivo:

```
ana@dev:~/vue/planner$ npm pkg set scripts.type-check='vue-tsc --noEmit'
```

## Todos os arquivos, renomeados

O TypeScript lê arquivos `.ts` e blocos `<script setup lang="ts">`. Renomeie todos os arquivos `.js`
de `src`, aponte o `index.html` para o `main.ts` e marque o script de cada componente:

```
ana@dev:~/vue/planner$ for f in $(find src -name '*.js'); do mv "$f" "${f%.js}.ts"; done
ana@dev:~/vue/planner$ sed -i 's#/src/main.js#/src/main.ts#' index.html
ana@dev:~/vue/planner$ sed -i 's/<script setup>/<script setup lang="ts">/' $(find src -name '*.vue')
```

Os imports continuam terminando em `.js`, `import { toggleDone } from '../planner.js'`, e isso não é
um engano: é assim que o TypeScript escreve imports de módulos que vão rodar como JavaScript, e o Vite
encontra o `planner.ts` para um import de `planner.js` feito de um arquivo TypeScript. Agora o
verificador:

```
ana@dev:~/vue/planner$ npm run type-check 2>&1 | grep -c 'error TS'
59
```

**Nada mudou além dos nomes, e o verificador encontrou todos esses problemas**, cada um deles um lugar
em que o TypeScript não consegue dizer o que um valor é. Contados por tipo, com o código que o
TypeScript dá a cada um:

```
ana@dev:~/vue/planner$ npm run type-check 2>&1 | grep -o 'error TS[0-9]*' | sort | uniq -c | sort -rn
     27 error TS7006
     20 error TS2339
      5 error TS18047
      3 error TS7031
      1 error TS7034
      1 error TS7005
      1 error TS2698
      1 error TS2322
```

Três códigos respondem por quase todos. **TS7006, `implicitly has an 'any' type`**: um parâmetro de
função que nada descreve, a maioria deles no `planner.ts`, que a próxima seção tipa. **TS2339, `does
not exist on type 'never'`**: o `ref([])` foi entendido como um array de nada, então nenhuma sessão
lida dele tem propriedade alguma (outros três dizem `on type '{}'`, no `SessionForm`). **TS18047, `is possibly 'null'`**: uma template ref usada como se o
elemento estivesse sempre lá. A seção sobre refs tipadas corrige os dois últimos. Enquanto isso, o app
continua rodando no navegador exatamente como antes: nada disso diz respeito ao que o código faz.
