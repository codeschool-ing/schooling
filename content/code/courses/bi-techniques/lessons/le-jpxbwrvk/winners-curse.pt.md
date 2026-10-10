---
title: A maldição do vencedor
version: 1
---

**Um resultado significativo de um teste exagera o efeito, em média**, e quanto menor o teste, mais
exagera. Isso se chama maldição do vencedor, e vem de como a significância funciona, não de algum
erro.

Imagine uma mudança com alta verdadeira de 0,3 ponto, testada com a amostra da Panela, que foi
dimensionada para 0,6. Cada rodada desse teste produz uma estimativa diferente: algumas perto de 0,3,
algumas perto de 0, algumas perto de 0,6, por acaso. Só as rodadas cuja estimativa por acaso cai longe
de zero cruzam a linha da significância. **Então as rodadas significativas são, por seleção, as que
superestimaram**, e o time só fica sabendo dessas. Um teste dimensionado para 0,6 que sai
significativo costuma relatar uma alta mais perto de 0,6 que de 0,3, seja qual for a verdade.

Três hábitos a mantêm sob controle.

- **Dimensione o teste direito.** Um teste com muito poder para o efeito que encontra relata esse
  efeito com pouco exagero. A maldição é pior em testes com pouco poder, que é o aviso da aula 8 em
  forma concreta.
- **Espere menos depois do lançamento.** Se um teste mal cruzou a linha, planeje para um efeito menor
  do que ele relatou. O acompanhamento depois do lançamento da Panela é como o efeito real é
  aprendido.
- **Relate o intervalo, não o ponto.** A ponta de baixo do intervalo é uma estimativa sóbria; o ponto
  estimado de um teste que mal foi significativo é uma estimativa otimista.

A maldição também explica uma queixa comum: "todo teste que rodamos vence, e o negócio não se mexe".
Muitas pequenas vitórias, cada uma exagerada, cada uma em parte novidade, somam bem menos do que a
soma delas prometia. A aula 11 acrescenta a outra metade dessa história: testes que vencem por serem
olhados vezes demais.
