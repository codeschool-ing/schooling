---
title: Provando que a cópia está íntegra
version: 1
---

Um teste de restauração prova que o backup estava certo no dia do teste. Entre um teste e outro, o
arquivo fica num disco, viaja para fora do local, é copiado para um serviço de nuvem. Qualquer um desses
passos pode danificá-lo: um disco falhando, uma transferência interrompida, um defeito numa ferramenta
de cópia. **O checksum da aula 1 é como você sabe que a cópia ainda é o backup.**

Logo depois do backup, a ana registra um hash SHA-256 do arquivo e o confere:

```
root@db:~# sha256sum /backup/shop-2026-10-05.tar.gz > /backup/SHA256SUMS
root@db:~# sha256sum -c /backup/SHA256SUMS
/backup/shop-2026-10-05.tar.gz: OK
```

O `SHA256SUMS` é um arquivinho de texto com o hash e o nome do arquivo. O `sha256sum -c` o lê, calcula o
hash do arquivo de novo e diz `OK`: o arquivo é, byte a byte, o que era quando o hash foi tirado.

Agora o arquivo é copiado para o disco que vai para fora do local, e a cópia se danifica. Aqui o dano é
feito de propósito, para poder ser visto: o `dd` sobrescreve um byte da cópia com a letra `X`, que é a
cara de um setor defeituoso ou de uma transferência corrompida.

```
root@db:~# cp /backup/shop-2026-10-05.tar.gz offsite.tar.gz
root@db:~# printf X | dd of=offsite.tar.gz bs=1 seek=200 conv=notrunc 2>/dev/null
root@db:~# cat /backup/SHA256SUMS; sha256sum offsite.tar.gz
e8d0846627c4ce345d291a73a47904fa3d305ae71b92d0988296bfad8c07cf4f  /backup/shop-2026-10-05.tar.gz
6342cb6d97c02abcc78151161db32157cee134930ad2a344d41d0f86840a3280  offsite.tar.gz
```

O hash registrado começa com `e8d08466`; o da cópia, com `6342cb6d`. Um byte do arquivo inteiro mudou,
e o hash diz isso sem deixar dúvida. Sem a conferência, o dano só apareceria no dia em que alguém
precisasse daquela cópia, que é o pior dia possível para descobrir.

### Uma rotina, não um ato heroico

Juntando tudo, a rotina de backup da loja cabe numa ficha:

1. o backup inclui tudo sob `/srv/shop` e roda toda noite;
2. logo depois, um hash do arquivo é registrado ao lado dele;
3. toda cópia, fora do local ou na nuvem, é conferida contra esse hash depois de chegar;
4. uma vez por mês, a ana restaura o arquivo mais recente numa pasta vazia, compara com os dados vivos e
   anota quanto tempo levou;
5. uma vez por ano, os sócios e a ana percorrem a restauração da loja inteira numa outra máquina, como o
   exercício de mesa da aula 10, comparando o tempo com o RTO.

O quarto passo é o que achou as notas faltando, e é o que se pula quando todo mundo está ocupado. É
também o seguro mais barato que a loja tem: meia hora por mês contra perder os documentos que a empresa
é obrigada por lei a guardar.
