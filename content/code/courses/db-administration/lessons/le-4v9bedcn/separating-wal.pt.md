---
title: Dando ao WAL um sistema de arquivos próprio
version: 1
---

Os arquivos de dados e o log de escrita antecipada são escritos de jeitos completamente diferentes.
**O log recebe acréscimos em ordem e passa por um flush a cada commit**, com uma sessão esperando
por cada flush. Os arquivos de dados são escritos em segundo plano, em rajadas, pelo checkpointer e
pelo background writer das lições 7 e 8, e ninguém espera por eles diretamente. Pôr os dois em
discos separados impede que a rajada de escritas de um checkpoint entre na fila na frente do flush
do próximo commit.

Há um segundo motivo, e num servidor pequeno ele é o mais forte: **os dois falham de jeitos
diferentes quando ficam sem espaço.** Um sistema de arquivos de dados cheio faz comandos falharem.
Um sistema de arquivos de log cheio para o servidor. As duas últimas seções desta lição mostram os
dois casos, e tê-los em sistemas de arquivos separados quer dizer que um pode encher sem o outro.

O que isso não compra é velocidade numa máquina virtual cujos discos são todos arquivos no mesmo
drive físico, que é o caso do servidor do curso. A separação ajuda quando os dois sistemas de
arquivos estão em dispositivos diferentes. No seu servidor, é treino para uma mudança que você vai
fazer num servidor que os tenha.

## Dimensionando

O `pg_wal` tem de guardar tudo desde o último checkpoint e mais um pouco, e a lição 7 deu nome à
configuração que decide quanto: `max_wal_size`. Meça o que existe agora e leia a configuração antes
de escolher um tamanho:

```
ana@db:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
337M	/var/lib/postgresql/16/main/pg_wal
ana@db:~$ psql shop -Atc "SHOW max_wal_size"
1GB
```

**Um sistema de arquivos para o `pg_wal` deve ser bem maior que o `max_wal_size`**, porque esse
limite é flexível: é o ponto em que um checkpoint é pedido, e o WAL continua chegando enquanto o
checkpoint roda. O dobro da configuração é um piso razoável, e mais se replicação ou arquivamento
puderem segurar arquivos, o que a lição 7 e o `db-reliability` tratam.

O sistema de arquivos abaixo tem 512 MB, **metade do `max_wal_size`, o que é pequeno demais de
propósito**. A última seção desta lição precisa de um disco de log que encha; nunca dimensione um de
verdade assim.

## Movendo

Um cluster novo pode ser criado com o log em outro lugar desde o início, com `initdb --waldir`. Um
existente é movido parando-o, movendo o diretório e deixando um link simbólico onde ele estava. O
sistema de arquivos novo aqui é um arquivo formatado como ext4 e montado por um dispositivo de loop,
que se comporta como um segundo disco sem precisar de um:

```
ana@db:~$ sudo truncate -s 512M /srv/wal.img
ana@db:~$ sudo mkfs.ext4 -q /srv/wal.img
ana@db:~$ sudo mkdir /srv/wal
ana@db:~$ sudo mount -o loop /srv/wal.img /srv/wal
ana@db:~$ sudo systemctl stop postgresql@16-main
ana@db:~$ sudo mv /var/lib/postgresql/16/main/pg_wal /srv/wal/pg_wal
ana@db:~$ sudo -u postgres ln -s /srv/wal/pg_wal /var/lib/postgresql/16/main/pg_wal
ana@db:~$ sudo systemctl start postgresql@16-main
ana@db:~$ sudo ls -l /var/lib/postgresql/16/main | grep pg_wal
lrwxrwxrwx 1 postgres postgres   15 Oct 10 16:54 pg_wal -> /srv/wal/pg_wal
ana@db:~$ df -h /srv/wal
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0      488M  337M  116M  75% /srv/wal
```

O `truncate` criou um arquivo de 512 MB sem escrever 512 MB, e o `mkfs.ext4 -q` o formatou em
silêncio. **O servidor tem de estar parado enquanto o `pg_wal` se move**: um servidor rodando e
escrevendo num diretório copiado pela metade é como se perde um cluster. Os 337 MB vieram junto, e
o sistema de arquivos ficou com 116 MB livres. Ele mostra 488 MB em vez de 512 porque o ext4 guarda
parte de todo sistema de arquivos para a sua própria contabilidade, e mais um pouco para o usuário
root, que a próxima seção usa.

Num servidor de verdade, o sistema de arquivos novo também ganha uma linha no `/etc/fstab`, como a
da seção anterior. Sem ela, o próximo boot deixa `/srv/wal` vazio, o link aponta para nada e o
cluster não consegue iniciar, o que pelo menos é barulhento.
