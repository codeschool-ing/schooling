---
title: Flags, argumentos e de onde vêm os valores
version: 1
---

O pacote flag da lição 1 lê as flags do começo da lista e para na primeira palavra que não é flag.
**A urfave/cli v3 lê a lista inteira**: uma palavra que começa com traço é flag onde quer que
esteja, e as palavras que não são flags, na ordem em que vieram, são o que o `cmd.Args()` devolve.
Essa diferença elimina a surpresa mais comum da seção 03 da lição 1, em que o `-v` depois de
`jan.log` foi tomado por nome de arquivo. Uma flag na v3 também é mais que um nome e um padrão, como
o `-n` do `top` mostrou na seção 02, e vale rodar cada campo extra uma vez.

## Em qualquer ponto da linha

Primeiro o arquivo e a flag depois dele, e então um segundo nome e a outra flag antes do arquivo:

```
ana@vm:~/cli-hits$ ./hits top access.log -n 2
path         requests
/login       2576
/api/orders  2542
ana@vm:~/cli-hits$ ./hits top --limit 2 -json access.log
[{"path":"/login","hits":2576},{"path":"/api/orders","hits":2542}]
```

**O `-n 2` depois do arquivo funcionou**, o que a versão da lição 1 recusa: lá, `-n` e `2` seriam
mais dois argumentos e o `summarise` reclamaria de três arquivos. O `--limit` é o apelido declarado
em `Aliases`, e os dois nomes definem um mesmo valor. A biblioteca aceitou `-json` com um traço só,
embora imprima o nome como `--json` na ajuda, então a grafia da lição 1 continua valendo; `--json`
também funciona.

O que não mudou é a convenção para um argumento que começa com traço, e a entrada padrão como `-`:

```
ana@vm:~/cli-hits$ go run ./tools/genlog -n 1000 -seed 3 | ./hits top -n 2 -
path             requests
/static/app.css  137
/api/users       135
ana@vm:~/cli-hits$ ./hits top -- -n
hits: open -n: no such file or directory
```

O `-` não é flag para ninguém, então chega ao `summarise`, que lê a entrada padrão como o da lição 1
lia; os dois caminhos e suas contagens são os da seção 05 da lição 1. **Depois de `--`, nada é
flag**, então `-n` virou nome de arquivo e a abertura falhou. É assim que se entrega ao `hits` um
arquivo que se chama mesmo `-n`.

## Um valor vindo do ambiente, e um valor recusado

O `Sources: cli.EnvVars("HITS_TOP")` dá ao `-n` um segundo lugar de onde vir. Quando a flag está na
linha de comando, ela vence; quando não está, a variável é lida; quando nenhuma das duas existe,
vale o padrão:

```
ana@vm:~/cli-hits$ HITS_TOP=4 ./hits top access.log
path            requests
/login          2576
/api/orders     2542
/static/app.js  2526
/api/users      2512
ana@vm:~/cli-hits$ HITS_TOP=4 ./hits top -n 2 access.log
path         requests
/login       2576
/api/orders  2542
```

**A ordem é linha de comando, depois ambiente, depois `Value`**, e é a ordem que você quer: uma
variável definida no perfil do shell vira um padrão pessoal, e uma flag digitada para uma execução
ainda passa por cima dela. O `EnvVars` aceita vários nomes e tenta um de cada vez. A v3 também tem
fontes para arquivos, e o `Sources` é uma cadeia justamente para que mais de um tipo possa ser
listado; esta lição usa só o ambiente.

O `Validator` é chamado com o valor já convertido, depois que a biblioteca recusou tudo o que não é
`int`:

```
ana@vm:~/cli-hits$ ./hits top -n 0 access.log 2>&1 | head -1
Incorrect Usage: invalid value "0" for flag -n: must be at least 1, got 0
```

O `top` da lição 1 não tinha essa checagem, e o `tally.Top` corta as linhas com
`rows[:min(n, len(rows))]`: `-n 0` pedia uma tabela sem nenhuma linha, e um `-n` negativo faz essa
expressão de fatia entrar em pânico. **Um valor que o programa não consegue usar agora é recusado na
porta**, com o nome da flag na mensagem. `Incorrect Usage` é só a primeira linha do que a biblioteca
imprimiu, e a seção 04 trata do resto.

O campo ao lado desses dois é o `Required`. Uma flag declarada com `Required: true` que falta na
linha de comando interrompe a execução antes da Action, pelo mesmo caminho de um valor recusado.
Nenhuma das flags do `hits` precisa disso, porque cada uma tem um padrão razoável, que é o motivo de
costume para algo ser flag e não argumento.

## A ajuda se escreve sozinha

Cada campo acima também vai parar na ajuda, que a biblioteca monta a partir das declarações:

```
ana@vm:~/cli-hits$ ./hits top -h
NAME:
   hits top - the paths with the most requests

USAGE:
   hits top [options] [file]

OPTIONS:
   -n int, --limit int  how many paths to show (default: 3) [$HITS_TOP]
   --json               print JSON instead of a table
   --help, -h           show help
```

**Nada no `hits` escreve esse texto.** A linha de uso vem do `ArgsUsage`, os dois nomes do `-n` do
`Aliases`, `int` do tipo da flag, o padrão do `Value` e `[$HITS_TOP]` do `Sources`. A constante
`usage` da lição 1 foi escrita à mão e podia se descolar do código que descrevia; esta não pode,
porque é o código lido de volta. A ajuda imprime um traço antes de um nome de uma letra e dois antes
de um nome maior, a convenção GNU, e aceita as duas grafias.

## Uma palavra que a biblioteca toma para si

Uma palavra não é argumento na v3 nem onde se espera um argumento:

```
ana@vm:~/cli-hits$ ./hits top help | head -2
NAME:
   hits top - the paths with the most requests
```

Todo comando ganha um subcomando `help` embutido, e **`hits top help` pede a ajuda do `top`** em vez
de ler um arquivo chamado `help`. É a mesma regra do `--`: a biblioteca reserva algumas palavras da
linha de comando, e um arquivo que por acaso tenha o nome de uma delas precisa de outra grafia,
`./help` aqui. O despacho da lição 1 só reservava `help` na primeira posição, porque eram vinte
linhas de `switch` e ele não fazia nada que não tivessem mandado.
