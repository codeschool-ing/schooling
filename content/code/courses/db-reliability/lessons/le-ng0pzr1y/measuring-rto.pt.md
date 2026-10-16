---
title: Medindo quanto tempo leva o caminho de volta
version: 1
---

O tempo de uma restauração tem uma parte que cresce com o tamanho do banco e uma parte que cresce com
o quanto aconteceu desde o último backup. O ensaio da lição 7 mediu a primeira: alguns segundos para
copiar os arquivos de volta. A segunda é a reaplicação do log, e é ela que surpreende, porque depende
de quão movimentado o banco estava, e não de quão grande ele é.

Deixe o irmão maior do shop movimentado. Dois updates em cada um dos seus três milhões de pedidos, com
a posição do log registrada antes:

```
bigshop=# SELECT pg_current_wal_lsn() AS before \gset
bigshop=# \timing on
Timing is on.

bigshop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 3000000
Time: 32822.988 ms (00:32.823)

bigshop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 3000000
Time: 37569.963 ms (00:37.570)

bigshop=# \timing off
Timing is off.

bigshop=# SELECT pg_size_pretty(pg_current_wal_lsn() - :'before');
 pg_size_pretty 
----------------
 2411 MB
(1 row)
```

**2411 MB de write-ahead log** em uns setenta segundos de trabalho, mais de sete vezes o tamanho dos
dados que mudaram, pelos motivos que a lição 4 deu. Um backup full foi feito antes desses updates,
então uma restauração até agora tem que reaplicar tudo isso. O ensaio da lição 7 faz exatamente isso,
e a linha dele diz quanto tempo levou cada fase:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main check
ana@vm:~$ ./restore-drill.sh
2026-10-10 22:48:28,20261010-224434F,4.2,55.3,9.2,79.7,ok
```

**4,2 segundos para copiar os arquivos de volta, 55,3 segundos para reaplicar**, e 9,2 para provar o
resultado. A reaplicação é onde o tempo foi parar: uns **44 MB de log por segundo**, nesta máquina,
buscados do repositório, descomprimidos e aplicados. Essa taxa é o número que transforma um volume de
log num tempo.

## De uma medição para a promessa

Suponha que o shop de verdade escreva 20 GB de log num dia movimentado e faça backup full só aos
domingos. Uma falha de disco no sábado à noite significa reaplicar quase uma semana disso:

| | log a reaplicar | a 44 MB/s |
|---|---|---|
| backup full semanal, mais nada | até uns 140 GB | uns 54 minutos |
| mais um diferencial toda noite | até uns 20 GB | uns 8 minutos |

A primeira linha sozinha já pode passar do que um RTO de uma hora deixa de espaço, depois de somados
perceber, decidir e reconectar. A segunda vem de uma única linha a mais na rotina noturna. Nenhum dos dois
números é chute: o volume vem das próprias posições de log do banco, e a taxa, de uma reaplicação
cronometrada de log real em hardware real.

Dois cuidados com a conta. **Meça no hardware que vai restaurar**, já que um servidor de restauração
menor que o que está sendo substituído reaplica mais devagar. E **meça num dia movimentado**, porque
um RTO é prometido para o pior dia, não para o dia médio.
