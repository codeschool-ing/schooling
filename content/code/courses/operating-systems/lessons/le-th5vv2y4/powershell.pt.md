---
title: O mesmo passeio no PowerShell
version: 1
---

Os comandos do PowerShell se chamam **cmdlets**, e todos têm nome no formato **Verbo-Substantivo**:
`Get-Location`, `Set-Location`, `Get-ChildItem`. São mais longos para digitar e muito mais fáceis de
adivinhar. Eis o mesmo passeio, no PowerShell 7 do mesmo servidor:

```
PS /home/ana> Get-Location

Path
----
/home/ana

PS /home/ana> Set-Location office
PS /home/ana/office> Get-ChildItem

    Directory: /home/ana/office

UnixMode         User Group         LastWriteTime         Size Name
--------         ---- -----         -------------         ---- ----
drwxrwxr-x        ana ana        09/01/2026 09:00         4096 clients
drwxrwxr-x        ana ana        09/01/2026 09:00         4096 invoices 2026
drwxrwxr-x        ana ana        09/01/2026 09:00         4096 scans
-rw-rw-r--        ana ana        09/01/2026 09:00           25 notes.txt

PS /home/ana/office> Set-Location 'invoices 2026'
PS /home/ana/office/invoices 2026> Get-Location

Path
----
/home/ana/office/invoices 2026

PS /home/ana/office/invoices 2026> Set-Location ..
PS /home/ana/office> cd clients
PS /home/ana/office/clients> pwd

Path
----
/home/ana/office/clients
```

- **`Get-Location`** é o `pwd`, e responde com uma tabelinha, porque o que ele devolve é um objeto com
  uma propriedade `Path`. A seção 06 volta a isso.
- **`Set-Location`** é o `cd`. As aspas funcionam do mesmo jeito em volta de `'invoices 2026'`.
- **`Get-ChildItem`** é o `ls`, e no Linux mostra a mesma sequência de permissões numa coluna chamada
  `UnixMode`.
- As duas últimas linhas digitaram **`cd`** e **`pwd`**, e funcionaram, porque o PowerShell define
  **aliases**, apelidos curtos, para os cmdlets.

## Aliases, e por que eles mudam entre sistemas

```
PS /home/ana> Get-Alias cd, pwd, dir, gci

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Alias           cd -> Set-Location
Alias           pwd -> Get-Location
Alias           dir -> Get-ChildItem
Alias           gci -> Get-ChildItem

PS /home/ana> Get-Command ls

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Application     ls                                                 0.0.0.0    /usr/bin/ls
```

`cd`, `pwd`, `dir` e `gci` são aliases em todo sistema. **O `ls` não é, aqui**: no Linux, o PowerShell
deixa o `ls` para o `/usr/bin/ls` de verdade, para não escondê-lo. **No Windows, `ls` é um alias de
`Get-ChildItem`**, e é por isso que o `ls` "funciona" no PowerShell do Windows e depois não aceita o
`-l`:

```sh
PS C:\Users\ana> Set-Location Documents
PS C:\Users\ana\Documents> Get-ChildItem
PS C:\Users\ana\Documents> Get-Alias ls        # on Windows: ls -> Get-ChildItem
PS C:\Users\ana\Documents> $env:USERPROFILE
```

**Nada disso foi rodado para esta aula.** A lição que fica é geral: um alias faz um comando parecer
conhecido, e as opções que você conhece do original não vêm junto. Num script, escreva o nome completo
do cmdlet.
