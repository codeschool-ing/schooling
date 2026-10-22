---
title: Quatro jeitos de saber de uma mudança
version: 1
---

Toda resposta que o boxoffice deu até aqui foi pedida. Uma página que diz "restam 112 lugares" era verdade
no momento em que o navegador a buscou, e na noite em que um show esgota ela deixa de ser verdade em
segundos. O servidor não tem como chamar o navegador. Ou o navegador fica perguntando, ou mantém uma linha
aberta para o servidor falar por ela.

Há quatro jeitos de arranjar isso, e eles diferem em quem paga e quanto:

| técnica | como funciona | o que custa | direção |
|---|---|---|---|
| **polling** | a página pergunta de novo a cada poucos segundos | uma requisição por visitante a cada intervalo, quase todas respondidas com o número que ele já tinha, e a notícia chega até um intervalo atrasada | o cliente pergunta |
| **long polling** | a página pergunta, e o servidor segura a requisição até algo mudar ou passar um tempo limite; aí a página pergunta de novo | uma requisição esperando por visitante, e uma nova depois de cada mudança | o servidor responde quando tem notícia |
| **server-sent events** | um `GET` cuja resposta nunca termina; o servidor escreve uma linha sempre que há notícia | uma conexão aberta por visitante, em HTTP comum, só texto; o navegador se reconecta sozinho | do servidor para o cliente |
| **WebSocket** | uma requisição HTTP que vira um canal de mensagens nos dois sentidos | uma conexão aberta por visitante, um protocolo próprio depois da primeira requisição, e reconectar fica a cargo do seu código | nos dois sentidos |

Vale fazer a conta do polling. Duas mil pessoas numa página de evento, cada uma perguntando a cada dois
segundos, dão mil requisições por segundo, e entre uma venda e outra quase todas recebem o mesmo número de
volta. Ainda assim ele é a resposta certa mais vezes do que a fama sugere: um painel atualizado a cada
minuto por uma dúzia de funcionários não precisa de mais nada, e não tem conexão nenhuma para manter viva.
Dois segundos de atraso e mil respostas vazias por segundo são o preço que ele cobra quando o público é
grande e a notícia é urgente.

**A disponibilidade de lugares anda num sentido só**, do servidor para quem está olhando, então
server-sent events a cobrem por inteiro. Um WebSocket compensa a maquinaria extra quando o cliente fala o
tempo todo: um chat, um jogo, um documento que várias pessoas editam ao mesmo tempo. Esta aula constrói os
dois sobre a mesma fonte de notícias, nas seções 04 e 05, para que a diferença fique no handler e não nos
dados. As seções 06 e 07 passam o trabalho do WebSocket para uma biblioteca e depois para um servidor à
parte.

## Uma conexão que fica aberta

As três últimas técnicas mantêm algo aberto por visitante, e em Go esse é o caso comum, não um caso
especial: o servidor da aula 1 já dá a cada conexão uma goroutine própria. Dez mil conexões abertas são
dez mil goroutines quase todas dormindo, esperando algo para escrever.

Dois limites ficam fora do programa. Um navegador falando HTTP/1.1 abre no máximo seis conexões para um
mesmo site, e cada aba com um fluxo de server-sent events ocupa uma delas; em HTTP/2 os fluxos dividem uma
conexão só e o limite some. E o que estiver entre o navegador e o servidor, como um proxy ou um balanceador
de carga, tem opiniões sobre conexões que ficam quietas, de que a seção 08 trata.

A conexão nunca foi a parte difícil. **A parte difícil é saber que algo mudou**, e esse é o assunto da
próxima seção.
