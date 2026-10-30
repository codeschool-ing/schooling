---
title: O que pode atravessar a fronteira
version: 1
---

**Um Server Component pode renderizar um Client Component, e as props que passa precisam viajar até o
navegador como dados.** `monday` é uma string, que viaja como está. Uma função é o caso que não pode,
pelo mesmo motivo do `onClick`, com uma mensagem mais direta quando o nome não começa com `on…`:

```
ana@dev:~/planner-next$ sed -i 's|<WeekKeys monday={monday} />|<WeekKeys monday={monday} toWeek={(m: string) => console.log(m)} />|' app/Planner.tsx
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 | grep -A 3 'Functions cannot' | head -n 4
Uncaught Error: Functions cannot be passed directly to Client Components unless you explicitly expose it by marking it with "use server". Or maybe you meant to call this function rather than return it.
  <... monday=... toWeek={function toWeek}>
                         ^^^^^^^^^^^^^^^^^
- img
ana@dev:~/planner-next$ sed -i 's|<WeekKeys monday={monday} toWeek={(m: string) => console.log(m)} />|<WeekKeys monday={monday} />|' app/Planner.tsx && grep -c toWeek app/Planner.tsx
0
```

*Functions cannot be passed directly to Client Components unless you explicitly expose it by marking it
with "use server".* Essa exceção é o assunto da aula 16: uma **Server Function**, que o navegador chama
pela rede. Qualquer outra coisa que seja código fica do lado em que foi escrita.

O que um Server Component pode passar a um Client Component, pela lista do próprio React:

| atravessa | não atravessa |
|---|---|
| strings, números, booleanos, `null`, `undefined` | funções, a menos que sejam Server Functions |
| arrays e objetos simples desses | instâncias das suas próprias classes |
| `Date`, `Map`, `Set` | símbolos não registrados com `Symbol.for` |
| JSX, inclusive Server Components como `children` | |
| promises, que um Client Component pode ler com `use` | |

Duas consequências moldam como um app assim é construído:

- **Mantenha a fronteira baixa.** O `'use client'` torna um arquivo inteiro, e tudo o que ele importa,
  código do cliente. Pô-lo no `Planner` teria mandado a aritmética de datas, a lista de cursos e o fetch
  ao navegador, e o fetch então teria precisado do proxy de volta. O `WeekKeys` tem vinte linhas, e só
  elas, com o que importam de `lib/week.ts`, viraram código do navegador.
- **Children atravessam como resultados prontos.** Um Client Component pode receber Server Components
  como `children`, já renderizados no servidor, e posicioná-los; ele nunca os executa. É assim que um
  layout do lado do cliente, uma barra de abas por exemplo, envolve conteúdo buscado no servidor.
