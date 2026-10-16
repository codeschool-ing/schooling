---
title: SPACE, cinco dimensões de uma pergunta
version: 1
---

"Quão produtivo é este time?" parece uma pergunta com uma só resposta, e toda tentativa de dar essa resposta falhou do mesmo jeito: o número único captura uma coisa, e o time aprende a produzir essa coisa. Linhas de código produziram programas longos; tickets fechados produziram tickets pequenos; story points produziram estimativas infladas. **Produtividade não é uma quantidade só**, e o trabalho recente mais útil sobre o assunto parte disso.

Em 2021, Nicole Forsgren, Margaret-Anne Storey, Chandra Maddila, Thomas Zimmermann, Brian Houck e Jenna Butler publicaram *The SPACE of Developer Productivity* na ACM Queue. Forsgren é a mesma pesquisadora por trás do trabalho do DORA das aulas 5 a 7. O artigo propõe cinco dimensões, e a sigla é formada pelas iniciais delas em inglês: **S** de *Satisfaction*, **P** de *Performance*, **A** de *Activity*, **C** de *Communication* e **E** de *Efficiency*.

| dimensão | o que pergunta | um exemplo de medição |
|---|---|---|
| **S**atisfação e bem-estar | quão realizadas, saudáveis e felizes as pessoas estão com o trabalho? | uma pesquisa regular; se as pessoas recomendariam o time |
| **P**erformance (desempenho) | o que o trabalho conquistou? | resultados: confiabilidade, satisfação do cliente, adoção |
| **A**tividade | quanto foi feito? | deploys, revisões, itens concluídos, incidentes tratados |
| **C**omunicação e colaboração | quão bem pessoas e times trabalham juntos? | tempo de retorno das revisões, facilidade de achar informação, tempo de onboarding |
| **E**ficiência e fluxo | o trabalho consegue andar sem interrupções e passagens de mão? | tempo de ciclo, tempo em filas, tempo de foco sem interrupção |

## Três níveis, também

O artigo acrescenta um segundo eixo: cada dimensão pode ser medida para **um indivíduo, um time ou grupo, ou o sistema inteiro**. Atividade para um indivíduo são os commits que ele fez; para um time, os itens que ele concluiu; para o sistema, os deploys em toda a organização. Os níveis se comportam de jeitos diferentes, e o uso indevido mais danoso desta aula, assunto da quarta seção, mora no primeiro deles.

## O que o curso já mediu

A maior parte do que as aulas 1 a 7 calcularam cai em duas das cinco dimensões. Tempo de ciclo, tempo de espera, eficiência de fluxo e trabalho em andamento são **eficiência e fluxo**. Frequência de deploy e itens concluídos são **atividade**. Taxa de falha de mudanças e tempo para restaurar puxam para **desempenho**, no sentido estreito da confiabilidade do sistema.

Sobram três dimensões que os arquivos do time de Billing nunca tocaram: como as pessoas se sentem em relação ao trabalho, quão bem elas colaboram e o que o trabalho conquistou para alguém. **Um relatório feito só com os arquivos descreveria metade da produtividade do time e a apresentaria como o todo**, que é exatamente o alerta da aula 6 sobre as métricas DORA, generalizado.
