---
title: O pipeline, e o momento em que texto vira objetos
version: 1
---

O `|` faz o que faz no bash: a coisa da esquerda alimenta a da direita. O que
viaja por ele é a diferença.

```
PS /home/ana/work/ps> Import-Csv sales.csv | Select-Object -First 3
region  : north
rep     : ana
quarter : Q1
units   : 171
revenue : 8721

region  : north
rep     : bruno
quarter : Q1
units   : 49
revenue : 4116

region  : south
rep     : carla
quarter : Q1
units   : 292
revenue : 37084
```

**O `Import-Csv` é o momento em que texto vira objetos.** Ele leu a linha de
cabeçalho, fez uma propriedade de cada nome de coluna, e emitiu um objeto por
linha. Tudo depois dele no pipeline trabalha com nomes em vez de posições.

```
PS /home/ana/work/ps> Import-Csv sales.csv | Get-Member -MemberType NoteProperty
   TypeName: System.Management.Automation.PSCustomObject

Name    MemberType   Definition
----    ----------   ----------
quarter NoteProperty string quarter=Q1
region  NoteProperty string region=north
rep     NoteProperty string rep=ana
revenue NoteProperty string revenue=8721
units   NoteProperty string units=171
```

Leia a coluna da direita com cuidado, porque a próxima seção gira em torno dela:
**cada um daqueles é uma `string`**. O `Import-Csv` não adivinha tipos. O `171`
são os três caracteres `171`.

## Um de cada vez, não todos de uma vez

Um pipeline de bash roda os estágios simultaneamente como processos, ligados por
um buffer. Um pipeline de PowerShell roda num processo só, e passa **um objeto
por vez** pela cadeia inteira antes de começar o próximo.

É por isso que o `Select-Object -First 3` acima parou o `Import-Csv` depois de
três linhas em vez de ler o arquivo e jogar o resto fora — a mesma ideia do `head`
fechando o pipe na aula 8, chegando por outro caminho. É fácil de provar para si
mesmo:

```
PS /home/ana/work/ps> 1..1000000 | ForEach-Object { $_ } | Select-Object -First 3
1
2
3
```

**Um milhão de objetos não foram feitos.** Três passaram, o `Select-Object` tinha
o que pediu, e ele parou o pipeline.

Isso também quer dizer que os resultados de um comando demorado aparecem conforme
são produzidos, que é o que torna o `Get-ChildItem -Recurse | Where-Object …` numa
árvore grande utilizável.

## O `$_`, o objeto atual

```
PS /home/ana/work/ps> 1..4 | ForEach-Object { $_ * $_ }
1
4
9
16
```

**O `$_` é o que está passando agora.** Ele é o `$PSItem` escrito por extenso, e
aparece em todo bloco que roda uma vez por objeto: `ForEach-Object`,
`Where-Object`, `switch`.

O `1..4` é um intervalo, e é um array de inteiros e não quatro linhas de texto.

## O `Select-Object` faz três trabalhos diferentes

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

| | |
|---|---|
| `Select-Object Name, Length` | fique com estas propriedades, descarte o resto. Como o `cut` |
| `Select-Object -First 3` | fique com os três primeiros objetos. Como o `head` |
| `Select-Object -ExpandProperty Name` | **os valores, não objetos que os têm** |

O terceiro é o que derruba as pessoas:

```
PS /home/ana/work/ps> (Get-ChildItem | Select-Object Name)[0].GetType().Name
PSCustomObject
PS /home/ana/work/ps> (Get-ChildItem | Select-Object -ExpandProperty Name).GetType().Name
Object[]
PS /home/ana/work/ps> Get-ChildItem | Select-Object -ExpandProperty Name
access.log
sales.csv
```

O `Select-Object Name` te dá **objetos que têm um `Name`**; o `-ExpandProperty
Name` te dá **os valores**. Quando algo mais adiante diz que não acha o que você
entregou, normalmente é isso.

E o `ConvertTo-Json` vale notar por si: transformar objetos em JSON é um cmdlet, e
o `ConvertFrom-Json` os traz de volta. Não há passo de `jq` porque não há nada a
analisar.

## De onde vêm os objetos

**Alguns comandos te entregam objetos. A maior parte do texto não.** Os três
cmdlets que transformam texto em objetos carregam a maior parte do peso:

| | |
|---|---|
| `Import-Csv` | um arquivo CSV, um objeto por linha, propriedades do cabeçalho |
| `ConvertFrom-Json` | JSON, objetos aninhados e tudo |
| `ConvertFrom-StringData` | um arquivo `chave=valor`, virando uma hashtable |

E quando o texto não é nenhum desses — um arquivo de log, a saída de um programa
nativo — você monta os objetos você mesmo, que é o que o vídeo da pergunta faz:

```sh
Get-Content access.log | ForEach-Object {
  $f = $_ -split " "
  [pscustomobject]@{ ip = $f[0]; path = $f[6]; status = [int]$f[8]; ms = [int]$f[-1] }
}
```

**Aquela linha é o preço honesto do pipeline de objetos.** O bash nunca precisa
escrevê-la, porque o bash nunca para de trabalhar em texto. O PowerShell paga uma
vez, na borda, e tudo depois é propriedade em vez de número de coluna.
