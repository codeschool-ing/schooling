---
title: Espaços, e letras maiúsculas
version: 1
---

Duas coisas que são invisíveis num desktop decidem se um comando funciona.

## Um espaço separa palavras

O shell divide o que você digita em cada espaço, e o `cd` recebeu duas palavras:

```
ana@server:~$ cd office
ana@server:~/office$ cd invoices 2026
bash: cd: too many arguments
ana@server:~/office$ cd "invoices 2026"
ana@server:~/office/invoices 2026$ pwd
/home/ana/office/invoices 2026
```

O `cd invoices 2026` pediu ao `cd` para ir para `invoices` *e* `2026`, e o `cd` vai para um lugar só.
**As aspas fazem disso uma palavra**, e uma barra invertida antes do espaço também: `cd invoices\ 2026`.
O erro aqui é inofensivo; o mesmo engano com um comando que apaga pode remover duas coisas em vez de
uma.

**A tecla Tab põe as aspas por você.** Digite `cd inv` e aperte Tab: o shell completa o nome e escapa o
espaço sozinho. É também o jeito mais rápido de digitar qualquer nome comprido, e a checagem mais
segura de que um arquivo existe, porque o Tab só completa o que está lá.

## Maiúsculas são outras letras

```
ana@server:~$ cd office
ana@server:~/office$ ls Notes.txt
ls: cannot access 'Notes.txt': No such file or directory
ana@server:~/office$ ls notes.txt
notes.txt
```

**No Linux, `Notes.txt` e `notes.txt` são dois nomes diferentes**, o ponto da aula 3 encontrado de novo
no prompt. No Windows e, por padrão, no macOS, são o mesmo arquivo. Um script escrito num notebook que
diz `Notes.txt` pode funcionar ali por anos e falhar no servidor na primeira vez.

## No Windows

Os caminhos usam `\`, começam com uma **letra de unidade** e *não diferenciam maiúsculas*:
`cd c:\users` e `cd C:\Users` vão para o mesmo lugar. Espaços precisam de aspas do mesmo jeito, e eles
estão em todo canto dos caminhos do Windows, a começar por `C:\Program Files`. O PowerShell também
aceita `/`, e é por isso que a mesma linha de PowerShell muitas vezes funciona nos dois sistemas.
