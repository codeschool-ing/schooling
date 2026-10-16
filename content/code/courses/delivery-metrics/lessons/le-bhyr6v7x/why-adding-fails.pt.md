---
title: Por que somar estimativas dá a data errada
version: 1
---

O jeito usual de responder "quando estes trinta itens vão ficar prontos?" é estimar cada item e somar as estimativas. Parece rigoroso: trinta números cuidadosos, uma soma. Está errado de três maneiras diferentes, e cada uma empurra a data na mesma direção, para antes da realidade.

## As estimativas deixam de fora a espera

Uma estimativa diz quanto trabalho um item precisa. A aula 2 descobriu que a maior parte do tempo de um item no quadro é espera: no backlog, numa fila de revisão, por um deploy, atrás dos outros itens de quem é responsável por ele. Sob as regras antigas do time de Billing, itens que precisavam de uns dois dias de trabalho levavam uma mediana de 18. **Somar estimativas de trabalho prevê o trabalho e esquece a espera**, e a espera era a maior parte.

## Os itens não acontecem um depois do outro

A soma supõe que os itens são feitos em fila. Um time faz vários ao mesmo tempo, então o tempo total não é a soma dos tempos dos itens; dividir por "quantas pessoas temos" é a correção de costume, e ela traz de volta o erro da aula 12 de supor que todo mundo está totalmente disponível. A relação entre quantos itens estão abertos, com que rapidez terminam e quanto tempo levam é a lei de Little, e ela diz que a data depende da **vazão**, não da duração de nenhum item.

## A incerteza não se soma como os números

Suponha que cada item tenha 50% de chance de terminar dentro da estimativa. A chance de que **todos os trinta** terminem é uma fração de um por cento. Somar as medianas dá um total que muito provavelmente não será cumprido. Somar estimativas pessimistas, digamos o percentil 85 de cada item, erra para o outro lado, porque os itens lentos e os rápidos em parte se compensam. **Percentis não se somam.** O único jeito de obter o percentil 85 de um total é olhar a distribuição dos totais, e isso exige uma simulação.

## O que usar no lugar

O time já tem o único número que inclui toda a espera, todo o trabalho em paralelo e todas as interrupções: **quantos itens ele de fato terminou, dia a dia**. Uma previsão construída a partir desse histórico não precisa que ninguém saiba como a espera aconteceu. Ela só precisa que o futuro se pareça com o passado recente, o que o resto desta aula testa, e de um jeito de transformar um histórico de dias numa distribuição de futuros. Esse jeito se chama Monte Carlo, por causa do cassino, porque funciona sorteando ao acaso.
