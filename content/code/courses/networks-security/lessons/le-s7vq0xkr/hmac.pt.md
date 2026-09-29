---
title: Um hash com chave entre dois sistemas que compartilham um segredo
version: 1
---

Um hash não tem chave, então qualquer um pode calculá-lo. Acrescente uma chave e só quem a tem
consegue: isso é um **HMAC**, um código de autenticação de mensagem baseado em hash. Ele prova que uma
mensagem veio de alguém que conhece o segredo e não foi alterada no caminho.

O uso do dia a dia é um **webhook**. Um provedor de pagamentos avisa a loja de que o pedido 17 foi pago
enviando uma requisição ao servidor da loja, e assina o corpo com um segredo que os dois combinaram
quando a integração foi configurada. A loja calcula o mesmo HMAC sobre o corpo que recebeu, com a sua
cópia do segredo, e compara:

```
ana@laptop:~$ printf "order=17&status=paid" | openssl dgst -sha256 -hmac "shared-webhook-secret"
SHA2-256(stdin)= 263351323f062f7dcf2f5eefc9c7429d1833ab81eebebb33976d309d94db5d0b
```

Com o segredo errado, o valor não tem nada em comum com o certo:

```
ana@laptop:~$ printf "order=17&status=paid" | openssl dgst -sha256 -hmac "a-guessed-secret"
SHA2-256(stdin)= 05fcb886ae5dfd8a2a1a069e989254211bcde9a86da7509b3b579b58f20f6361
```

Então uma requisição ao webhook da loja dizendo `status=paid` é aceita **só se o HMAC dela bater**. Sem
essa conferência, qualquer um que descubra o endereço do webhook pode marcar pedidos como pagos,
porque a requisição não precisa de senha e o endereço não é segredo.

Dois detalhes decidem se uma conferência de HMAC é sólida:

- **Comparar em tempo constante.** Uma comparação que para no primeiro byte diferente responde mais
  rápido para um palpite que compartilha um prefixo mais longo, e esse tempo vaza o valor byte a byte.
  As bibliotecas oferecem uma comparação que sempre leva o mesmo tempo, como a `hmac.compare_digest`
  em Python.
- **Incluir o que não pode ser reenviado.** Um HMAC só sobre o corpo deixa alguém reenviar a
  requisição legítima de ontem. Os provedores acrescentam um carimbo de tempo (*timestamp*) ao que é
  assinado e rejeitam os antigos.

O HMAC tem a limitação de todo segredo compartilhado: **os dois lados conseguem criar códigos
válidos**, então ele prova que a mensagem veio de um dos dois, não de qual. Quando um terceiro precisa
conseguir conferir quem assinou, a ferramenta é uma assinatura.
