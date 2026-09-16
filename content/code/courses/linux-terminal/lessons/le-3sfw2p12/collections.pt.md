---
title: Arrays e hashtables, e a contagem que não está lá
version: 1
---

```
PS /home/ana/work/ps> $hosts = "web01","web02","db01"; $hosts.Count; $hosts[0]; $hosts[-1]
3
web01
db01
```

**Uma vírgula faz um array.** Sem colchetes necessários, embora o
`@("web01","web02")` seja a forma explícita e importe mais abaixo. A indexação
começa em zero, e `-1` é o último elemento — o que arrays de bash não conseguem.

```
PS /home/ana/work/ps> $hosts += "cache01"; $hosts.Count
4
PS /home/ana/work/ps> $hosts | Where-Object { $_ -like "web*" }
web01
web02
```

O `+=` acrescenta. Ele também é uma mentira: **arrays do PowerShell têm tamanho
fixo**, então o `+=` constrói um array novo inteiro e copia tudo para dentro. Em
quatro elementos isso é invisível; num laço sobre dez mil é o motivo mais comum
de um script de PowerShell ser lento. O conserto é deixar o pipeline coletar:

```sh
$result = foreach ($h in $hosts) { Test-Something $h }     # collects, no copying
$result = $hosts | ForEach-Object { Test-Something $_ }    # the same
```

Um array é encanado um elemento por vez, que é por que o `$hosts | Where-Object`
funciona sem nada especial — uma coleção posta no pipeline é desenrolada.

## Hashtables

```
PS /home/ana/work/ps> $h = @{ name = "web01"; port = 8080 }; $h["name"]; $h.port
web01
8080
PS /home/ana/work/ps> $h.Keys
port
name
```

`@{ }` com pares `chave = valor`, separados por `;` numa linha ou por quebras de
linha num arquivo. Leia um valor com `$h["name"]` ou `$h.name` — a forma com ponto
é mais curta e falha numa chave com espaço.

**A ordem não é a de inserção.** O `port` voltou antes do `name`, igual aos arrays
associativos do bash na aula 9 seção 12. O `[ordered]@{ }` a mantém:

```
PS /home/ana/work/ps> $h = [ordered]@{ name = "web01"; port = 8080 }; $h.Keys
name
port
```

Você quer isso sempre que a hashtable for virar uma tabela, um `pscustomobject` ou
um documento JSON, porque a ordem das colunas é a ordem das chaves.

`$h.Keys`, `$h.Values`, `$h.ContainsKey('port')`, `$h.Remove('port')` — e o
`$h.novachave = 1` acrescenta uma.

Hashtables também são como se constrói um objeto:

```sh
[pscustomobject]@{ ip = $f[0]; path = $f[6]; status = [int]$f[8] }
```

Aquela conversão é a linha de análise inteira do vídeo da pergunta. Uma hashtable
é um saco de nomes e valores; um `pscustomobject` é uma *coisa* com propriedades,
e é o que o pipeline quer.

## A contagem que não está lá

Esta é a armadilha desta seção, e é real.

```
PS /home/ana/work/ps> $empty = @(); $empty.Count; ($empty | Measure-Object).Count
0
0
PS /home/ana/work/ps> $one = Get-ChildItem sales.csv; $one.Count
1
PS /home/ana/work/ps> @(Get-ChildItem sales.csv).Count
1
```

Todos aqueles se comportam. O problema é o que o `Get-ChildItem` **devolve**
quando não casa com nada ou casa com uma coisa: não um array de zero ou um, mas
`$null` ou o objeto pelado.

No PowerShell 7 um objeto sozinho tem `.Count` de 1 e o `$null.Count` é 0, então as
quatro linhas acima funcionam. **No Windows PowerShell 5.1 — que é o que está em
todo Windows Server — nenhum dos dois funciona**, e o `$result.Count` num resultado
único é `$null`, em silêncio, e a sua conferência de "recebemos exatamente um"
nunca é verdadeira.

O conserto funciona nos dois e custa três caracteres:

```sh
@(Get-ChildItem *.log).Count       # @( ) forces an array, of zero, one or many
($x | Measure-Object).Count        # the same, through the pipeline
```

**Escreva `@( )` em volta de qualquer coisa cuja contagem você vai testar.** É de
graça, é correto em toda versão, e a versão sobre a qual você está errado é a que
vão te pedir para dar suporte.

## Mais duas coisas que valem

**`$array + $array` concatena** e `$hash1 + $hash2` mescla — o segundo lançando
erro se uma chave estiver nos dois:

```
PS /home/ana/work/ps> $a = @{x=1}; $b = @{y=2}; ($a + $b).Keys
x
y
PS /home/ana/work/ps> $c = @{x=1}; $d = @{x=2}; $c + $d
OperationStopped: Item has already been added. Key in dictionary: 'x'  Key being added: 'x'
```

**O `-join` e o `-split` são operadores**, não cmdlets:

```
PS /home/ana/work/ps> $hosts = "web01","web02"; $hosts -join ", "
web01, web02
PS /home/ana/work/ps> "one two  three" -split "\s+"
one
two
three
```

O `-split` numa expressão regular é a divisão em campos do `awk` e o `tr -s ' '` da
aula 8 num operador só, e o `-join` é o `paste -sd,` da aula 8 seção 15.
