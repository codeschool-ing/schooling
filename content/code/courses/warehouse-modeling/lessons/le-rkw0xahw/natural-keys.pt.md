---
title: O que há de errado com as chaves que a rede já tem
version: 1
---

Toda linha do banco operacional tem uma chave: `customer_id`, `book_id`, `shop_id`, e o ISBN e o
e-mail também são únicos. O warehouse poderia simplesmente usá-los. A lição 2 deu a cada dimensão uma
chave própria, `book_key` ao lado de `book_id`, e esta seção é o porquê.

Uma chave que vem do negócio ou de um sistema de origem é uma **chave natural**. Quatro coisas
acontecem com chaves naturais ao longo da vida de um warehouse, e cada uma quebra uma tabela fato que
as usasse diretamente.

**Elas mudam.** Um endereço de e-mail identifica um cliente até o cliente arranjar outro:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT changed_at, old_value, new_value FROM staging.customer_changes WHERE field = 'email' ORDER BY change_id LIMIT 2"
┌──────────────────────────┬──────────────────────────────┬─────────────────────────────────┐
│        changed_at        │          old_value           │            new_value            │
│ timestamp with time zone │           varchar            │             varchar             │
├──────────────────────────┼──────────────────────────────┼─────────────────────────────────┤
│ 2024-09-28 14:59:00-03   │ gabriela.barbosa@example.net │ gabriela.barbosa.21@example.net │
│ 2025-12-28 17:42:32-03   │ murilo.alves@example.com     │ murilo.alves.55@example.org     │
└──────────────────────────┴──────────────────────────────┴─────────────────────────────────┘
```

São 825 mudanças assim no histórico da rede. Uma tabela fato com chave de e-mail guardaria os pedidos
do primeiro cliente de antes de setembro de 2024 num endereço e os seguintes em outro, e "quanto este
cliente gastou" precisaria saber dos dois.

**Elas são reaproveitadas.** Uma loja que fecha e uma nova que abre com o mesmo código; um ISBN que uma
editora pequena atribui duas vezes por engano; um código de produto reciclado para outro item anos
depois. As linhas fato de antes e de depois apontam para a mesma chave e significam coisas diferentes.

**Sistemas são trocados.** Quando a rede passar para um novo software de caixa, o sistema novo numera
os clientes a partir de um de novo. O cliente 2123 do sistema antigo e o cliente 2123 do novo são
pessoas diferentes, e um warehouse que usasse só `customer_id` como chave não teria como separar as
vendas deles.

**Várias origens discordam.** O site e um aplicativo de fidelidade podem conhecer o mesmo leitor, cada
um com o seu id. O warehouse deve ser integrado (lição 1), então precisa de uma identidade que não seja
de nenhum dos dois.

**Nos quatro casos, uma chave natural pertence a outra pessoa**, e essa pessoa pode mudá-la por motivos
que não têm nada a ver com o warehouse. O warehouse precisa de chaves que só ele controla.
