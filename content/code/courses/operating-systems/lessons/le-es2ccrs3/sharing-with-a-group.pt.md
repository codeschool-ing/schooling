---
title: Uma pasta que um grupo pode compartilhar
version: 1
---

O problema da folha é, na verdade, um problema de grupo: **o pessoal da contabilidade** deve ler e gravar
na pasta, e ninguém mais. No Linux isso é um grupo, uma pasta que pertence a ele, e um bit especial.

```
ana@server:/srv/office$ sudo groupadd accounts
ana@server:/srv/office$ sudo usermod -aG accounts bruno
ana@server:/srv/office$ sudo mkdir /srv/accounts
ana@server:/srv/office$ sudo chown root:accounts /srv/accounts
ana@server:/srv/office$ sudo chmod 2770 /srv/accounts
ana@server:/srv/office$ ls -ld /srv/accounts
drwxrws--- 2 root accounts 4096 Sep 25 10:53 /srv/accounts
ana@server:/srv/office$ sudo -u bruno touch /srv/accounts/ledger.xlsx
ana@server:/srv/office$ sudo -u carla touch /srv/accounts/ledger.xlsx
touch: cannot touch '/srv/accounts/ledger.xlsx': Permission denied
ana@server:/srv/office$ sudo ls -l /srv/accounts
total 0
-rw-rw-r-- 1 bruno accounts 0 Sep 25 10:53 ledger.xlsx
```

Passo a passo:

1. O `groupadd accounts` cria o grupo, e o **`usermod -aG accounts bruno`** põe o bruno nele. O `-a`
   importa: sem ele, o `-G` *substitui* todos os grupos do bruno por este.
2. A pasta pertence a **`root:accounts`**, então as letras do grupo são as que contam.
3. `2770`: tudo para o dono e o grupo, nada para os outros, e o **2** na frente, o bit *setgid*,
   mostrado como o `s` em `rws`.
4. O bruno, membro, criou um arquivo. A carla, que não é, foi recusada.
5. O grupo do arquivo novo é **`accounts`**, não o grupo particular do bruno. **É isso que o setgid faz
   numa pasta**: todo arquivo novo lá dentro entra no grupo da pasta, então o próximo membro consegue
   abri-lo. Sem ele, cada arquivo pertenceria ao grupo particular de quem o criou, e o compartilhamento
   pararia de funcionar em silêncio, um arquivo de cada vez.

Um usuário posto num grupo o recebe **no próximo login**. Uma sessão aberta antes do `usermod` ainda tem a
lista antiga, que é o motivo de sempre para "eu a coloquei no grupo e ainda diz Permission denied".

## O padrão dos arquivos novos

De onde veio o `-rw-rw-r--` do arquivo novo? Da *umask*, as permissões com que todo arquivo novo
nasce *sem*:

```
ana@server:/srv/office$ umask
0002
ana@server:/srv/office$ touch new.txt && mkdir newdir
ana@server:/srv/office$ ls -ld new.txt newdir
-rw-rw-r-- 1 ana ana    0 Sep 25 10:53 new.txt
drwxrwxr-x 2 ana ana 4096 Sep 25 10:53 newdir
```

Os programas pedem `666` para arquivos e `777` para pastas, e a umask **`0002`** tira o `w` dos outros.
Arquivos novos saem `664`, pastas novas `775`. Um servidor mais rígido define `027`, e os arquivos novos
já nascem ilegíveis para os outros.
