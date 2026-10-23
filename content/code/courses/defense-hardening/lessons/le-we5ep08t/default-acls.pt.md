---
title: ACLs padrão, para arquivos que ainda não existem
version: 1
---

**Uma ACL num arquivo cobre aquele arquivo. O próximo arquivo que alguém criar no mesmo diretório
começa sem nenhuma.** O João salva o documento de um cliente novo:

```
ana@web:~$ sudo -u joao sh -c "umask 007; echo CPF 987.654.321-00 > /srv/clientes/costa.txt"; sudo getfacl -p --omit-header /srv/clientes/costa.txt
user::rw-
group::rw-
other::---

ana@web:~$ sudo -u auditoria cat /srv/clientes/costa.txt
cat: /srv/clientes/costa.txt: Permission denied
```

O primeiro comando mostra o arquivo novo só com os bits, sem entradas nomeadas, e a auditora é
recusada, como era antes das duas últimas seções. Cada arquivo novo precisaria do mesmo `setfacl` à
mão, e o primeiro esquecido seria justamente o que a auditora pedisse.

Uma **ACL padrão** num diretório é um modelo. Não concede nada no próprio diretório; todo arquivo e
subdiretório criado dentro dele já nasce com essas entradas. O `setfacl -d` a escreve, e o `getfacl` a
mostra como as linhas que começam com `default:`. Aqui ela é definida com o `rw` do grupo e nada para
os outros, o que também deixa o diretório compartilhado independente do umask de quem salvar um
arquivo.

Depois a Maria salva outro documento, e ele chega com a auditora e o portal já nele:

```
ana@web:~$ sudo setfacl -d -m u:auditoria:r,u:portal:r,g::rw,o::- /srv/clientes && sudo getfacl -p --omit-header /srv/clientes | grep default
default:user::rwx
default:user:portal:r--
default:user:auditoria:r--
default:group::rw-
default:mask::rw-
default:other::---
ana@web:~$ sudo -u maria sh -c "umask 007; echo CPF 111.222.333-96 > /srv/clientes/souza.txt"; sudo getfacl -p --omit-header /srv/clientes/souza.txt
user::rw-
user:portal:r--
user:auditoria:r--
group::rw-
mask::rw-
other::---

ana@web:~$ sudo -u auditoria cat /srv/clientes/souza.txt
CPF 111.222.333-96
```

O `costa.txt`, criado antes de o padrão existir, não mudou e ainda precisa ser corrigido à mão. Um
padrão vale na criação e nunca depois, então um diretório cheio de arquivos antigos é ajustado uma
vez com `setfacl -R -m` para o que existe e uma vez com `-d` para o que vai existir.

## O que cópias e movimentações fazem

Dois hábitos quebram padrões na prática, e vale conhecer os dois antes de acontecerem:

- **Um arquivo movido para dentro com `mv` mantém a ACL que tinha.** Mover dentro de um mesmo sistema
  de arquivos renomeia o arquivo e não cria nada, então o padrão nunca se aplica; um documento movido
  do home de alguém chega com o acesso do home dessa pessoa.
- **Um arquivo copiado com `cp -p` ou `rsync -A` mantém a própria ACL** em vez de receber a do
  diretório, porque essas opções existem para preservar o que o arquivo tinha.

`getfacl -R` sobre o diretório, comparado com o que os padrões prometem, é a verificação que acha os
dois, e ela pertence à linha de base da aula 2 para qualquer diretório que guarde dados de clientes.
