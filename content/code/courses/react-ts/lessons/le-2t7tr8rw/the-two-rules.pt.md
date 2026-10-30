---
title: Duas regras, e mais nada
version: 1
---

**Hooks são as funções cujo nome começa com `use`**: `useState`, `useEffect`, e as que a aula 7
acrescenta e ensina você a escrever. Eles vêm com duas regras, e a documentação do React diz cada uma
numa frase:

1. **Chame hooks no nível de cima de um componente**, nunca dentro de uma condição, de um laço, de uma
   função aninhada, ou depois de um `return` antecipado.
2. **Chame hooks só de componentes React ou de outros hooks**, nunca de uma função comum, de uma
   classe ou de um handler de evento.

É só isso. Tudo o mais que as pessoas chamam de regra dos hooks é uma dessas duas, ou uma
consequência do array de dependências da aula 5.

As regras parecem arbitrárias até você saber o que o React faz com uma chamada de hook, e aí parecem
inevitáveis. A próxima seção mostra o mecanismo. As três seguintes quebram a primeira regra no
planejador, dos dois jeitos em que ela costuma ser quebrada, e veem quanto cada um custa: um quebra o
app na primeira carga, e o outro não faz nada visível e joga fora em silêncio o que o usuário
escolheu, o que é pior. A última seção trata de um erro que não quebra nenhuma das regras e é o bug de
hook mais comum que existe.

A segunda regra é mais curta de explicar. Um hook funciona prendendo estado ao componente que o React
está renderizando naquele momento. Fora de uma renderização não existe esse componente, então um
hook chamado de um handler de clique ou de uma função utilitária não tem a que se prender; o React
lança um erro dizendo isso na primeira vez que acontece. Um hook próprio, uma função chamada
`useAlgumaCoisa` que chama hooks, é permitido porque só é chamado durante a renderização de um
componente, e o nome é como as ferramentas do React, e a próxima pessoa, sabem disso.
