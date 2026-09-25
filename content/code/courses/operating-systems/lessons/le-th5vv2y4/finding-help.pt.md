---
title: Achando ajuda para um comando
version: 1
---

Ninguém lembra de toda opção. A habilidade é saber onde está a resposta, e todo shell a carrega.

```
ana@server:~$ ls --help | head -8
Usage: ls [OPTION]... [FILE]...
List information about the FILEs (the current directory by default).
Sort entries alphabetically if none of -cftuvSUX nor --sort is specified.

Mandatory arguments to long options are mandatory for short options too.
  -a, --all                  do not ignore entries starting with .
  -A, --almost-all           do not list implied . and ..
      --author               with -l, print the author of each file
ana@server:~$ type cd ls
cd is a shell builtin
ls is hashed (/usr/bin/ls)
PS /home/ana> (Get-Command -Verb Get).Count
61
PS /home/ana> Get-Command -Noun Location | Select-Object Name

Name
----
Get-Location
Pop-Location
Push-Location
Set-Location
```

- `--help` depois de quase qualquer comando do Linux imprime as opções dele. É comprido, então
  costuma ser lido pelo `head`, ou pelo `less` para rolar.
- `type` diz o que um nome é de fato. O `cd` é um **builtin**, parte do próprio shell, e é por isso
  que ele consegue mudar a pasta do próprio shell; o `ls` é um programa no disco, em `/usr/bin/ls`.
- `Get-Command` faz os dois trabalhos no PowerShell. O `-Verb Get` contou 61 cmdlets cujo nome
  começa com `Get-` nesta instalação, e o `-Noun Location` achou todo cmdlet que trabalha com locais,
  incluindo dois que você não sabia que devia procurar.

Esse último truque é o que os nomes Verbo-Substantivo compram. **Adivinhe o substantivo, peça por ele e
leia os verbos**: o `Get-Command -Noun Service` no Windows lista tudo o que gerencia serviços antes de
você saber o nome de qualquer um.

## Os manuais completos

Numa instalação Linux normal, o **`man ls`** abre a página de manual completa, com toda opção e
exemplos. No PowerShell, o **`Get-Help Set-Location -Examples`** faz o mesmo, depois que o
`Update-Help` baixou os arquivos de ajuda uma vez. O servidor da aula 3 é uma instalação mínima e deixa
os manuais de fora, então aqui o primeiro deles nem existe:

```
ana@server:~$ man ls
bash: man: command not found
```

O `sudo apt install man-db` o traz de volta, que é o assunto da aula 11.
