---
title: Quatro formatos, e o que usar
version: 1
---

O `pg_dump` escreve quatro tipos de arquivo, escolhidos com `-F`. Faça um de cada a partir do mesmo
banco:

```
ana@vm:~$ pg_dump -Fp -f shop-plain.sql shop
ana@vm:~$ pg_dump -Fc -f shop.dump shop
ana@vm:~$ pg_dump -Fd -f shop.dir shop
ana@vm:~$ pg_dump -Ft -f shop.tar shop
ana@vm:~$ ls -l shop-plain.sql shop.dump shop.tar shop.dir
-rw-r--r-- 1 ana ana 1937458 Oct 10 04:06 shop-plain.sql
-rw-r--r-- 1 ana ana  539121 Oct 10 04:06 shop.dump
-rw-r--r-- 1 ana ana 1946112 Oct 10 04:06 shop.tar

shop.dir:
total 532
-rw-r--r-- 1 ana ana   4880 Oct 10 04:06 3401.dat.gz
-rw-r--r-- 1 ana ana 529447 Oct 10 04:06 3403.dat.gz
-rw-r--r-- 1 ana ana   4088 Oct 10 04:06 toc.dat
```

| | flag | o que é | restaurado com |
|---|---|---|---|
| **plain** | `-Fp` | um script SQL, legível em qualquer editor | `psql -f` |
| **custom** | `-Fc` | um único arquivo compactado, com um sumário | `pg_restore` |
| **directory** | `-Fd` | um diretório: um arquivo compactado por tabela, mais o sumário | `pg_restore` |
| **tar** | `-Ft` | o formato directory empacotado num arquivo tar, sem compressão | `pg_restore` |

O arquivo plain tem 1,9 MB e o custom 0,5 MB, porque o custom comprime por padrão. O diretório
mostra para onde vai o espaço: um arquivo com os dados de cada tabela, com o nome do número da
entrada dela, e os pedidos são quase tudo.

**SQL puro é o que todo mundo pega primeiro, e o mais fraco.** Ele é restaurado executando-o, de
cima a baixo, tudo ou nada: para recuperar uma tabela você edita o arquivo, e se ele tem 40 GB você
está editando 40 GB. Ele não pode ser restaurado em paralelo. A única virtude dele é que uma pessoa
consegue lê-lo.

**O custom é o padrão que vale a pena.** Ele é compactado e traz um sumário que o `pg_restore`
consegue listar, filtrar e reordenar:

```
ana@vm:~$ pg_restore -l shop.dump
;
; Archive created at 2026-10-10 04:06:18 -03
;     dbname: shop
;     TOC Entries: 16
;     Compression: gzip
;     Dump Version: 1.15-0
;     Format: CUSTOM
;     Integer: 4 bytes
;     Offset: 8 bytes
;     Dumped from database version: 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
;     Dumped by pg_dump version: 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
;
;
; Selected TOC Entries:
;
215; 1259 16386 TABLE public customers shop_owner
3410; 0 0 ACL public TABLE customers shop_owner
217; 1259 16394 TABLE public orders shop_owner
3411; 0 0 ACL public TABLE orders shop_owner
216; 1259 16393 SEQUENCE public orders_id_seq shop_owner
3401; 0 16386 TABLE DATA public customers shop_owner
3403; 0 16394 TABLE DATA public orders shop_owner
3412; 0 0 SEQUENCE SET public orders_id_seq shop_owner
3253; 2606 16392 CONSTRAINT public customers customers_pkey shop_owner
3256; 2606 16399 CONSTRAINT public orders orders_pkey shop_owner
3254; 1259 16405 INDEX public orders_customer shop_owner
3257; 2606 16400 FK CONSTRAINT public orders orders_customer_id_fkey shop_owner
```

Cada linha é uma coisa que a restauração vai fazer, com o tipo dela (`TABLE`, `TABLE DATA`,
`INDEX`, `FK CONSTRAINT`, `ACL` para as permissões) e o dono. Salve essa lista num arquivo, apague
ou comente linhas, e `pg_restore -L arquivo` restaura exatamente o que sobrou. A restauração
seletiva, duas seções adiante, é construída sobre isso.

**O directory é o custom dividido em arquivos**, e é o único formato que o `pg_dump` consegue
escrever em paralelo, com `-j`. É o que usar num banco grande. O **tar** existe para ferramentas que
querem um arquivo único; nada neste curso precisa dele.

Então: custom para as cópias do dia a dia, directory quando o banco fica grande o bastante para a
duração de um dump importar, e plain só quando alguém precisa ler o resultado.
