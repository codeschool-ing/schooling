---
title: O pipeline carrega objetos, e todo o resto decorre disso
version: 1
---

Toda ferramenta da aula 8 lia texto e escrevia texto. O `grep` casava caracteres,
o `cut` contava delimitadores, o `awk` dividia no espaço em branco. Essa é a ideia
do Unix, e ela funciona porque todo programa concorda em falar o mesmo mínimo
denominador comum.

**O PowerShell fez a outra escolha.** Um comando emite objetos — coisas com
propriedades nomeadas e tipadas — e o comando seguinte do pipeline recebe esses
objetos em vez de uma representação deles.

```
PS /home/ana/work/ps> Get-ChildItem | Select-Object -First 3
    Directory: /home/ana/work/ps

UnixMode         User Group         LastWriteTime         Size Name
--------         ---- -----         -------------         ---- ----
-rw-r--r--        ana ana        09/15/2026 10:48       148233 access.log
-rw-r--r--        ana ana        09/15/2026 10:48          788 sales.csv
```

Aquela tabela parece a saída do `ls -l`. Não é. **É uma representação, produzida
bem no fim, de dois objetos que nunca foram texto em momento nenhum.** Pergunte o
que eles são:

```
PS /home/ana/work/ps> Get-ChildItem | Get-Member -MemberType Property | Select-Object -First 8
   TypeName: System.IO.FileInfo

Name            MemberType Definition
----            ---------- ----------
Attributes      Property   System.IO.FileAttributes Attributes {get;set;}
CreationTime    Property   datetime CreationTime {get;set;}
CreationTimeUtc Property   datetime CreationTimeUtc {get;set;}
Directory       Property   System.IO.DirectoryInfo Directory {get;}
DirectoryName   Property   string DirectoryName {get;}
Exists          Property   bool Exists {get;}
Extension       Property   string Extension {get;}
FullName        Property   string FullName {get;}
```

O `Get-Member` é o comando mais útil do PowerShell e o primeiro a aprender. Ele
responde "o que é esta coisa, e o que posso perguntar a ela".

## O que isso compra

```
PS /home/ana/work/ps> (Get-ChildItem sales.csv).Length
788
PS /home/ana/work/ps> (Get-ChildItem sales.csv).LastWriteTime.Year
2026
```

Compare com o bash para as mesmas duas perguntas:

```sh
ls -l sales.csv | awk '{print $5}'      # the size — if the filename has no spaces
ls -l sales.csv | awk '{print $8}'      # the year — if the file is over six months old
```

**A versão com `awk` está contando colunas numa representação.** A seção do `cut`
da aula 8 era sobre isso dar errado, e a seção do `awk` mediu: num log de mil e
duzentas linhas em que toda linha parece ter a mesma forma, o `awk '{print NF}'`
informa quatro contagens de campo diferentes, porque um dos campos é texto livre
com espaços dentro.

O `.Length` não tem como ter esse problema. Ele não é a quinta palavra de nada; é
um número num objeto, e é o mesmo número seja qual for o nome do arquivo.

E o `.LastWriteTime.Year` é a parte que não tem equivalente em bash nenhum: o
`LastWriteTime` não é uma string parecida com uma data, é um `DateTime`, então ele
tem um `.Year`, um `.AddDays(7)`, e uma comparação que entende meses.

## O que isso custa

Três coisas, e são reais.

**É verboso.** `Get-ChildItem | Where-Object { $_.Length -gt 1000 }` contra
`ls -l | awk '$5>1000'`. Apelidos ajudam num prompt — `gci`, `?`, `%` — e deixam
um script ilegível.

**Demora mais para começar.** O PowerShell inicia um runtime .NET:

```
ana@vm:~/work/ps$ time pwsh -NoProfile -Command 'Write-Output hello'
hello

real	0m0.405s
user	0m0.387s
sys	0m0.146s
ana@vm:~/work/ps$ time bash -c 'echo hello'
hello

real	0m0.003s
user	0m0.000s
sys	0m0.003s
```

Cento e trinta vezes, nesta máquina. Para um shell em que você digita, ninguém
nota; para algo que um agendador roda a cada minuto, alguém nota.

**Os objetos são tão bons quanto o comando que os fez.** Um cmdlet que devolve um
objeto tipado é um prazer; um cmdlet que devolve strings que você ainda precisa
analisar te dá o pior dos dois mundos. E quando você lê um arquivo de texto puro,
você voltou a analisar — que é a seção do pipeline, e a armadilha da seção de
filtragem.

## Onde esta aula se situa

**Isto é uma visão geral.** É o bastante para ler um script que te entregam,
escrever um curto, e saber o que procurar. Não é um curso de PowerShell.

E ela foi capturada no PowerShell 7 rodando em Linux:

```
PS /home/ana/work/ps> $PSVersionTable
Name                           Value
----                           -----
PSVersion                      7.4.6
PSEdition                      Core
GitCommitId                    7.4.6
OS                             Ubuntu 24.04.4 LTS
Platform                       Unix
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0…}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0
```

A linguagem, o pipeline, os objetos e os erros desta aula são todos reais, e
foram rodados como um usuário comum. **O que não está aqui é o Windows** — os
serviços, o registro, as classes CIM — e a seção sobre falar com o Windows mostra
aqueles cmdlets não existindo em vez de descrever uma saída que ninguém produziu.
