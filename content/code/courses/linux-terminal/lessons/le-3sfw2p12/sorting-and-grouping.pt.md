---
title: Ordenar, agrupar e medir — o `sort | uniq -c` com o sort embutido
version: 1
---

A regra do encerramento da aula 8 era que o `sort` antes do `uniq -c` não é
opcional, porque o `uniq` junta duplicatas adjacentes e em silêncio dá uma
resposta errada caso contrário.

**O `Group-Object` não tem esse modo de falha**, porque ele não trabalha com
adjacência — trabalha com valores.

```
PS /home/ana/work/ps> Import-Csv sales.csv | Group-Object region | Select-Object Name, Count
Name  Count
----  -----
east      8
north     8
south     8
west      8
```

Um comando onde a aula 8 precisava de `cut -d, -f1 | sort | uniq -c`, e nenhuma
pré-condição de ordenação para esquecer.

O `Group-Object` devolve um objeto de grupo por valor distinto, com `Name`,
`Count` e uma propriedade `Group` com os membros — então dá para contá-los, ou
entrar neles:

```
PS /home/ana/work/ps> Import-Csv sales.csv | Group-Object region | Select-Object -First 1 Name, Count, @{n="first rep";e={$_.Group[0].rep}}
Name Count first rep
---- ----- ---------
east     8 elena
```

Aquela terceira coluna é uma **propriedade calculada**: uma hashtable com `n` para
o nome e `e` para uma expressão avaliada por objeto. O `Select-Object` e o
`Format-Table` aceitam as duas, e é assim que se acrescenta uma coluna que cmdlet
nenhum produziu — um tamanho em megabytes, uma idade em dias, um campo tirado de
um objeto aninhado.

## O `Sort-Object`

```
PS /home/ana/work/ps> Import-Csv sales.csv | Sort-Object { [int]$_.revenue } -Descending | Select-Object -First 3 rep, revenue
rep    revenue
---    -------
ana    43731
felipe 41574
carla  37084
```

O `Sort-Object` recebe nomes de propriedade, ou um bloco que calcula a chave — e o
`[int]` é a armadilha da seção anterior chegando de novo. Aqui está a mesma
ordenação sem ele:

```
PS /home/ana/work/ps> Import-Csv sales.csv | Sort-Object revenue -Descending | Select-Object -First 3 rep, revenue
rep  revenue
---  -------
ana  8721
ana  8601
hugo 7257
```

**A maior receita do arquivo é 43731 e ela não está naquela tabela.** Ordenado
como texto, `8721` é a maior coisa que existe, porque `8` ganha de `4`. Nenhum
erro, uma resposta perfeitamente plausível, e as três linhas erradas.

| | |
|---|---|
| `Sort-Object Name` | por uma propriedade |
| `Sort-Object Length -Descending` | invertido |
| `Sort-Object region, rep` | duas chaves, em ordem. Como o `sort -k` |
| `Sort-Object { [int]$_.units }` | por algo calculado |
| `Sort-Object -Unique` | ordena e descarta duplicatas |

**O `Sort-Object` é um estágio bloqueante.** Ele não consegue emitir nada até ter
visto tudo, então um pipeline com um sort dentro para de fluir naquele ponto. Isso
vale para o `sort` do bash também, e é o motivo de o `Select-Object -First 3` ficar
*depois* do sort e não antes.

## O `Measure-Object`

```
PS /home/ana/work/ps> Import-Csv sales.csv | Measure-Object -Property units -Sum -Average
Count             : 32
Average           : 199.34375
Sum               : 6379
Maximum           :
Minimum           :
StandardDeviation :
Property          : units
```

O `wc -l`, o `awk '{s+=$4} END {print s}'` e uma média, num comando. As linhas
vazias são as estatísticas que não foram pedidas — o `-Maximum` e o `-Minimum` são
chaves separadas, e o `-AllStats` liga tudo.

Repare que o `Count` é 32, não 33: a linha de cabeçalho virou nomes de
propriedade, não um objeto.

E repare no que aconteceu em silêncio: o `units` é uma propriedade **string**, e o
`Measure-Object` somou assim mesmo, porque ele converte o que recebe. Isso é
conveniente aqui e é a mesma coerção que deu a resposta errada na seção anterior —
ele converte para aritmética e não converte para comparação.

Sem `-Property`, o `Measure-Object` só conta, o que faz do
`… | Measure-Object | Select-Object Count` a forma padrão de perguntar "quantos
saíram deste pipeline".

## Por que não o `$x.Count`

```sh
(Import-Csv sales.csv).Count                        # works — 32
(Get-ChildItem sales.csv).Count                     # works — 1
```

O `.Count` serve bem quando você já tem a coleção. Ele não serve quando o comando
pode devolver **nada ou exatamente uma coisa**, o que no PowerShell mais antigo
devolve algo sem `.Count` nenhum. O `Measure-Object` conta um fluxo de zero, um ou
um milhão de forma idêntica, e o `@( … ).Count` força um array antes.

## Os quatro juntos

```
PS /home/ana/work/ps> Import-Csv sales.csv | Where-Object { [int]$_.revenue -gt 20000 } | Group-Object region | Sort-Object Count -Descending | Select-Object Name, Count
Name  Count
----  -----
east      4
north     4
south     3
west      1
```

Filtre, agrupe, ordene, pegue. **Essa forma responde a maioria das perguntas que
você vai fazer a uma máquina**, e é a mesma forma do `grep | cut | sort | uniq -c
| sort -rn` da aula 8 — com a análise removida e a pré-condição de ordenação
desaparecida.

Um pipeline pode ser quebrado em linhas depois de um `|`. O PowerShell sabe que a
instrução não terminou, então não há `\` no fim da linha.
