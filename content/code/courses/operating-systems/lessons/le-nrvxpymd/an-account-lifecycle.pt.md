---
title: Criando, bloqueando e removendo uma conta
version: 1
---

A pessoa nova ganha uma conta. O **`useradd`** a cria; o `-m` faz a pasta pessoal, o `-s` define o
shell e o `-c` o nome completo:

```
ana@server:~$ sudo useradd -m -s /bin/bash -c "Carla Souza" carla
ana@server:~$ getent passwd carla
carla:x:1001:1001:Carla Souza:/home/carla:/bin/bash
ana@server:~$ sudo passwd -S carla
carla L 2026-09-25 0 99999 7 -1
ana@server:~$ ls -A /home/carla
ls: cannot open directory '/home/carla': Permission denied
ana@server:~$ sudo ls -A /home/carla
.bash_logout
.bashrc
.profile
```

- O `getent` mostra a linha nova, com o **próximo ID livre, 1001**.
- **O `passwd -S` diz `L`**: a conta existe, e está **bloqueada** porque ainda não tem senha. Ninguém
  consegue entrar nela, que é o jeito seguro de uma conta nascer.
- A ana não conseguiu listar a pasta pessoal da carla, o `drwxr-x---` da aula 9, e com `sudo` conseguiu:
  a pasta nova foi preenchida a partir do **`/etc/skel`**, os arquivos com que todo usuário novo começa.

## Uma senha, e o primeiro login

```
ana@server:~$ sudo passwd carla
New password: 
Retype new password: 
passwd: password updated successfully
ana@server:~$ sudo passwd -S carla
carla P 2026-09-25 0 99999 7 -1
```

**A senha foi digitada duas vezes e nunca apareceu**, que é como todo pedido de senha no Linux se
comporta: nem asteriscos, para que alguém olhando não consiga contar os caracteres. O status agora é
`P`, uma senha utilizável.

O **`su`** troca para outro usuário, e pede a senha **desse usuário**:

```
ana@server:~$ su - carla
Password: 
carla@server:~$ whoami

carla
carla@server:~$ exit

logout
```

Uma senha temporária não deveria durar mais que o primeiro login, então a conta é marcada para exigir
uma nova:

```
ana@server:~$ sudo passwd -e carla
passwd: password changed.
ana@server:~$ sudo chage -l carla | head -3
Last password change					: password must be changed
Password expires					: password must be changed
Password inactive					: password must be changed
```

## Saindo

```
ana@server:~$ sudo usermod -L carla
ana@server:~$ sudo passwd -S carla
carla L 1970-01-01 0 99999 7 -1
ana@server:~$ sudo usermod -U carla
```

Quando alguém sai, **bloqueie primeiro**: o `usermod -L` desativa a senha mantendo a conta, os arquivos
e a posse deles intactos, e o `-U` desfaz. Bloqueie no último dia, e apague depois, quando os arquivos
da pessoa já tiverem sido passados adiante.

```
ana@server:~$ sudo userdel -r carla
userdel: carla mail spool (/var/mail/carla) not found
ana@server:~$ getent passwd carla || echo "no such user"
no such user
```

O **`userdel -r`** remove a conta e a pasta pessoal. O aviso sobre a caixa de correio é inofensivo: não
havia correio. Arquivos que a pessoa tinha **em outro lugar**, numa pasta compartilhada, não são
removidos; ficam, pertencendo a um número, 1001, sem nome, até que a próxima conta criada receba o mesmo
ID e, com ele, esses arquivos. É mais um motivo para passar os arquivos adiante antes de apagar.
