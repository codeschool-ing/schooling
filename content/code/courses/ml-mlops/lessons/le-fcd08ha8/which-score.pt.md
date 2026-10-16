---
title: Qual nota, para quem
version: 1
---

Os números da lição, para um modelo num mês de teste:

| nota | valor | o que ela diria a um gestor |
| --- | --- | --- |
| acurácia | 86,0% | nada: o modelo que não sabe nada tira 83,1% |
| precisão e revocação em 0,5 | 0,685, 0,321 | um corte que ninguém escolheu |
| valor líquido em 0,2 | R$ 11.900,00 | quanto vale agir com o modelo, aos preços do marketing |
| ROC AUC | 0,790 | o modelo ordena bem os membros |
| precisão média | 0,522 contra 0,169 | três vezes melhor que o acaso para achar afastamentos |
| precisão em 300 | 195 de 300 | quão boa é a lista que podemos pagar |
| calibração | 0,176 dito, 0,169 acontecido | as probabilidades dele podem ser multiplicadas |

**Escolher entre elas faz parte de combinar para que serve o modelo**, e isso pertence ao começo de
um projeto, ao lado do rótulo e do corte, não ao fim, quando alguém precisa de um número para um
slide. Duas regras valem quase sempre.

**Uma nota decide, várias são acompanhadas.** Uma publicação é julgada pela nota que corresponde ao
uso: precisão no orçamento para a lista de vouchers, valor líquido se os custos estão combinados. As
outras são registradas ao lado, porque um modelo pode melhorar a nota que decide enquanto outra coisa
piora em silêncio, e a calibração é a vítima de sempre.

**Toda nota é registrada com a sua linha de base e as suas linhas.** "AUC 0,790" não quer dizer nada
sem "nos membros em 30 de novembro, 530 de 3.130 se afastaram". A lição 7 registra exatamente isso a
cada treino, e a lição 9 continua registrando depois que o modelo está no ar, que é quando os rótulos
das próprias predições dele finalmente chegam.

**De quem é esse trabalho?** Quem modela escolhe quais notas fazem sentido. A plataforma garante que
elas sejam calculadas do mesmo jeito toda vez, em linhas que não foram usadas para escolher, e
guardadas onde a próxima pessoa possa comparar com elas. Uma nota calculada de um jeito diferente a
cada mês é um número que muda por motivos que ninguém vê.
