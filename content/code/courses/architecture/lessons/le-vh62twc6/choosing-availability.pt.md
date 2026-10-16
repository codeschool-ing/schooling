---
title: Escolhendo disponibilidade: replicação assíncrona
version: 1
---

Com **replicação assíncrona**, o padrão, o primário grava localmente, avisa o cliente na hora, e manda a
mudança ao standby depois. Volte para ela, isole o standby de novo, e venda mais um pacote:

```
ana@vm:~/lab/cap$ $P -c "ALTER SYSTEM RESET synchronous_standby_names" -c "SELECT pg_reload_conf()"
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@vm:~/lab/cap$ docker network disconnect cap_default cap-standby-1
ana@vm:~/lab/cap$ time $P -c "UPDATE stock SET units = 10 WHERE sku = 'coffee'"
UPDATE 1

real	0m0.240s
user	0m0.083s
sys	0m0.056s
ana@vm:~/lab/cap$ $P -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    10
(1 row)

ana@vm:~/lab/cap$ $S -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    11
(1 row)
```

Desta vez a atualização voltou na hora: `UPDATE 1`, numa fração de segundo, com o standby inalcançável.
**O primário continuou disponível para escritas**, e o preço aparece nas duas linhas seguintes: o primário
diz 10 e o standby, ainda respondendo leituras, diz 11. Um cliente que lê do standby durante a partição
fica sabendo que há 11 pacotes de café, o que deixou de ser verdade um instante atrás.

Essa é a escolha **A**: todo nó continua respondendo, e as respostas podem discordar. Reconecte:

```
ana@vm:~/lab/cap$ docker network connect cap_default cap-standby-1
ana@vm:~/lab/cap$ $S -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    10
(1 row)
```

O standby reaplicou o que tinha perdido e concorda de novo, que é o **eventual** de consistência
eventual: quando a partição acaba e as mudanças param, as cópias convergem. A aula 9 trata do que
acontece no meio disso, quando um cliente está olhando.

## O outro custo: o que um failover perde

A replicação assíncrona tem um segundo preço que o laboratório não mostrou, e é o que as pessoas
descobrem do jeito difícil. Se o primário se perde de vez enquanto o standby está atrasado, e o standby é
promovido a novo primário, **toda mudança que o primário antigo tinha confirmado e ainda não tinha mandado
some**. Os clientes foram avisados de que essas escritas estavam gravadas. A quantidade em risco é o
atraso de replicação no momento da falha, que a aula 10 mostra como medir.

| | síncrona | assíncrona |
| --- | --- | --- |
| uma escrita durante uma partição | espera, talvez para sempre | dá certo na hora |
| leituras do standby durante uma partição | o mesmo valor do primário | possivelmente velho |
| o primário perdido de vez | nada do que um cliente foi avisado se perde | até o atraso de replicação se perde |
| uma escrita sem partição | uma ida e volta a mais | nenhuma espera extra |

A última linha é a próxima seção.
