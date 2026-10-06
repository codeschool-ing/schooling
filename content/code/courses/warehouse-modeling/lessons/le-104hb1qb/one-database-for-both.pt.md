---
title: Por que não um banco para as duas coisas
version: 1
---

A objeção óbvia é que o relatório funcionou. Levou 1,6 segundo, deu a resposta certa e não precisou
de um segundo banco. Para uma rede deste tamanho, numa tarde tranquila, isso é verdade, e é a
versão mais forte do argumento contra construir um warehouse.

**A resposta está nas condições, não no número.** O relatório rodou sozinho. Em produção ele rodaria
ao lado dos caixas, e os dois disputam as mesmas três coisas:

- **Memória.** O relatório puxou 103 MB de páginas pela memória compartilhada do PostgreSQL. Essas
  páginas tiram do lugar as que os caixas usavam, e a próxima busca que não as achar precisa ir ao
  disco.
- **Disco.** Os 119 MB de arquivos temporários foram gravados enquanto alguém na Paulista esperava
  um recibo.
- **Processadores.** Um relatório é um processo a toda velocidade durante toda a execução. Dez
  gerentes abrindo um painel às nove da manhã de segunda são dez.

Nada disso é fatal com 895 mil linhas. **Cresce com o histórico, e os caixas não crescem.** Um
caixa grava as mesmas quatro linhas no quinto ano e no primeiro; o relatório lê cinco anos em vez
de dois. Uma carga fica mais pesada todo mês enquanto a outra fica parada, e por isso essa
discussão costuma ser perdida devagar, e não de uma vez.

Mais dois motivos não têm nada a ver com velocidade:

- **O modelo briga com a pergunta.** O relatório precisou de seis tabelas e de um `coalesce` para
  lidar com uma árvore de categorias que tem dois níveis em alguns lugares e três em outros. Toda
  pessoa que escreve um relatório tem de saber disso, e quem não sabe recebe um total errado com
  cara de certo.
- **O histórico não está lá.** O banco operacional guarda o estado atual, então algumas perguntas
  sobre o passado não têm resposta nele em velocidade nenhuma. Esse é o assunto da próxima seção.

**O argumento a favor de um banco só é mais forte quando os dados são poucos, as perguntas são
poucas e ninguém pergunta sobre o passado.** A lição 7 volta a ele com um número para "poucos".
