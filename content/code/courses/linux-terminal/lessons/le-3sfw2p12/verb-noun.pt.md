---
title: Verbo-Substantivo, e como achar um comando que você não conhece
version: 1
---

Os nomes de comando do Unix são arqueologia: o `cat` concatena, o `awk` são as
iniciais de três pessoas, o `less` é uma piada com o `more`. Você os aprende um a
um e não há padrão.

**Todo comando do PowerShell é `Verbo-Substantivo`.** `Get-ChildItem`,
`Set-Location`, `Stop-Process`, `Import-Csv`. O verbo diz o que está sendo feito,
o substantivo diz a quê, e os dois vêm de uma lista controlada.

```
PS /home/ana/work/ps> Get-Verb | Select-Object -First 8 Verb, Group
Verb   Group
----   -----
Add    Common
Clear  Common
Close  Common
Copy   Common
Enter  Common
Exit   Common
Find   Common
Format Common
```

**Os verbos são aprovados**, em grupos — Common, Data, Lifecycle, Security e mais
alguns — e um módulo que inventa um recebe um aviso ao carregar. Isso soa
burocrático e é o que faz a próxima seção funcionar.

| | |
|---|---|
| `Get` | leia algo e devolva. Não muda nada |
| `Set` | sobrescreve |
| `New` | cria um que não existia |
| `Remove` | apaga |
| `Add` | acrescenta a algo que existe |
| `Start` `Stop` | ciclo de vida |
| `Test` | devolve verdadeiro ou falso |

**O `Get-` é seguro e o `Set-` não é**, o que é uma convenção de verdade e não uma
esperança: um cmdlet chamado `Get-` que mudasse algo não passaria na revisão do
módulo em que foi publicado.

## Achar um comando

Você não decora os nomes. Você pergunta.

```
PS /home/ana/work/ps> Get-Command -Verb Get -Noun Child*
CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Cmdlet          Get-ChildItem                                      7.0.0.0    Microsoft.PowerShell…
```

A direção mais útil é por substantivo, porque ela te mostra tudo que dá para
fazer com um tipo de coisa:

```
PS /home/ana/work/ps> Get-Command -Noun Object | Select-Object Name
Name
----
Compare-Object
ForEach-Object
Group-Object
Measure-Object
New-Object
Select-Object
Sort-Object
Tee-Object
Where-Object
```

**Essa é a caixa de ferramentas inteira desta aula, descoberta em vez de
lembrada.** O `Get-Command -Noun Service` numa máquina Windows faz o mesmo para
serviços; o `-Noun Process` para processos.

## O `Get-Help`

```
PS /home/ana/work/ps> Get-Help Get-ChildItem -Parameter Recurse
-Recurse

    Required?                    false
    Position?                    Named
    Accept pipeline input?       false
    Parameter set name           (All)
    Aliases                      s
    Dynamic?                     false
    Accept wildcard characters?  false
```

| | |
|---|---|
| `Get-Help X` | o resumo |
| `Get-Help X -Examples` | **o que vale usar.** Escrito por quem escreveu o cmdlet |
| `Get-Help X -Parameter Y` | um parâmetro, como acima |
| `Get-Help X -Full` | tudo |
| `Get-Help X -Online` | abre a página de documentação no navegador |

O `Get-Help` lê arquivos de ajuda que vêm separados dos cmdlets; o `Update-Help`
os baixa, e uma máquina nova vai te dizer que a ajuda é mínima até você rodá-lo.

## Parâmetros são nomeados, e podem ser abreviados

```
PS /home/ana/work/ps> Get-ChildItem -Pa /etc -Fi "host*" | Select-Object Name
Name
----
host.conf
hostname
hosts
hosts.allow
hosts.deny
```

**Um nome de parâmetro pode ser abreviado para qualquer prefixo não ambíguo** —
`-Pa` para `-Path`, `-Fi` para `-Filter`. É uma conveniência num prompt e um
passivo num arquivo: uma versão futura do cmdlet que acrescente outro parâmetro
`Pa…` transforma o seu `-Pa` num erro num script em que você não tocou. Escreva
por extenso em scripts.

O `-Path` também é posicional, então o `Get-ChildItem /etc` funciona sem nome de
parâmetro nenhum.

Parâmetros de chave não recebem valor: o `-Recurse` está ligado por estar
presente. E há uma grafia para desligar um explicitamente, o que importa quando o
valor vem de uma variável:

```
PS /home/ana/work/ps> Get-ChildItem /etc -Filter "host*" -Recurse:$false | Select-Object Name
Name
----
host.conf
hostname
hosts
hosts.allow
hosts.deny
```

## Apelidos, e uma surpresa entre plataformas

```
PS /home/ana/work/ps> Get-Alias ls, dir, cat, ps, cd | Format-Table -AutoSize
Get-Alias: This command cannot find a matching alias because an alias with the name 'ls' does not exist.

CommandType Name                 Version Source
----------- ----                 ------- ------
Alias       dir -> Get-ChildItem
Get-Alias: This command cannot find a matching alias because an alias with the name 'cat' does not exist.
Get-Alias: This command cannot find a matching alias because an alias with the name 'ps' does not exist.
Alias       cd -> Set-Location
```

O `dir` e o `cd` são apelidos aqui. **O `ls`, o `cat` e o `ps` não são** — e no
Windows PowerShell eles são, apontando para `Get-ChildItem`, `Get-Content` e
`Get-Process`.

O motivo é óbvio depois que você vê: no Linux esses são programas de verdade que
uma pessoa digitando `ls` quer dizer, então o PowerShell remove os apelidos e
deixa os de verdade passarem. No Windows não há um `/bin/ls` para colidir.

**É por isso que um script que diz `ls` faz coisas diferentes nas duas
plataformas**, e por que apelidos pertencem a um prompt e nunca a um arquivo. Num
script, escreva `Get-ChildItem`.

Alguns que você vai ver assim mesmo, porque todo mundo digita:

```
PS /home/ana/work/ps> Get-Alias gci, "?", "%", select, sort, ft, fl | Format-Table -AutoSize
CommandType Name                    Version Source
----------- ----                    ------- ------
Alias       gci -> Get-ChildItem
Alias       ? -> Where-Object
Alias       % -> ForEach-Object
Alias       h -> Get-History
Alias       r -> Invoke-History
Alias       % -> ForEach-Object
Alias       select -> Select-Object
Get-Alias: This command cannot find a matching alias because an alias with the name 'sort' does not exist.
Alias       ft -> Format-Table
Alias       fl -> Format-List
```

Duas coisas naquela saída não foram pedidas. **O `sort` está faltando** — mesmo
motivo do `ls`: o `/usr/bin/sort` existe aqui, então o apelido não é criado, e no
Windows é. E o `h`, o `r` e um segundo `%` apareceram porque **o `Get-Alias` trata
o argumento como curinga**, e o `?` casa com qualquer caractere — o que é uma
demonstração pequena e honesta de que `?` e `*` são padrões em quase todo lugar no
PowerShell.

O `Get-Alias` sem argumentos lista todos eles.
