---
title: A divisão, vista como vazamento
version: 1
---

A aula 3 mediu dois vazamentos sem dar esse nome a eles. Os dois põem do lado do treino uma
informação que o modelo não teria em uso, que é a definição, e os dois chegam pela divisão e não por
uma coluna.

**Parentes dos dois lados.** Quando a pergunta era *este assinante algum dia vai cancelar?*, uma
divisão ao acaso deixou o modelo aprender a resposta de uma pessoa numa linha e ser medido em outra.
A parte de acertos no décimo do topo foi 76,0% ao acaso e 54,7% com assinantes inteiros. Os 21
pontos entre as duas eram um vazamento.

**O futuro dos dois lados.** Uma divisão ao acaso dos 18 meses deixou o modelo aprender com os meses
depois do aumento e ser medido em meses anteriores a ele. Ele valeu R$ 1.007 por mil linhas, contra
R$ 893 dividindo por tempo. Os 13% entre os dois eram um vazamento.

Visto assim, a aula 3 e esta são um assunto só. Uma divisão é uma promessa de que as linhas medidas
são tão novas para o modelo quanto as de amanhã serão, e todo vazamento é uma promessa desse tipo
quebrada. Três consequências práticas:

- **A divisão vem primeiro**, antes de escolher qualquer coluna, preencher qualquer lacuna ou
  escrever qualquer regra, para nada aprendido com os dados enxergar do outro lado.
- **Quando uma divisão e uma coluna discordam, acredite na divisão por tempo.** Na seção 04 a
  divisão ao acaso aprovou o `days_since_last_order` e a divisão por tempo o recusou, e a divisão por
  tempo estava certa.
- **A última conferência é o próprio futuro.** Um modelo só está livre de vazamento quando mediu
  linhas escritas depois de ter sido construído e foi tão bom quanto prometido. A aula 22 é essa
  conferência.
