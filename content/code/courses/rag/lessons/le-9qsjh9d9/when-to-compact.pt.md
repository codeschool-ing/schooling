---
title: Quando compactar
version: 1
---

A aula 13 mediu quanto custa uma conversa quando todo turno é mandado de novo: o prompt da Beatriz
cresceu de 98 tokens na primeira mensagem a 725 na décima primeira, e os doze turnos custaram 4.609
tokens de prompt. Aquela conversa é curta. Um chat de atendimento que dura quarenta mensagens, um
agente trabalhando numa tarefa com saídas longas de ferramentas, uma sessão de tutoria que dura uma
hora: cada um chega à janela, e muito antes chega ao orçamento que a aula 12 definiu.

A resposta da aula 13 foi mandar menos: um estado e uma recuperação em vez do histórico. Isso funciona
quando o programa sabe o que importa. Quando não sabe, a outra resposta é a **compactação**: trocar a
parte mais antiga da conversa por algo mais curto que ainda carregue o que o resto da conversa precisa,
e seguir em frente.

Três decisões formam uma política de compactação, e cada uma é um número que uma equipe pode medir.

- **Quando.** Por contagem de tokens, não de turnos: compactar quando o histórico passa de uma parte do
  orçamento, para que um chat de mensagens curtas fique em paz e um chat com uma colagem enorme não.
- **O que fica como estava.** Os últimos turnos, literalmente. A próxima resposta provavelmente é sobre
  eles, e o resumo da mensagem que o cliente acabou de mandar é o único resumo de que ninguém precisa.
- **O que substitui o resto**, e essa é a difícil. Um resumo é a resposta de costume. O resto desta aula
  mede o que um resumo guarda, o que perde, e como fazê-lo não perder nada que importe.

Compactação também é o que frameworks e produtos de agentes fazem com nomes como "memória por resumo"
ou "compactação automática", muitas vezes com um limite padrão e um prompt padrão. A aula 10 disse o que
fazer com um padrão: lê-lo, e medi-lo nas suas próprias conversas.
