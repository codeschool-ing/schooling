---
title: O que pertence ao repositório
version: 1
---

**"O repositório é a fonte da verdade" é uma regra com bordas, e a maior parte dos problemas num
arranjo GitOps vem de não saber onde elas estão.** Algo que está no Git mas não deveria, ou que muda
no cluster mas também está no Git, aparece como uma briga entre o agente e o que mais escrever ali.

## O que entra

- **Os manifestos**: todo objeto que o cluster deve ter, com todo campo que você pretende decidir.
- **Os valores de configuração** que mudam entre ambientes: número de réplicas, mensagens, chaves de
  funcionalidades, recursos pedidos.
- **As referências de imagem**, pela tag no mínimo e pelo digest no melhor caso; a aula 7 explica a
  diferença.
- **A configuração do próprio agente**, quando houver uma: a aula 3 põe neste repositório também a
  descrição, para o Argo CD, do que publicar.

## O que fica de fora

**Segredos em texto puro.** Um Secret do Kubernetes é base64, uma codificação que qualquer um
reverte com um comando, e um repositório é copiado para todo notebook que o clona e guardado para
sempre no histórico. As aulas 9 a 11 são sobre pôr no Git uma *referência* a um segredo, ou uma
cópia cifrada, no lugar dele.

**Campos que outra coisa controla.** Se um HorizontalPodAutoscaler decide quantas réplicas um
deployment tem, e o manifesto no Git também diz `replicas: 2`, os dois vão brigar: o autoscaler
aumenta, o agente devolve, para sempre. A regra é **um dono por campo**. Deixe `replicas` fora do
manifesto quando um autoscaler for o dono, e tanto o Argo CD da aula 3 quanto o Flux da aula 4 têm
também um jeito de ser avisados explicitamente sobre quais campos ignorar.

**Estado que a aplicação produz.** Os dados de um banco, um cache, um log. O Git descreve o que deve
rodar; o que a coisa rodando escreve é problema de outro, com backups no lugar de commits.

**Saída gerada, quase sempre.** Se uma ferramenta gera os manifestos a partir de templates, os
templates e os valores deles vão para o Git, e o agente gera. A aula 6 discute a exceção, em que
times commitam o resultado gerado de propósito para que quem revisa leia exatamente o que será
aplicado.

## Um repositório, uma verdade

Uma regra que soa óbvia e é quebrada o tempo todo: **todo objeto tem exatamente um lugar no Git que o
descreve.** Duas pastas que contêm, ambas, o Deployment do staging, ou dois agentes que o aplicam,
não são redundância. São duas verdades que discordam assim que alguém edita uma delas, e o cluster
alterna entre elas a cada passada. A aula 5 é sobre organizar um repositório de modo que esse lugar
único seja fácil de achar.
