---
title: Uma lista para antes de prever
version: 1
---

As seis primeiras aulas, dobradas nas perguntas a fazer a uma série nova antes de ajustar qualquer
modelo. Cada uma é barata, e cada uma já foi a causa de uma previsão que parecia certa e não era.

**Sobre a decisão**

- O que vai ser decidido com a previsão, em que horizonte e em que grão? (aula 4)
- Quanto custa um erro, e um erro grande é pior que vários pequenos? Isso escolhe entre MAE e RMSE.
  (aula 5)

**Sobre o dado**

- Os últimos períodos estão completos? Compare um retrato com os números finais, e corte ou marque
  o que ainda está chegando.
- Há períodos parciais em alguma ponta: uma semana de três dias, um mês começado no dia 20?
- A definição mudou? Um jeito novo de contar é uma mudança de regime no dado e não no negócio, e
  parece igual.

**Sobre a série**

- Quais são as sazonalidades dela, e elas somam ou multiplicam? (aulas 1 e 2)
- Que feriados mudam de lugar, e eles aparecem nos resíduos de uma decomposição? (aula 2 e esta)
- Aconteceu algo que o histórico não contém: uma mudança de preço, um lançamento, um fechamento?
  Marque antes que um suavizador o absorva.

**Sobre a previsão**

- Ela vence as referências ingênua e ingênua sazonal em semanas que não viu? (aulas 3 e 5)
- Foi medida a partir de várias origens, no horizonte de que a decisão precisa? (aula 5)
- Os intervalos dela cobrem o que dizem num teste retroativo? (aula 4)
- Cada safra está guardada com a sua data? (aula 4)

Uma previsão que passa por tudo isso ainda pode errar; o futuro não deve nada a ninguém. Mas vai
errar por motivos que ninguém podia saber, que é o único tipo de erro que quem prevê consegue
defender.
