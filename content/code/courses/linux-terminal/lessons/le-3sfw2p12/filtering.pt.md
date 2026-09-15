---
title: O `Where-Object`, e a comparação que responde errado em silêncio
version: 1
---

O `Where-Object` fica com os objetos para os quais uma condição é verdadeira. Ele
é o `grep` com uma propriedade em vez de um padrão.

```
PS /home/ana/work/ps> Import-Csv sales.csv | Where-Object { [int]$_.revenue -gt 30000 } | Select-Object rep, revenue
rep    revenue
---    -------
carla  37084
ana    43731
carla  30272
elena  34122
hugo   35541
carla  34417
felipe 41574
```

Duas grafias, e as duas estão em todo lugar:

```sh
Where-Object { $_.revenue -gt 30000 }      # the block form: any expression, $_ is the object
Where-Object revenue -gt 30000             # the comparison form: shorter, one property
```

## Os operadores são palavras

Não existem operadores `<` e `>`, porque aqueles são redirecionamento — a mesma
colisão que o bash tem, resolvida do outro jeito.

| | |
|---|---|
| `-eq` `-ne` | igual, diferente |
| `-lt` `-le` `-gt` `-ge` | menor, maior |
| `-like` `-notlike` | correspondência de **glob**: `*` e `?` |
| `-match` `-notmatch` | correspondência de **expressão regular** |
| `-contains` `-in` | este valor está naquela coleção |
| `-and` `-or` `-not` `!` | juntar condições |

**O `-eq` não diferencia maiúsculas.** Nenhum deles diferencia:

```
PS /home/ana/work/ps> "ANA" -eq "ana"
True
PS /home/ana/work/ps> "ANA" -ceq "ana"
False
PS /home/ana/work/ps> "file.LOG" -like "*.log"
True
```

O `-ceq`, o `-clike` e o `-cmatch` são as versões sensíveis à caixa, com um `c` na
frente. Isso é o oposto de toda ferramenta Unix, e pega as pessoas nos dois
sentidos — uma comparação que casa quando você esperava que não, e um script
portado para bash que de repente liga para maiúsculas.

```sh
Where-Object { $_.Name -like '*.log' }        # glob, the same patterns as case in bash
Where-Object { $_.Name -match '^\d{4}-' }     # regex, the same syntax as lesson 125
```

O `-match` também preenche o `$Matches` com os grupos de captura, do jeito que o
`[[ =~ ]]` preenchia o `BASH_REMATCH` na seção 145:

```
PS /home/ana/work/ps> "report-2026.log" -match "^(\w+)-(\d{4})"; $Matches[2]
True
2026
```

## A armadilha, medida

Aqui está o mesmo arquivo, o mesmo limite, e duas respostas:

```
PS /home/ana/work/ps> Import-Csv sales.csv | Where-Object { $_.revenue -gt 30000 } | Measure-Object | Select-Object Count
Count
-----
   16
PS /home/ana/work/ps> Import-Csv sales.csv | Where-Object { [int]$_.revenue -gt 30000 } | Measure-Object | Select-Object Count
Count
-----
    7
```

**Dezesseis contra sete, e nada avisou sobre as outras nove.**

A seção anterior explica: o `Import-Csv` produziu strings, então o `$_.revenue` é
o texto `8721`. Os operadores de comparação do PowerShell **convertem o lado
direito para o tipo do lado esquerdo** — então o `30000` virou a string `"30000"`,
e a comparação foi alfabética.

```
PS /home/ana/work/ps> "9" -gt "30000"
True
PS /home/ana/work/ps> 9 -gt 30000
False
```

O `"9"` vem depois do `"3"` na ordenação, então como texto nove é maior que trinta
mil. É exatamente o problema do `[ "10" \> "9" ]` da seção 145, chegando pelo
outro lado — lá o shell te obrigava a escolher um operador, aqui o operador é o
mesmo e quem decide é o *tipo*.

**Converta na borda.** `[int]`, `[double]`, `[datetime]`, na linha em que texto
vira dado:

```sh
Import-Csv sales.csv | Where-Object { [int]$_.revenue -gt 30000 }

Import-Csv sales.csv | ForEach-Object {
  $_.revenue = [int]$_.revenue      # or fix it once, and stop thinking about it
  $_
}
```

A segunda é melhor em qualquer coisa maior que um comando de uma linha, e é o que
o `[pscustomobject]@{ status = [int]$f[8] }` do vídeo da pergunta está fazendo.

## De que lado está a coleção

```sh
$allowed -contains $name      # the collection is on the LEFT
$name -in $allowed            # the collection is on the RIGHT
```

Os dois fazem a mesma pergunta e são imagens espelhadas. O `-in` se lê melhor e é
mais novo; o `-contains` está em todo script antigo. Trocá-los de lado é a forma
usual de um erro em PowerShell:

```
PS /home/ana/work/ps> $allowed = "web01","web02"; $allowed -contains "web01"; "web01" -in $allowed
True
True
PS /home/ana/work/ps> "web01" -contains $allowed
False
```

**`False`, não um erro.** Uma string sozinha é uma coleção de um, e ela não contém
um array de dois elementos, então a resposta é perfeitamente correta e
perfeitamente inútil.

## Filtre à esquerda, quando der

```sh
Get-ChildItem -Filter '*.log'                        # the provider does it
Get-ChildItem | Where-Object { $_.Name -like '*.log' }   # PowerShell does it
```

Os dois dão a mesma resposta. **O `-Filter` é tratado pela coisa que fornece os
objetos** — o sistema de arquivos, o serviço de diretório, a máquina remota — então
menos objetos chegam a ser construídos. O `Where-Object` constrói todos e descarta
a maioria.

Em dois arquivos não importa. Num servidor de diretório com quarenta mil contas,
ou atravessando uma rede, é a diferença entre um segundo e um minuto. **Filtre o
mais à esquerda que o comando permitir**, que é o "reduza antes de decidir" da
aula 8 com outro sotaque.
