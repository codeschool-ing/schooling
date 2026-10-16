---
title: De onde vem o viés
version: 1
---

**Um modelo é enviesado, no sentido que esta aula usa, quando os erros dele caem mais pesados sobre um
grupo de pessoas que sobre outro.** Ninguém precisa ter essa intenção. Um modelo aprende com dados que
pessoas produziram e é usado em decisões que pessoas escolheram, e cada um desses passos pode
incliná-lo. As fontes mais comuns têm nome, e vale conhecê-las, porque cada uma aponta para um lugar
diferente onde procurar.

- **Viés histórico.** O dado registra o que aconteceu, inclusive os efeitos de decisões passadas. Se a
  Panela sempre tivesse mandado as melhores ofertas para o Sudeste, os clientes do Sudeste teriam
  ficado mais tempo, e um modelo treinado nessa história aprenderia que o Sudeste é fiel. Ele acertaria
  sobre o passado e levaria a decisão antiga adiante.
- **Viés de representação.** Alguns grupos são escassos no dado. O Norte é 4% dos clientes da Panela,
  117 dos 2.558 do teste da aula 17, e 17 deles saíram. Um modelo ajustado quase todo no Sudeste se
  ajusta ao Sudeste, e qualquer medida de como ele vai no Norte se apoia num punhado de pessoas.
- **Viés de medição.** Uma entrada quer dizer coisas diferentes para grupos diferentes. Dias desde o
  último pedido parece um número neutro. Deixa de ser neutro se os pedidos de um grupo demoram mais
  para chegar, e a etapa quatro mostra que esse é exatamente o caso da Panela.
- **Viés de agregação.** Um modelo para todo mundo supõe que o mesmo padrão vale para todo mundo.
  Quando um grupo se comporta diferente por motivos que as entradas não captam, o modelo único fica
  afinado com a maioria e erra sobre o resto numa direção constante.
- **Viés de implantação.** Um modelo feito para uma decisão é usado em outra. O modelo de churn foi
  feito para escolher quem recebe uma oferta. O time de marketing agora quer usá-lo para escolher quem
  entra num clube. Nada no modelo mudou, e o custo dos erros dele mudou por completo.

Uma sexta fonte pertence a todo modelo cujas decisões moldam os dados futuros: o **ciclo de
retroalimentação**, em que clientes que recebem uma oferta se comportam diferente por causa dela, e o
modelo do ano que vem aprende com um comportamento que o atual causou. A aula 19 volta a ele.

Nenhuma dessas fontes aparece na acurácia, na precisão ou na revocação gerais. Um modelo pode ter 89%
de acurácia e muito menos numa região, porque a região é pequena o bastante para sumir na média. **O
viés se encontra quebrando as medidas por grupo**, e é o que a próxima etapa faz.
