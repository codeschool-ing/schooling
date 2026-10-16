---
title: Medindo um disco do jeito que um banco o usa
version: 1
---

O número na caixa de um disco, e o que uma cópia de arquivo mostra, é **vazão**: megabytes por
segundo de escritas grandes. Um banco confirmando transações faz outra coisa. Cada commit espera até
que o seu registro no WAL esteja em armazenamento estável, o que a lição 8 mostrou ser um flush, e
**a pergunta é quantos flushes por segundo o disco consegue fazer**, cada um de poucos kilobytes. Um
disco pode ser ótimo na primeira coisa e fraco na segunda, e é na segunda que um servidor ocupado
espera.

O PostgreSQL traz uma ferramenta que faz exatamente essa pergunta, o `pg_test_fsync`. No Ubuntu ela
fica em `/usr/lib/postgresql/16/bin`, que não está no seu `PATH`. Rode-a como `postgres`, no sistema
de arquivos que você quer medir, que aqui é o do diretório de dados. O `-s 2` faz cada teste durar
dois segundos em vez de cinco:

```
ana@db:~$ sudo -u postgres /usr/lib/postgresql/16/bin/pg_test_fsync -s 2 -f /var/lib/postgresql/fsync-test
2 seconds per test
O_DIRECT supported on this platform for open_datasync and open_sync.

Compare file sync methods using one 8kB write:
(in wal_sync_method preference order, except fdatasync is Linux's default)
        open_datasync                      2709.405 ops/sec     369 usecs/op
        fdatasync                          2315.189 ops/sec     432 usecs/op
        fsync                              1903.340 ops/sec     525 usecs/op
        fsync_writethrough                              n/a
        open_sync                           513.860 ops/sec    1946 usecs/op

Compare file sync methods using two 8kB writes:
(in wal_sync_method preference order, except fdatasync is Linux's default)
        open_datasync                      1098.451 ops/sec     910 usecs/op
        fdatasync                          2213.200 ops/sec     452 usecs/op
        fsync                              1530.893 ops/sec     653 usecs/op
        fsync_writethrough                              n/a
        open_sync                           806.941 ops/sec    1239 usecs/op

Compare open_sync with different write sizes:
(This is designed to compare the cost of writing 16kB in different write
open_sync sizes.)
         1 * 16kB open_sync write          1654.578 ops/sec     604 usecs/op
         2 *  8kB open_sync writes          793.674 ops/sec    1260 usecs/op
         4 *  4kB open_sync writes          427.897 ops/sec    2337 usecs/op
         8 *  2kB open_sync writes          154.827 ops/sec    6459 usecs/op
        16 *  1kB open_sync writes           38.936 ops/sec   25683 usecs/op

Test if fsync on non-write file descriptor is honored:
(If the times are similar, fsync() can sync data written on a different
descriptor.)
        write, fsync, close                 844.708 ops/sec    1184 usecs/op
        write, close, fsync                1090.900 ops/sec     917 usecs/op

Non-sync'ed 8kB writes:
        write                           2317460.087 ops/sec       0 usecs/op
```

**Estes são os números da máquina de gravação, e os seus serão diferentes.** Aquela máquina é um
contêiner num disco virtual compartilhado com outras máquinas, então os resultados mudam de uma
execução para outra, e uma segunda execução não imprimiria esta tabela de novo. Meça o seu próprio
disco; nunca planeje a partir do disco de outra pessoa.

## Lendo a saída

Cada linha é um jeito de pedir ao kernel que torne uma escrita durável, e os nomes são os valores do
parâmetro `wal_sync_method`. A linha a ler primeiro é **`fdatasync`, o padrão do Linux e o que o seu
servidor usa**: 2315,189 flushes por segundo, 432 microssegundos cada, nesta máquina. Uma
sessão confirmando uma transação por vez nunca consegue, portanto, confirmar mais rápido do que
isso, faça o processador o que fizer. Muitas sessões juntas vão melhor, porque um flush pode levar
os registros de várias transações de uma vez.

A última linha é o contraste. **Uma escrita sem flush cai na memória do kernel**, e 2.317.460 delas
cabem num segundo. Toda linha acima dela é mais lenta por essa distância inteira porque espera pelo
disco. Um `wal_sync_method` diferente pode ser mais rápido em algum hardware, e a primeira tabela é
como você descobriria; deixe o padrão, a não ser que a ferramenta mostre uma diferença grande e que
se repete.

## Um disco que diz sim depressa demais

Um flush é uma promessa de que os dados vão sobreviver a uma queda de energia, e há armazenamento
que faz a promessa sem cumpri-la: um disco ou controlador com um cache de escrita que responde
"pronto" assim que os dados chegam a esse cache. O jeito de reconhecê-lo é que os números dele são
bons demais. Aqui está o mesmo teste num sistema de arquivos que mora inteiro na memória, um
`tmpfs`, que nunca consegue cumprir a promessa:

```
ana@db:~$ sudo mkdir /mnt/ram && sudo mount -t tmpfs -o size=64M tmpfs /mnt/ram && sudo chmod 1777 /mnt/ram
ana@db:~$ sudo -u postgres /usr/lib/postgresql/16/bin/pg_test_fsync -s 2 -f /mnt/ram/fsync-test | head -10
2 seconds per test
O_DIRECT supported on this platform for open_datasync and open_sync.

Compare file sync methods using one 8kB write:
(in wal_sync_method preference order, except fdatasync is Linux's default)
        open_datasync                   1742913.899 ops/sec       1 usecs/op
        fdatasync                       1436133.751 ops/sec       1 usecs/op
        fsync                           1583709.527 ops/sec       1 usecs/op
        fsync_writethrough                              n/a
        open_sync                       1978531.208 ops/sec       1 usecs/op
```

Bem mais de um milhão de flushes por segundo é a cara de um flush para lugar nenhum. **Um disco de
verdade que mostra números nessa faixa está cumprindo a promessa em memória volátil**, e uma queda
de energia ali perde transações confirmadas sem nada no log que diga isso. A versão legítima é um
controlador cujo cache tem uma bateria ou um capacitor atrás, que é rápido porque consegue terminar
a escrita depois que a energia acabou. Sem isso, a solução é desligar o cache de escrita do disco, e
o preço é o número mais lento, que era o verdadeiro desde o começo.

Desmonte o sistema de arquivos de teste quando terminar:

```
ana@db:~$ sudo umount /mnt/ram && sudo rmdir /mnt/ram
```
