---
title: Três pacotes
version: 1
---

**A biblioteca vem em três partes, e o planner usa as três.** A `@testing-library/dom` guarda as buscas
e funciona em qualquer DOM, com ou sem framework, e é por isso que este curso consegue usá-la numa
página de TypeScript puro; a versão de cada framework, como a `@testing-library/react`, é este pacote
com um `render` para os componentes daquele framework. A `@testing-library/user-event` age como uma
pessoa: digita uma tecla de cada vez e clica com o ponteiro. A `@testing-library/jest-dom` acrescenta
ao `expect` matchers como `toBeInTheDocument` e `toHaveAccessibleName`, que se leem como a frase que
conferem.

```
ana@dev:~/planner$ npm install --save-exact -D @testing-library/dom@10.4.2 @testing-library/user-event@14.6.8 @testing-library/jest-dom@7.0.1

added 22 packages, and audited 111 packages in 5s

found 0 vulnerabilities
```

O `jest-dom` nasceu como uma biblioteca do Jest e, apesar do nome, tem um módulo para o Vitest: um
`import "@testing-library/jest-dom/vitest"` no topo de um arquivo de teste acrescenta os matchers ao
`expect` do Vitest. É toda a configuração que existe.
