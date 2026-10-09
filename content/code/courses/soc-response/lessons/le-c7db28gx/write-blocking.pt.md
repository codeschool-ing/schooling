---
title: Bloqueio de escrita
version: 1
---

Conectar um disco a um computador basta para mudá-lo. Um sistema operacional que enxerga um sistema de arquivos
pode montá-lo, reprocessar o journal, atualizar um horário de acesso; qualquer uma dessas coisas escreve na
evidência, e o hash tirado depois não bate mais com o que qualquer outra pessoa vai tirar. Um **bloqueador de
escrita** fica entre o disco e o computador de quem examina e **deixa passar leituras e recusa escritas**. Num
caso real ele é um pequeno aparelho entre o cabo do disco e o computador; hardware é preferido porque não depende
de o sistema operacional de quem examina se comportar.

No laboratório, o próprio Linux faz o papel. O `losetup` apresenta o `disk.img` como dispositivo de bloco, e o
`--read-only` faz o kernel recusar toda escrita nele:

```
root@soc:~/case# losetup --read-only --find --show disk.img
/dev/loop0
root@soc:~/case# blockdev --getro /dev/loop0
1
root@soc:~/case# dd if=/dev/zero of=/dev/loop0 count=1
dd: writing to '/dev/loop0': Operation not permitted
1+0 records in
0+0 records out
0 bytes copied, 2.3043e-05 s, 0.0 kB/s
```

O `losetup` responde com o dispositivo que escolheu, `/dev/loop0`; na sua máquina pode ser outro número, então
use o que ele imprimir. O `blockdev --getro` lê o indicador de somente leitura do dispositivo: `1`. E a prova é o
último comando, que tenta escrever um bloco de zeros no dispositivo e é recusado: `Operation not permitted`, com
`0 bytes` escritos. **Teste o bloqueador antes de confiar nele**, toda vez, do jeito que a aula 13 testou uma
regra de firewall. Um bloqueador de escrita que deixa passar escritas em silêncio é pior do que nenhum, porque
todo mundo acredita nele.
