---
title: Erros, e dois tipos diferentes de falha
version: 1
---

O PowerShell tem duas classes de erro e elas se comportam de forma diferente.
Saber qual você está olhando é a maior parte desta seção.

```
PS /home/ana/work/ps> Get-Content /etc/nosuchfile; "this line still ran"
Get-Content: Cannot find path '/etc/nosuchfile' because it does not exist.
this line still ran
```

**Esse é um erro não terminante.** O cmdlet o informou e o script seguiu, que é o
padrão e é o `noset.sh` da seção 143 de novo.

```
PS /home/ana/work/ps> Get-Content /etc/nosuchfile -ErrorAction Stop; "this line did not"
Get-Content: Cannot find path '/etc/nosuchfile' because it does not exist.
```

**O `-ErrorAction Stop` o promove a erro terminante**, e a segunda instrução nunca
rodou.

| | |
|---|---|
| `Continue` | informe e siga. **O padrão** |
| `Stop` | termine |
| `SilentlyContinue` | não informe, siga |
| `Ignore` | idem, e nem registre no `$Error` |

```
PS /home/ana/work/ps> $ErrorActionPreference
Continue
```

Definir `$ErrorActionPreference = 'Stop'` no topo de um script faz **todo** cmdlet
parar em erro, que é o mais perto que o PowerShell chega do `set -e`. Ponha ao
lado do `Set-StrictMode -Version Latest` da seção 167, e o par é o
`set -euo pipefail`.

**O `SilentlyContinue` é o de tomar cuidado.** Ele é o `2>/dev/null` da seção 121,
com o mesmo problema: ele esconde o erro que você esperava e também o que você não
esperava.

## `try` / `catch` / `finally`

```
PS /home/ana/work/ps> try { Get-Content /etc/nosuchfile -ErrorAction Stop } catch { "caught: $($_.Exception.Message)" }
caught: Cannot find path '/etc/nosuchfile' because it does not exist.
```

Tratamento de exceção de verdade, que o bash não tem — o `trap … ERR` da seção 153
é a coisa mais próxima e é de outra forma.

**O `-ErrorAction Stop` não é opcional ali:**

```
PS /home/ana/work/ps> try { Get-Content /etc/nosuchfile } catch { "caught it" }; "after the try"
Get-Content: Cannot find path '/etc/nosuchfile' because it does not exist.
after the try
PS /home/ana/work/ps> $ErrorActionPreference = "Stop"; try { Get-Content /etc/nosuchfile } catch { "caught it" }; "after the try"
caught it
after the try
```

O primeiro `catch` nunca rodou. O `catch` só enxerga erros **terminantes**, então
um `try` em volta de um cmdlet que informa um não terminante não pega nada, o erro
é impresso normalmente, e o bloco segue. É esse o erro por trás de toda afirmação
de que o `try`/`catch` do PowerShell não funciona.

Ou `-ErrorAction Stop` no cmdlet, ou `$ErrorActionPreference = 'Stop'` uma vez no
topo — e o segundo é o que a maioria dos scripts deveria fazer.

Dentro do `catch`, o `$_` é um `ErrorRecord`:

```
PS /home/ana/work/ps> $Error[0].GetType().FullName
System.Management.Automation.ErrorRecord
```

| | |
|---|---|
| `$_.Exception.Message` | o texto |
| `$_.Exception.GetType().Name` | de que tipo, para o `catch [System.IO.FileNotFoundException]` |
| `$_.InvocationInfo.ScriptLineNumber` | onde |
| `$_.ScriptStackTrace` | como chegou lá |

```
PS /home/ana/work/ps> try { 1/0 } catch { $_.Exception.GetType().Name } finally { "finally ran" }
RuntimeException
finally ran
```

O `finally` roda dos dois jeitos, e é **o `trap … EXIT` da seção 153**: o lugar de
apagar o arquivo temporário, fechar a conexão, devolver a configuração.

O `$Error` é um array de tudo que deu errado nesta sessão, do mais novo para o
mais velho, e o `$Error[0]` depois de algo confuso é a forma mais rápida de
descobrir o que era de fato.

## O `throw`

```
PS /home/ana/work/ps> function Check { param($P) if (-not (Test-Path $P)) { throw "cannot read $P" } ; "ok" }
PS /home/ana/work/ps> Check /etc/hostname
ok
PS /home/ana/work/ps> try { Check /etc/nope } catch { "died: $($_.Exception.Message)" }
died: cannot read /etc/nope
```

O `throw` levanta um erro terminante com a sua mensagem — o `die()` da seção 150,
embutido, e capturável por quem te chamou, o que o `die()` não é. É a forma certa
de uma função recusar.

## O `$?` e o `$LASTEXITCODE` são coisas diferentes

Isso importa no momento em que o seu script chama um programa nativo, o que no
Linux é o tempo todo.

```
PS /home/ana/work/ps> ls /etc/nosuchfile; "$? is $?"
/usr/bin/ls: cannot access '/etc/nosuchfile': No such file or directory
False is False
PS /home/ana/work/ps> ls /etc/nosuchfile; "LASTEXITCODE is $LASTEXITCODE"
/usr/bin/ls: cannot access '/etc/nosuchfile': No such file or directory
LASTEXITCODE is 2
PS /home/ana/work/ps> Get-Content /etc/nosuchfile; "$? is $?, LASTEXITCODE is still $LASTEXITCODE"
Get-Content: Cannot find path '/etc/nosuchfile' because it does not exist.
False is False, LASTEXITCODE is still 2
PS /home/ana/work/ps> ls /etc/hostname; "$? is $?, LASTEXITCODE is $LASTEXITCODE"
/etc/hostname
True is True, LASTEXITCODE is 0
```

| | |
|---|---|
| `$?` | um **booleano**: a instrução anterior deu certo. Definido por tudo |
| `$LASTEXITCODE` | um **inteiro**: o código de saída do último programa nativo |

Leia a terceira linha de novo. O `Get-Content` falhou, o `$?` foi para `False` — e
o `$LASTEXITCODE` continuou dizendo `2`, sobra do `ls` duas linhas antes.
**Cmdlets não tocam no `$LASTEXITCODE`**, então ele fica velho até o próximo
programa externo rodar, e um script que o confere depois de um cmdlet está lendo
uma resposta antiga.

E a outra direção: **o `-ErrorAction Stop` não faz nada com um programa nativo**,
porque o `ls` não faz ideia do que é um ErrorAction. Conferir um comando externo
quer dizer conferir o `$LASTEXITCODE` você mesmo:

```sh
git clone $url
if ($LASTEXITCODE -ne 0) { throw "clone failed" }
```

O `$?` também é `False` para um programa nativo que falhou, como a primeira linha
mostra, então o `if (-not $?)` funciona — desde que seja a instrução seguinte,
porque qualquer coisa no meio o redefine.

## O que pôr no topo

```sh
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
```

Duas linhas. A primeira pega a variável que nunca foi definida, a segunda para no
primeiro cmdlet que falhar. Nenhuma das duas percebe um programa nativo que
devolveu 1, que é o buraco que você tem que cobrir na mão — a mesma forma de
lacuna que a seção 143 mediu no `set -e`.
