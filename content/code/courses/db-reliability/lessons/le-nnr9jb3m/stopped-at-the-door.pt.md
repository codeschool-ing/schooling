---
title: Um ensaio que se recusa a começar
version: 1
---

Teste o aborto primeiro, de propósito. Pare o `pg3` de forma limpa, para que o cluster fique com só
dois nós, e rode o ensaio:

```
ana@vm:~$ pkill -TERM -f 'patroni/pg3[.]yml'
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697144668418349739) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  1 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  1 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | stopped   |    |   unknown |
+--------+----------------+---------+-----------+----+-----------+
ana@vm:~$ ./rehearsal.sh; echo "exit $?"
ABORT: 3 members, 2 healthy, lag 999 MB, leader pg1
exit 1
```

O `pg3` está `stopped`, com atraso `unknown`, e o script **recusou**, com status de saída 1, antes de
mexer em qualquer coisa: dois membros saudáveis de três, e um atraso que ele não conseguiu ler, contado
como 999. Matar o líder agora teria deixado um nó só, e a próxima falha de qualquer coisa teria parado
o shop.

O atraso contado como 999 é uma decisão escrita no script depois que ele errou. A primeira versão lia o
atraso do `patronictl` como número, deu com a palavra `unknown`, e a linha de Python falhou sem
imprimir nada. As checagens do shell então compararam strings vazias, reclamaram e **seguiram em
frente**: iniciaram o `orders.sh`, tentaram matar um líder cujo nome já não tinham e reportaram uma
execução saudável. Uma proteção que falha aberta é pior do que nenhuma, porque as pessoas acreditam
nela. A versão acima para diante de qualquer coisa que não consiga ler, que é a única leitura segura
de "não sei".

Deixe o cluster inteiro de novo antes da execução de verdade:

```
ana@vm:~$ patroni ~/patroni/pg3.yml > ~/patroni/pg3.log 2>&1 &
ana@vm:~$ patronictl -c ~/patroni/pg1.yml list
+ Cluster: shop (7697144668418349739) ----------+----+-----------+
| Member | Host           | Role    | State     | TL | Lag in MB |
+--------+----------------+---------+-----------+----+-----------+
| pg1    | 127.0.0.1:5441 | Leader  | running   |  1 |           |
| pg2    | 127.0.0.1:5442 | Replica | streaming |  1 |         0 |
| pg3    | 127.0.0.1:5443 | Replica | streaming |  1 |         0 |
+--------+----------------+---------+-----------+----+-----------+
```
