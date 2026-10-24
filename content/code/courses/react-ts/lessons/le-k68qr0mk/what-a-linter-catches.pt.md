---
title: O que um linter pega
version: 1
---

**Um linter lê o código sem rodá-lo e aponta padrões que costumam ser erros.** O planejador tem um desde a
aula 1: o `create-vite` configurou o **Oxlint**, um linter escrito em Rust, e o `npm run lint` o rodou
depois de cada mudança. A aula 6 o viu recusar um hook chamado dentro de uma condição.

Esta aula muda os próprios arquivos do projeto, então primeiro o planejador vira um repositório git, que a
última seção precisa e que torna cada mudança abaixo um diff que dá para ler:

```
ana@dev:~/planner$ git init -q && git add -A && git commit -q -m "The planner, as lesson 22 left it" && git log --format=%s
The planner, as lesson 22 left it
```

Agora um erro da aula 7: ler uma ref enquanto o componente renderiza. O `sed` acrescenta uma linha que
registra a ref do título no meio do `CourseScreen`:

```
ana@dev:~/planner$ sed -i 's|^  const heading = useRef<HTMLHeadingElement>(null)$|&\n  console.log(heading.current)|' src/CourseScreen.tsx && sed -n '17,18p' src/CourseScreen.tsx
  const heading = useRef<HTMLHeadingElement>(null)
  console.log(heading.current)
ana@dev:~/planner$ npm run lint

> planner@0.0.0 lint
> oxlint


  ! react(refs): Cannot access refs during render
    ,-[src/CourseScreen.tsx:18:15]
 17 |   const heading = useRef<HTMLHeadingElement>(null)
 18 |   console.log(heading.current)
    :               ^^^^^^^|^^^^^^^
    :                      `-- Passing a ref to a function may read its value during render
 19 |   useEffect(() => {
    `----
  help: React refs are values that are not needed for rendering. Refs should only be accessed outside of render, such as in event handlers or effects. Accessing a ref value (the `current` property) during render can cause your component not to update as expected
  note: React Compiler skipped optimizing this component or hook. Additional guidance: https://react.dev/reference/eslint-plugin-react-hooks/lints/refs

Found 1 warning and 0 errors.
Finished in 88ms on 36 files with 116 rules using 4 threads.
```

**`react(refs)`: Cannot access refs during render.** O Oxlint aponta a expressão exata, explica o porquê
na linha `help` e acrescenta o que isso custa: *React Compiler skipped optimizing this component*, o
React Compiler deixou de otimizar este componente. Essa regra é uma das checagens do próprio React
Compiler, e o Oxlint a roda. Aqui ela é um aviso, não um erro, então o `npm run lint` terminou com
sucesso: um aviso te conta, e um erro te para.

Um linter não é o compilador. O TypeScript não achou nada de errado nessa linha, porque nada está errado
nos tipos dela: `heading.current` é um `HTMLHeadingElement | null`, e registrar um é permitido. O que
está errado é quando ela roda, e isso é um fato sobre o React, que é o que um linter de React conhece.
