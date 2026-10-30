---
title: React em cinco minutos, para este curso
version: 1
---

**O React Native é React, então as telas dele são componentes React.** Se você já escreve React, esta
seção é um lembrete. Se o framework que você conhece é Angular, Vue ou Svelte, as ideias são umas que
você conhece por outros nomes, e isto basta da grafia do React para ler e escrever as telas do planner.
Não é um curso de React: as quatro ideias abaixo são as que as aulas 7 a 9 usam.

**Um componente é uma função que devolve o que desenhar.** O que ela devolve é JSX, que parece marcação e
é JavaScript: cada tag é uma chamada que cria um elemento.

```tsx
function Total({ done, planned }: { done: number; planned: number }) {
  return <Text>This week: {done} of {planned} minutes done</Text>;
}
```

**Props são os argumentos de um componente.** O `Total` acima recebe `done` e `planned`, e `<Total
done={75} planned={125} />` o desenha. Chaves põem um valor JavaScript dentro do JSX, numa prop ou no
texto.

**Estado é um valor que um componente lembra entre um desenho e outro.** O `useState` dá o valor atual e
uma função para trocá-lo; trocá-lo desenha o componente de novo com o valor novo:

```tsx
const [open, setOpen] = useState<string | null>(null);
// later, in a press handler:
setOpen("statistics");
```

**O React desenha a partir do estado, então você nunca muda a tela diretamente.** Onde o `main.ts` da
aula 1 chamava `draw()` depois de cada mudança, um componente React muda o seu estado, e o React calcula o
que redesenhar. O plano em si nunca é editado no lugar: `markDone` devolve um plano novo, como sempre fez
em `planner.ts`, e `setPlan(markDone(plan, id))` o entrega ao React. **É por isso que as regras do planner
atravessam sem mudança**: elas já estavam escritas do jeito que o React quer, como funções que recebem um
plano e devolvem um novo.

*Esses dois trechos são ilustrações, não um programa para rodar; o `App.tsx` da próxima seção é o
programa inteiro, e usa as quatro ideias.*
