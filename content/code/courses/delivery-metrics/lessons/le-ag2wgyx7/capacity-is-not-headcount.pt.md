---
title: Capacidade não é número de pessoas
version: 1
---

"Temos cinco devs" é uma afirmação sobre a folha de pagamento, não sobre capacidade. O tempo que essas cinco pessoas conseguem dedicar ao trabalho planejado é bem menor que cinco semanas de trabalho, e um plano que não sabe quanto menor é um plano para um time que não existe.

## Para onde vai o tempo

Eis uma semana plausível para os cinco devs do time de Billing, apresentada como um cálculo. As proporções são ilustrativas, escritas para o curso, e cada linha é algo que um time real consegue medir.

| | dias por semana |
|---|---|
| cinco pessoas, cinco dias | 25,0 |
| feriados, doenças e treinamentos, na média do ano (cerca de 10%) | −2,5 |
| reuniões: dailies, planejamento, retrospectiva, one-on-ones | −2,5 |
| revisão do trabalho uns dos outros | −2,5 |
| plantão e trabalho de incidentes, aula 17 | −2,0 |
| perguntas de suporte e pedidos de outros times | −1,5 |
| **sobra para itens planejados** | **14,0** |

**Catorze dias de vinte e cinco**, pouco mais da metade. Nenhuma das deduções é desperdício. As revisões são o motivo de o tempo de ciclo do time ter caído; o plantão é o motivo de as lojas conseguirem usar o produto à noite; o suporte faz parte do trabalho. Elas simplesmente não são os itens planejados, e um plano que atribui 25 dias de itens a este time planejou onze dias que não vão estar lá.

## Meça a divisão

Os números da tabela são um palpite para um time inventado. Os seus podem ser medidos, de forma aproximada e barata:

- **Marque o trabalho não planejado quando ele chega.** Uma etiqueta nos itens que não estavam no plano, uma raia de urgência, aula 4, ou uma contagem de incidentes e pedidos de suporte por semana.
- **Compare o que foi planejado com o que foi feito.** Ao longo de um trimestre, a fração dos itens terminados que não eram planejados é o número em torno do qual planejar o trimestre seguinte.
- **Conte as interrupções, não só o trabalho.** Uma pergunta de suporte que leva dez minutos custa mais que dez minutos: o dev que ela interrompeu precisa voltar ao que estava fazendo.

Um time que sabe que um terço da sua capacidade vai para trabalho não planejado consegue planejar os outros dois terços com honestidade, e consegue ter uma conversa baseada em fatos sobre se o terço não planejado tem o tamanho certo.

## A vazão já sabe

Há um atalho que torna a maior parte dessa conta desnecessária para fazer previsões. **A vazão é medida depois de todas as deduções.** O histórico do time de Billing, de cerca de um item por dia, já contém as reuniões, as revisões, os incidentes e os feriados daquelas semanas. Esse é o motivo mais profundo de a aula 10 fazer previsões a partir da vazão em vez do número de pessoas: o histórico já fez a subtração.
