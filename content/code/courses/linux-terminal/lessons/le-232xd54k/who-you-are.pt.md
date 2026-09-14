---
title: Uma máquina com mais de uma pessoa nela
version: 1
---

O Linux foi construído num mundo em que um computador servia um departamento, e **ele nunca deixou
de assumir isso**. Mesmo num laptop em que ninguém mais toca, o sistema é arrumado como se várias
pessoas e vários programas o dividissem e não devessem conseguir alcançar as coisas uns dos outros.

Essa suposição é o motivo de você não ser o administrador, e de isso ser uma qualidade.

## Você é um número com um nome pendurado

```
ana@vm:~$ id
uid=1001(ana) gid=1002(ana) groups=1002(ana)
```

O nome é para você; o número é o que o sistema usa. `uid` é o usuário, `gid` o grupo primário, e
`groups` todos os grupos a que você pertence. A aula 4 é construída sobre esses três.

A sua conta é uma linha num arquivo de texto, como todo o resto:

```
ana@vm:~$ grep "^ana" /etc/passwd
ana:x:1001:1002::/home/ana:/bin/bash
```

Sete campos, separados por dois-pontos:

| campo | valor aqui | |
|---|---|---|
| nome | `ana` | |
| senha | `x` | **não** é a senha — quer dizer "veja em `/etc/shadow`" |
| uid | `1001` | |
| gid | `1002` | o grupo primário |
| comentário | *(vazio)* | um nome completo, historicamente |
| casa | `/home/ana` | para onde o `~` aponta |
| shell | `/bin/bash` | o que inicia quando você loga — o `$SHELL` da seção 03 |

## O root é o uid 0, e não é uma pessoa

```
ana@vm:~$ head -1 /etc/passwd
root:x:0:0:root:/root:/bin/bash
```

**O zero é tudo.** O kernel não confere permissões para o uid 0; ele confere para todo o resto. O
root não é "uma conta com muitas permissões" — é a conta para a qual a verificação de permissão é
pulada.

E é por isso que o `#` da seção 06 merece ser lido antes de você apertar enter. Não há diálogo, não
há "tem certeza", e não há desfazer.

## A maioria das contas não é gente

```
ana@vm:~$ grep -c "" /etc/passwd
26
```

Vinte e seis contas numa máquina com quatro humanos. O resto pertence a **programas**: o servidor
web ganha uma, o banco de dados ganha uma, o sistema de impressão ganha uma.

Essa é a razão profunda do projeto multiusuário, e não tem nada a ver com dividir um computador. Se
o servidor web roda como um usuário próprio, então uma falha nele alcança exatamente o que aquele
usuário pode alcançar — não os seus documentos, não o banco, não a máquina. **A conta é um raio de
alcance.** A aula 5 cria uma; todo curso depois deste depende disso.

## Como é o "você não pode"

```
ana@vm:~$ ls -l /etc/shadow
-rw-r----- 1 root shadow 677 Sep 14 13:00 /etc/shadow
ana@vm:~$ cat /etc/shadow
cat: /etc/shadow: Permission denied
```

Leia essas duas linhas juntas e a recusa deixa de ser misteriosa. O arquivo pertence ao `root`, o
grupo dele é `shadow`, e as permissões dão leitura e escrita ao dono, leitura ao grupo, e **nada a
todo o resto** — é isso que as três posições vazias no fim querem dizer.

A `ana` não é root e não está no `shadow`, então a `ana` cai em "todo o resto". O kernel conferiu e
disse não, exatamente como a seção 03 prometeu: o shell achou o `cat`, o `cat` pediu, e o kernel
recusou.

Aquele arquivo guarda os hashes das senhas. As permissões dele são a razão inteira de você não
conseguir ler a senha dos seus colegas, e são nove bits numa listagem que você pode imprimir.

## Por que você não é root por padrão

O Windows passou uma década ensinando as pessoas a clicar "Sim" num aviso. O Linux vai pelo outro
caminho: **você é um usuário comum, e virar root é um ato explícito, para um comando.**

O ganho não é impedir que você faça estrago — você sempre pode pedir. É que o estrago exige que
você tenha dito isso. Um erro de digitação num comando rodado como você mesmo pode destruir os seus
arquivos. O mesmo erro como root pode destruir a máquina.

A seção 61 da aula 4 é o `sudo`, que é como se pede. Até lá, o reflexo útil é o da seção 06: **olhe
o último caractere do prompt.**
