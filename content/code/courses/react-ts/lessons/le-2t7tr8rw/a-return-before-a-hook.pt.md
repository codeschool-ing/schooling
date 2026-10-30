---
title: Um return antes de um hook
version: 1
---

**O jeito mais comum de quebrar a regra um não é um `if` em volta de um hook. É um `return` acima de
um.** Ele se lê com naturalidade: trate os casos especiais primeiro, depois vá ao trabalho de verdade.
No `App` isso seria responder "ainda carregando" antes de montar o efeito do título, então aqui estão
as duas linhas que desenham as telas de carregamento e de falha levadas para cima, acima do segundo e
do terceiro efeitos:

```
ana@dev:~/planner$ sed -n 38,45p src/App.tsx
    }
  }, [])

  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <p role="alert">The planner could not be loaded.</p>

  useEffect(() => {
    document.title = `Week of ${formatWeek(monday)} · Study planner`
ana@dev:~/planner$ npx tsc -b && echo no errors
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21
[error] React has detected a change in the order of Hooks called by %s. This will lead to bugs and errors if not fixed. For more information, read the Rules of Hooks: https://react.dev/link/rules-of-hooks

   Previous render            Next render
   ------------------------------------------------------
%s   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 App 1. useState                   useState
2. useState                   useState
3. useState                   useState
4. useState                   useState
5. useState                   useState
6. useEffect                  useEffect
7. undefined                  useEffect

Uncaught Error: Rendered more hooks than during the previous render.
[warn] %s

%s
 An error occurred in the <App> component. Consider adding an error boundary to your tree to customize error handling behavior.
Visit https://react.dev/link/error-boundaries to learn more about error boundaries.

ana@dev:~/planner$ npm run lint 2>&1 | grep -c rules-of-hooks
2
ana@dev:~/planner$ cp /tmp/App.tsx src/App.tsx
```

**A checagem de tipos passou e o app não aparece.** Na primeira renderização o `status` é
`'loading'`, então o `App` retornou depois de seis hooks: cinco `useState` e o efeito da busca.
Quando os dados chegaram, o `App` renderizou de novo com `status` em `'ready'`, passou pelo `return`
e chamou mais dois efeitos. O React guardava uma lista de seis espaços e recebeu um pedido de oito.

O console diz isso duas vezes. Primeiro, uma tabela dos hooks que o `App` chamou na renderização
anterior contra os que chamou nesta, em que o espaço 7 era `undefined` e agora é um `useEffect`; o
`look` imprime a mensagem do React antes de os marcadores `%s` serem preenchidos com o nome do
componente, que o console do seu navegador preenche para você. Depois, o próprio erro: **"Rendered
more hooks than during the previous render"**, e um aviso que sugere um error boundary, o assunto da
aula 12. Um erro não tratado durante a renderização remove a árvore inteira, e é por isso que a
página está vazia.

O linter contou dois hooks depois do `return`. A correção é a ordem que o `App` tinha: todo hook
primeiro, depois todo `return`.

```tsx
// all the hooks
const [monday, setMonday] = useState(…)
// …
useEffect(() => { … }, [])

// then the screens that depend on them
if (status === 'loading') return <p>Loading the planner…</p>
```

O último `cp` pôs o `App` correto de volta.
