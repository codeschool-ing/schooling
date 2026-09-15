---
title: Padrões, e quem os expande
version: 1
---

**O fato mais importante desta seção:** o shell expande um padrão *antes* de o comando rodar. O
comando nunca vê o seu `*`. Ele vê a lista de nomes de arquivo que o shell entregou.

Prove com o `echo`, que só imprime o que recebeu:

```
ana@vm:~/gl$ ls
a.txt  b.txt  c.log  sub
ana@vm:~/gl$ echo *
a.txt b.txt c.log sub
ana@vm:~/gl$ echo *.txt
a.txt b.txt
```

O `echo` não faz ideia do que é um arquivo. Ele imprimiu quatro palavras porque **o shell
substituiu o `*` por quatro palavras** a caminho do comando. Isso se chama *globbing*, e acontece
com todo comando que você digita, sempre, saiba esse comando o que é um arquivo ou não.

## Os quatro padrões

| | casa |
|---|---|
| `*` | qualquer sequência de caracteres, inclusive nenhuma |
| `?` | exatamente um caractere |
| `[abc]` | um caractere do conjunto |
| `[a-z]`, `[0-9]` | um caractere da faixa |
| `[!a]`, `[^a]` | um caractere que **não** seja aquele |

```
ana@vm:~/gl$ echo [ab].txt
a.txt b.txt
ana@vm:~/gl$ echo [!a]*.txt
b.txt
ana@vm:~/gl$ echo ??.txt
??.txt
```

Essa última linha é o comportamento a decorar, e a próxima seção é sobre ele.

## Quando nada casa, o padrão fica como está

```
ana@vm:~/gl$ echo nope*
nope*
ana@vm:~/gl$ ls nope*
ls: cannot access 'nope*': No such file or directory
```

**Se um glob não casa com nada, o bash o repassa literalmente.** Então o `ls` recebeu de verdade um
nome de arquivo com um asterisco dentro, foi procurar um arquivo chamado `nope*`, e não achou.

É por isso que a mensagem de erro tem um asterisco — um detalhe que confunde quem supõe que o `ls`
fez a comparação. Não fez. Nunca faz.

Dá para mudar o comportamento:

```
ana@vm:~/gl$ shopt -s nullglob
ana@vm:~/gl$ echo nope*
ana@vm:~/gl$ shopt -u nullglob
```

Com `nullglob` ligado, um padrão sem correspondência vira *nada* em vez de virar ele mesmo. É o que
um script frequentemente quer, e vem desligado porque surpreenderia todo mundo.

## Globs não são expressões regulares

Eles se parecem e não são, e confundir os dois é um rito de passagem:

| | glob | expressão regular |
|---|---|---|
| qualquer sequência de caracteres | `*` | `.*` |
| um caractere | `?` | `.` |
| `*` sozinho | tudo | *zero ou mais da coisa anterior* |
| usado por | o shell, em nomes de arquivo | `grep`, `sed`, editores, em texto |

A aula 8 ensina expressões regulares direito. Até lá a regra é: **um padrão digitado no shell para
casar nomes de arquivo é um glob.** Um padrão dado ao `grep` não é.

## O que o `*` **não** casa

**Ele não atravessa uma `/`.** `*.txt` casa nomes só do diretório atual; `*/*.txt` casa um nível
abaixo; e achar um padrão em qualquer lugar abaixo de você é trabalho do `find` (seção 44) ou do
`**` com `shopt -s globstar`.

**Ele não casa um ponto inicial.** É por isso que `ls *` e `ls -a` discordam:

```
ana@vm:~/gl$ echo *
a.txt b.txt c.log sub
ana@vm:~/gl$ echo .*
.hidden.txt
```

Um arquivo oculto é *deliberadamente* excluído do `*`, e é isso que torna `rm *` no seu diretório
pessoal sobrevivível — o seu `.bashrc` não está na lista. O bash moderno também deixa `.` e `..` de
fora do `.*`, coisa que versões antigas não faziam, e que foi a origem de algumas tardes
memoravelmente ruins.

## Chaves são outra coisa que se parece com essa

```
ana@vm:~/gl$ echo {jan,feb}-report.csv
jan-report.csv feb-report.csv
ana@vm:~/gl$ echo {1..3}
1 2 3
ana@vm:~/gl$ echo a{b,c}d
abd acd
```

**A expansão de chaves não olha o sistema de arquivos.** `{jan,feb}` produziu duas palavras
existindo ou não esses arquivos — é geração de texto pura, e acontece *antes* do globbing.

Isso faz dela a ferramenta para **criar**:

```
mkdir -p project/{src,tests,docs}
cp config.yml{,.bak}
```

O segundo merece um olhar demorado: `config.yml{,.bak}` expande para `config.yml config.yml.bak`,
que é uma cópia-de-segurança em onze caracteres. É o truque de chaves que todo mundo acaba
aprendendo.

## Onde a regra do "o shell expande primeiro" se paga

### `ls *` num diretório que tem um subdiretório

```
ana@vm:~/gl$ ls
a.txt  b.txt  c.log  sub
ana@vm:~/gl$ ls *
a.txt  b.txt  c.log

sub:
d.txt
```

Duas listagens de um comando só, e nada está errado. O shell substituiu `*` por
`a.txt b.txt c.log sub`, então o `ls` recebeu quatro argumentos — três arquivos e um diretório.
Listar um diretório é listar o que há dentro dele, e foi o que ele fez. **`ls *` não é `ls`.**

### Aspas entregam o padrão ao programa

A seção 44 mandou pôr aspas no padrão do `find`, e agora o motivo está à vista:

```
find . -name '*.c'      # o find compara — correto
find . -name *.c        # o shell comparou, e o find recebeu um nome de arquivo
```

A segunda forma funciona por acidente quando existe exatamente um arquivo `.c` no diretório atual,
e quebra de forma confusa quando existem dois ou nenhum. Ponha aspas e a pergunta nunca aparece.

### Um arquivo cujo nome contém um asterisco

Raro, e instrutivo. `rm '*'` apaga um arquivo literalmente chamado `*`. `rm *` apaga tudo. Um
caractere de aspas, duas manhãs bem diferentes.

### E o hábito que vale construir hoje

**Antes de um comando destrutivo com um glob dentro, rode o glob por um `ls` ou um `echo`.**

```
ana@vm:~/gl$ echo *.log
c.log
```

Essa é exatamente a lista que `rm *.log` removeria, impressa sem estrago. Custa três segundos, e é
a única defesa confiável contra um padrão que casou mais do que você queria — porque, na hora em
que o `rm` roda, o asterisco já foi embora e não sobrou nada para te avisar.
