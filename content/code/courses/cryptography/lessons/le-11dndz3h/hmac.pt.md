---
title: HMAC, um hash com uma chave dentro
version: 1
---

**Um HMAC é um hash calculado sobre uma mensagem junto com uma chave secreta, de modo que só quem
tem a chave consegue calculá-lo ou conferi-lo.** Ele é definido na RFC 2104 e funciona com
qualquer hash; o HMAC-SHA256 é a escolha comum. A saída se chama **etiqueta** (*tag*), e é o que o
gateway manda com cada mensagem.

## A etiqueta da mensagem real, e da forjada

Com a chave compartilhada em `keys/webhook.hex`, a etiqueta do aviso genuíno:

```
ana@lab:~/lab$ openssl dgst -sha256 -mac HMAC -macopt hexkey:$(cat keys/webhook.hex) data/webhooks/evt-1.json
HMAC-SHA2-256(data/webhooks/evt-1.json)= 2e62aade7c551522eb97c60dee626384a62e4926bef81ea646754f0c9847c6d1
```

E a etiqueta do forjado, com o valor mudado para 120:

```
ana@lab:~/lab$ openssl dgst -sha256 -mac HMAC -macopt hexkey:$(cat keys/webhook.hex) forged.json
HMAC-SHA2-256(forged.json)= 0936c48c8fb16e7785b635099d19463cda9f35509653dc882df41caff39c9b2f
```

As duas etiquetas não têm relação, como o efeito avalanche da aula 4 prometeu. O que importa é quem
consegue produzi-las. O falsificador tem o corpo forjado, mas não a chave da Vereda. Se ele calcular
um HMAC com qualquer outra chave, aqui a chave AES do laboratório fazendo o papel de um palpite,
obtém uma terceira etiqueta, igualmente sem relação:

```
ana@lab:~/lab$ openssl dgst -sha256 -mac HMAC -macopt hexkey:$(cat keys/aes-256.hex) forged.json
HMAC-SHA2-256(forged.json)= d473f2538cbcbb4d33f8ca0aafac5df230279de37cc172be85ac5346f604ea35
```

Ela não bate com o que o portal calcula com a chave real, então a mensagem forjada é recusada.
**Sem a chave, não há como produzir a etiqueta certa para uma mensagem alterada**, e com uma chave
de 256 bits não há como adivinhá-la.

## Por que não simplesmente SHA-256(chave + mensagem)?

Parece equivalente e não é. A aula 4 descreveu a propriedade de extensão de comprimento do SHA-256:
quem conhece o resumo de uma mensagem consegue calcular o resumo dessa mensagem com bytes
acrescentados, sem conhecer a mensagem. Com a chave na frente, isso significa estender a mensagem e
produzir uma verificação válida **sem a chave**. O HMAC evita isso calculando o hash duas vezes, com
a chave misturada nas duas de um jeito fixo:

```
HMAC(K, m) = H( (K xor opad) || H( (K xor ipad) || m ) )
```

`ipad` e `opad` são duas constantes fixas, e `||` é concatenação. Ninguém precisa decorar a
fórmula. O que vale lembrar é a conclusão: **nunca monte você mesmo uma verificação com chave a
partir de um hash simples.** Toda linguagem tem HMAC na biblioteca padrão (`hmac` no Python,
`crypto/hmac` no Go, `javax.crypto.Mac` no Java, `crypto.createHmac` no Node), e ele é a
ferramenta certa.

## O que um MAC não dá

Um HMAC prova que a mensagem veio de alguém que tem a chave. Com uma chave compartilhada entre duas
partes, isso significa "do gateway, ou da própria Vereda". Para um webhook isso basta: a Vereda
confia em si mesma. Para uma disputa com um terceiro não basta, porque a Vereda poderia ter
produzido qualquer etiqueta que mostrar. Quando isso importa, a resposta é uma assinatura, na
seção 05.

O AES-GCM, da aula 1, contém um MAC próprio, a etiqueta que recusou o arquivo alterado. É a mesma
ideia embutida numa cifra: cifragem mais uma verificação com chave, sob uma única chave.
