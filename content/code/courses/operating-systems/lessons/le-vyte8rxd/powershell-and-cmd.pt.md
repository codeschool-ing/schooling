---
title: Os mesmos quatro trabalhos no PowerShell e no Prompt de Comando
version: 1
---

Os cmdlets do PowerShell dizem o que fazem, o Verbo-Substantivo da aula 8:

```
PS /home/ana/work> New-Item -ItemType Directory -Path archive

    Directory: /home/ana/work

UnixMode         User Group         LastWriteTime         Size Name
--------         ---- -----         -------------         ---- ----
drwxrwxr-x        ana ana        09/25/2026 11:15         4096 archive

PS /home/ana/work> Set-Content -Path archive/readme.txt -Value 'old invoices, kept for five years'
PS /home/ana/work> Add-Content -Path archive/readme.txt -Value 'ask the accountant before deleting'
PS /home/ana/work> Get-Content archive/readme.txt
old invoices, kept for five years
ask the accountant before deleting
PS /home/ana/work> Get-Content backup.log -Tail 2
2026-09-24 09:58 backup ok
2026-09-24 09:59 backup ok
PS /home/ana/work> Copy-Item clients.csv archive/
PS /home/ana/work> Remove-Item archive -Recurse -WhatIf
What if: Performing the operation "Remove Directory" on target "/home/ana/work/archive".
PS /home/ana/work> Get-ChildItem archive -Name
clients.csv
readme.txt
```

| trabalho | bash | PowerShell | Prompt de Comando |
|---|---|---|---|
| fazer uma pasta | `mkdir -p` | `New-Item -ItemType Directory` | `md` |
| gravar um arquivo | `echo … >` | `Set-Content` | `echo … >` |
| acrescentar a um arquivo | `echo … >>` | `Add-Content` | `echo … >>` |
| ler um arquivo | `cat`, `tail` | `Get-Content`, `-Tail` | `type` |
| copiar | `cp`, `cp -r` | `Copy-Item`, `-Recurse` | `copy`, `xcopy` |
| mover ou renomear | `mv` | `Move-Item`, `Rename-Item` | `move`, `ren` |
| apagar | `rm`, `rm -r` | `Remove-Item`, `-Recurse` | `del`, `rd /s` |

A coluna do Prompt de Comando não foi rodada para esta aula. O `>` e o `>>` querem dizer o mesmo nos três
shells, com o mesmo perigo.

## `-WhatIf`

A opção mais útil do PowerShell para esta aula é o **`-WhatIf`**. O `Remove-Item archive -Recurse
-WhatIf` **descreveu** o que apagaria e não apagou nada: o último comando ainda achou os dois arquivos em
`archive`. É o "olhe antes" da seção 05, embutido no comando, e a maioria dos cmdlets que mudam algo o
aceita. O **`-Confirm`** é o equivalente do `rm -i`.

O `Remove-Item` numa pasta que tem algo dentro pede confirmação a não ser que o `-Recurse` seja dado,
uma proteção que o `rm -r` não tem.
