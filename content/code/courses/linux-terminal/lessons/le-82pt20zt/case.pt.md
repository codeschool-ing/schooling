---
title: O `case`, e o parser de opções em que todo script acaba
version: 1
---

O `case` compara um valor com uma lista de padrões e roda o primeiro que casar. É o que uma
sequência de seis `elif` queria ser.

```
ana@vm:~/work/scripts$ cat kindof.sh
#!/bin/bash
case "$1" in
  *.log)          echo "a log file" ;;
  *.tar.gz|*.tgz) echo "a compressed tarball" ;;
  *.txt|*.md)     echo "text" ;;
  "")             echo "you gave me nothing" ;;
  *)              echo "no idea what $1 is" ;;
esac
ana@vm:~/work/scripts$ ./kindof.sh access.log; ./kindof.sh backup.tar.gz; ./kindof.sh notes.md
a log file
a compressed tarball
text
ana@vm:~/work/scripts$ ./kindof.sh; ./kindof.sh mystery.bin
you gave me nothing
no idea what mystery.bin is
```

A forma:

| | |
|---|---|
| `case "$x" in` | o valor, entre aspas |
| `padrão)` | um **glob**, não uma expressão regular — a sintaxe da aula 3 seção 10 |
| `a\|b)` | alternativas, com `\|` |
| `;;` | fim deste ramo. Fácil de esquecer, e erro de sintaxe quando você esquece |
| `*)` | o pega-tudo. Ponha por último; ele casa com tudo |
| `esac` | `case` ao contrário, como o `fi` |

**O `*)` não é obrigatório e você deve escrevê-lo assim mesmo.** Sem ele, um valor que não casa
passa em silêncio e o script não faz nada — o que se parece exatamente com sucesso.

Dois detalhes:

**Os padrões são globs.** `*.log` casa, `[0-9]*` casa, `report?.txt` casa. O `.*` não quer dizer o
que quer dizer numa expressão regular; ele casa com um ponto literal seguido de qualquer coisa.

**O primeiro que casa vence e nada escorre.** Não há fallthrough estilo C — o `;;` encerra o ramo
por completo. (O bash tem `;&` e `;;&` para escorrer, e em vinte anos você não vai precisar deles.)

## A única coisa que todo mundo escreve com ele

Todo script que recebe opções termina com este laço. Ele é `while` da seção 10, `shift` da seção 05,
e `case`:

```
ana@vm:~/work/scripts$ cat deploy.sh
#!/bin/bash
verbose=0
env=staging
while [ "$#" -gt 0 ]; do
  case "$1" in
    -v|--verbose) verbose=1 ;;
    -e|--env)     env="$2"; shift ;;
    --env=*)      env="${1#*=}" ;;
    -h|--help)    echo "usage: deploy.sh [-v] [-e ENV] TARGET"; exit 0 ;;
    -*)           echo "unknown option: $1" >&2; exit 2 ;;
    *)            target="$1" ;;
  esac
  shift
done
echo "target=${target:-none} env=$env verbose=$verbose"
```

Dezesseis linhas, e ele trata toda convenção que se espera de uma ferramenta de linha de comando:

```
ana@vm:~/work/scripts$ ./deploy.sh web01
target=web01 env=staging verbose=0
ana@vm:~/work/scripts$ ./deploy.sh -v --env production web01
target=web01 env=production verbose=1
ana@vm:~/work/scripts$ ./deploy.sh --env=qa web02
target=web02 env=qa verbose=0
ana@vm:~/work/scripts$ ./deploy.sh --wat; echo "exit $?"
unknown option: --wat
exit 2
ana@vm:~/work/scripts$ ./deploy.sh --help
usage: deploy.sh [-v] [-e ENV] TARGET
```

Leia ramo por ramo, porque cada linha é uma decisão que vale copiar:

| | |
|---|---|
| `-v\|--verbose` | grafia curta e longa de uma opção, um ramo só |
| `-e\|--env` | recebe um valor: use o `$2` e então dê um `shift` **a mais** por ele |
| `--env=*` | a grafia `--opção=valor`. O `${1#*=}` é "tudo depois do primeiro `=`" |
| `-h\|--help` | imprime o uso e sai com **zero** — pedir ajuda não é erro |
| `-*)` | **qualquer outra coisa começando com traço é engano.** Diga isso, no stderr, saia diferente de zero |
| `*)` | não é opção, então é um argumento posicional |

O ramo que fica de fora dos parsers escritos à mão é o `-*)`, e é o que importa. Aqui está o mesmo
laço sem ele, recebendo um erro de digitação:

```
ana@vm:~/work/scripts$ ./nodash.sh --verbsoe web01
target=web01 verbose=0
ana@vm:~/work/scripts$ ./deploy.sh --verbsoe web01; echo "exit $?"
unknown option: --verbsoe
exit 2
```

**O `--verbsoe` caiu no `*)`, foi atribuído ao `target`, e então foi sobrescrito pelo `web01`.** O
script rodou, não disse nada, e fez o trabalho sem a opção que você pediu. Quatro caracteres no
`case` transformam isso num erro com código de saída.

## Onde isso deixa de bastar

Este laço não trata opções curtas agrupadas — `-vf` não é o mesmo que `-v -f` para ele — e não trata
o `--` como marcador de fim de opções.

O `getopts` é o builtin que faz a primeira coisa direito:

```sh
while getopts ":vt:n:" opt; do
  case "$opt" in
    v) verbose=1 ;;
    t) threshold="$OPTARG" ;;
    n) rows="$OPTARG" ;;
    \?) echo "unknown option: -$OPTARG" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
```

```
ana@vm:~/work/scripts$ ./getopts.sh -v -t 3000 -n 3 access.log
verbose=1 threshold=3000 rows=3 rest=access.log
ana@vm:~/work/scripts$ ./getopts.sh -vt3000 access.log
verbose=1 threshold=3000 rows=5 rest=access.log
ana@vm:~/work/scripts$ ./getopts.sh -z access.log; echo "exit $?"
unknown option: -z
exit 2
ana@vm:~/work/scripts$ ./getopts.sh --verbose access.log; echo "exit $?"
unknown option: --
exit 2
```

O `-vt3000` foi agrupado corretamente, o que o laço escrito à mão não consegue. O
`shift $((OPTIND - 1))` no fim descarta tudo que o `getopts` consumiu e deixa os argumentos
posicionais no `$@`.

**E o `--verbose` foi lido como `-` seguido de `-verbose`.** O `getopts` trata apenas opções
curtas; ele não faz ideia do que é uma opção longa, e a mensagem de erro que produz para uma é
confusa. Essa é a troca, e é por isso que a maioria dos scripts reais usa o laço com `case` acima:
opções longas valem mais que agrupamento.

Se você precisar das duas coisas, direito, você chegou ao ponto em que o script quer ser um
programa em outra linguagem — que é o argumento que o vídeo de encerramento faz sobre o bash em
geral.
