---
title: O `Format-*` é o fim do pipeline, e nunca o meio
version: 1
---

Toda tabela que você viu nesta aula foi produzida por um formatador que o
PowerShell rodou automaticamente no fim, escolhendo tabela ou lista conforme
quantas propriedades havia.

Dá para pedir um explicitamente:

```
PS /home/ana/work/ps> Import-Csv sales.csv | Select-Object -First 2 | Format-Table -AutoSize
region rep   quarter units revenue
------ ---   ------- ----- -------
north  ana   Q1      171   8721
north  bruno Q1      49    4116
PS /home/ana/work/ps> Import-Csv sales.csv | Select-Object -First 1 | Format-List
region  : north
rep     : ana
quarter : Q1
units   : 171
revenue : 8721
```

| | |
|---|---|
| `Format-Table` | colunas. O `-AutoSize` as ajusta ao conteúdo |
| `Format-List` | uma propriedade por linha. O que você quer quando há muitas |
| `Format-Wide` | uma propriedade, em colunas, como o `ls` |
| `Out-Host -Paging` | um paginador, como o `less` |

**O `Format-Table -AutoSize` precisa acumular tudo** para calcular as larguras,
então ele para o fluxo do pipeline — a mesma troca do `Sort-Object`.

## A regra

**Nada vem depois de um `Format-*` exceto saída.**

```
PS /home/ana/work/ps> Import-Csv sales.csv | Format-Table | Where-Object { $_.region -eq "north" } | Measure-Object | Select Count
Count
-----
    0
```

Oito linhas têm `region` igual a `north` e a resposta é zero. Pergunte o que o
`Format-Table` de fato emitiu:

```
PS /home/ana/work/ps> Import-Csv sales.csv | Format-Table | Get-Member | Select-Object -First 3 TypeName, Name
TypeName                                                      Name
--------                                                      ----
Microsoft.PowerShell.Commands.Internal.Format.FormatStartData Equals
Microsoft.PowerShell.Commands.Internal.Format.FormatStartData GetHashCode
Microsoft.PowerShell.Commands.Internal.Format.FormatStartData GetType
```

**O `Format-Table` não emitiu registros de venda. Ele emitiu instruções de
formatação** — `FormatStartData`, depois uma linha por registro, depois um
`FormatEndData` — que são objetos descrevendo uma tabela e não os dados dela. O
`Where-Object` obedientemente procurou uma propriedade `region` neles, não achou
nenhuma, e não guardou nada.

Este é o erro mais comum do PowerShell depois da comparação de strings, e tem a
mesma forma: **nenhum erro, uma resposta vazia e limpa.**

O conserto é a ordem. Filtre, ordene e selecione primeiro; formate por último:

```sh
Import-Csv sales.csv | Where-Object region -eq north | Format-Table   # right
Import-Csv sales.csv | Format-Table | Where-Object region -eq north   # wrong
```

## Quando você quer texto, peça texto

O `Format-*` é para um humano lendo uma tela. Para qualquer outra coisa existe um
cmdlet que produz dados:

| | |
|---|---|
| `ConvertTo-Json` | JSON. `-Depth n`, porque o padrão é 2 e ele trunca |
| `ConvertTo-Csv` `Export-Csv` | CSV, para o pipeline ou para um arquivo |
| `Out-String` | a representação, como string, para quando você quer mesmo o texto |
| `Out-File` `Set-Content` | para um arquivo |
| `Out-Null` | para lugar nenhum. O `> /dev/null` da aula 8 seção 03 |

```
PS /home/ana/work/ps> Get-ChildItem | Select-Object Name, Length | ConvertTo-Json
[
  {
    "Name": "access.log",
    "Length": 148233
  },
  {
    "Name": "sales.csv",
    "Length": 788
  }
]
```

**Essa é a fronteira de volta para o mundo Unix.** Um pipeline de PowerShell que
precisa entregar os resultados a outra coisa os converte, e o JSON é o que tudo do
outro lado consegue ler.

O `-Depth` do `ConvertTo-Json` vale conhecer antes de ele te morder:

```
PS /home/ana/work/ps> @{a=@{b=@{c=@{d=1}}}} | ConvertTo-Json
WARNING: Resulting JSON is truncated as serialization has exceeded the set depth of 2.
{
  "a": {
    "b": {
      "c": "System.Collections.Hashtable"
    }
  }
}
```

**Dois níveis por padrão**, e qualquer coisa mais funda vira o nome do tipo como
string — `"System.Collections.Hashtable"` onde deveria haver um objeto. Ele avisa,
ao menos nesta versão, e o aviso vai para o fluxo de avisos e não para dentro do
JSON. O `-Depth 10` é o hábito a formar.

O `Export-Csv -NoTypeInformation` era necessário em versões antigas para impedir
que um comentário `#TYPE` fosse escrito como primeira linha; no PowerShell 6 em
diante é o padrão e a chave é aceita e ignorada.

## O `Write-Host` não é saída

```sh
Write-Output "this goes down the pipeline"
Write-Host   "this goes straight to the screen"
```

**O `Write-Output` emite um objeto.** É o que uma função devolve, ele pode ser
capturado, encanado e redirecionado — a saída padrão da aula 8 seção 02.

**O `Write-Host` escreve para a aplicação hospedeira**, contornando o pipeline por
completo:

```
PS /home/ana/work/ps> $a = Write-Output "captured"; "a is [$a]"
a is [captured]
PS /home/ana/work/ps> $b = Write-Host "not captured"; "b is [$b]"
not captured
b is []
PS /home/ana/work/ps> Write-Host "to file?" > /tmp/ps-h.txt; (Get-Content /tmp/ps-h.txt).Count
to file?
0
```

Ele foi para a tela nas duas vezes e nem para a variável nem para o arquivo. Ele
serve para uma mensagem de progresso a uma pessoa, e usá-lo para devolver um valor
é o erro que faz uma função parecer não devolver nada.

Também existem o `Write-Error`, o `Write-Warning`, o `Write-Verbose` e o
`Write-Debug` — fluxos separados, do jeito que a saída de erro é separada, cada um
com a própria chave para ligar. Essa é a coisa mais próxima de um `>&2` que o
PowerShell tem, e é mais bem organizada que o arranjo de dois fluxos do shell.
