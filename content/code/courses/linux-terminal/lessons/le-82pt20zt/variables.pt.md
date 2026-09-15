---
title: Variáveis, e os quatro caracteres que não são permitidos
version: 1
---

```
ana@vm:~/work/scripts$ name=ana
ana@vm:~/work/scripts$ echo $name
ana
```

Atribua com `=`, leia com `$`. É só isso, e então há uma regra que custa a todo mundo os primeiros
dez minutos.

## Sem espaços em volta do `=`

```
ana@vm:~/work/scripts$ name = ana
bash: name: command not found
ana@vm:~/work/scripts$ name= ana
bash: ana: command not found
```

**As duas são shell válido — só não querem dizer o que você queria.** O shell divide uma linha em
palavras e roda a primeira como comando, então `name = ana` é "rode o comando `name` com os
argumentos `=` e `ana`", e `name= ana` é "rode o `ana` com `name` definido como vazio".

Essa segunda é um recurso de verdade, e ela volta mais adiante nesta seção. Por ora, lembre:
**`name=valor`, sem nada dos dois lados do `=`.**

## Tudo é string

```
ana@vm:~/work/scripts$ count=3
ana@vm:~/work/scripts$ echo $count+1
3+1
```

Não existe tipo numérico. O `count` guarda os dois caracteres `3`, e `$count+1` é a string `3+1`.
Aritmética precisa do `$(( ))`, que é a seção 151.

Aspas são só para o shell — elas nunca acabam dentro do valor:

```
ana@vm:~/work/scripts$ greeting='hello there'
ana@vm:~/work/scripts$ echo $greeting
hello there
```

As aspas são como você pôs `hello there` numa variável só em vez de rodar o `there` como comando. A
variável em si não contém aspas.

## Chaves, para onde o nome termina

```
ana@vm:~/work/scripts$ echo ${name}s
anas
ana@vm:~/work/scripts$ echo $names

```

**O `$names` é uma variável chamada `names`**, que não existe — então expandiu para nada e o `echo`
imprimiu uma linha em branco. O `${name}s` é a variável `name` seguida de um `s` literal.

O shell lê um nome até onde consegue: letras, dígitos e sublinhados. Qualquer outra coisa o
termina, que é por que `$name.txt` e `$name/file` funcionam sem chaves e `${name}s` precisa delas.

**As chaves também são onde tudo da seção 152 se pendura**, então não é um mau hábito usá-las
sempre. As duas grafias estão corretas; escolha uma e seja consistente.

## Uma variável não definida não é um erro

```
ana@vm:~/work/scripts$ unset name; echo "[${name}]"
[]
```

**Um nome que não existe expande para absolutamente nada**, em silêncio. Este é o comportamento
mais perigoso do shell, ele já apagou diretórios de verdade, e a seção 143 é sobre transformá-lo
num erro.

Enquanto isso, existem dois padrões:

```
ana@vm:~/work/scripts$ echo "[${name-not set}] [${name:-empty or unset}]"
[not set] [empty or unset]
```

| | |
|---|---|
| `${name-padrão}` | use o padrão quando `name` **não estiver definida** |
| `${name:-padrão}` | use o padrão quando `name` não estiver definida **ou estiver vazia** |

**Os dois pontos são a diferença entre as duas, e a com dois pontos é quase sempre a que você
quis.** Uma variável definida como string vazia é um bug tão frequentemente quanto é um valor.

## Variáveis de shell e variáveis de ambiente

São duas coisas diferentes e a diferença decide o que os seus scripts conseguem enxergar.

```
ana@vm:~/work/scripts$ SHELLVAR=one
ana@vm:~/work/scripts$ export ENVVAR=two
ana@vm:~/work/scripts$ echo "$SHELLVAR $ENVVAR"
one two
ana@vm:~/work/scripts$ ./child.sh
shell variable SHELLVAR is [unset]
environment  ENVVAR   is [two]
ana@vm:~/work/scripts$ env | grep -E '^(SHELLVAR|ENVVAR)='
ENVVAR=two
```

As duas existem no shell em que você as digitou. Só a exportada atravessou para o filho.

**O `export` é o que faz uma variável virar parte do ambiente**, e o ambiente é a única coisa que
um processo filho herda. É por isso que um script não enxerga uma variável que você definiu no
prompt a menos que você a tenha exportado, e por que o `source` (seção 139) é o mesmo problema pelo
outro lado.

O `env` lista exatamente o que está exportado, o que faz dele a forma de conferir.

### Um comando, uma variável

```
ana@vm:~/work/scripts$ SHELLVAR=three ./child.sh
shell variable SHELLVAR is [three]
environment  ENVVAR   is [two]
ana@vm:~/work/scripts$ echo $SHELLVAR
one
```

Aquilo é o `name= comando` do começo desta seção, usado de propósito: **uma variável escrita na
frente de um comando é exportada para aquele comando e para mais nada.** O `SHELLVAR` do próprio
shell continua `one` depois.

É assim que você roda algo uma vez com uma configuração diferente — `LANG=C sort arquivo`,
`DEBUG=1 ./deploy.sh` — sem mexer no seu shell.

## O `declare`, e duas opções que valem

```
ana@vm:~/work/scripts$ readonly PI=3.14; PI=3
bash: PI: readonly variable
ana@vm:~/work/scripts$ declare -i n=5; n=n+2; echo $n
7
ana@vm:~/work/scripts$ declare -p ENVVAR SHELLVAR n
declare -x ENVVAR="two"
declare -- SHELLVAR="one"
declare -i n="7"
```

O `declare -i` torna a variável inteira, então atribuições a ela são avaliadas como aritmética — o
`n=n+2` deu `7` em vez da string `n+2`. É ocasionalmente prático e principalmente uma curiosidade;
o `$(( ))` é mais claro.

O `readonly` é o que vale usar de fato, para o punhado de coisas que um script não pode
reatribuir.

**O `declare -p` é a ferramenta de depuração**: ele imprime uma variável com o tipo e o valor
exato, com aspas. Quando você está olhando para uma saída se perguntando se a variável tem um
espaço no fim, o `declare -p` responde numa linha onde o `echo` não responde.

## Nomes

| | |
|---|---|
| `minusculas` | as suas próprias variáveis, por convenção |
| `MAIUSCULAS` | variáveis exportadas e constantes, por convenção |
| `PATH HOME USER PWD` | as do sistema. Não atribua a estas sem querer |

A convenção importa mais do que parece: **um script que faz `PATH=/opt/mytool` em vez de
`PATH=/opt/mytool:$PATH` acabou de perder todo comando da máquina**, e a falha é uma cascata de
"command not found" que não aponta obviamente para a atribuição.
