---
title: Os atalhos: `.`, `..`, `~` e `-`
version: 1
---

Quatro atalhos aparecem em quase todo caminho que você vai digitar na vida. Dois deles são entradas
de diretório de verdade, que o kernel conhece; dois são texto que o shell reescreve antes de o
comando ver qualquer coisa. **Essa diferença decide onde cada um funciona**, então vale acertar
agora.

| | quer dizer | quem trata |
|---|---|---|
| `.` | este diretório | o **kernel** — é uma entrada real |
| `..` | o diretório acima | o **kernel** — é uma entrada real |
| `~` | o seu diretório pessoal | o **shell** — é expandido e depois descartado |
| `-` | o diretório onde você estava antes | o **shell**, e só para o `cd` |

## `.` e `..` estão realmente lá

Não são convenção. Todo diretório do sistema de arquivos contém duas entradas chamadas `.` e `..`,
colocadas ali quando o diretório foi criado:

```
ana@vm:~/work$ ls -a
.  ..  .env  Makefile  README.md  build  data  logs  notes  src
```

O `-a` mostrou porque começam com ponto, como qualquer nome oculto. Mas, diferente do `.env`, não
foram criadas por ninguém.

**`.` é usado muito mais do que um iniciante espera**, porque muitos comandos querem um destino, e
"aqui" é um destino:

```
cp ~/Downloads/report.csv .        # copie para cá
tar -xzf backup.tar.gz -C .        # extraia aqui
find . -name '*.log'               # procure daqui para baixo
```

`..` é como se sobe, e ele se compõe:

```
ana@vm:~/work$ cd ..
ana@vm:~$ cd work/src
ana@vm:~/work/src$ cd ../notes
ana@vm:~/work/notes$ pwd
/home/ana/work/notes
```

`../notes` é "sobe um, depois entra em notes" — um movimento lateral, e de longe o uso mais comum
de `..` na prática.

### Na raiz, `..` para

```
ana@vm:/$ cd ..
ana@vm:/$ pwd
/
```

Sem erro, sem reclamação e sem movimento. `/` é o topo, então `/..` é `/` — e isso não é o shell
sendo gentil, é literalmente verdade em disco:

```
ana@vm:/$ ls -di / /.. /.
2 /  2 /.  2 /..
```

O `-i` imprime o número do inode, que é o identificador que o próprio sistema de arquivos usa para
uma coisa (seção 11). Os três são o inode 2. São um diretório com três nomes.

## `~` é expandido pelo shell

```
ana@vm:~$ echo ~
/home/ana
ana@vm:~$ echo ~root
/root
```

`echo` imprime o que recebeu, e recebeu `/home/ana`. **O til nunca chegou até ele.** O shell
substituiu enquanto lia a linha, que é a mesma maquinaria que expande `*` na seção 10.

| você digita | vira |
|---|---|
| `~` | seu diretório pessoal |
| `~/work` | `/home/ana/work` |
| `~root` | a casa do root, `/root` |
| `~ana` | a casa da ana, onde quer que o sistema diga que ela esteja |

Os dois últimos são genuinamente úteis quando você está logado como outra pessoa e quer nomear a
casa de alguém sem saber o arranjo da máquina.

**Onde `~` não funciona**: em qualquer lugar em que o shell não esteja lendo a linha. Num arquivo
de configuração, num campo de crontab, dentro de aspas simples, ou num argumento que algum programa
analisa sozinho, `~` é só um caractere:

```
ana@vm:~$ echo '~/work'
~/work
```

É por isso que `/etc` está cheio de `/home/fulano/...` escrito por extenso. Não é prolixidade: é que
nada expandiria o atalho.

## `-` quer dizer "de volta"

```
ana@vm:~$ cd /tmp
ana@vm:/tmp$ cd -
/home/ana
ana@vm:~$ pwd
/home/ana
```

`cd -` volta para o diretório anterior, e imprime onde aterrissou — aquela linha de saída é o `cd`
te avisando, não um erro. Aperte duas vezes e você está de volta ao ponto de partida, o que faz
dele um alternador entre dois lugares em que você está trabalhando.

**Só funciona no `cd`.** `ls -` não é "liste o diretório anterior"; é o `ls` recebendo algo que
parece uma opção e não existe.

## Dois lugares onde esses atalhos surpreendem

### `.` não está no `$PATH`, de propósito

```
ana@vm:~/work$ ./ledger
```

Você precisa escrever `./` para rodar um programa que está no diretório atual. A razão é segurança:
se `.` fosse procurado automaticamente, deixar um arquivo chamado `ls` num diretório compartilhado
bastaria para a próxima pessoa rodá-lo. A seção 03 já fez o ponto mecânico; este é o motivo de
ninguém nunca ter "consertado" isso.

### Um `/.` no final força "o conteúdo de"

`cp -r src dest` e `cp -r src/. dest` se comportam diferente quando `dest` já existe, e a diferença
é se você copia *o diretório* ou *o que está dentro dele*. Você vai encontrar isso na primeira vez
que uma cópia produzir `dest/src/` quando você queria `dest/`. O hábito confiável é conferir com um
`ls` logo depois, em vez de decorar a regra — e a seção 07 mostra a mesma armadilha no `mv`.
