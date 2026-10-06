---
title: O que nunca cortar
version: 1
---

A compactação vale para fontes tanto quanto para conversas: um documento longo buscado por um agente,
uma fonte antiga ainda no contexto de um chat, uma seção longa demais para o orçamento. A aula 12
comprimia fontes mantendo frases inteiras sobre a pergunta; um resumo vai além, e algumas frases não
sobrevivem a serem separadas das vizinhas. Duas seções da política de devoluções, resumidas em no máximo
25 palavras:

```
ana@lab:~/rag$ python policy.py "Items that cannot be returned" 25
The following cannot be returned unless they arrive damaged or faulty: - personalised copies and copies signed by the author; - jigsaw puzzles and games whose packaging has been opened; - anything bought in the clearance section; - newspapers and magazines.
summary:
jigsaw puzzles and games whose packaging has been opened; anything bought in the clearance section; newspapers and magazines.
```

**O resumo é uma lista de três tipos de item, e nada diz o que é a lista.** A frase de abertura, "The
following cannot be returned unless they arrive damaged or faulty", não passou no corte, e com ela foram
embora a regra e a exceção. O primeiro item, exemplares personalizados e autografados, também foi. Quem
lê o resumo tem três coisas e nenhuma ideia de se podem ou não ser devolvidas.

```
ana@lab:~/rag$ python policy.py "Gifts" 25
The person who received a gift can return it with the gift receipt and gets store credit for the price paid, without the buyer being told. To get the money back on the original card instead, the buyer has to start the return from their own account.
summary:
To get the money back on the original card instead, the buyer has to start the return from their own account.
```

"Instead" de quê? A frase de que ele dependia, a de que quem recebeu o presente ganha crédito na loja,
não está lá, então o resumo parece uma instrução completa sobre reembolsos e trata da exceção.

Destas e das seções anteriores, as coisas que uma compactação precisa manter, ou manter juntas:

- **Identificadores e números**: números de pedido, valores, datas, prazos. São ditos uma vez e
  necessários com exatidão.
- **Negações e condições**: *not*, *unless*, *only*, *except*. Perder uma inverte a frase.
- **Referências com aquilo a que se referem**: *it*, *them*, *instead*, *the other*. Uma frase que
  aponta para trás só é verdadeira ao lado do que aponta.
- **Escolhas e instruções da pessoa**: o que ela pediu e como falar com ela.
- **Tudo o que uma resposta já citou.** Se uma resposta citou uma fonte como [2], o contexto compactado
  ainda precisa deixar o [2] ser conferido, ou a verificação da aula 7 não tem o que verificar.
