---
title: O reparo, e o que custa um ponto no tempo
version: 1
---

Agora existem dois shops. O de produção tem os três pedidos que chegaram depois do `DELETE`, e está
sem doze mil pedidos mais antigos. O restaurado tem os doze mil e não tem os três. Uma recuperação
para um ponto no tempo te entrega essa escolha, e há dois jeitos de fazê-la.

**Substituir o banco de produção pelo restaurado.** Tudo o que foi escrito depois do alvo se perde:
aqui, três pedidos; num shop de verdade, cada pedido, pagamento e cadastro desde o erro. Isso é o
certo quando o erro foi tão amplo (um schema apagado, uma tabela corrompida) que nada depois dele
merece confiança, e é a única opção quando o servidor de produção se foi de vez.

**Reparar o banco de produção a partir do restaurado.** A cópia restaurada é usada como a lição 2
usou uma cópia lateral: como fonte das linhas que se perderam, copiadas de volta para o banco de
produção, que mantém tudo o que veio depois. Aqui as linhas perdidas são exatamente os pedidos de
antes de março:

```
ana@vm:~$ psql -p 5433 shop -c "\copy (SELECT * FROM orders WHERE placed_at < '2026-03-01') TO 'deleted.csv' CSV"
COPY 12059
ana@vm:~$ psql shop -c "\copy orders FROM 'deleted.csv' CSV"
COPY 12059
ana@vm:~$ psql shop -c "SELECT count(*), min(placed_at) FROM orders"
 count |          min           
-------+------------------------
 50008 | 2026-01-01 09:07:00-03
(1 row)
```

**50008 pedidos, desde 1º de janeiro**: os cinquenta mil, os cinco antes do erro e os três depois
dele. O reparo levou o shop de volta ao que ele deveria ser e não perdeu nada.

Foi fácil porque o `DELETE` só atingiu linhas que nada mais tinha tocado desde então. Num banco de
verdade, as linhas que um erro estragou muitas vezes são alteradas de novo depois, referenciadas por
linhas novas ou contadas em totais que alguém já reportou, e o reparo vira um conjunto de consultas
que juntam as duas cópias e precisam ser conferidas por uma pessoa. A cópia restaurada é o que torna
essas consultas possíveis. **Sem ela, a única pergunta que dá para responder é quanto se perdeu.**

Qual caminho seguir é uma decisão, e em geral não cabe só ao administrador de banco de dados: ela
troca os dados escritos depois do erro pelo tempo que um reparo cuidadoso leva. A lição 22 é sobre
quem toma essa decisão durante um incidente, e como.
