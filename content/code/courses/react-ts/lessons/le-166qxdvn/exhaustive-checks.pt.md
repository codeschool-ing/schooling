---
title: O caso que ninguém tratou
version: 1
---

**Uma união cresce.** Um dia o planejador vai aprender a funcionar offline, e o `PlannerState` vai ganhar
uma quarta forma. Todo `switch` em `status` passa a ter um caso que não trata, e nada diria isso: o
`Root` devolveria `undefined` para ele, que o React desenha como nada, e o estudante veria uma página em
branco.

O `default` do `Root` é o que diz isso:

```tsx
default: {
  const unhandled: never = planner
  return unhandled
}
```

**`never` é o tipo sem valores.** Quando toda forma tem o seu `case`, nada chega ao `default`, o tipo do
planejador ali é `never`, e a atribuição está certa. Acrescente uma forma, com `sed`, e veja:

```
ana@dev:~/planner$ sed -i "s/  | { status: 'loading' }/  | { status: 'loading' }\\n  | { status: 'offline' }/" src/usePlanner.ts && npx tsc -b
src/Root.tsx(20,13): error TS2322: Type '{ toggleDone: UseMutateFunction<unknown, Error, string, unknown>; addSession: UseMutateFunction<unknown, Error, NewSession, unknown>; status: "offline"; }' is not assignable to type 'never'.
ana@dev:~/planner$ sed -i "/  | { status: 'offline' }/d" src/usePlanner.ts && npx tsc -b && echo no errors
no errors
```

**TS2322 no `Root.tsx`**: a forma `'offline'` chegou ao `default`, e ela não é `never`. O erro está no
arquivo que precisa mudar, na linha que precisa mudar, antes de qualquer coisa rodar. O segundo comando
tirou a forma de novo.

Essa conferência só funciona por causa de como o `stateOf` está escrito. **O TypeScript estreita uma
variável ao que foi atribuído a ela**: um `const state: PlannerState = …` montado a partir de três
condições seria tipado como as três formas que essas condições produzem, não como a união com que foi
declarado, e uma quarta forma acrescentada à união nunca chegaria ao `ReturnType<typeof usePlanner>`. Uma
função com tipo de retorno declarado não tem esse atalho: seja o que for que ela devolva, quem a chama vê
`PlannerState`, inteiro.

O mesmo padrão serve para qualquer valor que pode ser uma de um conjunto fixo de coisas: uma requisição
parada, pendente, concluída ou falha; um passo de formulário; uma mensagem de servidor com um campo
`type`. **Torne os estados impossíveis impossíveis de escrever**, e o compilador confere que os possíveis
são todos tratados.
