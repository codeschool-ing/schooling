---
title: `if`, `foreach`, `switch` — e o `Set-StrictMode`
version: 1
---

As formas são do estilo C e há muito pouco a aprender.

```
PS /home/ana/work/ps> $hosts = "web01","web02","db01"
PS /home/ana/work/ps> if ($hosts.Count -gt 2) { "more than two" } else { "two or fewer" }
more than two
```

**A condição vai entre parênteses e o bloco entre chaves**, os dois obrigatórios.
Não há `then`, não há `fi`, e não há `;` antes da chave — a chave é a gramática. O
`elseif` é uma palavra só.

Diferente do bash (aula 9 seção 07), **a condição é uma expressão, não um comando**. O
`if (Get-Process pwsh) { }` funciona porque um resultado não vazio é verdadeiro,
mas o normal é uma comparação.

```
PS /home/ana/work/ps> if ("false") { "truthy" } else { "falsy" }
truthy
PS /home/ana/work/ps> if (0) { "truthy" } else { "falsy" }
falsy
PS /home/ana/work/ps> if (@()) { "truthy" } else { "falsy" }
falsy
PS /home/ana/work/ps> if ("") { "truthy" } else { "falsy" }
falsy
```

Verdadeiro: um número diferente de zero, uma string não vazia, uma coleção não
vazia, um objeto não nulo. Falso: `0`, `""`, `$null`, `@()`, `$false`.

**E a string `"false"` é verdadeira**, porque é uma string não vazia. É assim que
uma configuração lida de um arquivo faz exatamente o oposto do que diz:

```
PS /home/ana/work/ps> [bool]"false"
True
PS /home/ana/work/ps> [System.Convert]::ToBoolean("false")
False
```

A conversão que você pega é a errada. O `[System.Convert]::ToBoolean` lê a
palavra; o `[bool]` pergunta se há alguma coisa ali.

## Laços

```
PS /home/ana/work/ps> foreach ($h in "web01","db01") { "checking $h" }
checking web01
checking db01
PS /home/ana/work/ps> 1..4 | ForEach-Object { $_ * $_ }
1
4
9
16
PS /home/ana/work/ps> $i = 0; while ($i -lt 3) { "i=$i"; $i++ }
i=0
i=1
i=2
```

**O `foreach` e o `ForEach-Object` são coisas diferentes** com nomes confusamente
parecidos.

| | |
|---|---|
| `foreach ($x in $coll) { }` | uma palavra-chave. A coleção já tem que estar na memória |
| `$coll \| ForEach-Object { }` | um cmdlet. Flui, um objeto por vez, `$_` é o item |

O `foreach` é mais rápido; o `ForEach-Object` flui, então é o que você quer quando
a coleção tem um milhão de linhas ou está chegando pela rede. O apelido do
`ForEach-Object` é `%`, e o `foreach` é *também* um apelido do `ForEach-Object`
quando aparece depois de um pipe — o que é uma verruga genuína e o motivo de
escrever o nome do cmdlet por extenso.

O `for`, o `do…while` e o `do…until` existem e são como você espera.

O `break` e o `continue` funcionam em laços:

```
PS /home/ana/work/ps> foreach ($n in 1,2,3) { if ($n -eq 2) { continue }; "n=$n" }
n=1
n=3
```

**Eles não se comportam igual dentro de um bloco de `ForEach-Object`**, porque
aquilo é uma função chamada uma vez por objeto e não um laço. Filtre com o
`Where-Object` antes, ou use a palavra-chave `foreach`, e a questão não aparece.

## O `switch`

```
PS /home/ana/work/ps> switch ("report.log") { {$_ -like "*.log"} { "a log file" } {$_ -like "*.csv"} { "a spreadsheet" } default { "no idea" } }
a log file
```

O `switch` recebe um valor e uma lista de pares `condição { ação }`. Uma condição
pode ser um literal, um curinga (com `-Wildcard`), uma expressão regular (com
`-Regex`), ou um bloco que devolve booleano, como acima.

E aqui está a diferença para o `case` da aula 9 seção 09, que vai te pegar uma vez:

```
PS /home/ana/work/ps> switch (3) { 1 { "one" } 3 { "three" } 3 { "three again" } default { "other" } }
three
three again
```

**Todo ramo que casa roda.** O `case` para no primeiro e o `switch` não — ele
continua pela lista. Um `break` dentro de um ramo o para, que é por que blocos de
`switch` de verdade são cheios de `break` e blocos de `case` do bash não têm
nenhum.

O `default` roda só quando nada casou.

O `switch` também recebe uma coleção e roda a coisa toda por elemento, que é um
jeito elegante de classificar uma lista:

```
PS /home/ana/work/ps> switch -Regex ("ERROR: disk full","WARN: slow","ERROR: again") { "^ERROR" { "err: $_" } "^WARN" { "warn: $_" } }
err: ERROR: disk full
warn: WARN: slow
err: ERROR: again
```

Três strings entrando, um `switch`, o `$_` segurando cada uma por vez. Isso é um
laço inteiro de classificação de log sem laço nenhum dentro.

## O `Set-StrictMode`

O `set -u` do bash tem um equivalente exato, e ele está desligado por padrão do
mesmo jeito.

```
PS /home/ana/work/ps> if ($nothing.Count -gt 2) { "more than two" } else { "two or fewer" }
two or fewer
PS /home/ana/work/ps> Set-StrictMode -Version Latest
PS /home/ana/work/ps> if ($nothing.Count -gt 2) { "more than two" } else { "two or fewer" }
InvalidOperation: The variable '$nothing' cannot be retrieved because it has not been set.
```

**Sem ele, um nome de variável errado é `$null`, o `$null.Count` é 0, e o ramo do
`else` roda.** Isso é o `$TARGE` da aula 9 seção 06 noutra linguagem: nenhum erro, uma
decisão tomada sobre um valor que nunca esteve lá.

| | |
|---|---|
| `Set-StrictMode -Version Latest` | variáveis não inicializadas, propriedades e métodos inexistentes |
| `$ErrorActionPreference = 'Stop'` | a metade do `set -e`. A próxima seção |

**As duas linhas pertencem ao topo de todo script que você escrever**, pelo mesmo
motivo que o `set -euo pipefail`, e com a mesma ressalva: elas não são uma rede de
segurança, são duas classes de resposta errada e silenciosa transformadas em uma
parada.
