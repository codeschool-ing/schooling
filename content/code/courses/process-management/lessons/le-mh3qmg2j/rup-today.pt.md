---
title: O que foi feito do RUP
version: 1
---

Poucas organizações dizem usar RUP hoje, e é fácil concluir que ele sumiu. Não sumiu; se dispersou. A maioria das ideias dele foi para métodos posteriores e para os hábitos de quem aprendeu o ofício com ele, e algumas das fraquezas dele explicam por que os métodos ágeis têm o formato que têm.

## Por que ele saiu de moda

O RUP era um **framework de processo**, não um processo: uma grande biblioteca de papéis, atividades, artefatos e orientações da qual cada projeto devia selecionar o que precisava. Os autores disseram isso com clareza. Na prática, muitas organizações adotaram muito mais do que precisavam, porque selecionar é mais difícil que adotar tudo, e porque cada artefato parecia um seguro. Times produziam dezenas de documentos por iteração e usavam poucos. O peso de que as pessoas se lembram em geral foi falha de adaptação — a mesma falha que a sétima edição do PMBOK, na aula 6, põe a adaptação no centro para evitar.

Ele também estava amarrado a ferramentas vendidas pela mesma empresa, e quando o mercado foi para métodos mais leves e abertos, o peso comercial que tinha espalhado o RUP jogou contra ele.

## Para onde foram as ideias dele

- O **OpenUP**, da fundação Eclipse, é uma versão deliberadamente mínima do Processo Unificado, que mantém as quatro fases e as iterações e larga a maioria dos artefatos.
- O **Agile Unified Process**, de Scott Ambler, era um RUP simplificado com práticas ágeis.
- O **Disciplined Agile Delivery**, de Scott Ambler e Mark Lines (2012), mantém a ideia de fases do RUP na forma de uma **concepção**, uma **construção** e uma **transição**, em volta de iterações ágeis. Ele virou parte da caixa de ferramentas Disciplined Agile do PMI, que a aula 5 citou.
- A **pista arquitetural** do SAFe e o **spike** do XP são respostas à pergunta que a elaboração respondia: como reduzir os maiores riscos técnicos antes de construir sobre eles.

## O que um arquiteto deveria guardar

A ideia que vale guardar é a regra da elaboração: **prove a arquitetura com código rodando que exercite as decisões mais arriscadas, cedo**. É a ordem do modelo em espiral da aula 1, tornada concreta. A aula 11 a transforma em técnica para riscos, e ela é a resposta mais direta ao cone da incerteza: o cone estreita quando decisões são tomadas, e um esqueleto funcionando é um conjunto de decisões que foram testadas em vez de supostas.
