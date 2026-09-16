---
title: Variáveis têm tipo, e quem decide é o operando da esquerda
version: 1
---

```
PS /home/ana/work/ps> $name = "ana"; $name.GetType().Name
String
PS /home/ana/work/ps> $n = 42; $n.GetType().Name
Int32
```

Uma variável é `$name`, com o `$` dos dois lados da atribuição — diferente do
bash, em que ele não aparece à esquerda. Espaços em volta do `=` são permitidos.

**E o valor tem um tipo.** O `42` é um `Int32`, não os dois caracteres `42`, que é
a coisa que o bash não tem e o motivo de tudo nesta aula funcionar.

## A conversão acontece, e a direção importa

```
PS /home/ana/work/ps> $n = "42"; $n + 1
421
PS /home/ana/work/ps> $n = 42; $n + "1"
43
PS /home/ana/work/ps> [int]"42" + 1
43
```

Os mesmos dois valores, respostas opostas.

**Quem decide é o operando da esquerda.** String mais número é concatenação;
número mais string converte a string e soma. Essa é a mesma regra da armadilha de
comparação da seção de filtragem, e vale enunciar uma vez como regra porque ela
explica as duas:

> O PowerShell converte o operando da **direita** para o tipo do da **esquerda**.

`[int]`, `[double]`, `[datetime]`, `[string]`, `[bool]` entre colchetes na frente
de um valor é uma conversão, e é como você para de adivinhar.

Uma conversão também pode ir na variável, e aí ela gruda:

```
PS /home/ana/work/ps> [int]$count = 0; $count = "twelve"
MetadataError: Cannot convert value "twelve" to type "System.Int32". Error: "The input string 'twelve' was not in a correct format."
```

**Um erro, em vez de uma mudança silenciosa de tipo.** Uma variável declarada com
tipo o mantém, que é a coisa mais próxima de um `readonly` que o PowerShell tem e
é mais útil.

## Strings

```
PS /home/ana/work/ps> $x = 5; "the answer is $x, and twice it is $(2*$x)"
the answer is 5, and twice it is 10
PS /home/ana/work/ps> 'no expansion here: $x'
no expansion here: $x
```

**Aspas duplas expandem, aspas simples não** — a mesma divisão da aula 9 seção 04,
com a mesma consequência para expressões regulares e qualquer coisa contendo um
`$`.

**O `$( )` dentro de uma string com aspas duplas** roda uma expressão, que é como
você põe uma propriedade numa mensagem:

```
PS /home/ana/work/ps> "$f.Name"
/home/ana/work/ps/sales.csv.Name
PS /home/ana/work/ps> "$($f.Name) is $($f.Length) bytes"
sales.csv is 788 bytes
```

Sem o `$( )`, a variável expandiu sozinha e o `.Name` virou quatro caracteres
literais depois dela — um incômodo diário pequeno até você aprender.

O caractere de escape é uma **crase**, não uma barra invertida:

```
PS /home/ana/work/ps> "a`tb`nc"
a       b
c
PS /home/ana/work/ps> "C:\Users\ana"
C:\Users\ana
```

`` `n `` é uma quebra de linha, `` `t `` uma tabulação, `` `$ `` um cifrão
literal. **A barra invertida é um caractere comum**, que é por que caminhos do
Windows podem ser escritos sem duplicá-la, e por que uma expressão regular dentro
de aspas duplas é um campo minado — `"\d+"` funciona, mas use aspas simples e pare
de pensar nisso.

Here-strings são a forma de várias linhas:

```sh
@"
expands $variables
"@

@'
does not expand anything
'@
```

## Objetos, não strings parecidas com coisas

```
PS /home/ana/work/ps> $d = Get-Date; $d.GetType().FullName; $d.AddDays(7).DayOfWeek
System.DateTime
Tuesday
```

O `Get-Date` não devolve texto. Ele devolve um `DateTime`, que sabe o que é uma
semana. O equivalente em bash é `date -d '+7 days' +%A`, que é o `date` fazendo a
aritmética porque o shell não consegue.

E strings têm métodos, porque uma string também é um objeto:

```
PS /home/ana/work/ps> "hello".ToUpper(); "  padded  ".Trim(); "a,b,c".Split(",")
HELLO
padded
a
b
c
```

`.ToUpper()`, `.Trim()`, `.Split()`, `.Replace()`, `.StartsWith()`, `.PadLeft()` —
a biblioteca de strings inteira do .NET, em qualquer string. Isso é o `tr`, o `sed`
e o `cut` da aula 8, como métodos, sem um processo para cada.

**Repare nos parênteses.** O `.Trim()` é um método e precisa deles; o `.Length` é
uma propriedade e não pode tê-los. Errar não é um erro:

```
PS /home/ana/work/ps> "hello".Length
5
PS /home/ana/work/ps> "hello".Trim
OverloadDefinitions
-------------------
string Trim()
string Trim(char trimChar)
string Trim(Params char[] trimChars)
```

Um método sem os parênteses imprime **as assinaturas do método**, o que
ocasionalmente é exatamente o que você queria — é assim que se descobre que o
`Trim` aceita um caractere opcional — e no resto do tempo é sinal de que você
esqueceu os colchetes.

## Variáveis especiais

| | |
|---|---|
| `$_` | o objeto atual do pipeline |
| `$?` | a última coisa deu certo. Um booleano, não um número |
| `$LASTEXITCODE` | o código de saída do último programa **nativo** |
| `$null` | nada. `$null -eq $x` é a ordem segura de escrever |
| `$true` `$false` | booleanos, por extenso |
| `$PSVersionTable` | o que você está rodando |
| `$IsLinux` `$IsWindows` `$IsMacOS` | qual plataforma |
| `$env:NOME` | uma variável de ambiente |

O `$env:PATH` é como você lê o ambiente, e defini-la com `$env:LEVEL = "debug"` a
exporta para os filhos — o `export` da aula 9 seção 03, embutido no nome.

O `$IsLinux` e companhia são como um script multiplataforma se ramifica:

```
PS /home/ana/work/ps> $PSVersionTable.Platform; $IsLinux; $IsWindows; $IsMacOS
Unix
True
False
False
```

Essa é esta máquina respondendo. Na caixa Windows para a qual esses scripts são
feitos, a segunda e a terceira trocam de lugar — e essa é uma das poucas coisas
desta aula que você vai ter que aceitar por confiança, porque não há Windows aqui
para rodar.
