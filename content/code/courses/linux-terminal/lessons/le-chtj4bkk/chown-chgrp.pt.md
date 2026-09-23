---
title: Propriedade, e por que dar um arquivo exige root
version: 2
---

Dois comandos, e uma regra que explica a seção inteira.

```
chown ana file          # change the owner
chown ana:team file     # change the owner and the group
chgrp team file         # change only the group
```

## Dono e grupo são números

```
ana@vm:~$ ls -l /srv/perm/teamonly.txt
-rw-r----- 1 ana team 13 Sep 14 22:45 /srv/perm/teamonly.txt
ana@vm:~$ ls -ln /srv/perm/teamonly.txt
-rw-r----- 1 1001 1004 13 Sep 14 22:45 /srv/perm/teamonly.txt
```

O `-n` pede os valores crus, e ali estão. **O sistema de arquivos guarda `1001` e `1004`.** Os nomes
são procurados na hora em que o `ls` imprime, em `/etc/passwd` e `/etc/group`, que é o assunto da
seção 08.

Isso importa em dois lugares. Copie um disco para uma máquina onde o uid 1001 é outra pessoa, e os
arquivos passam a pertencer a essa pessoa. E dentro de um contêiner o mesmo número mapeia para uma
conta diferente da de fora — que é por que um arquivo escrito por um contêiner aparece pertencendo
a um desconhecido.

## Só o root pode dar um arquivo

```
ana@vm:~/perm$ ls -l public.txt
-rw-r--r-- 1 ana ana 6 Sep 14 22:44 public.txt
ana@vm:~/perm$ chown bruno public.txt
chown: changing ownership of 'public.txt': Operation not permitted
```

A ana é dona do arquivo e é recusada. **Um usuário comum não entrega um arquivo a outra pessoa**,
nem um arquivo que é inteiramente dele.

O motivo é cota e responsabilidade. Se você pudesse dar arquivos, poderia despejar cem gigabytes
num diretório e atribuir todos a um colega, e a cota de disco dele pagaria a conta. Também
significa que o dono de um arquivo é alguém que efetivamente escolheu tê-lo.

Como root funciona, e todas as formas funcionam:

```
root@vm:/srv/perm# ls -l public.txt
-rw-r--r-- 1 ana ana 22 Sep 14 22:45 public.txt
root@vm:/srv/perm# chown bruno public.txt
root@vm:/srv/perm# ls -l public.txt
-rw-r--r-- 1 bruno ana 22 Sep 14 22:45 public.txt
root@vm:/srv/perm# chown ana:team public.txt
root@vm:/srv/perm# ls -l public.txt
-rw-r--r-- 1 ana team 22 Sep 14 22:45 public.txt
```

`chown usuario` muda o dono e deixa o grupo. `chown user:group` muda os dois. `chown :group` —
sem nada antes dos dois-pontos — muda só o grupo, que é o `chgrp` escrito de outro jeito.

## O grupo é a metade que você *pode* mudar

```
ana@vm:~/perm$ chgrp team public.txt
```

Sem reclamação. A ana é dona do arquivo e é membro do `team`, e essas são as duas condições: **você
pode definir o grupo de um arquivo como qualquer grupo a que você pertença, num arquivo seu.**

Essa é a razão inteira de a seção 08 existir. O grupo é a parte do modelo que um usuário comum
controla, e é como duas pessoas compartilham um arquivo sem ninguém virar root.

Tente com um grupo em que você não está e é recusado pelo mesmo motivo do `chown`.

## `-R`, e as duas flags que importam com ele

```
sudo chown -R www-data:www-data /srv/www
```

Recursivo, e é o jeito normal de entregar uma árvore inteira a uma conta de serviço depois de um
deploy. Duas opções valem conhecer:

| | faz |
|---|---|
| `-R` | o diretório e tudo abaixo dele |
| `--from=antigo:antigo` | muda só as entradas que hoje têm aquele dono — um conserto cirúrgico |
| `-h` | age no link simbólico em si, e não no alvo |
| `--reference=file` | copia o dono e o grupo de outro arquivo |

**O `-R` entra em sistemas de arquivos montados**, o que já surpreendeu quem rodou no topo de uma
árvore com um compartilhamento de rede embaixo. `find ... -exec chown` com `-xdev` é a versão
cuidadosa.

## Os enganos que vale nomear

**`chown ana.team file`** — um ponto no lugar dos dois-pontos. Funciona em sistemas GNU por
razões históricas e é ambíguo quando um nome de usuário contém ponto. Use os dois-pontos.

**`sudo chown -R $USER /`** — alguém tentando consertar uma permissão no próprio diretório pessoal,
com um erro de digitação no caminho. Isso reescreve a propriedade do sistema inteiro, e a máquina
não dá boot. Não há desfazer; a recuperação é reinstalar ou ter um backup dos metadados. **Confira
o caminho antes de apertar enter num `chown` recursivo**, exatamente como a aula 3 seção 07 disse do
`rm -rf`.

**Mudar o dono não muda o modo.** Um arquivo que era `-rw-------` da `ana` continua `-rw-------`
depois de um `chown bruno` — agora legível pelo bruno, e por mais ninguém. As duas coisas são
separadas, e um deploy que conserta a propriedade e deixa um arquivo `600` para um serviço que roda
como outra conta vai continuar falhando.
