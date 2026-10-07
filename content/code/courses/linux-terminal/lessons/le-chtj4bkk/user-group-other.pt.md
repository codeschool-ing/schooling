---
title: Três públicos, e só um deles é você
version: 2
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

## As contas e os arquivos que esta aula usa

Permissão é sobre quem pergunta, então esta aula precisa de mais de uma pessoa. O `bruno` foi criado
na seção 14 da aula 3; isto cria a `carla`, um grupo chamado `team` com a `ana` e o `bruno` dentro, e
alguns arquivos e diretórios em `/srv` com exatamente as permissões que as seções abaixo leem. A
carla e o bruno ganham uma senha, `practice`, porque a seção 11 e a aula 5 os fazem digitar uma. Copie tudo para o terminal;
ele pede a sua senha uma vez:

```sh
id bruno >/dev/null 2>&1 || sudo useradd -m -s /bin/bash bruno
sudo groupadd team
sudo useradd -m -s /bin/bash carla
echo 'carla:practice' | sudo chpasswd
echo 'bruno:practice' | sudo chpasswd
sudo usermod -aG team ana
sudo usermod -aG team bruno
sudo mkdir -p /srv/perm /srv/closed /srv/dirbits/r /srv/dirbits/rx /srv/dirbits/x /srv/team
cd /srv/perm
printf 'a secret\n' | sudo tee private.txt > /dev/null
printf 'anybody can read this\n' | sudo tee public.txt > /dev/null
printf '#!/bin/bash\necho "the script ran"\n' | sudo tee script.sh > /dev/null
printf 'for the team\n' | sudo tee teamonly.txt > /dev/null
printf 'the trap\n' | sudo tee trap.txt > /dev/null
sudo chown ana:ana private.txt public.txt script.sh
sudo chown ana:team teamonly.txt trap.txt
sudo chmod 600 private.txt
sudo chmod 644 public.txt
sudo chmod 755 script.sh
sudo chmod 640 teamonly.txt
sudo chmod 477 trap.txt
printf 'readable\n' | sudo tee /srv/closed/readable.txt > /dev/null
sudo chown -R ana:ana /srv/closed
sudo chmod 700 /srv/closed
for d in r rx x; do printf 'the contents\n' | sudo tee /srv/dirbits/$d/file.txt > /dev/null; done
sudo chown -R ana:ana /srv/dirbits
sudo chmod 444 /srv/dirbits/r
sudo chmod 555 /srv/dirbits/rx
sudo chmod 111 /srv/dirbits/x
sudo chown root:team /srv/team
sudo chmod 2775 /srv/team
cd
# Then log out and back in, so that ana's new group applies to her (section 08 says why).
```

As aulas 5 e 7 também mexem na máquina, e um snapshot tirado agora é um bom lugar para onde voltar.
Para ser outra pessoa por um instante, `sudo -iu bruno` abre um shell como ele e `exit` o fecha.

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
total 20
-rw------- 1 ana ana   9 Oct  7 11:27 private.txt
-rw-r--r-- 1 ana ana  22 Oct  7 11:27 public.txt
-rwxr-xr-x 1 ana ana  34 Oct  7 11:27 script.sh
-rw-r----- 1 ana team 13 Oct  7 11:27 teamonly.txt
-r--rwxrwx 1 ana team  9 Oct  7 11:27 trap.txt
bruno@vm:/srv/perm$ cat public.txt
anybody can read this
bruno@vm:/srv/perm$ cat private.txt
cat: private.txt: Permission denied
bruno@vm:/srv/perm$ cat teamonly.txt
for the team
bruno@vm:/srv/perm$ echo 'bruno' >> teamonly.txt
bash: teamonly.txt: Permission denied
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
-r--rwxrwx 1 ana team 9 Oct  7 11:27 trap.txt
ana@vm:/srv/perm$ id -nG
ana sudo team
ana@vm:/srv/perm$ cat trap.txt
the trap
ana@vm:/srv/perm$ echo 'ana' >> trap.txt
bash: trap.txt: Permission denied
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