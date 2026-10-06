---
title: O teste de restauração
version: 1
---

Os dados da loja moram no `db`, em `/srv/shop`. Aqui está tudo o que há lá:

```
root@db:~# find /srv/shop -type f | sort
/srv/shop/data/customers.csv
/srv/shop/data/orders.csv
/srv/shop/invoices/2026-10-01.txt
/srv/shop/invoices/2026-10-02.txt
/srv/shop/invoices/2026-10-03.txt
```

Pedidos e clientes em `data/`, e as notas dos três primeiros dias de outubro em `invoices/`. Agora o
backup, que roda toda noite e nunca relatou problema:

```
root@db:~# cat backup.sh
#!/bin/bash
# Nightly backup of the shop's data, written in March.
set -e
day=$1
tar --sort=name --mtime='2026-10-04 18:00:00 -0300' --owner=0 --group=0 --numeric-owner \
    -cf - -C /srv/shop data | gzip -n > /backup/shop-$day.tar.gz
root@db:~# ./backup.sh 2026-10-04
root@db:~# tar -tzf /backup/shop-2026-10-04.tar.gz
data/
data/customers.csv
data/orders.csv
```

O `backup.sh` usa o `tar` para empacotar uma pasta num arquivo só e o `gzip` para comprimi-lo, e grava o
resultado em `/backup` com o dia no nome. Rodado para 4 de outubro, ele não imprime nada, o que para um
programa Unix quer dizer sucesso. O `tar -tzf` lista o que o arquivo contém, e essa é a primeira pista:
`data/` e os dois arquivos dela. Mais nada.

A maioria das pessoas pararia aqui. O backup rodou, o arquivo existe, os pedidos estão nele. **Um teste
de restauração não pergunta se o backup rodou. Pergunta se os dados voltam.** Então a ana restaura o
arquivo numa pasta vazia e a compara com os dados vivos:

```
root@db:~# mkdir restore && tar -xzf /backup/shop-2026-10-04.tar.gz -C restore
root@db:~# diff -r /srv/shop restore; echo "exit $?"
Only in /srv/shop: invoices
exit 1
```

O `diff -r` compara duas pastas arquivo por arquivo e imprime cada diferença. `Only in /srv/shop:
invoices` ("só em /srv/shop: invoices") quer dizer que uma pasta inteira existe nos dados vivos e falta
na restauração. `exit 1` é o `diff` dizendo que as duas não são iguais.

A causa está na primeira linha do script: *written in March*, "escrito em março". A pasta das notas veio
depois, e ninguém avisou o backup. Ele faz backup de `data` toda noite desde então, com sucesso, e esse
sucesso foi o que escondeu o problema: **nenhum erro, nenhum alerta e nenhuma nota.** Se o servidor
tivesse morrido, a loja teria restaurado os pedidos e perdido todas as notas fiscais, que no Brasil são
documentos que uma empresa é obrigada a guardar.

### A correção, e a prova

```
root@db:~# sed -i 's/ data | gzip/ data invoices | gzip/' backup.sh
root@db:~# tail -2 backup.sh
tar --sort=name --mtime='2026-10-04 18:00:00 -0300' --owner=0 --group=0 --numeric-owner \
    -cf - -C /srv/shop data invoices | gzip -n > /backup/shop-$day.tar.gz
root@db:~# ./backup.sh 2026-10-05
root@db:~# rm -r restore && mkdir restore && tar -xzf /backup/shop-2026-10-05.tar.gz -C restore
root@db:~# diff -r /srv/shop restore; echo "exit $?"
exit 0
```

O `sed` muda a última linha do script para que o `tar` empacote `data invoices`, e o `tail -2` mostra a
linha como ficou. O backup roda para 5 de outubro, a ana limpa a restauração antiga e restaura o arquivo
novo, e o `diff -r` não imprime nada e sai com 0: **a restauração é idêntica aos dados vivos.** Esse
silêncio é o resultado que um teste de restauração procura.

A lição vai além deste script. Um backup seleciona o que copiar, e a seleção foi escrita em algum
momento do passado. Tudo o que entrou depois fica desprotegido até alguém perceber, e só uma restauração
comparada com os dados vivos percebe. **Faça backup incluindo tudo e excluindo o que você decidiu não
guardar**, em vez de listar o que incluir, e a próxima pasta nova fica protegida por padrão, como o
negar por padrão da aula 5 virado do avesso.
