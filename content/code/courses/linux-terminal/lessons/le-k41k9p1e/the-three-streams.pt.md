---
title: Três fluxos, e por que dois deles parecem o mesmo
version: 1
---

A aula 6 seção 13 te deu os números. Esta é para que eles servem.

Todo programa começa com três conexões já abertas, e ele não precisa pedir nenhuma delas:

| | | |
|---|---|---|
| `0` | **stdin** | de onde a entrada vem. O seu teclado, um arquivo, outro programa |
| `1` | **stdout** | para onde os **resultados** dele vão |
| `2` | **stderr** | para onde as **reclamações** dele vão |

**Tanto o `1` quanto o `2` caem na sua tela por padrão**, e é por isso que eles parecem uma coisa só.
Não são, e a seção seguinte inteira depende de você saber disso.

Aqui está a diferença, visível:

```
ana@vm:~/work$ ls logs nosuchdir
ls: cannot access 'nosuchdir': No such file or directory
logs:
access.log  app.log  app.log.1  empty.log  error.log
ana@vm:~/work$ ls logs nosuchdir > out.txt
ls: cannot access 'nosuchdir': No such file or directory
ana@vm:~/work$ cat out.txt
logs:
access.log
app.log
app.log.1
empty.log
error.log
```

Um comando, dois destinos. O `> out.txt` capturou a listagem e **o erro ficou na tela**, porque o `>`
redireciona a saída padrão e nada mais.

Isso não é uma esquisitice; é o projeto. Os resultados vão para onde um programa consegue lê-los; as
reclamações vão para onde uma pessoa consegue vê-las. Um pipeline que engolisse as próprias
mensagens de erro seria muito mais difícil de depurar do que um que não engole.

## E repare no que mudou de forma

Olhe aquelas duas saídas de novo. Na tela, o `ls` imprimiu os cinco nomes **ao longo da linha, em
colunas**. No arquivo, ele imprimiu **um por linha**.

**O `ls` pergunta se a saída dele é um terminal, e formata conforme a resposta** — a pergunta do
`isatty()` da aula 6. Colunas são para pessoas; um por linha é para programas.

Isso importa mais do que parece. Quer dizer que:

- o `ls | wc -l` conta arquivos corretamente, porque o `ls` mudou para um por linha por causa do
  pipe;
- e quer dizer que o que você viu na tela nem sempre é o que o comando seguinte recebeu.

A maioria das ferramentas não faz isso. O `ls`, o `grep` (cor) e o `ps` (largura) são os três que
você vai encontrar que fazem. **Quando um pipeline se comporta diferente do que você viu, esta é a
primeira coisa a suspeitar.**

## Para onde os fluxos vão de fato

```
ana@vm:~/work$ ls -l /proc/$FDPID/fd
total 0
lr-x------ 1 ana ana 64 Sep 15 07:23 0 -> /dev/null
l-wx------ 1 ana ana 64 Sep 15 07:23 1 -> /tmp/out.txt
l-wx------ 1 ana ana 64 Sep 15 07:23 2 -> /tmp/err.txt
```

Essa é a transcrição da aula 6, e vale uma segunda olhada agora que os números querem dizer algo.
**Redirecionar não é um recurso do programa.** O programa escreve no descritor 1; o shell decidiu o
que o descritor 1 era, antes de o programa começar, na lacuna entre o `fork` e o `exec` da aula 6
seção 03.

Que é por que o `>` funciona em todo comando que já foi escrito, inclusive naqueles cujos autores
nunca pensaram em arquivos.

## Lendo da entrada padrão

A maioria das ferramentas desta aula aceita um nome de arquivo **ou** lê a entrada padrão se você não
der um:

```
wc -l logs/app.log        # from a file
wc -l < logs/app.log      # from stdin, redirected by the shell
cat logs/app.log | wc -l  # from stdin, through a pipe
```

Os três contam a mesma coisa. A diferença é só quem abre o arquivo:

```
ana@vm:~/work$ wc -l logs/app.log
30 logs/app.log
ana@vm:~/work$ wc -l < logs/app.log
30
```

**O `wc` imprimiu o nome do arquivo no primeiro e não no segundo**, porque no segundo ele nunca
soube de um. Isso é uma coisinha que pega as pessoas em scripts: o formato da saída mudou por causa
de como a entrada chegou.

**Um `-` como nome de arquivo quer dizer entrada padrão** em muitas ferramentas, que é como se
mistura as duas:

```
ana@vm:~/work$ printf "header\n" > /tmp/h.txt; printf "body\n" | cat /tmp/h.txt -
header
body
```

Um arquivo, e depois o que veio pelo pipe, nessa ordem — porque é essa a ordem em que os argumentos
estão.
