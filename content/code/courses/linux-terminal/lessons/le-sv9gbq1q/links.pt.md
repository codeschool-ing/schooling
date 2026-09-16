---
title: Inodes, hard links e links simbólicos
version: 1
---

Um nome de arquivo não é um arquivo. **O arquivo é uma coisa numerada no disco, e o nome é uma
entrada num diretório que aponta para aquele número.** Quando essa frase fica real para você, tudo
nesta seção fica óbvio — e várias coisas que você já viu param de ser estranhas.

O número se chama **inode**, e `ls -i` imprime:

```
ana@vm:~/hard$ ls -li
total 4
573516 -rw-r--r-- 1 ana ana 13 Sep 14 22:20 report.txt
```

`573516` é como o sistema de arquivos chama estes dados. `report.txt` é como o diretório os chama.
O inode guarda tudo que o `ls -l` te mostrou — permissões, dono, tamanho, horários e onde estão os
bytes. **O nome não está no inode.** O nome está no diretório.

## Um hard link é um segundo nome para o mesmo inode

```
ana@vm:~/hard$ ln report.txt hardlink.txt
ana@vm:~/hard$ ls -li
total 8
573516 -rw-r--r-- 2 ana ana 13 Sep 14 22:20 hardlink.txt
573516 -rw-r--r-- 2 ana ana 13 Sep 14 22:20 report.txt
```

Dois nomes. **Um inode.** E a contagem de links — o campo 3 da seção 06 — foi de `1` para `2`,
porque aquele campo é exatamente *quantos nomes apontam para cá*.

Nada foi copiado. Não existe original e cópia; existem dois nomes de mesma estatura, e o sistema de
arquivos não saberia dizer qual veio primeiro se você perguntasse. Mude um e você muda o outro,
porque só existe um:

```
ana@vm:~/hard$ printf 'changed\n' > report.txt
ana@vm:~/hard$ cat hardlink.txt
changed
```

E agora a parte que surpreende as pessoas:

```
ana@vm:~/hard$ rm report.txt
ana@vm:~/hard$ ls -li
total 4
573516 -rw-r--r-- 1 ana ana 8 Sep 14 22:20 hardlink.txt
ana@vm:~/hard$ cat hardlink.txt
changed
```

**O `rm` não apagou o arquivo.** Ele removeu um nome e decrementou a contagem, de 2 de volta para
1. Os dados continuam lá, alcançáveis pelo outro nome — e vão continuar lá até o último nome que
aponta para eles sumir.

É isso que o `rm` sempre fez. Num arquivo com um nome só, remover o nome e remover os dados parecem
o mesmo evento, e é por isso que ninguém repara. `unlink` é a chamada de sistema de verdade, e o
nome dela é honesto.

## Um link simbólico é um nome que contém um caminho

Um diretório novo, um arquivo, e um link feito com `-s`:

```
ana@vm:~/soft$ ln -s report.txt softlink.txt
ana@vm:~/soft$ ls -li
total 4
573518 -rw-r--r-- 1 ana ana 13 Sep 14 22:20 report.txt
573519 lrwxrwxrwx 1 ana ana 10 Sep 14 22:20 softlink.txt -> report.txt
```

Três diferenças em relação a um hard link, e cada uma importa:

- **inode próprio**, `573519` — é uma coisa separada no disco;
- **tipo `l`** na primeira coluna — o campo 1 da seção 06, pagando o aluguel;
- **tamanho 10**, que é o comprimento da string `report.txt`. Um link simbólico é só isso: um
  arquivo minúsculo cujo conteúdo é um caminho.

Abrir funciona, porque o kernel lê o caminho de dentro e recomeça a partir dali:

```
ana@vm:~/soft$ cat softlink.txt
the original
```

E então:

```
ana@vm:~/soft$ rm report.txt
ana@vm:~/soft$ cat softlink.txt
cat: softlink.txt: No such file or directory
ana@vm:~/soft$ ls -l softlink.txt
lrwxrwxrwx 1 ana ana 10 Sep 14 22:20 softlink.txt -> report.txt
```

**O link está inteiro. O que ele aponta sumiu.** O `ls` mostra sem problema — é um arquivo real,
com permissões reais — e tudo que tenta *seguir* falha. Isso é um link simbólico pendurado, e é o
jeito mais comum de um link simbólico te surpreender.

Dá para fazer um apontando para nada, e ninguém reclama:

```
ana@vm:~/soft$ ln -s /etc/nothing-here broken.txt
ana@vm:~/soft$ ls -l broken.txt
lrwxrwxrwx 1 ana ana 17 Sep 14 22:20 broken.txt -> /etc/nothing-here
```

O `ln -s` não confere, porque o alvo tem o direito de chegar depois — isso é uma funcionalidade, e
é como um link para dentro de um disco que ainda não foi montado deve se comportar.

## Os dois, lado a lado

| | hard link | link simbólico |
|---|---|---|
| criado com | `ln a b` | `ln -s a b` |
| é | outro nome para um inode | um arquivinho contendo um caminho |
| tem inode próprio? | não | sim |
| aparece no `ls -l` como | um arquivo comum | `l`, com `-> alvo` |
| sobrevive à remoção do alvo | **sim** — ele *é* o alvo | não, fica pendurado |
| atravessa sistemas de arquivos | não | sim |
| aponta para um diretório | não | sim |
| aponta para algo que não existe | não | sim |

**Duas dessas restrições são a razão de links simbólicos existirem.** Um hard link não atravessa um
sistema de arquivos, porque um número de inode só significa algo dentro de um sistema de arquivos.
E um hard link para diretório é proibido, porque permitiria montar um laço que o `find` percorreria
para sempre.

Na prática: **você vai usar links simbólicos, quase sempre.** Hard links aparecem em ferramentas de
backup que deduplicam, e na resposta para "por que apagar o log não liberou espaço nenhum" — seção
13.

## Relativo e absoluto, de novo

Um link simbólico guarda o caminho que você deu, sem alterar:

```
ana@vm:~/soft$ ln -s ../soft/report.txt rel.txt
ana@vm:~/soft$ ls -l rel.txt
lrwxrwxrwx 1 ana ana 18 Sep 14 22:20 rel.txt -> ../soft/report.txt
ana@vm:~/soft$ cat rel.txt
back again
```

**Um link relativo é resolvido a partir do diretório em que o link está**, não de onde você está ao
abri-lo. Esse é o comportamento sensato, e quer dizer que um link relativo sobrevive à árvore
inteira ser movida ou copiada para outro lugar.

Um link absoluto sobrevive ao *link* ser movido, e quebra quando o alvo se move. Escolha por qual
das duas coisas é mais provável.

Dois comandos respondem "para onde isto vai de verdade":

```
ana@vm:~/soft$ readlink rel.txt
../soft/report.txt
ana@vm:~/soft$ readlink -f rel.txt
/home/ana/soft/report.txt
```

`readlink` imprime o texto guardado. `readlink -f` segue cada link da cadeia e imprime o caminho
absoluto real no fim dela. O segundo é o que você quer quando algo está três links de profundidade
e você se perdeu.

## Onde você vai encontrá-los de verdade

**`/bin`, `/lib`, `/sbin`.** As setas da seção 02:

```
ana@vm:~/work$ ls -l /bin
lrwxrwxrwx 1 root root 7 Apr 22  2024 /bin -> usr/bin
ana@vm:~/work$ ls -ld /bin/
drwxr-xr-x 2 root root 36864 Mar 31 13:31 /bin/
```

Com `-l`, o `ls` descreve o link. Com uma barra no fim, ele atravessa. É o mesmo par de comandos
que a seção 05 te mostrou, e agora você sabe por que eles diferem.

**Software versionado.** `/usr/lib/libssl.so.3` é real; `/usr/lib/libssl.so` é um link simbólico
para ele. Atualizar move o link, e nada que se referia ao nome curto precisa mudar.

**`/etc/alternatives`.** No Debian e no Ubuntu, `/usr/bin/editor` é um link simbólico para dentro de
um diretório de links simbólicos, que é como o sistema deixa você escolher qual editor é "o editor"
sem mover programa nenhum.

**E uma armadilha que vale nomear uma vez**: `cp -r algumlink dest` copia o link, e não o que ele
aponta, a menos que você acrescente `-L`. Quando uma cópia sai cheia de links pendurados, é por
isso.
