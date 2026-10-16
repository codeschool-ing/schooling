---
title: O mesmo número, para quem perguntar
version: 1
---

O objetivo da camada é que uma pergunta tenha uma resposta. A receita líquida do primeiro trimestre
de 2026, perguntada a `semantic.orders`, e perguntada de novo depois de mudar a sessão para UTC:

```
lantern=# SELECT sum(net_revenue) FROM semantic.orders
lantern-# WHERE order_date BETWEEN '2026-01-01' AND '2026-03-31';
    sum    
-----------
 294209.60
(1 row)

lantern=# SET timezone = 'UTC';
SET

lantern=# SELECT sum(net_revenue) FROM semantic.orders
lantern-# WHERE order_date BETWEEN '2026-01-01' AND '2026-03-31';
    sum    
-----------
 294209.60
(1 row)
```

R$ 294.209,60 nas duas vezes — o mesmo número a que o financeiro chegou na ponte da aula 2, ao
centavo, porque a camada aplica as mesmas cinco partes. E o fuso não o moveu. A aula 2 mostrou que a
mesma pergunta feita a `shop.orders` muda quando muda o fuso da sessão, porque `ordered_at::date` é
calculado no fuso em que a sessão está. O `order_date` da camada é calculado com `AT TIME ZONE
'America/Sao_Paulo'` escrito na view, então **a definição vale até para um cliente que define o
próprio fuso** — o que ferramentas de BI fazem, e é exatamente onde uma configuração no banco deixa
de bastar.

Esse é o teste a aplicar a qualquer coisa numa camada: **pergunte do jeito que um cliente
descuidado perguntaria.** Uma sessão em outro fuso, um join com outra tabela, um filtro esquecido.
As respostas que ficam paradas são definições; as que se mexem ainda são o hábito de alguém.

O mapeamento de regiões passa no mesmo teste por outro motivo. Agora ele é uma tabela, então um
gráfico por região no Metabase e uma consulta por região no `psql` leem as mesmas sete linhas, e não
existe um segundo `CASE` em lugar nenhum para discordar dele.
