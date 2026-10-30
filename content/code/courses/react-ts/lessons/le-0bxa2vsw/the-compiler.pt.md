---
title: O compilador faz isso por você
version: 1
---

**O React Compiler acrescenta a memoização no build, para o código não precisar carregá-la.** A aula 7 o
apresentou; aqui ele é ligado. Primeiro o `memo` escrito à mão sai do `SessionRow`, para o que o compilador
faz não se misturar com o que o código faz, e então o compilador entra:

```
ana@dev:~/planner$ sed -i 's/^export const SessionRow = memo(function SessionRow(/export function SessionRow(/; s/^import { memo, Profiler } from .react./import { Profiler } from '\''react'\''/' src/SessionRow.tsx && sed -i '$s/^})$/}/' src/SessionRow.tsx && grep -c memo src/SessionRow.tsx
0
ana@dev:~/planner$ npm install --save-dev @rolldown/plugin-babel@0.2.4 @babel/core@8.0.7 babel-plugin-react-compiler@1.0.0

added 42 packages, and audited 82 packages in 2s

21 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

Três pacotes, fixados como todo o resto. O `babel-plugin-react-compiler` é o compilador em si, 1.0.0, a
versão estável. É um plugin do Babel, e o Vite 8 não usa Babel, então o `@rolldown/plugin-babel` roda o
Babel dentro do bundler do Vite para esta tarefa só, com o `@babel/core`. O plugin do React exporta um
preset pronto, e o `vite.config.ts` o liga:

```ts
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
})
```

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 91ms on 31 files with 116 rules using 4 threads.
no errors
```

Para conferir que está ligado, peça ao servidor de desenvolvimento o `SessionRow` como o navegador o
recebe:

```
ana@dev:~/planner$ curl -s http://localhost:5173/src/SessionRow.tsx | grep -o 'react_compiler-runtime\.js\|_c([0-9]*)' | sort -u
_c(16)
react_compiler-runtime.js
```

**`_c(16)`** é o trabalho do compilador: um cache de dezesseis posições que o componente compilado guarda
entre renderizações, do `compiler-runtime` do React. O componente que você escreveu não tem `memo`, nem
`useMemo`, nem `useCallback`; o que o navegador roda tem um cache para todo valor que vale guardar. As mesmas
duas interações de antes:

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click button Plan a session'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click button Plan a session
```

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click checkbox Wed 21 Oct · 40 min'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click checkbox Wed 21 Oct · 40 min
drawn: row s2 (update)
```

**O mesmo resultado do `memo` escrito à mão**: nada redesenhado quando o diálogo abre, uma linha quando uma
sessão muda. O `SessionRow` compilado devolve exatamente o mesmo elemento da última vez quando as props são
as mesmas, e o React pula o que está embaixo, `Profiler` inclusive.

O compilador impõe duas condições ao código, ambas de aulas anteriores. **Os componentes precisam ser puros
e seguir as regras dos hooks**, aulas 3 e 6: ele guarda o que uma função pura devolveria, e um componente
que lê algo que não recebeu é guardado errado, ou pulado pelo compilador. E ele só compila o seu código: um
componente de uma biblioteca publicada sem ele não ganha cache nenhum do seu. A arrow inline da seção
anterior, neste projeto, agora é outra história:

```
ana@dev:~/planner$ sed -i 's|onToggle={toggleDone} />}|onToggle={(id) => toggleDone(id)} />}|' src/CourseScreen.tsx && grep -n 'onToggle=' src/CourseScreen.tsx
34:        render={(s) => <SessionRow session={s} onToggle={(id) => toggleDone(id)} />}
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click button Plan a session'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click button Plan a session
ana@dev:~/planner$ sed -i 's|onToggle={(id) => toggleDone(id)} />}|onToggle={toggleDone} />}|' src/CourseScreen.tsx && grep -n 'onToggle=' src/CourseScreen.tsx
34:        render={(s) => <SessionRow session={s} onToggle={toggleDone} />}
```

**Nada redesenhado**, com a arrow inline no lugar: o compilador guardou a própria arrow, como o
`useCallback` teria feito. É esse o objetivo dele. A estabilidade não depende mais de todos lembrarem.

**O que fazer com uma tela lenta, em ordem**: medir com o profiler, ou com a aba Profiler das ferramentas de
desenvolvedor do React no navegador; achar a renderização que é lenta, não a que é frequente; e só então
mudar o código, com o compilador ligado, o que deixa muito menos lugares onde o `memo` à mão é a resposta.
