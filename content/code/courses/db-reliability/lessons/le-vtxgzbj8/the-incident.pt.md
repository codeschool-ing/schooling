---
title: Detectar e decidir
version: 1
---

O cluster das lições 16 a 19: três nós Patroni com `pg1` como líder, o HAProxy na frente na porta
5000, e o `orders.sh` da lição 19 fazendo um pedido por segundo através dele. Ligue o shop e, oito
segundos depois, mate o líder como uma máquina morta faria, anotando a hora:

```
ana@vm:~$ ./orders.sh > orders.log 2>&1 &
ana@vm:~$ date +%T; pkill -9 -f 'patroni/pg1[.]yml'; kill -9 $(head -n 1 ~/patroni/pg1/postmaster.pid)
02:47:32
```

## Detectar

Nada neste laboratório chamou ninguém. O que os clientes viram está em `orders.log`:

```
ana@vm:~$ grep -c ok orders.log; grep -c FAILED orders.log
14
26
ana@vm:~$ grep -m 1 FAILED orders.log; grep FAILED orders.log | tail -n 1; grep -A 1 FAILED orders.log | tail -n 1
02:47:35 FAILED
02:48:01 FAILED
02:48:02 ok on 5442
ana@vm:~$ patronictl -c ~/patroni/pg2.yml list
+ Cluster: shop (7697137969997383883) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg2    | 127.0.0.1:5442 | Leader  | running   |  2 |           |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  2 |         0 |
+--------+----------------+---------+-----------+----+-----------+
```

**26 pedidos falharam e 14 passaram.** A primeira falha foi às 02:47:35, três segundos depois do
kill; a última às 02:48:01; o pedido seguinte, às 02:48:02, foi para o `pg2` na porta 5442. E o
`patronictl` mostra o `pg2` como líder na timeline 2, o `pg3` seguindo ele, e o `pg1` ausente.

Num shop de verdade, o primeiro sinal teria sido uma de três coisas: um alerta (a checagem da lição 13,
ou a troca de primário no HAProxy), um cliente, ou um engenheiro que por acaso estava olhando. Só a
primeira é um plano, e o relatório pós-incidente vai perguntar qual delas foi.

## Decidir

O Patroni tomou a decisão urgente sozinho, meio minuto depois do kill. O que sobra para as pessoas é
tudo o que ele não sabe:

- **Acabou?** O shop voltou a aceitar pedidos. Ainda tem alguma outra coisa errada, como uma réplica
  atrasada demais, ou um disco enchendo com o log que o slot de um nó morto segura (lição 11)?
- **O que se perdeu?** A pergunta da lição 12: qualquer coisa com commit no `pg1` que o `pg2` nunca
  recebeu. Com réplicas assíncronas, a resposta honesta vem das posições e dos registros do próprio shop.
- **E o `pg1`?** Trazer de volta agora, ou deixar parado até alguém saber por que a máquina dele morreu.
  Um nó que falhou por um motivo ainda não entendido pode falhar de novo no meio da recuperação.
- **Quem precisa saber?** O suporte, antes que as mensagens dos clientes cheguem; os responsáveis pela
  aplicação, de quem eram esses erros.

Cada decisão entra na nota corrente com a sua hora. Decidir esperar é uma decisão, e é anotado como
uma.
