---
title: O useCallback é o useMemo para uma função
version: 1
---

**Uma função escrita dentro de um componente é uma função nova a cada renderização**, pelo mesmo
motivo que o `filter` devolvia um array novo: o código que a cria roda de novo. O
`useCallback(fn, deps)` guarda a primeira e a devolve até uma dependência mudar. É exatamente
`useMemo(() => fn, deps)`, com a seta extra escrita para você.

O planejador tem uma função que é passada para baixo por um caminho longo: `toggleDone`, do `App`
pelo `CourseScreen` até cada caixa de marcação. A próxima seção a leva para um hook próprio, e lá ela
é escrita assim:

```tsx
const toggleDone = useCallback((id: string) => {
  setSessions((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
}, [])
```

O array é vazio, e com razão: a função não lê nada da renderização, porque a forma de função recebe
as sessões do React. É o mesmo movimento que manteve o efeito do teclado da aula 5 atualizado com
`[]`, rendendo uma segunda vez. **Uma função que só chama setters com a forma de função pode ser
criada uma vez e nunca ficar velha.**

Por que se dar ao trabalho, se a seção anterior disse para não memorizar por reflexo? Porque esta
função sai do hook. Quem chama o `usePlanner` a recebe, e quem chama um hook deve poder pôr o que ele
devolve num array de dependências, ou passá-lo a um componente com `memo`, sem que o miolo do hook
decida que ele muda a cada renderização. **Dentro de um componente, memorize quando medir um motivo.
No que um hook próprio devolve, mantenha as identidades estáveis**, porque o hook não tem como saber
como será usado.

Três coisas que o `useCallback` não faz, porque cada uma é uma crença comum:

- **Não deixa a função mais rápida.** A função faz o mesmo trabalho; só a identidade é mantida.
- **Não impede o componente de renderizar.** O componente renderiza do mesmo jeito; o callback só é o
  mesmo objeto da vez anterior.
- **Não conserta uma closure velha.** Um callback memorizado com as dependências erradas é uma closure
  velha guardada de propósito, e o `exhaustive-deps` do linter confere o array do `useCallback` como
  confere o de um efeito.
