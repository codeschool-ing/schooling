---
title: Consistência eventual, e o que ela promete
version: 1
---

A réplica assíncrona da seção 04 respondeu "um milhão de lugares" durante toda a partição, e o
número certo alguns segundos depois de ela acabar. Esse comportamento tem nome. **Consistência
eventual** é a promessa de que, se não chegarem novas escritas, toda cópia vai acabar com o mesmo
valor.

É uma promessa fraca, e vale ser exato sobre quão fraca:

- **Ela não diz quanto tempo é "acabar".** Microssegundos numa rede saudável, minutos atrás de uma
  réplica ocupada, a duração inteira de uma partição. Uma réplica uma semana atrasada continua sendo
  eventualmente consistente.
- **Ela não diz o que uma leitura devolve no meio-tempo.** Qualquer valor que já foi escrito, em
  princípio, inclusive um mais antigo que um valor que o mesmo cliente já viu.
- **Ela supõe que as escritas param.** Num sistema escrito o tempo todo, as cópias podem nunca ser
  todas iguais num mesmo instante, e a promessa é sobre para onde elas caminham.

O que a torna usável é que a janela é curta quase sempre, e que um programa pode pedir garantias
específicas dentro dela. A lista delas de Werner Vogels é a que a maioria dos sistemas ainda usa, e
cada uma é uma promessa a **um cliente**, mais barata que consistência para todos:

| garantia | o que um cliente recebe | quebrada quando |
|---|---|---|
| **ler as próprias escritas** | depois de escrever, ele vê a própria escrita | aula 2: o ingresso comprado e não mostrado |
| **leituras monotônicas** | ele nunca vê um valor mais velho que um que já viu | duas leituras vão a duas réplicas, a segunda mais atrasada |
| **escritas monotônicas** | as escritas dele são aplicadas na ordem em que ele as fez | um "renomear" chega antes do "criar" de que depende |
| **prefixo consistente** | ele vê as escritas numa ordem que aconteceu, nunca uma resposta antes da pergunta | uma resposta num tópico aparece antes da mensagem que ela responde |

As leituras monotônicas são a garantia que as pessoas encontram sem saber o nome. Um usuário
recarrega a página do show, e o primeiro pedido vai para uma réplica que tem a venda enquanto o
segundo vai para uma que não tem: a contagem de lugares **sobe** um entre duas recargas. A correção
de costume é manter cada usuário na mesma réplica durante uma sessão, o que um balanceador consegue
com as sessões grudadas da aula 1, desta vez usadas por um bom motivo.

**A consistência eventual serve para um valor que só anda para a frente e sobre o qual ninguém age
na hora**: uma contagem de curtidas, de visualizações, a lista de shows. Não serve para um valor de
que uma decisão depende, como saber se o último lugar está livre. As próximas duas seções tratam do
caso que a complica: dois lados que aceitaram escritas.
