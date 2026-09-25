---
title: Variáveis de ambiente: ajustes que todo programa lê
version: 1
---

Todo processo carrega um conjunto de valores com nome, as **variáveis de ambiente**, que ele passa
adiante para todo programa que inicia. Elas respondem perguntas como *onde é a pasta desta pessoa* e
*onde estão os programas*.

```
ana@server:~$ echo $HOME
/home/ana
ana@server:~$ echo $PATH | tr ":" "\n" | head -4
/usr/local/sbin
/usr/local/bin
/usr/sbin
/usr/bin
ana@server:~$ printenv USER SHELL
ana
/bin/bash
PS /home/ana> $env:HOME
/home/ana
PS /home/ana> $env:USER
ana
```

- O **`$HOME`** é a pasta pessoal e o `$USER` o nome da conta. O `echo` os imprime; o `printenv`
  também, sem o `$`.
- O **`$PATH`** é a lista de pastas procuradas, em ordem, quando você digita o nome de um comando. É por
  isso que o `ls` roda o `/usr/bin/ls` sem ninguém digitar a pasta, e por que um programa instalado num
  lugar fora da lista é "command not found" embora esteja no disco. No Linux e no macOS as pastas são
  separadas por `:`.
- O PowerShell lê as mesmas variáveis como **`$env:HOME`**, `$env:USER`, a unidade `env:`.

No Windows os nomes e o separador mudam:

```sh
echo %USERPROFILE%
echo %PATH%
```

```sh
$env:USERPROFILE                  # C:\Users\ana
$env:Path -split ';'              # one folder per line
```

**`%NOME%`** no Prompt de Comando, `$env:NOME` no PowerShell, e as pastas do `PATH` separadas por
`;`, porque o `:` já aparece em todo caminho do Windows depois da letra da unidade. A pasta pessoal é
**`USERPROFILE`**, não `HOME`.
