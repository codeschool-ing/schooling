---
title: Uma pedra de Roseta, e as quatro regras que a produzem
version: 1
---

## Andar e olhar

| bash | PowerShell |
|---|---|
| `pwd` | `Get-Location` |
| `cd /etc` | `Set-Location /etc` |
| `ls` | `Get-ChildItem` |
| `ls -la` | `Get-ChildItem -Force` |
| `ls -R` | `Get-ChildItem -Recurse` |
| `find . -name '*.log'` | `Get-ChildItem -Recurse -Filter *.log` |
| `cat f` | `Get-Content f` |
| `head -5 f` | `Get-Content f -TotalCount 5` |
| `tail -f f` | `Get-Content f -Wait` |
| `cp a b` | `Copy-Item a b` |
| `mv a b` | `Move-Item a b` |
| `rm f` | `Remove-Item f` |
| `mkdir d` | `New-Item -ItemType Directory d` |
| `touch f` | `New-Item -ItemType File f` |
| `test -e f` | `Test-Path f` |
| `which cmd` | `Get-Command cmd` |
| `man cmd` | `Get-Help cmd -Full` |

## Texto e dados

| bash | PowerShell |
|---|---|
| `grep pat f` | `Select-String pat f` |
| `grep -v pat` | `Select-String pat -NotMatch` |
| `grep -c pat f` | `(Select-String pat f).Count` |
| `cut -d, -f2` | `Import-Csv f \| Select-Object col` |
| `sort` | `Sort-Object` |
| `sort -u` | `Sort-Object -Unique` |
| `sort \| uniq -c` | `Group-Object` |
| `wc -l` | `Measure-Object -Line` |
| `awk '{s+=$3} END{print s}'` | `Measure-Object col -Sum` |
| `sed 's/a/b/g'` | `$s -replace 'a','b'` |
| `tr a-z A-Z` | `$s.ToUpper()` |
| `paste -sd,` | `$arr -join ','` |
| `tr , '\n'` | `$s -split ','` |
| `xargs cmd` | `ForEach-Object { cmd $_ }` |
| `jq` | `ConvertFrom-Json`, e então propriedades |

## Processos e o sistema

| bash | PowerShell |
|---|---|
| `ps aux` | `Get-Process` |
| `kill PID` | `Stop-Process -Id PID` |
| `pkill -f nome` | `Stop-Process -Name nome` |
| `systemctl status x` | `Get-Service x` — só no Windows |
| `systemctl restart x` | `Restart-Service x` — só no Windows |
| `env` | `Get-ChildItem Env:` |
| `export X=1` | `$env:X = 1` |
| `echo $HOME` | `$env:HOME` |
| `date` | `Get-Date` |
| `sleep 5` | `Start-Sleep -Seconds 5` |
| `ssh host cmd` | `Invoke-Command -ComputerName host { cmd }` |

## Construções do shell

| bash | PowerShell |
|---|---|
| `$1 $2` | um bloco `param()` com nomes |
| `$@` | `$args`, ou parâmetros nomeados |
| `$?` (0 é bom) | `$?` (`$true` é bom), `$LASTEXITCODE` para programas |
| `set -u` | `Set-StrictMode -Version Latest` |
| `set -e` | `$ErrorActionPreference = 'Stop'` |
| `[ -f x ]` | `Test-Path x -PathType Leaf` |
| `[ "$a" = "$b" ]` | `$a -eq $b` |
| `[[ $a == pat* ]]` | `$a -like 'pat*'` |
| `[[ $a =~ re ]]` | `$a -match 're'` |
| `for f in *.log; do` | `foreach ($f in Get-ChildItem *.log) {` |
| `cmd \| while read l` | `cmd \| ForEach-Object { $_ }` |
| `func() { … }` | `function Verbo-Substantivo { … }` |
| `local x` | o padrão. `$script:x` para escapar dele |
| `source f` | `. ./f`, ou `Import-Module` |
| `2>&1` | `2>&1`, e `*>&1` para todos os fluxos |
| `> /dev/null` | `\| Out-Null` |
| `$(cmd)` | `$(cmd)` — igual |
| `$((1+2))` | `1+2` — aritmética não precisa de nada |

## As quatro regras por trás da tabela

A maior parte da tabela é dedutível em vez de memorizável, a partir de quatro
coisas.

**Uma. O pipeline carrega objetos.** Então não há `awk`, não há `cut` e não há
`jq`: você pega uma propriedade. E por isso o `Format-*` é terminal, porque ele
destrói os objetos para fazer um desenho.

**Duas. Comandos são `Verbo-Substantivo` e os verbos são aprovados.** Então você
não lembra nomes — o `Get-Command -Noun Service` os acha. E o `Get-` é seguro.

**Três. Parâmetros são nomeados e tipados.** Então não há opções de uma letra para
decorar nem `getopts`: o `-Recurse` diz o que faz, e `[int]$Threshold` num bloco
`param` são quatro linhas de validação de bash.

**Quatro. Valores têm tipo.** Então o `Sort-Object` num número ordena
numericamente — desde que seja mesmo um número, que é a armadilha que esta aula
repete três vezes. Texto lido de um arquivo é texto até você converter.

## E as quatro coisas que o bash faz melhor

Simetria não é honestidade. Há coisas em que o pipeline de texto ganha de lavada.

**Iniciar.** 0,4 segundo contra 0,003. Para qualquer coisa que um agendador roda
num cronograma, esse é o argumento inteiro.

**Brevidade.** `ls | wc -l` contra `(Get-ChildItem | Measure-Object).Count`. Num
prompt, digitar importa.

**Tudo fala texto.** Qualquer programa escrito nos últimos cinquenta anos pode
fazer parte de um pipeline de bash. Um pipeline de PowerShell é rico no meio e
precisa converter nas duas pontas, e o `ConvertFrom-Json` só ajuda quando o outro
lado fala JSON.

**Ele já está lá.** Toda máquina Linux tem bash; o PowerShell é um download e uma
decisão. Esse é o mesmo argumento que a seção 115 fez sobre não sair da
distribuição, e ele se aplica aqui.

**Então a regra não é que um é melhor.** É que no Windows os objetos são a única
forma sensata de trabalhar, no Linux as ferramentas de texto são, e a habilidade
interessante é saber em que máquina você está e não brigar com ela.
