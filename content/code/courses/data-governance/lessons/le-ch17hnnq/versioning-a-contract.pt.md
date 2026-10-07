---
title: Versionando um contrato
version: 1
---

Um contrato que nunca pode mudar é um contrato que ninguém vai assinar. O dado precisa evoluir; o ponto
do contrato é que ele evolua **sem surpreender ninguém**. A maioria dos times empresta o versionamento
semântico do software, com as regras escritas para dados:

| mudança | versão | por quê |
|---|---|---|
| um campo opcional novo no fim | **minor**: 1.0.0 → 1.1.0 | um consumidor que ignora campos desconhecidos continua funcionando |
| a correção de uma descrição, uma regra de qualidade mais rígida | **patch**: 1.0.0 → 1.0.1 | nada que o consumidor lê muda |
| um campo removido ou renomeado | **major**: 1.0.0 → 2.0.0 | todo consumidor que o lê quebra |
| um tipo mudado | **major** | a leitura, a soma, a comparação podem mudar |
| um sentido mudado com o nome mantido | **major**, e a mais perigosa | nada quebra, tudo está errado |

A última linha é a segunda quebra da seção 6. Uma mudança de sentido é sempre major, mesmo quando o
esquema é idêntico byte a byte, e é exatamente por isso que ela tem de estar descrita em palavras em
algum lugar que um revisor lê.

## Duas versões ao mesmo tempo

Uma mudança major não se faz editando a view. Ela se faz **publicando a versão nova ao lado da antiga**
— `share.delivery_feed_v2` ao lado de `share.delivery_feed` —, anunciando uma data, e removendo a antiga
quando todo consumidor tiver migrado. Por um tempo, as duas existem e as duas são conferidas contra os
seus contratos. Custa uma view e algumas semanas; a alternativa custa uma manhã de vans carregadas para
metade das encomendas.

## Mudanças de privacidade também são major

Um campo que acrescenta dado pessoal, uma finalidade nova, uma retenção mais longa no consumidor, um
país novo: cada um muda o que a Ipê está compartilhando e por quê. Pelas regras deste curso elas são
mudanças **major** mesmo que nenhum código de consumidor quebre, porque precisam da decisão do dono e,
muitas vezes, do encarregado — e porque, para um operador como a Rota Certa, elas são mudanças nas
instruções da Ipê, que é o que o artigo 39 obriga o operador a seguir.
