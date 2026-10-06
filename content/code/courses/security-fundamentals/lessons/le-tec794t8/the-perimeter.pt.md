---
title: O perímetro, e o que ele já não faz sozinho
version: 1
---

O **perímetro** é a fronteira entre a rede que uma organização controla e tudo o que ela não controla,
e na prática quer dizer o equipamento nessa fronteira: o firewall entre a empresa e a internet. Por
muito tempo ele foi a segurança de rede inteira. Tudo lá fora era hostil, tudo aqui dentro era
confiável, e o firewall era a muralha no meio.

Esse modelo se chama **castelo e fosso**, e vale a pena entendê-lo antes de desmontá-lo, porque ainda
é como a maioria das redes pequenas é montada, a da livraria inclusive.

Um **firewall** é um equipamento, ou um programa num equipamento, que olha cada conexão que passa por
ele e decide, por regras que alguém escreveu, se deixa passar. Nesse nível uma regra olha os
endereços da conexão e a **porta**: o número que diz qual serviço de uma máquina ela quer, 80 para
uma página web, 5432 para o banco PostgreSQL, 22 para administração remota. A aula 3 de `networks`
explica portas, e a aula 1 de `networks-security` explica como um firewall acompanha conexões; aqui
basta "quem pode se conectar a qual serviço de qual máquina".

O perímetro continua sendo uma camada útil. Ele é compartilhado, então um conjunto de regras protege
todas as máquinas atrás dele, e bloqueia o ruído da internet inteira antes que chegue a qualquer
coisa. O que mudou é que **ele não pode mais ser a única linha**, por três motivos que se sustentam
sozinhos:

| o que mudou | por que a muralha não cobre |
|---|---|
| as pessoas trabalham de casa, do café, do celular | o notebook sai do castelo toda noite |
| os serviços foram para a nuvem | e-mail, arquivos e pagamentos ficam fora da muralha por projeto |
| atacantes entram sem atravessá-la | um e-mail de phishing põe o atacante num notebook da equipe que já está dentro |

A terceira linha é a importante. Quando algo lá dentro é comprometido, uma rede construída sobre
"dentro é confiável" oferece tudo a ele. O resto desta aula monta o perímetro direito, depois mostra
por que o lado de dentro também precisa de muros, e a aula 7 leva a ideia até o fim.

**Uma coisa que não é controle de perímetro: NAT.** A maioria dos roteadores de casa e de escritório
pequeno traduz endereços privados para um endereço público, e um efeito colateral é que conexões não
solicitadas vindas da internet não chegam às máquinas de dentro. Esse efeito parece um firewall e não
foi projetado como um. O laboratório do curso não tem NAT nenhum, para que as regras dele sejam a
única coisa decidindo o que passa, e tudo o que você vir bloqueado adiante foi bloqueado por uma
regra que alguém escreveu.
