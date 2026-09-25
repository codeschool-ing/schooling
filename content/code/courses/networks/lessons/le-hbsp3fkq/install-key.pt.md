---
title: Instalando a chave no servidor
version: 1
---

O `ssh-copy-id` entra uma vez com a senha e acrescenta a chave pública ao `~/.ssh/authorized_keys` do
servidor:

```
ana@laptop:~$ ssh-copy-id -i ~/.ssh/id_ed25519.pub 192.168.10.10
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ana/.ssh/id_ed25519.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
ana@192.168.10.10's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh '192.168.10.10'"
and check to make sure that only the key(s) you wanted were added.

ana@server:~$ cat ~/.ssh/authorized_keys | cut -c1-50; ls -ld ~/.ssh ~/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOba7uYPf3qw8X
drwx------ 2 ana ana 4096 Sep 25 15:11 /home/ana/.ssh
-rw------- 1 ana ana   92 Sep 25 15:11 /home/ana/.ssh/authorized_keys
```

Foi a última senha de que esta conexão precisou. O arquivo no servidor tem uma linha por chave, a mesma
linha do `.pub` do laptop. **As permissões importam**: `~/.ssh` é `drwx------` e o `authorized_keys` é
`-rw-------`. Se outros usuários puderem escrever em qualquer um dos dois, o sshd ignora a chave, com o
raciocínio de que outra pessoa pode tê-la posto ali, e volta a pedir a senha. Quando uma chave "para de
funcionar" depois de alguém arrumar uma pasta pessoal, confira isto primeiro.

Tirar o acesso é apagar essa linha. Uma pessoa que sai da empresa perde a conta; uma chave é removida
de cada servidor para onde foi copiada, e isso é um bom motivo para manter uma lista de onde elas estão.
