---
title: Uma cultura em que a má notícia corre rápido
version: 1
---

**O objetivo dos postmortems sem culpados não são os documentos. É um time em que as pessoas relatam
problemas cedo, porque relatar nunca custou nada a ninguém.** Isso é uma propriedade da cultura, e dá
para medir mais ou menos pela rapidez com que a má notícia chega a quem pode agir sobre ela.

## As três culturas de Westrum

O sociólogo Ron Westrum, estudando segurança em organizações, descreveu três tipos de cultura pela
forma como tratam a informação:

| | patológica | burocrática | generativa |
|---|---|---|---|
| a informação é | escondida, usada como poder | tratada pelos canais | buscada ativamente |
| os mensageiros são | fuzilados | ignorados | treinados |
| a falha leva a | bodes expiatórios | justiça | investigação |
| ideias novas são | esmagadas | vistas como problema | bem-vindas |

O programa de pesquisa sobre DevOps descrito em *Accelerate*, de Nicole Forsgren, Jez Humble e Gene
Kim, usou a tipologia de Westrum nos seus questionários e descobriu que culturas generativas estavam
associadas a uma entrega de software melhor e a um desempenho melhor da organização. A causalidade é
difícil de provar com questionários, e os autores dizem isso. A direção bate com aquilo em que já
acredita todo engenheiro que trabalhou nos dois tipos de time.

## O que leva um time para o lado generativo

Nada disso é política da empresa. Tudo é comportamento que as pessoas veem se repetir:

- **Agradeça a quem relatou**, em público, principalmente quando o relato era sobre um erro da própria
  pessoa. O relato de Paulo sobre 6 de março foi o mais útil da revisão, e Lívia disse isso na
  reunião.
- **Escreva relatos de quase incidentes, além dos incidentes.** Em abril, um segundo backfill quase
  rodou no pico e foi barrado pela nova linha do runbook. O relato de dois parágrafos mostrou a ação
  funcionando, e esse é o melhor argumento para a próxima ação.
- **Publique os postmortems onde todo mundo possa ler**, não só a engenharia. Suporte, produto e
  diretoria leem os da Marola; o time de Sofia usa esses textos para responder às perguntas dos
  clientes.
- **Quem lidera vai primeiro.** Quando a decisão de Otávio de lançar uma funcionalidade sem teste de
  carga contribuiu para uma lentidão em 2025, ele mesmo escreveu isso no postmortem. Ninguém abaixo
  dele precisou escrever.

## O teste

Pergunte ao engenheiro mais novo de um time: "Se você derrubasse a produção amanhã, o que aconteceria
com você?" Num time generativo, a resposta é algo como "a gente consertaria, e haveria uma revisão
sobre como o sistema deixou isso acontecer". Num time patológico, é uma pausa, e depois uma resposta
cuidadosa. **A resposta a essa pergunta é a cultura, com mais exatidão do que qualquer documento sobre
ela.**
