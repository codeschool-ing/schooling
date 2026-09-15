---
title: Funções que conferem os próprios argumentos
version: 1
---

```
PS /home/ana/work/ps> function Get-Doubled { param([int]$Number) $Number * 2 }
PS /home/ana/work/ps> Get-Doubled -Number 21
42
PS /home/ana/work/ps> Get-Doubled 21
42
```

`function Verbo-Substantivo { param(…) … }`. O nome segue a mesma convenção de um
cmdlet, porque uma função **é** um cmdlet no que diz respeito a todo o resto — o
`Get-Command` a encontra, o `Get-Help` a documenta, e dá para encanar para ela.

## O `param` é a diferença

As funções de bash da seção 150 recebiam `$1` e `$2` e não conferiam nada. O bloco
`param` do PowerShell declara nomes, tipos e regras, e o shell as impõe **antes de
o seu código rodar**:

```
PS /home/ana/work/ps> Get-Doubled -Number "twelve"
Get-Doubled: Cannot process argument transformation on parameter 'Number'. Cannot convert value "twelve" to type "System.Int32". Error: "The input string 'twelve' was not in a correct format."
```

Nada dentro da função precisou testar coisa nenhuma. Compare com o
`logreport.sh` da aula 9, que gasta quatro linhas conferindo que o `-t` é um
número.

A declaração cresce até onde você precisar:

```sh
function Get-Report {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [ValidateRange(1, 60000)]
    [int]$ThresholdMs = 1000,

    [ValidateSet('Table', 'Json', 'Csv')]
    [string]$As = 'Table',

    [switch]$Quiet
  )
  …
}
```

| | |
|---|---|
| `[Parameter(Mandatory)]` | o PowerShell **pergunta** se ele faltar |
| `[ValidateRange]` `[ValidateSet]` `[ValidatePattern]` | rejeitados antes de o corpo rodar |
| `= 1000` | um padrão |
| `[switch]` | uma opção. `$Quiet.IsPresent`, ou só `if ($Quiet)` |
| `[CmdletBinding()]` | veja abaixo |

```
PS /home/ana/work/ps> function Pick { param([ValidateSet("Table","Json")]$As) "as $As" }
PS /home/ana/work/ps> Pick -As Json
as Json
PS /home/ana/work/ps> Pick -As Xml
Pick: Cannot validate argument on parameter 'As'. The argument "Xml" does not belong to the set "Table,Json" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again.
```

A mensagem nomeia o parâmetro, o valor ruim e o conjunto permitido, e nada disso
foi escrito por quem fez a função. O `[ValidateSet]` também alimenta o
autocompletar para quem chama.

**O `[CmdletBinding()]` é uma linha e te dá cinco coisas**: `-Verbose`, `-Debug`,
`-ErrorAction`, `-WarningAction` e suporte a `-WhatIf`/`-Confirm`, tudo tratado
pelo PowerShell. O `Write-Verbose "…"` no corpo então imprime só quando quem chama
passa `-Verbose`. Não há equivalente em bash a não ser escrever tudo.

## Devolver valores

```
PS /home/ana/work/ps> function Get-Two { "first"; "second" }
PS /home/ana/work/ps> $r = Get-Two; $r.Count; $r[1]
2
second
```

**Toda expressão que não é consumida vira saída.** Não é preciso `return`, e o
`return $x` quer dizer "emita `$x` e pare aqui" em vez de "este é o valor" — um
`return` não é o que produz o resultado.

Isso é o mesmo que o "uma função devolve dados na saída padrão" da seção 150, com
uma diferença grande: o que volta são **objetos**, não texto. O `$r` é um array de
duas strings, o `$r[1]` é a segunda, e nada foi analisado.

E é a mesma armadilha. Um `Write-Output` perdido ou uma expressão não capturada se
junta ao valor de retorno:

```sh
function Get-Size {
  Write-Host "measuring…"          # fine: bypasses the pipeline
  Write-Output "measuring…"        # NOT fine: this is now part of the result
  (Get-Item $Path).Length
}
```

**`Write-Host` para uma pessoa, `Write-Verbose` para uma pessoa que pediu, e nada
mais no fluxo de saída além da resposta.**

## Receber entrada do pipeline

É isso que faz uma função parecer um cmdlet:

```
PS /home/ana/work/ps> function Get-Big { param([Parameter(ValueFromPipeline)]$Item) process { if ($Item.Length -gt 1000) { $Item.Name } } }
PS /home/ana/work/ps> Get-ChildItem | Get-Big
access.log
```

Duas peças:

| | |
|---|---|
| `[Parameter(ValueFromPipeline)]` | este parâmetro é preenchido pelo pipeline |
| `process { }` | **roda uma vez por objeto.** Sem ele, só o último chega |

Há três blocos: o `begin` roda uma vez antes, o `process` uma vez por objeto, o
`end` uma vez depois. Uma função sem bloco nenhum é tratada como um `end` grande, e
aqui está o que isso custa:

```
PS /home/ana/work/ps> function No-Process { param([Parameter(ValueFromPipeline)]$Item) if ($Item) { "got $($Item.Name)" } }
PS /home/ana/work/ps> Get-ChildItem | No-Process
got sales.csv
PS /home/ana/work/ps> function With-Process { param([Parameter(ValueFromPipeline)]$Item) process { "got $($Item.Name)" } }
PS /home/ana/work/ps> Get-ChildItem | With-Process
got access.log
got sales.csv
```

**Dois arquivos entraram e o primeiro disse um.** O corpo rodou uma vez, no fim,
com o `$Item` segurando o que chegou por último. Nenhum erro — a forma de sempre.

O `[Parameter(ValueFromPipelineByPropertyName)]` é o outro: ele preenche o `$Path`
a partir de uma propriedade `.Path` no que quer que venha pelo pipe, que é como
cmdlets se encadeiam sem ninguém escrever cola.

## Escopo

Variáveis são visíveis para funções **chamadas a partir** de onde são definidas, e
uma atribuição dentro de uma função cria uma local — o padrão oposto ao do bash,
em que a seção 150 tinha que dizer `local` em toda linha.

```
PS /home/ana/work/ps> $x = 1; function Set-It { $x = 2 }; Set-It; "x is $x"
x is 1
PS /home/ana/work/ps> $x = 1; function Set-It2 { $script:x = 2 }; Set-It2; "x is $x"
x is 2
```

`$script:`, `$global:` e `$local:` são escopos explícitos. **Precisar de um
normalmente é sinal de que a função deveria devolver um valor.**

## Onde funções moram

Um arquivo `.ps1` é um script; um `.psm1` é um módulo. O
`Import-Module ./tools.psm1` traz as funções dele — o `source` da seção 139, com um
manifesto e números de versão anexados.

**Um arquivo de script não precisa de shebang no Windows** e precisa no Linux —
`#!/usr/bin/env pwsh`, exatamente como a seção 139 descreveu — e então ele é um
arquivo executável comum, a partir de um prompt de bash comum:

```
ana@vm:~/work/ps$ cat bigfiles.ps1
#!/usr/bin/env pwsh
param([Parameter(Mandatory)][string]$Path, [int]$MinBytes = 1000)
Get-ChildItem $Path |
  Where-Object Length -gt $MinBytes |
  Select-Object Name, Length
ana@vm:~/work/ps$ ./bigfiles.ps1 -Path .

Name       Length
----       ------
access.log 148233
```

Repare que o `param()` funciona no topo de um arquivo de script e não só numa
função, e que os parâmetros são nomeados ao jeito do PowerShell mesmo tendo sido o
bash que o lançou. O bloco `param` de um script precisa ser a **primeira instrução
do arquivo**, depois do shebang e de quaisquer comentários.

O que um `.ps1` precisa no Windows e não aqui é permissão:
`Set-ExecutionPolicy RemoteSigned` para o usuário, porque por padrão um script
recém-escrito não roda de jeito nenhum. Essa é uma configuração exclusiva do
Windows e não há nada nesta máquina em que demonstrá-la.
