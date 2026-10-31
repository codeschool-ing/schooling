---
title: Hooks, e as duas regras que eles seguem
version: 1
---

**Um hook é uma função cujo nome começa com `use` e que guarda algo para um componente entre uma
renderização e outra.** O `useState` guarda um valor. O `useEffect` roda código depois de uma renderização.
O `useTheme` da aula 5 e o `useSafeAreaInsets` da aula 6 são hooks feitos de outros hooks. A função de um
componente roda desde o começo a cada renderização; hooks são como qualquer coisa sobrevive de uma execução
para a seguinte.

## As duas regras

O React encontra o valor guardado de cada hook pela **ordem em que os hooks são chamados**: o primeiro
`useState` de um componente é sempre o primeiro, o segundo sempre o segundo. É por isso que existem duas
regras, e por que quebrar qualquer uma produz valores errados em vez de um erro claro:

1. **Chame hooks no nível de cima de um componente ou de outro hook.** Nunca dentro de uma condição, de um
   laço ou de um callback. Um hook pulado numa renderização desloca todo hook depois dele para o valor
   guardado errado.
2. **Chame hooks só a partir de componentes e de outros hooks.** Uma função comum chamada de um handler de
   evento não tem renderização a que pertencer.

A `CourseScreen` do planner segue a primeira regra de um jeito fácil de não notar: ela chama `useTheme`,
`usePlan` e `useLayoutEffect` **antes** do `return` antecipado para um curso que falta. Mover o
`useLayoutEffect` para baixo desse `return` o chamaria em algumas renderizações e não em outras.

## O useEffect, para o que acontece depois de desenhar

O `useEffect(fn, deps)` roda `fn` depois que o React pôs uma renderização na tela, e de novo sempre que um
valor em `deps` muda. Ele serve para **sincronizar com algo de fora do React**: uma assinatura, um
temporizador, o cabeçalho da navegação, uma requisição. O que ele devolve é a limpeza, rodada antes do
próximo efeito e quando o componente sai:

```tsx
useEffect(() => {
  const id = setInterval(() => setNow(Date.now()), 60_000); // a clock that ticks each minute
  return () => clearInterval(id); // stop it when the screen goes
}, []);
```

Um `deps` vazio roda o efeito uma vez. **Um valor usado dentro e deixado fora de `deps` é um valor velho**: o
efeito continua vendo o que viu da primeira vez. A regra de lint de hooks do React o aponta, e o hábito de
listar cada valor que o efeito lê poupa uma classe de bug que só aparece depois que o estado muda.

O que um efeito **não** é: um jeito de calcular algo a partir de props ou estado. O total da semana é
calculado durante a renderização, a partir do plano, toda vez; guardá-lo em estado e atualizá-lo num efeito
seria uma segunda cópia que fica errada por uma renderização cada vez que o plano muda.

## O useTransition, em resumo

A aula 1 disse que a nova arquitetura deixa o React interromper uma renderização. O `useTransition` é como
você pede isso. `startTransition(() => setFilter(text))` marca uma atualização como **não urgente**: o React a
renderiza em segundo plano e a abandona se algo mais urgente, a próxima tecla, chegar antes. Uma busca em
milhares de sessões continua respondendo à digitação assim. As listas do planner são curtas demais para
precisar disso, e a aula 19 é onde uma medição diria o contrário.
