---
title: O que o caminho nativo compra, e o que custa
version: 1
---

**A aula 6 perguntou quando um app precisa de views nativas. Agora que o planner tem as duas, a resposta
pode ser concreta**, recurso por recurso, em vez de questão de gosto.

## O que ele compra

- **Os controles da própria plataforma.** Um campo de texto é o campo do sistema, com o teclado, a
  correção automática, as alças de seleção e a acessibilidade dele, em cada plataforma do jeito que ela
  faz. O campo de uma WebView é um campo web que parece quase igual.
- **Listas que rolam como as da plataforma.** A `FlatList`, na aula 8, desenha só as linhas que estão na
  tela e as reaproveita enquanto você rola; a medida da aula 6 é o motivo de isso importar.
- **Gestos e animação fora da thread do JavaScript.** Bibliotecas como os pacotes de gestos e de animação
  do React Native rodam um deslizar ou uma transição no lado nativo, então uma thread JavaScript ocupada
  não faz o movimento engasgar.
- **Uma entrada para o mundo nativo quando for preciso.** Um app Expo pode incluir módulos nativos em
  Swift e Kotlin, como um plugin do Capacitor, e existem bibliotecas para widgets e trabalho em segundo
  plano para ele.

## O que ele custa

- **As telas, escritas de novo.** Nada do `view.ts` sobreviveu, e nada do HTML e do CSS de um app de
  verdade sobreviveria. As regras e os dados sobreviveram.
- **Sem CSS.** Estilos são objetos, o layout é só flexbox, e nada se propaga em cascata. A aula 8 mostra
  as diferenças que surpreendem quem vem da web.
- **Duas plataformas que ainda diferem.** Uma base de código, sim; mas uma sombra, uma fonte ou um
  teclado se comportam diferente no Android e no iOS, e os dois têm que ser testados. Uma WebView esconde
  mais disso.
- **Um build nativo no fim.** O navegador e o Expo Go levam você longe, e um lançamento precisa de um
  build Android e iOS de verdade, que é o assunto da aula 9.

**Para o planner, a conta honesta é apertada.** A versão nativa não dá nada de que a pessoa sentiria
falta hoje, e custa um segundo conjunto de telas. No dia em que o planner mostrar uma lista de mil
sessões com um deslizar para marcar uma como feita, a conta muda, e as três perguntas da aula 6 são como
você percebe.
