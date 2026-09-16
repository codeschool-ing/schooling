---
title: Três públicos, e só um deles é você
version: 1
---

Todo arquivo tem um **dono** e um **grupo**, e a aula 3 seção 06 já te mostrou os dois:

```
-rw-r----- 1 ana team 13 Sep 14 22:45 teamonly.txt
```

A `ana` é dona. O grupo é `team`. E os nove caracteres da frente são três conjuntos de três:

| | caracteres | vale para |
|---|---|---|
| **user** | `rw-` | a `ana`, dona do arquivo |
| **group** | `r--` | qualquer um do grupo `team` |
| **other** | `---` | todo o resto |

O Linux chama de *user*, *group* e *other* — **u**, **g**, **o** — que é de onde o `chmod u+x`
tira as letras dele.

## Três pessoas, um arquivo, três respostas

Aqui está o mesmo diretório lido por três contas. O `bruno` está no grupo `team`; a `carla` não.

**`ana`, a dona:**

```
ana@vm:/srv/perm$ id
uid=1001(ana) gid=1002(ana) groups=1002(ana),27(sudo),1004(team)
```

**`bruno`, do grupo:**

```
bruno@vm:/srv/perm$ id
uid=1002(bruno) gid=1003(bruno) groups=1003(bruno),1004(team)
bruno@vm:/srv/perm$ ls -l
total 16
-rw------- 1 ana ana   9 Sep 14 22:45 private.txt
-rw-r--r-- 1 ana ana  22 Sep 14 22:45 public.txt
-rwxr-xr-x 1 ana ana  34 Sep 14 22:45 script.sh
-rw-r----- 1 ana team 13 Sep 14 22:45 teamonly.txt
bruno@vm:/srv/perm$ cat public.txt
anybody can read this
bruno@vm:/srv/perm$ cat private.txt
cat: private.txt: Permission denied
bruno@vm:/srv/perm$ cat teamonly.txt
for the team
bruno@vm:/srv/perm$ echo 'bruno' >> teamonly.txt
bash: line 11: teamonly.txt: Permission denied
```

Quatro comandos, quatro resultados diferentes, e cada um decidido por um conjunto diferente de três
caracteres. O `public.txt` é `r--` para other, então ele lê. O `private.txt` é `---` para other,
então ele não lê. O `teamonly.txt` é `r--` para **group**, e ele está no `team`, então ele lê e não
consegue escrever.

**`carla`, de nenhum dos dois:**

```
carla@vm:/srv/perm$ id
uid=1003(carla) gid=1005(carla) groups=1005(carla)
carla@vm:/srv/perm$ cat public.txt
anybody can read this
carla@vm:/srv/perm$ cat teamonly.txt
cat: teamonly.txt: Permission denied
```

Mesmo arquivo, mesmos bits, resposta diferente — porque a linha do *group* não valia para ela e a
de *other* valia.

**Repare no que mudou e no que não mudou.** O arquivo nunca mudou. Nada foi reconfigurado entre
aquelas duas sessões. A única variável é quem perguntou, e qual das três linhas a identidade dessa
pessoa seleciona.

## A regra que as pessoas erram

**Exatamente um dos três conjuntos vale para você, e é o primeiro que casa:**

1. Você é o **dono**? Então valem os bits de user, e os outros dois são irrelevantes para você.
2. Se não, você está no **grupo**? Então valem os bits de group.
3. Se não, valem os bits de **other**.

A intuição que todo mundo traz — *sou o dono e também estou no grupo, então ganho o mais generoso
dos dois* — está errada, e aqui está um arquivo feito para provar:

```
ana@vm:/srv/perm$ ls -l trap.txt
-r--rwxrwx 1 ana team 9 Sep 14 22:45 trap.txt
ana@vm:/srv/perm$ id -nG
ana sudo team
ana@vm:/srv/perm$ cat trap.txt
the trap
ana@vm:/srv/perm$ echo 'ana' >> trap.txt
bash: line 7: trap.txt: Permission denied
```

Leia o modo: `r--` para o dono, `rwx` para o grupo, `rwx` para todo o resto. **A ana é dona, a ana
está no `team`, e a ana não consegue escrever.** O bruno consegue. A carla consegue. A dona é a
única pessoa trancada do lado de fora, porque a linha dela é conferida primeiro e a linha dela diz
`r--`.

Parece bug e é o projeto. A linha do dono existe para que um dono possa *deliberadamente* se dar
menos que todo mundo — um arquivo que você quer ter certeza de não sobrescrever sem querer é
exatamente isso. E o root ignora tudo isso de qualquer forma, que é a seção 11.

## O que as três letras querem dizer

| | num arquivo |
|---|---|
| `r` | ler o conteúdo |
| `w` | alterar o conteúdo |
| `x` | executar como programa |
| `-` | não pode |

Num **diretório** as mesmas três letras querem dizer outra coisa, e esse é o assunto inteiro da
seção 06. Não leve os significados de arquivo para lá; eles vão te enganar.

## Duas coisas que não estão nos nove caracteres

**Apagar um arquivo não é controlado pelos bits do arquivo.** É controlado pelos bits do
**diretório** — porque remover um arquivo é remover um nome de um diretório, o que é uma alteração
no diretório. É por isso que você consegue apagar um arquivo que não consegue ler, e é por isso que
o `/tmp` precisa do bit extra da seção 10.

**Nada aqui conhece pessoas.** Estas são *contas* de usuário e grupos, casados por número. A seção
08 é de onde esses números vêm, e a aula 5 é onde as contas de fato moram.