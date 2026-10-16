---
title: Quatro jeitos de trabalhar, um trabalho só
version: 1
---

**Scrum, Kanban, XP e SAFe respondem perguntas diferentes, e um time real em geral os mistura.** O Scrum diz como
planejar e inspecionar em ciclos. O Kanban diz como ver e limitar o fluxo. O XP diz como escrever o código. O SAFe
diz como muitos times se alinham. Nenhum deles diz a mesma coisa sobre teste, e essa é a parte útil: cada um mexe
numa peça diferente do trabalho.

| | Scrum | Kanban | XP | SAFe |
|---|---|---|---|---|
| o que descreve | o ciclo de um time | o fluxo do trabalho | práticas de engenharia | muitos times num produto |
| ritmo | sprints de um mês ou menos | contínuo, com cadências | iterações curtas, muitos laços | intervalos de 8 a 12 semanas |
| onde fica quem testa | um Developer, sem papel separado | onde o fluxo precisar | ao lado do cliente e de quem programa | num time, e num System Team entre times |
| quem escreve as verificações automatizadas | não diz | não diz | quem programa, com o teste antes; os testes do cliente, com ajuda | todo time, e as de ponta a ponta pelo System Team |
| onde a qualidade fica guardada | a definição de pronto | a política de cada coluna | as próprias práticas | a qualidade embutida, e o System Demo |
| a falha típica | uma minicascata dentro da sprint | uma fila na frente do teste | confiar nas verificações verdes | uma sprint de estabilização no fim de todo intervalo |

A última linha é a que vale lembrar. Cada jeito de trabalhar tem um modo característico de escorregar de volta para
a fase de teste da cascata, e quem testa e sabe qual esperar consegue percebê-lo na primeira semana.

## O que não muda

Leia a tabela de novo de cima a baixo e procure o que é igual em todas as colunas. É o trabalho que este curso
descreve desde a aula 1:

- **prevenção primeiro**: perguntas antes do código, das quatro perguntas da aula 2 ao PI Planning;
- **exemplos como base**: critérios de aceitação escritos como casos, chame o método isso de critérios, testes do
  cliente ou políticas de coluna;
- **exploração por cima da automação**: as verificações confirmam o que alguém escreveu, e uma pessoa procura o que
  ninguém escreveu;
- **defeitos como evidência sobre o processo**: por que isso foi possível?, perguntado numa retrospectiva, num
  cartão bloqueado, num build vermelho.

No Cine Aurora, o time agora toca o trabalho dos preços em sprints de duas semanas, os pedidos da bilheteria num
quadro Kanban, faz par e integra continuamente como o XP diz, e nunca precisou do SAFe. Ninguém planejou essa
mistura. Ela cresceu de corrigir um problema de cada vez, que é como a maioria dos times chega ao seu jeito de
trabalhar, e é por isso que quem testa ganha mais conhecendo as peças do que defendendo um método.
