---
title: Tokens
version: 1
---

O banco da Ipê tem tokens desde a primeira aula, e eles são o exemplo mais claro da ideia. Clientes
pagam com cartão, e a tabela de pagamentos nunca viu um número de cartão:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT method, card_token, card_last4, amount_cents FROM sales.payments WHERE method = 'card' ORDER BY order_id LIMIT 3"
SET
 method |      card_token      | card_last4 | amount_cents 
--------+----------------------+------------+--------------
 card   | tok_bbc2f3feed7b87e2 | 1195       |         7970
 card   | tok_7047e508b313e1b0 | 5129       |         1590
 card   | tok_9945210f5943d04f | 4814       |        12730
(3 rows)
```

**`card_token` é um substituto.** O provedor de pagamento recebeu o número do cartão direto do
navegador do cliente, guardou-o no próprio cofre e devolveu à Ipê uma referência aleatória: `tok_`
seguido de dezesseis caracteres hexadecimais. A Ipê consegue cobrar esse cartão de novo enviando o
token ao provedor, estornar, e mostrar ao cliente "o cartão final 1195" — e nunca tem um número que
alguém pudesse usar numa loja.

Isso é **tokenização**, e ela tem três partes:

- **o token** — um valor sem relação calculável com o original: aleatório, ou tirado de um
  contador. Nada em `tok_bbc2f3feed7b87e2` diz que cartão é;
- **o cofre** — o único lugar que mapeia tokens de volta a valores, operado por outra empresa ou por
  um sistema pequeno, separado e muito vigiado;
- **a destokenização** — a operação de pedir o original ao cofre, concedida a quase ninguém, e
  registrada.

O arranjo muda o risco de lugar, de propósito. Números de cartão são regidos pelo padrão da
indústria de cartões, o PCI DSS, e todo sistema que guarda, processa ou transmite um entra no escopo
dele, com as auditorias que vêm junto. **Por nunca receber um número de cartão, o banco da Ipê, os
backups dele e os analistas ficam fora desse escopo.** O cofre do provedor está nele, e isso é
assunto do provedor.

`card_last4` é outra coisa: um valor **truncado**, mantido porque o cliente precisa reconhecer o
próprio cartão. Quatro dígitos de dezesseis identificam um cartão para o dono e para mais ninguém.

## Um cofre que a própria Ipê operaria

O mesmo padrão serve para qualquer valor: uma tabela num schema próprio, com token e valor, legível
por uma função que poucos papéis podem executar, gravando uma linha numa tabela de auditoria a cada
chamada. É o desenho certo quando o original precisa voltar em claro em algum lugar — um documento
mandado a um tribunal, um relatório para a autoridade fiscal — e quem precisa dele são poucos.

Para o CPF, a Ipê não precisa de um cofre desses. O suporte precisa de duas coisas de um CPF:
**lê-lo** para o cliente, o que a coluna cifrada da aula 4 já faz pelo OpenBao, e **achar um
cliente por ele** quando ele o dita. Achar precisa de um substituto que seja *o mesmo toda vez para
o mesmo CPF*, o que um token aleatório não é — e a próxima seção constrói um.
