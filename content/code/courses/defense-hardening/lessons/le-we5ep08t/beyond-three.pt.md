---
title: Mais que um usuário e um grupo
version: 1
---

**Uma lista de controle de acesso acrescenta entradas para usuários e grupos nomeados aos nove bits
de um arquivo.** Os bits ficam; a lista soma a eles. No Linux a lista é uma ACL POSIX, lida com
`getfacl` e escrita com `setfacl`, e os sistemas de arquivos do Ubuntu a aceitam sem configuração.

Monte o caso primeiro. Os contadores são um grupo, `contabil`, com a Maria e o João dentro; a
auditora tem conta própria, `auditoria`. O diretório dos clientes pertence ao grupo, com o bit
set-group-id no diretório para que os arquivos criados dentro dele também pertençam ao grupo:

```
ana@web:~$ sudo groupadd contabil && for u in maria joao auditoria; do sudo useradd -M -s /usr/sbin/nologin $u; done; sudo usermod -aG contabil maria; sudo usermod -aG contabil joao; id maria; id auditoria
uid=1002(maria) gid=1003(maria) groups=1003(maria),1002(contabil)
uid=1004(auditoria) gid=1005(auditoria) groups=1005(auditoria)
ana@web:~$ sudo install -d -o root -g contabil -m 2770 /srv/clientes && ls -ld /srv/clientes
drwxrws--- 2 root contabil 4096 Oct 23 09:35 /srv/clientes
ana@web:~$ sudo -u maria sh -c "umask 007; echo CPF 123.456.789-09, IRPF 2025 > /srv/clientes/silva.txt"; sudo ls -l /srv/clientes
total 4
-rw-rw---- 1 maria contabil 30 Oct 23 09:35 silva.txt
```

`2770` é o bit set-group-id, depois acesso total para o dono e o grupo e nada para os outros. A Maria
cria um arquivo com o umask de que um diretório compartilhado precisa, `007`, que não deixa nada para
os outros, e o arquivo sai como os bits pretendem: legível e gravável pelos contadores, fechado para
todo o resto.

Inclusive para as duas que precisam lê-lo:

```
ana@web:~$ sudo -u auditoria cat /srv/clientes/silva.txt
cat: /srv/clientes/silva.txt: Permission denied
ana@web:~$ sudo -u portal cat /srv/clientes/silva.txt
cat: /srv/clientes/silva.txt: Permission denied
```

Os bits não têm como dizer "esta pessoa pode ler". Tornar o arquivo legível para os outros o daria a
todas as contas da máquina; pôr a auditora em `contabil` lhe daria gravação também. É para esse
momento que uma ACL existe.

## Entradas nomeadas

```
ana@web:~$ sudo setfacl -m u:auditoria:rx,u:portal:rx /srv/clientes && sudo setfacl -m u:auditoria:r,u:portal:r /srv/clientes/silva.txt
ana@web:~$ ls -ld /srv/clientes; sudo ls -l /srv/clientes
drwxrws---+ 2 root contabil 4096 Oct 23 09:35 /srv/clientes
total 4
-rw-rw----+ 1 maria contabil 30 Oct 23 09:35 silva.txt
ana@web:~$ sudo getfacl -p /srv/clientes/silva.txt
# file: /srv/clientes/silva.txt
# owner: maria
# group: contabil
user::rw-
user:portal:r--
user:auditoria:r--
group::rw-
mask::rw-
other::---
```

Dois comandos: um para o diretório, que precisa de `x` para se entrar e de `r` para se listar, e um
para o arquivo. O `ls` marca os dois com um `+` depois dos bits, o único sinal numa listagem comum de
que existe mais acesso do que os bits mostram. O `getfacl` imprime a lista inteira: o dono, os dois
usuários nomeados, o grupo dono, uma **máscara** e os outros. A máscara é o assunto da próxima seção.

Depois o teste que importa, de cada lado:

```
ana@web:~$ sudo -u auditoria cat /srv/clientes/silva.txt
CPF 123.456.789-09, IRPF 2025
ana@web:~$ echo "edited" | sudo -u auditoria tee -a /srv/clientes/silva.txt
tee: /srv/clientes/silva.txt: Permission denied
edited
ana@web:~$ echo "edited" | sudo -u joao tee -a /srv/clientes/silva.txt
edited
```

A auditora lê o arquivo e não consegue gravar, e o João, como contador, consegue. O `tee` imprime o
que recebeu aconteça o que acontecer, então a palavra `edited` aparece embaixo da recusa também: a
linha `Permission denied` é a resposta. **Cada tipo de acesso agora é exatamente o que o trabalho
precisa**, e os arquivos dos outros clientes continuam fechados para todo mundo fora da lista.
