---
title: Local e remoto
version: 1
---

Todo servidor das aulas 11 a 15 era **local**: um programa que o hospedeiro iniciava na máquina da ana, falando por stdio, rodando como ana. A aula 12 mediu o que isso quer dizer. Um servidor **remoto** é um serviço em outra máquina, alcançado por Streamable HTTP. As mensagens do protocolo são as mesmas; quase tudo em volta delas muda.

| | local (stdio) | remoto (Streamable HTTP) |
|---|---|---|
| quem o inicia | o hospedeiro, como processo filho | outra pessoa, como serviço |
| como quem ele roda | a pessoa que roda o hospedeiro | a própria conta |
| o que ele consegue ler | tudo o que essa pessoa consegue | o que a própria máquina tem |
| o que ele herda | um ambiente que o hospedeiro escolheu (aula 12) | nada do hospedeiro |
| como é alcançado | um cano | uma rede, então TLS |
| quem está pedindo | quem o iniciou | precisa ser provado, em todo pedido |
| quanto tempo vive | o mesmo que o hospedeiro | independentemente |

As três últimas linhas são onde um servidor remoto precisa de um trabalho que um local não precisa: **TLS**, para o cliente saber que está falando com o servidor de verdade, e **autorização**, para o servidor saber quem está pedindo e o que pode fazer. A especificação põe a autorização numa seção própria, construída sobre o OAuth 2.1, e exige que ela seja feita de jeitos específicos; esta aula constrói a metade do servidor e lê a metade do cliente.

O ganho é o que a aula 11 nomeou: um servidor remoto pode receber exatamente o acesso de que precisa e nada mais, e pode rodar perto dos dados em vez de no laptop de cada pessoa.
