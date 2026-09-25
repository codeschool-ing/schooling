---
title: Por que um programa se recusa a rodar
version: 1
---

Um programa é feito para *uma arquitetura de processador*, *um sistema*, e muitas vezes para
*versões específicas* das bibliotecas que usa. Qualquer uma das três pode recusá-lo.

```
ana@server:~$ dpkg --print-architecture
amd64
ana@server:~$ ldd /usr/bin/ls
        linux-vdso.so.1 (0x00007fd6a8823000)
        libselinux.so.1 => /lib/x86_64-linux-gnu/libselinux.so.1 (0x00007fd6a87c6000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fd6a8400000)
        libpcre2-8.so.0 => /lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007fd6a872c000)
        /lib64/ld-linux-x86-64.so.2 (0x00007fd6a8825000)
ana@server:~$ ldd --version | head -1
ldd (Ubuntu GLIBC 2.39-0ubuntu8.9) 2.39
PS /home/ana> $PSVersionTable.PSEdition
Core
PS /home/ana> $PSVersionTable.PSVersion.ToString()
7.6.6
```

- `amd64` é a arquitetura deste servidor, a de 64 bits da Intel e da AMD. Um programa feito para
  `arm64`, o Apple silicon da aula 4 e o Windows on Arm da aula 5, não roda aqui sem um emulador.
- O `ldd` lista as **bibliotecas compartilhadas** de que um programa precisa. O `ls` precisa de
  algumas, entre elas a `libc.so.6`, a biblioteca C, aqui a **glibc 2.39**. Um programa compilado num
  sistema mais novo contra a glibc 2.40 se recusa a iniciar neste, e é por isso que um binário copiado de
  uma distribuição mais nova falha com *version GLIBC_2.40 not found*, e por que os pacotes vêm da
  distribuição e não de outra.
- O PowerShell diz qual é: **`Core`** é o PowerShell 7; `Desktop` é o Windows PowerShell 5.1. Um
  script escrito para um pode falhar no outro, o ponto da aula 5 sobre qual você vai encontrar.

## As mesmas três em cada sistema

| | a arquitetura | o sistema | a versão |
|---|---|---|---|
| Windows | programas de 32 bits rodam no Windows de 64; x64 roda no Arm pelo Prism | só programas do Windows | o *Modo de compatibilidade*, nas propriedades de um programa, finge ser um Windows mais velho |
| macOS | apps Intel rodam no Apple silicon pelo **Rosetta 2** | só apps do Mac | um app diz o macOS mais velho que aceita |
| Linux | `dpkg --add-architecture` para pacotes de 32 bits | só programas do Linux | bibliotecas da mesma distribuição e versão |

O **Modo de compatibilidade** vale uma frase: muitos programas velhos do Windows que se recusam a
iniciar só perguntaram *que Windows é este?* e não gostaram da resposta, o `ProductName` da aula 5 visto
do outro lado. Dizer a eles uma versão mais velha muitas vezes basta.
