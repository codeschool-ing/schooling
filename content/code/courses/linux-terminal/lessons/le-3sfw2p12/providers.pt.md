---
title: Provedores — o registro é um drive, e o ambiente também
version: 1
---

A seção 9 disse que tudo no Unix é um arquivo. A versão dessa ideia no PowerShell
corre ao contrário: **tudo que parece uma árvore vira um drive**, e os mesmos
quatro cmdlets funcionam em todos.

```
PS /home/ana/work/ps> Get-PSDrive | Format-Table -AutoSize
Name     Used (GB) Free (GB) Provider    Root   CurrentLocation
----     --------- --------- --------    ----   ---------------
/           225.77     26.20 FileSystem  /     home/ana/work/ps
Alias                        Alias
Env                          Environment
Function                     Function
Temp        225.77     26.20 FileSystem  /tmp/
Variable                     Variable
```

Seis drives nesta máquina Linux, apoiados em cinco provedores. **No Windows há
mais**, e dois deles são a razão de esta ideia existir: o `HKLM:` e o `HKCU:`, o
registro.

## Os mesmos cmdlets, em todos eles

| | |
|---|---|
| `Get-ChildItem` | liste o que há lá dentro |
| `Get-Item` / `Set-Item` | uma coisa |
| `New-Item` / `Remove-Item` | criar, apagar |
| `Get-Content` / `Set-Content` | o que há dentro dela |
| `Test-Path` | existe algo ali |

```
PS /home/ana/work/ps> Get-ChildItem Env: | Where-Object Name -like "U*"
Name                           Value
----                           -----
USER                           ana
PS /home/ana/work/ps> $env:HOME
/home/ana
PS /home/ana/work/ps> Get-ChildItem Function: | Select-Object -First 3 Name
Name
----
cd..
cd\
cd~
```

O `Env:` é o ambiente como diretório. O `Function:` é toda função definida como
diretório. O `Variable:` é toda variável. **Dá para fazer `Get-ChildItem` no estado
do seu próprio shell**, que é uma ideia genuinamente diferente de qualquer coisa
em bash, onde os equivalentes são o `env`, o `declare -F` e o `declare -p` — três
comandos diferentes com três formatos de saída diferentes.

O `$env:HOME` é o atalho para `Get-Item Env:HOME | Select -Expand Value`, e o
`$env:LEVEL = "debug"` define uma, exportada para os filhos, que é o `export` da
seção 140 dobrado dentro do nome.

## No Windows: o registro

Esta é a parte que não tem equivalente aqui e é por que a ideia se paga:

```sh
Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion
Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion | Select ProductName
New-Item -Path HKCU:\Software\MyApp
Set-ItemProperty -Path HKCU:\Software\MyApp -Name Level -Value debug
```

O registro é uma árvore de chaves com valores nelas, então ele é um drive, e lê-lo
usa os cmdlets que você já conhece. Nesta máquina ele não está lá:

```
PS /home/ana/work/ps> Get-ChildItem HKLM:\Software
Get-ChildItem: Cannot find drive. A drive with the name 'HKLM' does not exist.
```

**Esse é o erro, sem edição.** O provedor do registro vem num módulo exclusivo do
Windows, então no Linux o drive simplesmente não existe. Aquelas quatro linhas
acima são os únicos comandos não testados desta aula e estão marcados como tal.

## Arquivos

```
PS /home/ana/work/ps> Get-Content sales.csv -TotalCount 2
region,rep,quarter,units,revenue
north,ana,Q1,171,8721
PS /home/ana/work/ps> Get-Content sales.csv | Measure-Object -Line
Lines Words Characters Property
----- ----- ---------- --------
   33
```

**O `Get-Content` emite uma string por linha**, não um bloco só — que é por que ele
encanha para `Where-Object` e `ForEach-Object` do jeito que o `cat` encanha para o
`grep`. O `-Raw` te dá o arquivo inteiro como uma string, e o `-TotalCount` é o
`head`.

| bash | PowerShell |
|---|---|
| `cat f` | `Get-Content f` |
| `head -2 f` | `Get-Content f -TotalCount 2` |
| `tail -5 f` | `Get-Content f -Tail 5` |
| `tail -f f` | `Get-Content f -Wait` |
| `wc -l < f` | `(Get-Content f).Count` |
| `echo x > f` | `Set-Content f -Value x` |
| `echo x >> f` | `Add-Content f -Value x` |
| `test -e f` | `Test-Path f` |

**O `Set-Content` e o `>` não são a mesma coisa**, e vale ver uma vez:

```
PS /home/ana/work/ps> Get-ChildItem > /tmp/redir.txt; Get-Content /tmp/redir.txt
    Directory: /home/ana/work/ps

UnixMode         User Group         LastWriteTime         Size Name
--------         ---- -----         -------------         ---- ----
-rw-r--r--        ana ana        09/15/2026 10:48       148233 access.log
-rwxr-xr-x        ana ana        09/15/2026 11:01          175 bigfiles.ps1
-rw-r--r--        ana ana        09/15/2026 10:48          788 sales.csv
PS /home/ana/work/ps> Get-ChildItem | Set-Content /tmp/setc.txt; Get-Content /tmp/setc.txt
/home/ana/work/ps/access.log
/home/ana/work/ps/bigfiles.ps1
/home/ana/work/ps/sales.csv
```

O `>` escreveu **a tabela que uma pessoa teria lido**, cabeçalhos e tudo, porque
redirecionar formata primeiro. O `Set-Content` escreveu os valores. Qual dos dois
você quis dizer, um daqueles arquivos vai decepcionar o que vier lê-lo em seguida —
e essa é a regra da seção 164 chegando num lugar em que você não esperava.

## O `Select-String` é o `grep`

```
PS /home/ana/work/ps> Select-String -Path access.log -Pattern "500" | Select-Object -First 1 LineNumber, Line
LineNumber Line
---------- ----
        13 10.0.1.21 - - [14/Sep/2026:06:09:02 +0000] "POST /api/reports HTTP/1.1" 500 18487 "curl…
```

**E ele devolve objetos**, com `LineNumber`, `Line`, `Filename` e `Matches` neles —
então o número da linha é um número que dá para usar em vez de algo que você pediu
ao `grep -n` e depois teve que passar pelo `cut`.

| | |
|---|---|
| `-Pattern` | uma expressão regular por padrão. `-SimpleMatch` para texto literal |
| `-CaseSensitive` | porque, como sempre, o padrão não é |
| `-Context 2,2` | o `grep -C 2` |
| `-NotMatch` | o `grep -v` |
| `-List` | pare na primeira ocorrência por arquivo — o `grep -l` |
