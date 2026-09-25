---
title: Nomes para as máquinas que você usa
version: 1
---

Endereços, nomes de usuário e portas são chatos de digitar e fáceis de errar. O `~/.ssh/config` dá a
cada máquina um nome curto e lembra o resto:

```
ana@laptop:~$ cat ~/.ssh/config
Host office
    HostName 192.168.10.10
    User ana

Host web
    HostName 192.0.2.80
    User ana
ana@laptop:~$ eval $(ssh-agent) >/dev/null
ana@laptop:~$ ssh-add
Enter passphrase for /home/ana/.ssh/id_ed25519: 
Identity added: /home/ana/.ssh/id_ed25519 (ana@laptop)
ana@laptop:~$ ssh office uptime -p
up 31 minutes
```

`ssh office` agora quer dizer o usuário `ana` em `192.168.10.10`. Tudo que cabe na linha de comando
cabe num bloco `Host`: `Port`, `IdentityFile` para uma chave específica, `ProxyJump` para o salto da
seção 08. Toda ferramenta feita sobre SSH lê o mesmo arquivo, então `scp office:…`, `sftp office` e o
`git` também entendem o nome curto; a aula 8 usa todos eles.

O arquivo é lido de cima para baixo, e **para cada opção vale o primeiro valor encontrado**. Hosts
específicos vêm primeiro e um bloco `Host *` com os padrões vem por último, senão os padrões ganham em
todo lugar.
