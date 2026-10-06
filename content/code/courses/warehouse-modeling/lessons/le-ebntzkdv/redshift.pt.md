---
title: Redshift
version: 1
---

O **Amazon Redshift** é o warehouse da AWS e o mais antigo dos três. Começou como o cluster MPP shared-nothing
clássico da lição 7 e foi andando, em etapas, na direção de separar armazenamento e processamento. Hoje ele vem
em duas formas:

- **Clusters provisionados**: você escolhe um tipo de nó e uma quantidade de nós, e paga por eles por hora
  enquanto existem. A família atual de nós, RA3, guarda os dados num armazenamento gerenciado apoiado em
  armazenamento de objetos e mantém em cache a parte mais usada nos discos locais dos nós, para armazenamento e
  processamento serem dimensionados à parte.
- **Redshift Serverless**: nenhum cluster para escolher. A capacidade é medida em Redshift Processing Units,
  RPUs, aumentada e reduzida pelo serviço, e cobrada pelo tempo em que é usada.

Por dentro, um cluster provisionado ainda se parece com o diagrama da lição 7. Um **nó líder** recebe o
SQL, planeja e combina os resultados. **Nós de processamento** guardam cada um uma parte de cada tabela,
divididos ainda em **fatias** (slices), uma por unidade de processamento, cada uma trabalhando nas suas linhas.

Essa herança é o motivo de o Redshift, sozinho entre os três, fazer a quem modela as perguntas da lição 7:
**que coluna decide onde cada linha mora, e em que ordem as linhas ficam guardadas.** É o assunto da próxima
seção.
