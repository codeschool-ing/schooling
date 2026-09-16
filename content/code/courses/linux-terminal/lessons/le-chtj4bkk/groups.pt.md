---
title: Grupos, e o que você não sabia que tinha
version: 1
---

Um grupo é um conjunto nomeado de contas, e é a unidade de compartilhamento numa máquina Linux.
Duas pessoas que precisam dos mesmos arquivos não recebem uma conta compartilhada e não viram root
— elas entram num grupo, e os arquivos recebem aquele grupo.

```
ana@vm:~$ id
uid=1001(ana) gid=1002(ana) groups=1002(ana),27(sudo),1004(team)
```

Três números e três nomes numa linha só, e vale ler devagar.

## Primário e suplementares

**`gid=1002(ana)` é o grupo primário.** Toda conta tem exatamente um, ele fica registrado no
`/etc/passwd` ao lado da conta, e **é o grupo que os arquivos novos recebem**. O grupo primário da
ana se chama `ana`, o que é convenção — Debian e Ubuntu dão a cada usuário um grupo pessoal com o
próprio nome, para que um diretório compartilhado seja a exceção e não o padrão.

**`groups=1002(ana),27(sudo),1004(team)` é a lista completa**, primário mais suplementares. A ana
está no `sudo`, e é por isso que a seção 11 vai funcionar para ela, e no `team`, e é por isso que
ela conseguiu ler o `teamonly.txt`.

**Todos eles contam nas checagens de permissão.** Quando o kernel pergunta "esta pessoa está no
grupo do arquivo", ele confere a lista inteira. A única função especial do grupo primário é decidir
a quem os arquivos novos pertencem.

O `id` tem uma flag para cada pedaço:

```
ana@vm:~$ id -u
1001
ana@vm:~$ id -un
ana
ana@vm:~$ id -gn
ana
ana@vm:~$ id -nG
ana sudo team
```

`-u` usuário, `-g` grupo primário, `-G` todos os grupos, `-n` para nomes em vez de números. O
`groups` sozinho é o `id -nG` com nome mais curto, e aceita uma conta:

```
ana@vm:~$ groups bruno
bruno : bruno team
```

## Onde isso fica escrito

```
ana@vm:~$ getent group team
team:x:1004:ana,bruno
ana@vm:~$ getent passwd ana
ana:x:1001:1002::/home/ana:/bin/bash
```

Dois arquivos de texto, uma linha cada, separados por dois-pontos. O `/etc/group` é
`nome:x:gid:membros`, e aqueles membros são as participações **suplementares**. O `/etc/passwd` é
onde mora a primária — o `1002` na linha da ana, quarto campo.

**Então a participação da ana no `team` está escrita no `/etc/group`, e a participação dela no
`ana` não está.** Isso pega quem lê o `/etc/group` procurando alguém e não encontra.

`getent` em vez de `grep` é o hábito que vale construir. Ele pergunta ao serviço de nomes do
sistema, então responde certo numa máquina cujas contas vêm de LDAP ou Active Directory em vez de
um arquivo — e a aula 5 é onde isso importa.

## Acrescentar alguém a um grupo

```
sudo usermod -aG team bruno
```

**O `-a` não é opcional.** `usermod -G team bruno` define os grupos suplementares dele como
exatamente `team` — removendo todos os outros que ele tinha, em silêncio. É o jeito mais comum de
trancar alguém para fora do `sudo`, e está a um argumento de distância do comando correto.

`gpasswd -a bruno team` faz a mesma coisa e não tem como errar desse jeito específico.

## A parte que confunde todo mundo: não faz efeito

```
ana@vm:~$ id -nG
ana sudo team
ana@vm:~$ sudo usermod -aG deploy ana
[sudo] password for ana:
ana@vm:~$ id -nG
ana sudo team
ana@vm:~$ getent group deploy
deploy:x:1006:ana
```

A mudança funcionou — o `/etc/group` diz isso na última linha — e o `id` neste shell continua sem
enxergar.

**A participação em grupos é anexada a um processo quando ele começa**, e herdada pelos filhos dele.
Seu shell começou antes da mudança, então ele carrega a lista antiga, e tudo que você roda a partir
dele também. Nada vai atualizar isso.

O conserto de verdade é sair e entrar de novo. Existe também um jeito de ganhar um shell com o
grupo novo:

```
ana@vm:~$ newgrp deploy
ana@vm:~$ id -nG
deploy sudo ana team
ana@vm:~$ id -gn
deploy
ana@vm:~$ touch /tmp/newgrp-test.txt
ana@vm:~$ ls -l /tmp/newgrp-test.txt
-rw-r--r-- 1 ana deploy 0 Sep 14 22:56 /tmp/newgrp-test.txt
ana@vm:~$ exit
ana@vm:~$ id -nG
ana sudo team
```

Leia o que o `newgrp` fez. Ele iniciou **um shell novo** — é por isso que o `exit` voltou para o
antigo — com o `deploy` como grupo **primário**, e é por isso que o arquivo criado ali pertence ao
`deploy` em vez de ao `ana`.

Essa última parte é a metade útil: o `newgrp` é como se criam arquivos com um grupo sem mudar a
conta. `sg deploy -c 'comando'` faz isso para um comando em vez de um shell inteiro.

**Quando alguém diz "te coloquei no grupo e continua não funcionando", é por isso, em nove de cada
dez vezes.** Saia. Entre de novo. Depois olhe as permissões.

## Grupos que você não criou

Uma máquina chega com uns vinte, e vale reconhecer estes:

| | |
|---|---|
| `sudo`, ou `wheel` no Red Hat | pode usar o `sudo` — seção 11 |
| `adm` | pode ler os logs de `/var/log` |
| `docker` | pode falar com o daemon do Docker, **que na prática é root** |
| `www-data` | a conta com que um servidor web roda |
| `users` | um grupo geral; algumas distribuições usam, a maioria não |

**O `docker` merece o aviso.** Quem está nele pode subir um contêiner que monta `/` e escreve lá
dentro, o que é uma escalada completa para root sem senha. Colocar alguém no grupo `docker` é a
mesma decisão que dar `sudo`, e normalmente é tomada como se não fosse.
