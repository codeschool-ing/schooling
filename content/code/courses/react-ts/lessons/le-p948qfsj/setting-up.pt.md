---
title: Um executor de testes que já conhece o projeto
version: 1
---

**Toda verificação deste curso até aqui foi uma pessoa olhando**: `look`, `curl`, o compilador. Elas acham
um erro no dia em que alguém as roda. Um teste é uma verificação que roda de novo a cada mudança, escrita
uma vez, e diz numa linha se o planejador ainda faz o que fazia.

O **Vitest** é o executor de testes construído sobre o Vite: ele lê o mesmo `vite.config.ts`, então
TypeScript, JSX, o plugin do React e o compilador funcionam nos testes exatamente como no app, sem nada a
configurar duas vezes. O **React Testing Library** desenha componentes num teste e acha coisas neles do
jeito que uma pessoa acharia, pelo papel e pelo nome. Instale os dois, com três companheiros:

```
ana@dev:~/planner$ npm install --save-dev vitest@5.0.5 jsdom@29.1.1 @testing-library/react@16.3.3 @testing-library/dom@10.4.2 @testing-library/user-event@14.6.8 @testing-library/jest-dom@7.0.1

added 78 packages, and audited 160 packages in 6s

33 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npm pkg set scripts.test="vitest run" && grep "\"test\"" package.json
    "test": "vitest run"
```

- O **`jsdom`** é o documento de um navegador, escrito em JavaScript: elementos, eventos e a API do DOM,
  dentro do Node.js, sem janela nenhuma numa tela. É nele que os componentes desenham. A versão 29 é a que
  este curso fixa, porque a versão 30 pede um Node.js 22 mais novo do que o que a aula 1 instalou.
- O **`@testing-library/user-event`** digita e clica como uma pessoa, tecla por tecla, com todo evento que
  um navegador dispararia.
- O **`@testing-library/jest-dom`** acrescenta afirmações sobre elementos, como `toBeInTheDocument`.

O `npm pkg set` acrescentou um script `test`, então `npm test` roda todos os testes uma vez e para. As
opções do Vitest vão no `vite.config.ts`, em `test`:

```ts
/// <reference types="vitest/config" />
import babel from '@rolldown/plugin-babel'
import react, { reactCompilerPreset } from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), babel({ presets: [reactCompilerPreset()] })],
  server: {
    proxy: {
      '/api': 'http://localhost:3001',
    },
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
  },
})
```

A primeira linha conta ao TypeScript da chave `test`. **`environment: 'jsdom'`** dá a todo teste um
documento, e **`setupFiles`** nomeia um arquivo que roda antes de cada arquivo de teste, o
`src/test/setup.ts`:

```ts
import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { afterEach } from 'vitest'

// Every test draws into the same document: empty it after each one.
afterEach(cleanup)
```

Ele carrega as afirmações do `jest-dom` no `expect` do Vitest, e depois de cada teste remove o que o teste
desenhou, para o próximo começar de uma página vazia. O Testing Library faz isso sozinho só quando as
funções de teste são globais, o que este projeto não liga: todo arquivo de teste importa `describe`, `it` e
`expect` de `vitest`, então fica sempre claro de onde vêm.
