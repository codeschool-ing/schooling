---
title: As economias de sempre, e a que se paga primeiro
version: 1
---

Quando os times conseguem ver a sua parte da fatura, as primeiras economias aparecem quase sozinhas,
e raramente são engenhosas. A crença comum é que economia de nuvem vem de um projeto grande — uma
arquitetura nova, uma migração para um serviço mais barato, uma negociação dura de descontos. Esses
existem, e vêm por último. **As primeiras economias vêm de parar de pagar pelo que ninguém usa**, e
achá-las leva uma lista e uma tarde.

## Os ambientes de homologação da Coreto

O primeiro showback pôs o Checkout em R$ 67.191 no mês, e Mateus Araújo, tech lead do Checkout,
percorreu os recursos do time linha por linha. A maior surpresa não estava em produção. Os ambientes
de homologação — cópias do sistema contra as quais os times testam antes de uma entrega — ficavam
ligados vinte e quatro horas por dia, sete dias por semana, e eram usados no horário de trabalho.
Somando os times, a homologação parada à noite e no fim de semana custava **R$ 9.800 por mês**.

Isso dá R$ 117.600 por ano, por máquinas que ninguém estava olhando. A correção foi uma agenda: a
homologação desliga à noite e liga de manhã, e um time que precise dela à noite a liga por conta
própria.

Ponha a economia em proporção, com os números da aula 11. R$ 117.600 são 4,6% da fatura anual da
nuvem, de R$ 2.544.000, e 6,8% dos R$ 1.738.400 que um corte de 10% no orçamento teria pedido.
**Vale fazer na mesma semana, e está longe de ser uma estratégia de orçamento.** As duas metades da
frase importam: a economia é dinheiro de verdade por uma tarde de trabalho, e ninguém deveria
apresentá-la como resposta a um pedido de outro tamanho.

## A lista, na ordem de percorrer

| economia | o que é | esforço | quando |
|---|---|---|---|
| recursos ociosos | ambientes, discos, snapshots antigos e máquinas de teste que ninguém usa, ou que só se usam no horário de trabalho | baixo: uma lista, um dono, uma agenda | primeiro |
| redimensionamento | máquinas e bancos maiores que a carga real, em geral dimensionados para um pico que já passou | baixo a médio: medir a carga, redimensionar, acompanhar | segundo |
| compromissos | pagar adiantado por um ano ou mais de capacidade estável, em troca de um preço menor | pouco esforço, um compromisso financeiro de verdade | terceiro, e só para o que sobrar |
| arquitetura | mudar como um serviço é construído para que ele precise de menos | alto: tempo de engenharia, precificado como a aula 11 precifica | por último, e só com a conta feita |

**A ordem é a lição.** Comprometa-se com um ano de capacidade antes de remover as máquinas ociosas e
você assinou um contrato pelo desperdício. Redimensione antes de desligar e você gasta esforço
ajustando máquinas que nem deveriam existir. A arquitetura vem por último porque é a única linha em
que a economia precisa superar um custo grande em horas de engenharia, e a conta da aula 11 se
aplica: dois engenheiros por um trimestre são R$ 132.000 de tempo antes de qualquer economia.

O compromisso é o item da lista cujo mecanismo mais muda. Todo provedor oferece algum jeito de pagar
menos em troca de prometer usar mais, os nomes e os termos mudam de tempos em tempos, e os detalhes
pertencem à documentação atual do seu provedor, não a um curso. O princípio é estável:
**comprometa-se com o que o custo unitário diz que você vai usar, depois que o desperdício saiu.**

## Por que as economias voltam

A agenda da homologação economizou R$ 9.800 no primeiro mês. Deixada de lado, uma economia assim se
desfaz: alguém precisa da homologação ligada para uma entrega tarde da noite e a deixa ligada, um
time novo cria um ambiente fora da agenda, o próximo incidente acrescenta uma réplica que nunca é
removida. **Uma economia que depende de as pessoas lembrarem é uma economia para um trimestre.**

Esta é a fase de operar da primeira seção desta aula, e na Coreto ela tomou três formas. A
homologação fica desligada por padrão, então deixá-la ligada exige uma ação, e não um esquecimento.
Todo recurso novo sem etiqueta aparece no percentual sem etiqueta do mês seguinte, com os nomes do
Davi e da Rafaela ao lado. E a fatura tem um espaço fixo na reunião mensal dos líderes de time,
aberto com dois números: o custo por ingresso e a parte de cada time.

Nada disso é caro. É a diferença entre o FinOps como projeto, que termina, e o FinOps como hábito,
que mantém a fatura legível depois que as pessoas que primeiro a leram passaram para outro
trabalho. O exercício a seguir junta as quatro seções.
