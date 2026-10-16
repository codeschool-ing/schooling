---
title: Ler a própria escrita
version: 1
---

O atraso não faz mal à maioria das leituras. Uma página de produto que mostra um preço de dois
segundos atrás, um relatório que perde o último minuto: ninguém percebe. A leitura que não pode
estar atrasada é a que vem **logo depois da escrita da mesma pessoa**. Um cliente cancela um pedido,
a página recarrega, e o pedido continua pendente. Ele clica em cancelar de novo. Para ele a loja está
quebrada, e ele tem razão. A propriedade que ele esperava tem nome, **ler a própria escrita**
(read-your-own-writes), e uma réplica não a oferece.

A crença errada aqui é a de que o atraso é pequeno o bastante para ignorar se costuma ser de poucos
milissegundos. O "costuma" é o problema: recarregar uma página leva cem milissegundos, e na primeira
vez que um `UPDATE` grande ou uma rede lenta deixa a réplica um segundo atrás, todo usuário que
escreveu algo naquele segundo vê o passado.

## Velho, em três comandos

A réplica está dez segundos atrás, desde a última seção. O pedido 1999990 está pendente. Cancele-o
no primário e leia de volta na réplica na hora, e de novo depois de dez segundos:

```
ana@vm:~$ psql market -c "SELECT id, status FROM orders WHERE id = 1999990"
   id    | status  
---------+---------
 1999990 | pending
(1 row)

Time: 1.212 ms
ana@vm:~$ psql market -c "UPDATE orders SET status = 'cancelled' WHERE id = 1999990"
UPDATE 1
Time: 2.516 ms
ana@vm:~$ psql -p 5433 market -c "SELECT id, status FROM orders WHERE id = 1999990"
   id    | status  
---------+---------
 1999990 | pending
(1 row)

Time: 3.713 ms
ana@vm:~$ psql -p 5433 market -c "SELECT id, status FROM orders WHERE id = 1999990"
   id    |  status   
---------+-----------
 1999990 | cancelled
(1 row)

Time: 0.985 ms
```

O `UPDATE` relatou sucesso, e **a réplica respondeu `pending`** já no comando seguinte. Dez
segundos depois, ela diz `cancelled`. Nada falhou e nada se perdeu: a réplica estava certa sobre um
momento que tinha passado, e um usuário olhando para ela estaria errado sobre o presente.

## Dois jeitos de devolver isso

**Ler do primário por um tempo depois de escrever.** A aplicação lembra, por usuário, quando ele
escreveu pela última vez, na sessão ou num cookie, e manda as leituras desse usuário para o primário
por uma janela depois disso: alguns segundos, mais que o atraso que você espera. É simples e é a
resposta mais comum. A fraqueza é a janela: ela é um palpite sobre o atraso, e no dia em que o
atraso passa dela, a leitura velha volta. Ela também manda para o primário justamente as leituras
dos usuários mais ativos.

**Esperar até a réplica ter reaplicado a escrita.** Todo commit tem uma posição no WAL, e o primário
diz qual é com `pg_current_wal_lsn()` logo depois da escrita. Uma réplica diz até onde reaplicou com
`pg_last_wal_replay_lsn()`. Quando a segunda está na primeira ou além dela, a réplica tem a escrita,
e uma leitura ali é segura. O script abaixo faz exatamente isso: cancela um pedido no primário,
guarda a posição e consulta a réplica até ela alcançar, antes de ler:

```sh
cat > ~/read-your-write.sh <<'SH'
#!/bin/sh
# read-your-write.sh ORDER_ID: cancel an order on the primary, then read it
# back from the replica, but only once the replica has replayed the write.
set -e
lsn=$(psql -XAtq market \
        -c "UPDATE orders SET status = 'cancelled' WHERE id = $1" \
        -c "SELECT pg_current_wal_lsn()")
echo "written at $lsn"
checks=0
until [ "$(psql -XAtq -p 5433 market \
             -c "SELECT pg_last_wal_replay_lsn() >= '$lsn'")" = t ]; do
    checks=$((checks + 1))
    sleep 0.2
done
echo "replica caught up after $checks checks, 0.2 s apart"
psql -XAtq -p 5433 market -c "SELECT id, status FROM orders WHERE id = $1"
SH
chmod +x ~/read-your-write.sh
```

O `-XAtq` são quatro opções do `psql` juntas: sem `~/.psqlrc` (então sem linhas `Time:`), sem
alinhamento, só as linhas, silencioso. Isso deixa a saída um valor puro que o shell consegue
comparar. Rode-o com outro pedido pendente:

```
ana@vm:~$ ~/read-your-write.sh 1999991
written at 1A/7003B68
replica caught up after 42 checks, 0.2 s apart
1999991|cancelled
```

**42 verificações, a 0,2 segundo uma da outra**: o script esperou um pouco menos de dez segundos,
que é o atraso, e então a réplica devolveu `cancelled`, nunca o valor velho. O custo é essa espera.
Com um atraso normal é uma verificação; com dez segundos de atraso o usuário espera dez segundos, e
uma aplicação de verdade precisa de um limite, depois do qual desiste da réplica e lê do primário.

A posição não precisa ser verificada por um script. Uma aplicação pode devolvê-la ao navegador na
resposta a uma escrita, e recebê-la de volta na leitura seguinte. Essa leitura então espera por ela
ou vai ao primário: a mesma ideia, levada pelas próprias requisições do usuário, sem palpite sobre o
tamanho do atraso.

## Quais leituras podem ir para uma réplica

As duas respostas consertam uma leitura depois de uma escrita da mesma pessoa. Não deixam uma réplica
segura para leituras que **decidem** alguma coisa. Conferir o estoque antes de vender a última
unidade, conferir um saldo antes de um saque, conferir que um e-mail está livre antes de criar uma
conta: essas leem e depois agem, e agir sobre um momento que passou vende a mesma unidade duas
vezes. Elas pertencem ao primário, na mesma transação que a escrita, onde valem os níveis de
isolamento da aula 14.

Uma réplica serve para o resto, que é a maior parte do tráfego de uma loja: navegar, buscar,
relatórios, painéis, e tudo o que um usuário lê e não acabou de mudar. Separe as leituras nesses dois
tipos antes de apontar qualquer coisa para uma réplica, porque o código que manda uma consulta para
algum lugar é o único lugar onde a decisão pode morar.
