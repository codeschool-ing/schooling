---
title: Achar um pacote, e achar de onde veio um arquivo
version: 1
---

Quatro perguntas, e cada uma tem um comando. Elas são perguntas diferentes e as pessoas usam a
ferramenta errada em três delas.

| | |
|---|---|
| "como este pacote se chama?" | `apt search` |
| "o que tem neste pacote?" | `apt show`, `dpkg -L` |
| "o que pôs este arquivo aqui?" | `dpkg -S` |
| "qual pacote me daria este arquivo?" | `apt-file search` |

A terceira e a quarta parecem iguais e são opostas: **o `dpkg -S` pergunta ao banco de dados do que
está instalado; o `apt-file` pergunta aos repositórios sobre o que não está.**

## Buscar por nome e por descrição

```
root@vm:~# apt search "^ripgrep$" 2>/dev/null
Sorting... Done
Full Text Search... Done
ripgrep/noble,now 14.1.0-1 amd64 [installed]
  Recursively searches directories for a regex pattern
```

O `apt search` compara com o **nome e a descrição**, que é por que ele é bom em "algo que faz X" e
ruim em "a coisa chamada X". O padrão é uma expressão regular, então o `^ripgrep$` o prende
exatamente àquele nome — sem as âncoras você recebe tudo cuja descrição o mencione.

Leia a linha que ele imprimiu: `ripgrep/noble,now 14.1.0-1 amd64 [installed]`. A suíte de onde ele
vem, a versão, a arquitetura, e o `[installed]` — quatro fatos numa linha, e o último é o que as
pessoas não veem e reinstalam por cima.

O `apt-cache search` é a grafia mais antiga e imprime uma lista mais simples:

```
root@vm:~# apt-cache search json | head -5
libapache2-mod-php8.0 - server-side, HTML-embedded scripting language (Apache 2 module)
libapache2-mod-php8.1 - server-side, HTML-embedded scripting language (Apache 2 module)
libapache2-mod-php8.2 - server-side, HTML-embedded scripting language (Apache 2 module)
libapache2-mod-php8.3 - server-side, HTML-embedded scripting language (Apache 2 module)
libapache2-mod-php8.4 - server-side, HTML-embedded scripting language (Apache 2 module)
```

Cinco módulos de PHP numa busca por `json`, porque a descrição de cada um o menciona em algum lugar.
**É esse o modo de falha da busca por descrição**, e é por isso que vale digitar `^nome$`.

## O que está instalado

```
root@vm:~# apt list --installed 2>/dev/null | head -6
Listing...
acl/noble-updates,now 2.3.2-1build1.1 amd64 [installed]
adduser/noble,now 3.137ubuntu1 all [installed]
adwaita-icon-theme/noble,now 46.0-1 all [installed]
age/noble-updates,noble-security,now 1.1.1-1ubuntu0.24.04.3 amd64 [installed]
apt-transport-https/noble-updates,now 2.8.3 all [installed]
```

Repare na linha do `age`: `noble-updates,noble-security,now`. **Aquele pacote está disponível em duas
suítes** e a de segurança é por que isso importa — um pacote que lista `noble-security` teve uma
atualização de segurança publicada, que é coisa diferente de um aumento de versão normal.

O `dpkg -l` é o outro jeito de perguntar, e é aquele cuja saída é uma tabela com coluna de estado:

```
root@vm:~# dpkg -l cowsay
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name           Version      Architecture Description
+++-==============-============-============-=================================
ii  cowsay         3.03+dfsg2-8 all          configurable talking cow
```

**Aquelas três primeiras linhas são uma legenda, impressa toda vez, e são a chave do `ii`.** A
primeira letra é o que você quer, a segunda é o que é verdade, a terceira é se há erro. O `ii` é
"quer instalado, está instalado, sem erro" — e a seção 08 mostra um `rc` e a seção 07 mostra um
`iU`.

## O que um pacote pôs no disco

```
root@vm:~# dpkg -L cowsay | head -8
/.
/usr
/usr/games
/usr/games/cowsay
/usr/share
/usr/share/cowsay
/usr/share/cowsay/cows
/usr/share/cowsay/cows/apt.cow
```

Todo caminho que o pacote possui, diretórios incluídos. **É assim que você acha onde algo de fato se
instalou** quando não está no seu `PATH` — e o `cowsay` é um exemplo real, porque ele vai para o
`/usr/games`:

```
root@vm:~# which cowsay
/usr/games/cowsay
```

O `dpkg -L coisa | grep bin` é o atalho quando você só quer os comandos, e o `dpkg -L coisa | grep
etc` quando você quer saber o que ele vai configurar.

## O que pôs este arquivo aqui

```
root@vm:~# dpkg -S /usr/games/cowsay
cowsay: /usr/games/cowsay
root@vm:~# dpkg -S /usr/bin/ls
coreutils: /usr/bin/ls
root@vm:~# dpkg -S /usr/bin/zipinfo
unzip: /usr/bin/zipinfo
```

**Este é o de ter nos dedos.** Um binário estranho, um arquivo de configuração que você não escreveu,
uma biblioteca numa versão que te surpreende — o `dpkg -S` nomeia o pacote num instante, porque é uma
consulta a banco de dados e não uma busca.

E a resposta que mais ensina é aquela em que não há resposta:

```
root@vm:~# dpkg -S /usr/local/bin/python3
dpkg-query: no path found matching pattern /usr/local/bin/python3
```

**Nada é dono dele.** A aula 3 disse que o `/usr/local` é para software que você instalou, e esta é
aquela frase com dentes: um arquivo ali não foi empacotado, não vai ser atualizado, não vai ser
removido, e não vai ser mencionado por nada desta aula. Ele é seu. A seção 13 é sobre como esses
chegam lá.

O `rpm -qf` é a mesma pergunta na outra família, e a seção 10 o usa.

## O arquivo que você ainda não tem

O `dpkg -S` não responde "qual pacote me daria o `pdftotext`", porque o pacote não está instalado e a
lista de arquivos dele não está na sua máquina. O `apt-file` baixa as listas de arquivos para
conseguir:

```
root@vm:~# apt-file search bin/pdftotext
poppler-utils: /usr/bin/pdftotext         
root@vm:~# which pdftotext; echo "exit: $?"
exit: 1
```

**O arquivo não está nesta máquina e a pergunta foi respondida do mesmo jeito.** O `which` não acha
nada; o `apt-file` nomeia o pacote que o forneceria. Esse é o comando para "o bash diz command not
found e eu não sei o que instalar".

Ele custa duas coisas. A primeira é instalá-lo — `apt install apt-file` — e a segunda é um download
de índice separado, o `apt-file update`, que não é pequeno:

```
root@vm:~# du -sh /var/lib/apt/lists
346M    /var/lib/apt/lists
```

A maior parte daqueles 346 MB são os arquivos `Contents` que o `apt-file update` buscou. **É por isso
que ele não vem instalado**: vale a pena numa máquina em que você constrói coisas, e é dispensável
num servidor em que você já sabe o que está instalando.

O `apt-file list poppler-utils` é a outra direção — tudo que um pacote instalaria, sem instalá-lo.

O `dnf provides '*/pdftotext'` faz o mesmo trabalho do lado rpm sem download extra, porque os
metadados de repositório do dnf já incluem as listas de arquivos.
