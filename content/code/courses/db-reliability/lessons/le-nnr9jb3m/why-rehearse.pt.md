---
title: Por que matar um primário saudável
version: 1
---

A lição 1 disse que um backup é só uma afirmação até ser restaurado. Um failover é o mesmo tipo de
afirmação: o gerenciador de cluster está configurado, o proxy acompanha, a aplicação reconecta, e nada
disso se sabe até que um primário morra com uma aplicação rodando contra ele. A única questão é se essa
primeira vez é escolhida ou não.

Um **ensaio** (em alguns times, um *game day*) escolhe: uma falha provocada de propósito, num horário
que todo mundo combinou, com gente olhando e um caminho de volta pronto. Ele encontra o que o incidente
da lição 22 teria encontrado, num dia em que encontrar não custa nada:

- uma configuração certa em dois nós e errada no terceiro, que a lição 15 viu com `ALTER SYSTEM`;
- uma aplicação que não reconecta, ou reconecta e fica com um endereço velho;
- um alerta que não dispara, ou dispara num canal que ninguém lê mais;
- um passo do runbook que cita um servidor que foi renomeado no ano passado;
- o número real de segundos, que nunca é o do documento de design.

E ele treina as pessoas. Quem já matou um primário numa terça à tarde lê o log de um failover às três
da manhã sem precisar aprender ali.

A lição 7 fez isso para as restaurações: um ensaio com calendário, com cronômetro, registrado por
escrito. Esta lição faz o mesmo para o failover, no cluster da lição 16, com o HAProxy da lição 19 na
frente e o `orders.sh` fazendo o papel dos clientes.
