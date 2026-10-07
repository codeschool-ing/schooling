---
title: SAFe, o Scaled Agile Framework
version: 1
---

O SAFe é o framework de escala mais adotado em grandes empresas, e o mais criticado. Foi criado por Dean Leffingwell e publicado pela primeira vez em 2011; é mantido pela empresa dele, a Scaled Agile, que também cuida das certificações. A versão 6.0 saiu em 2023. Ele é grande de propósito: onde o Guia do Scrum tem treze páginas, o SAFe é um site com centenas de artigos, papéis e diagramas, e espera-se que uma organização escolha as partes de que precisa.

## O release train

A unidade central do SAFe é o **Agile Release Train**, ou ART: um time de times ágeis de longa duração, tipicamente de **50 a 125 pessoas**, que planeja, constrói e entrega junto em torno de um fluxo de valor — a sequência de passos pela qual a organização entrega algo por que um cliente paga. Os times de um trem usam Scrum ou Kanban por dentro. O que o trem acrescenta é uma cadência comum: as iterações de todos os times começam e terminam nos mesmos dias, para o trem conseguir planejar, integrar e demonstrar como um só.

Três papéis existem no nível do trem, além dos dos próprios times:

- o **Release Train Engineer**, que facilita os eventos do trem e remove impedimentos entre times — um Scrum Master do trem;
- a **Gestão de Produto** (Product Management), dona do backlog de funcionalidades do trem, que decide o que o trem constrói — o papel de Product Owner um nível acima;
- o **Arquiteto de Sistema** (System Architect), que dá forma à direção técnica entre os times.

O Arquiteto de Sistema é o papel mais relevante para quem lê este curso. O SAFe lhe dá uma tarefa explícita: construir a **pista arquitetural** (architectural runway), o código, os componentes e a infraestrutura existentes que permitem construir as próximas funcionalidades sem grandes atrasos. A pista é consumida por cada funcionalidade e precisa ser estendida de propósito, como trabalho de backlog como qualquer outro, senão o trem desacelera funcionalidade por funcionalidade.

## Quatro configurações

O SAFe vem em quatro configurações, da menor para a maior:

| configuração | o que acrescenta |
|---|---|
| Essential | um ou mais release trains; o núcleo do framework |
| Large Solution | coordenação entre vários trens construindo um sistema grande, como um veículo ou o núcleo de um banco |
| Portfolio | estratégia e financiamento: quais fluxos de valor existem e quanto cada um recebe |
| Full | tudo isso junto |

A maioria das organizações começa pela Essential e acrescenta o nível de Portfolio quando o financiamento vira o problema, o que costuma acontecer: um orçamento anual de projeto convive mal com times que planejam a cada dez semanas.

## Onde ele cabe

O SAFe cabe em organizações grandes em que muitos times dependem de fato uns dos outros, o negócio quer planos que consiga ver com um trimestre de antecedência e a estrutura existente não vai ser redesenhada. Sua força é dar a uma organização assim um vocabulário comum e um momento regular em que todos planejam juntos. Seu custo é o peso: papéis, eventos e artefatos que exigem pessoas e tempo, e que podem virar uma nova burocracia com nomes ágeis. A última seção desta aula volta a essa crítica.
