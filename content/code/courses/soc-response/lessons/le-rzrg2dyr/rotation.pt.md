---
title: Rotação, sem perder uma linha
version: 1
---

Um arquivo de log que só cresce acaba enchendo o disco, e um disco cheio para justamente o registro que
explicaria o que aconteceu. A **rotação** fecha o arquivo atual num momento fixo, renomeia-o, começa um
novo e apaga o mais antigo quando passa do que a política permite. No Linux é o `logrotate`, rodado uma
vez por dia por um timer. Ponha isto em `/etc/logrotate.d/remote`:

```conf
/var/log/remote/*.log {
    daily
    rotate 400
    dateext
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

| diretiva | o que decide |
|---|---|
| `daily` | um arquivo novo por dia, então um arquivo é um dia: fácil de calcular o hash, fácil de entregar |
| `rotate 400` | guardar 400 arquivos antigos, o que com `daily` é um pouco mais de treze meses, o teto da primeira figura desta aula |
| `dateext` | chamar o arquivo antigo pela data (`gw.log-20261007`) em vez de um número que muda todo dia |
| `compress`, `delaycompress` | comprimir os antigos, mas deixar o de ontem sem comprimir por mais um dia, caso algo ainda esteja escrevendo nele |
| `copytruncate` | copiar o arquivo e esvaziar o original no lugar, para quem escreve continuar com o arquivo aberto |

O `copytruncate` é uma troca que vale nomear. A alternativa, `create`, renomeia o arquivo e pede a quem
escreve para reabrir; o rsyslog faz isso ao receber um sinal, e a rotação do próprio Ubuntu para o
`/var/log/syslog` funciona assim. O `copytruncate` dispensa o sinal, ao preço de uma janela minúscula:
uma linha escrita entre a cópia e o esvaziamento se perde. Para um arquivo que precisa estar completo,
prefira o `create` e o sinal.

Force uma rotação e olhe:

```
root@soc:~# ls -l /var/log/remote
total 4
-rw-r----- 1 syslog adm 399 Oct  7 04:51 gw.log
root@soc:~# logrotate -f /etc/logrotate.d/remote
root@soc:~# ls -l /var/log/remote
total 4
-rw-r----- 1 syslog adm   0 Oct  7 04:51 gw.log
-rw-r----- 1 syslog adm 399 Oct  7 04:51 gw.log-20261007
```

As linhas do dia, 399 bytes, agora são o `gw.log-20261007`, ainda do `syslog` e do grupo `adm`; o
`gw.log` recomeça do zero. **Calcule o hash do arquivo rotacionado**, como na seção anterior, antes que
ele seja comprimido amanhã: um arquivo com o nome de um dia e um hash calculado uma vez é a unidade que a
próxima seção passa de mão em mão.
