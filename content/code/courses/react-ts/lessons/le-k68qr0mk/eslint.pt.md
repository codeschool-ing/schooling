---
title: ESLint, o dos plugins
version: 1
---

**O ESLint é o linter que a maioria dos projetos JavaScript usa**, e aquele para o qual a maioria das
regras é escrita primeiro. O time do React publica as regras dos hooks como um plugin de ESLint, e o
mesmo faz quase toda biblioteca com regras próprias. Instale-o, com os plugins que o template do Vite
trazia:

```
ana@dev:~/planner$ npm install --save-dev eslint@10.13.0 @eslint/js@10.0.1 typescript-eslint@8.72.0 eslint-plugin-react-hooks@7.1.1 eslint-plugin-react-refresh@0.5.7 globals@17.13.0

added 133 packages, and audited 293 packages in 6s

65 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

- **`@eslint/js`** são as regras recomendadas do próprio ESLint, e o **`typescript-eslint`** o deixa ler
  TypeScript e acrescenta regras sobre tipos.
- **`eslint-plugin-react-hooks`** é o do time do React: as regras dos hooks, os arrays de dependências e
  as checagens do React Compiler.
- **`eslint-plugin-react-refresh`** avisa de exports que impedem o hot reload do Vite de manter o estado
  de um componente, a mesma coisa que o `only-export-components` do Oxlint confere.
- **`globals`** diz ao ESLint que nomes existem num navegador, entre eles `window` e `document`.

O ESLint lê o `eslint.config.js`, uma lista de objetos de configuração:

```js
import js from '@eslint/js'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import { defineConfig, globalIgnores } from 'eslint/config'
import globals from 'globals'
import tseslint from 'typescript-eslint'

export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      js.configs.recommended,
      tseslint.configs.recommended,
      reactHooks.configs.flat.recommended,
      reactRefresh.configs.vite,
    ],
    languageOptions: {
      globals: globals.browser,
    },
  },
])
```

O `globalIgnores` deixa o build de fora; o segundo objeto vale para arquivos TypeScript e estende quatro
configurações prontas, uma de cada pacote. Rode-o sobre o projeto, com a mesma linha ainda no
`CourseScreen`:

```
ana@dev:~/planner$ npx eslint .

/home/ana/planner/src/CourseScreen.tsx
  18:15  error  Error: Cannot access refs during render

React refs are values that are not needed for rendering. Refs should only be accessed outside of render, such as in event handlers or effects. Accessing a ref value (the `current` property) during render can cause your component not to update as expected (https://react.dev/reference/react/useRef).

/home/ana/planner/src/CourseScreen.tsx:18:15
  16 |   const [message, setMessage] = useState('')
  17 |   const heading = useRef<HTMLHeadingElement>(null)
> 18 |   console.log(heading.current)
     |               ^^^^^^^^^^^^^^^ Passing a ref to a function may read its value during render
  19 |   useEffect(() => {
  20 |     heading.current?.focus()
  21 |   }, [])  react-hooks/refs

✖ 1 problem (1 error, 0 warnings)
```

**O mesmo achado**, com as mesmas palavras, porque é a mesma checagem: o `react-hooks/refs` do plugin é
de onde vem a cópia do Oxlint. O ESLint o chama de **erro** e sai com falha. A linha sai, e os dois
linters são cronometrados no projeto limpo:

```
ana@dev:~/planner$ sed -i '/^  console.log(heading.current)$/d' src/CourseScreen.tsx && git status --short
 M package-lock.json
 M package.json
?? eslint.config.js
ana@dev:~/planner$ time npx eslint .

real	0m2.428s
user	0m3.069s
sys	0m0.321s
ana@dev:~/planner$ time npx oxlint
Found 0 warnings and 0 errors.
Finished in 109ms on 37 files with 116 rules using 4 threads.

real	0m0.510s
user	0m0.371s
sys	0m0.266s
```

**Os dois não acharam nada, e o Oxlint foi várias vezes mais rápido**, e a maior parte do seu meio
segundo é o `npx` iniciando: o próprio Oxlint relata cerca de um décimo de segundo para o projeto
inteiro. Num projeto deste tamanho nenhum dos dois é lento; num com milhares de arquivos, essa diferença
decide se um linter roda a cada save ou só no CI.

**Então, qual?** O Oxlint cobre as regras comuns, as do React incluídas, numa velocidade que o deixa de
graça para rodar o tempo todo. O ESLint tem todo plugin já escrito, e regras que precisam da informação
de tipos do TypeScript, como uma promise que ninguém aguardou. Muitos projetos rodam os dois: Oxlint a
cada save e a cada commit, ESLint no CI, onde os segundos a mais não importam. O planejador fica com esse
arranjo: o `npm run lint` continua sendo o Oxlint, e o `npx eslint .` está lá quando você quiser o resto.
