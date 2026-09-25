---
title: Pedindo ao kernel: chamadas de sistema
version: 1
---

A seção 02 disse que os programas nunca mexem no hardware; eles pedem ao kernel. No Linux dá para
ver o pedido. O `strace` roda um programa e anota cada pedido que ele faz ao kernel. A Ana o usa no
`cat`, que imprime um arquivo:

```
ana@server:~/office$ strace -e trace=openat,read,write -o trace.txt cat notice.txt
Ribeiro Contabilidade
Open 8:00 to 18:00
ana@server:~/office$ grep -A3 notice.txt trace.txt
openat(AT_FDCWD, "notice.txt", O_RDONLY) = 3
read(3, "Ribeiro Contabilidade\nOpen 8:00 "..., 131072) = 41
write(1, "Ribeiro Contabilidade\nOpen 8:00 "..., 41) = 41
read(3, "", 131072)                     = 0
```

Quatro pedidos, e eles são tudo o que o `cat` faz:

1. `openat(..., "notice.txt", O_RDONLY) = 3`: *abra este arquivo para leitura.* O kernel confere que
   o arquivo existe e que a Ana pode lê-lo, e responde com um número, `3`, que o programa vai usar
   para se referir a ele daqui em diante.
2. `read(3, ...) = 41`: *me dê até 131072 bytes do arquivo 3.* O kernel busca os 41 bytes que o
   arquivo tem, no disco ou no cache da seção anterior.
3. `write(1, ...) = 41`: *escreva estes 41 bytes no 1.* O número 1 é a tela, ou mais exatamente o
   terminal, que todo programa recebe já aberto.
4. `read(3, "", ...) = 0`: *tem mais?* Zero bytes quer dizer fim do arquivo, e o `cat` para.

Em nenhum momento o `cat` sabe onde fica o disco, de que tipo ele é ou como o terminal desenha as
letras. O kernel faz tudo isso, e é por isso que o mesmo `cat` funciona em qualquer disco e qualquer
tela.

## Dois modos

O próprio processador garante essa separação. Os programas rodam em **modo usuário**, em que as
instruções que mexem no hardware são proibidas. Uma chamada de sistema passa para o **modo kernel**,
o kernel faz o trabalho e o controle volta. Um programa que se comporta mal em modo usuário trava
sozinho. Uma falha em modo kernel derruba a máquina inteira: a *tela azul* do Windows, o *kernel
panic* do Linux, o macOS reiniciando com *o computador reiniciou por causa de um problema*.

É por isso que um driver com defeito (próxima seção) é mais perigoso que um programa com defeito: os
drivers rodam em modo kernel.

## Nos outros dois

Windows e macOS fazem os mesmos tipos de pedido com outros nomes. As ferramentas que os mostram, o
Process Monitor no Windows e o `dtruss` no macOS, são os equivalentes do `strace`, e nenhuma delas
foi rodada para esta aula.
