---
title: Integridade de arquivos: perceber que algo mudou
version: 1
---

Um intruso que quer ficar precisa mudar alguma coisa: uma configuração que abre uma porta, uma chave
que o deixa voltar, um programa trocado por outro que faz mais. O **monitoramento de integridade de
arquivos** (*file integrity monitoring*) registra como estavam os arquivos que importam e reporta
qualquer diferença. É o hash da aula 11 aplicado a um servidor inteiro, com agenda.

O **AIDE** é a ferramenta clássica. A configuração dele diz o que registrar e quais diretórios
vigiar; no `www`, a configuração do proxy, as chaves TLS e a configuração do SSH:

```
root@www:~# cat /etc/aide/shop.conf
database_in=file:/var/lib/aide/aide.db
database_out=file:/var/lib/aide/aide.db.new
report_url=stdout
Watch = p+u+g+s+m+c+sha256
/etc/nginx Watch
/etc/ssl/private Watch
/etc/ssh Watch
```

`Watch` registra permissões, dono, grupo, tamanho, horários de modificação e de alteração, e um
SHA-256 do conteúdo. A primeira execução monta o banco de dados de como as coisas estão agora, que
passa a ser a referência:

```
root@www:~# aide --config /etc/aide/shop.conf --init | grep -E "^Number|^AIDE"; mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
AIDE successfully initialized database.
Number of entries:	43
```

43 entradas. Conferido na hora, nada difere, e o AIDE sai com 0:

```
root@www:~# aide --config /etc/aide/shop.conf --check | grep -E "^AIDE|^Number|found"; echo "exit $?"
AIDE found NO differences between database and filesystem. Looks okay!!
Number of entries:	43
exit 0
```

Então alguém acrescenta um location à configuração do proxy, mandando `/debug/` para um programa na
porta 8081. O AIDE, rodado de novo:

```
root@www:~# aide --config /etc/aide/shop.conf --check > aide.txt; echo "exit $?"; grep -E "^Summary|^ *Total|^ *Changed|^[fd] " aide.txt
exit 4
Summary:
  Total number of entries:	43
  Changed entries:		2
Changed entries:
d = ... mc        : /etc/nginx/sites-enabled
f > ... mc  H     : /etc/nginx/sites-enabled/shop
```

**Código de saída 4**, que significa *entradas alteradas*, e são duas: o diretório, cujo horário de
modificação andou, e o próprio arquivo, cujo tamanho, horários e hash mudaram. O detalhe diz quanto:

```
root@www:~# sed -n "/^File: /,/^$/p" aide.txt | grep -E "^File|Size|Mtime|SHA256"
File: /etc/nginx/sites-enabled/shop
 Size      : 602                              | 744
 Mtime     : 2026-09-28 18:06:09 -0300        | 2026-09-28 18:06:21 -0300
 SHA256    : quSh3YYoRucaiULCS+j/DH0mB8LL6A7d | gBTw4o9BdL4wu6Ygxf+qj8+Bn2nwcId1
```

602 bytes viraram 744, e os hashes não têm nada em comum. O AIDE não diz se a mudança foi boa. Essa
pergunta é de uma pessoa, e tem resposta rápida quando as mudanças são feitas por chamado: um relatório
do AIDE sem pedido de mudança correspondente é o primeiro a ler.

Duas condições fazem valer a pena rodá-lo. **O banco de referência precisa ficar onde um intruso não
consiga reescrevê-lo**, copiado para fora do host ou para uma mídia somente leitura; um banco que o
intruso consegue atualizar reporta que nada mudou. E **a verificação precisa rodar com agenda e mandar
o relatório para algum lugar**; uma verificação de integridade que ninguém lê é um arquivo que muda
toda noite.
