---
title: Medindo os juros
version: 1
---

Nenhum registro de horas tem uma coluna chamada juros. **Eles precisam ser montados a partir de três
fontes**, e cada uma vê uma parte: o imposto sobre as mudanças que encostam na dívida, as horas
gastas nos incidentes que ela causa e o que os engenheiros anotam enquanto trabalham. O Davi usou as
três para a dívida das reservas de assento, e as 31 horas por sprint são o que elas somaram.

O método que a maioria dos times tenta primeiro é uma reunião: perguntar aos engenheiros quanto cada
dívida lhes custa. As respostas voltam confiantes e não são uma medição. Vence a reclamação mais alta,
e a dívida que mais irrita raramente é a que mais custa. A suíte instável irrita todo dia, a réplica
de relatórios dá vergonha de mostrar a quem acabou de chegar, e nenhum desses sentimentos diz quantas
horas foram para onde. Os juros se medem no trabalho, não no humor.

## O imposto sobre cada mudança

A maior parte dos juros costuma ser um **imposto sobre as mudanças**: o trabalho que encosta na
dívida demora mais do que um trabalho parecido que não encosta. Na Coreto, uma mudança em quanto
tempo um assento fica reservado precisa de um revisor de cada time cuja funcionalidade depende da
reserva, de um ensaio contra uma cópia da produção e, muitas vezes, de uma segunda tentativa. Uma
mudança do mesmo tamanho no código de busca do time de Catálogo não precisa de nada disso.

Para medir, pegue as mudanças integradas nas últimas sprints e separe as que encostaram no módulo das
que não encostaram. Compare o tempo do primeiro commit até o deploy em mudanças de tamanho parecido
dos dois lados. A diferença, multiplicada pelo número de mudanças que encostaram no módulo, é o
imposto.

Dois cuidados mantêm esse número honesto:

- compare o comparável, porque uma correção de duas linhas e uma funcionalidade nova não cabem na
  mesma média;
- conte as horas dos revisores além das do autor, já que na Coreto a maior parte do imposto das
  reservas cai sobre quem é chamado para revisar.

## Horas de incidente

A segunda parte é o custo do que quebra. Cada incidente atribuído à dívida custa horas: as pessoas
acionadas, a investigação, a correção, o acompanhamento. O registro de incidentes da Coreto já anota
quem trabalhou em cada incidente e por quanto tempo, então esta é a parte mais fácil de contar. Filtre
os incidentes cuja causa cita o módulo de reservas, some as horas e divida pelo número de sprints que
o registro cobre.

**Conte aqui as horas, não as vendas que o incidente perdeu.** As vendas perdidas numa abertura que
falhou são reais, mas são o risco que a aula 20 precifica. Contá-las também como juros contaria a
mesma falha duas vezes, uma em cada lugar, e o argumento pareceria mais forte do que é.

## O que os engenheiros anotam

Parte dos juros não deixa rastro num pull request nem no registro de incidentes: a manhã perdida
descobrindo por que a suíte ponta a ponta falhou quando nada estava errado, a tarde gasta editando à
mão o layout de um PDF para uma casa com um ingresso fora do padrão. Para esses, peça a quem paga que
marque o próprio tempo por algumas sprints, com uma etiqueta por dívida — "rodar de novo a suíte
instável", "layout de PDF à mão".

É rudimentar, e funciona, porque a marcação acontece durante o trabalho em vez de ser lembrada um mês
depois. As 14 horas por sprint da suíte instável vieram principalmente desta fonte: execuções
repetidas e caçadas a falsas falhas não aparecem em nenhum outro lugar.

| fonte | o que ela pega | onde os dados já estão |
|---|---|---|
| imposto sobre mudanças | revisões mais lentas, ensaios, segundas tentativas | histórico de merges e deploys |
| horas de incidente | acionamentos, investigação, correções | o registro de incidentes |
| etiquetas dos engenheiros | execuções repetidas, trabalho manual, contornos | em lugar nenhum, até alguém perguntar |

## Quanta precisão é preciso

Os juros são uma estimativa, e não precisam ser exatos para servir. **O que precisam acertar é a
ordem de grandeza**, porque as decisões que eles alimentam comparam dívidas cujos juros diferem
várias vezes.

Suponha que as 31 horas do Davi fossem o dobro da verdade, e a dívida das reservas custasse na
realidade 15,5 horas por sprint. O seu principal de 320 horas se pagaria em cerca de 21 sprints em vez
de 10, o que é mais lento, e ela ainda ficaria muito à frente da réplica de relatórios, que leva 50.
Um erro de duas vezes deixou a ordem onde estava.

O que quebra a ordem é contar a coisa errada: a semana inteira de um time no módulo, por exemplo,
incluindo funcionalidades novas que seriam escritas de qualquer jeito. Só conta o que é a mais, ou
seja, as horas que sumiriam se a dívida sumisse.

## Escreva como você chegou lá

Ponha o método ao lado do número. "31 h por sprint, a partir dos tempos de merge das mudanças que
encostam no módulo de reservas, mais as horas de incidente do registro, mais as etiquetas de dois
times" convida o leitor a conferir. Um 31 solto convida a duvidar, e um número que ninguém consegue
conferir é a primeira coisa cortada numa reunião de orçamento. A próxima seção transforma os quatro
juros medidos numa planilha.
