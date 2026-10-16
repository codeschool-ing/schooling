---
title: Por que menos colunas
version: 1
---

A aula 16 agrupou clientes em oito colunas e só conseguiu descrever os grupos em tabelas, porque ninguém
consegue olhar oito dimensões. A **redução de dimensionalidade** faz poucas colunas a partir de muitas,
guardando o máximo que puder do que importa. Há três motivos para querer isso, e eles pedem métodos
diferentes.

- **Para olhar.** Duas colunas podem ser desenhadas. Um mapa dos clientes numa página mostra grupos,
  vazios, pontos fora da curva e erros que nenhuma tabela mostra, e um retrato é o que a equipe de
  marketing vai lembrar.
- **Para alimentar um modelo com menos colunas.** A aula 6 encontrou a maldição da dimensionalidade: em
  muitas colunas toda linha fica longe de todas as outras, e os métodos que medem distância sofrem. Menos
  colunas, mais densas, podem ajudar, e também deixam um modelo mais rápido.
- **Para tirar redundância.** Colunas que andam juntas dizem a mesma coisa duas vezes. Dobrá-las numa só
  tira a repetição, e às vezes o ruído junto.

Esta aula tem três métodos. A **PCA** traça eixos retos novos pelos dados e guarda aqueles ao longo dos
quais as linhas mais se espalham; é linear, rápida, exata e pode ser lida. O **t-SNE** e o **UMAP**
entortam o espaço para manter cada linha perto dos seus vizinhos; desenham retratos muito melhores e são
muito piores em todo o resto. Saber que pergunta cada um responde é a maior parte de usá-los bem.

Uma coisa não muda desde a aula 16: **escale primeiro.** Todo método aqui trabalha com distâncias ou
variâncias, e uma cesta em reais sem escala de novo decidiria tudo sozinha.
