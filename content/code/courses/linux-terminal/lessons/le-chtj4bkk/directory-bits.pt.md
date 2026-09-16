---
title: As mesmas três letras, num diretório
version: 1
---

Um diretório é uma lista de nomes. Essa frase é a seção inteira: quando você lê os três bits como
permissões **sobre uma lista**, todo comportamento estranho desta seção fica óbvio.

| | num arquivo | num diretório |
|---|---|---|
| `r` | ler o conteúdo | **ler a lista de nomes** |
| `w` | alterar o conteúdo | **acrescentar, remover e renomear entradas** |
| `x` | executar como programa | **atravessar, e olhar o que há dentro** |

O `x` é o que ganha significado novo, e costuma ser traduzido como *busca* ou *travessia*. Sem ele,
um diretório é um muro — não porque as coisas lá dentro estejam protegidas, mas porque você não
consegue alcançá-las para perguntar.

## Três diretórios, três meias-permissões

Aqui estão três diretórios com conteúdo idêntico, diferindo só no modo, lidos por alguém que não é
dono de nenhum:

```
bruno@vm:/srv$ ls -ld dirbits/rx dirbits/r dirbits/x
dr--r--r-- 2 ana ana 4096 Sep 14 22:45 dirbits/r
dr-xr-xr-x 2 ana ana 4096 Sep 14 22:45 dirbits/rx
d--x--x--x 2 ana ana 4096 Sep 14 22:45 dirbits/x
```

**`r-x` — os dois bits. Este é um diretório normal.**

```
bruno@vm:/srv$ ls dirbits/rx
file.txt
bruno@vm:/srv$ cat dirbits/rx/file.txt
the contents
```

Lista, e lê o que há dentro. Nada surpreendente.

**`r--` — leitura sem execução. Você recebe os nomes e nada mais.**

```
bruno@vm:/srv$ ls dirbits/r
file.txt
bruno@vm:/srv$ cat dirbits/r/file.txt
cat: dirbits/r/file.txt: Permission denied
```

O `ls` funcionou. O `cat` não. Você vê que `file.txt` existe e não consegue atravessar o diretório
para alcançá-lo. **O modo do próprio arquivo é `-rw-r--r--`** — legível por todos — e isso não faz
a menor diferença.

**`--x` — execução sem leitura. Você recebe o conteúdo, se já souber o nome.**

```
bruno@vm:/srv$ ls dirbits/x
ls: cannot open directory 'dirbits/x': Permission denied
bruno@vm:/srv$ cat dirbits/x/file.txt
the contents
```

O oposto exato. Listar é recusado, e ler um arquivo pelo nome funciona perfeitamente.

**Leia esse par de novo, porque é o que se leva daqui.** `r` é *ver o que tem aqui*. `x` é
*atravessar*. São perguntas separadas, e um diretório pode responder sim a qualquer uma delas
sozinha.

## `--x` não é curiosidade, é como diretórios pessoais funcionam

Um diretório que dá `x` e não dá `r` é o jeito padrão de dizer *há coisas aqui para quem sabe delas,
e eu não publico a lista*. Você vai encontrar isso em:

- `/home/fulano` numa máquina compartilhada, com modo `711`, para qualquer um alcançar um caminho
  que você contou e ninguém enumerar o que você tem;
- a raiz de documentos de um servidor web, onde a listagem de diretório está desligada pelo mesmo
  motivo;
- `/var/log` em algumas distribuições.

"Segurança por obscuridade" é o deboche de praxe, e não é isso: os arquivos continuam com as
permissões deles. O que o `--x` remove é o *índice*, que é uma coisa real a não entregar.

## Todo diretório do caminho precisa de `x`

Essa é a regra que explica a maior parte das recusas confusas. Alcançar
`/srv/closed/readable.txt` é caminhar por `/`, depois `srv`, depois `closed`, e **cada um deles
precisa de `x` para você.** Um bit faltando em qualquer ponto da corrente e o arquivo é
inalcançável, diga ele o que disser sobre si mesmo.

```
bruno@vm:~$ namei -l /srv/closed/readable.txt
f: /srv/closed/readable.txt
drwxr-xr-x root root /
drwxr-xr-x root root srv
drwx------ ana  ana  closed
                      readable.txt - Permission denied
```

O `readable.txt` é `-rw-r--r--`. Qualquer um pode ler. Ninguém além da `ana` chega nele.

**Quando uma recusa não faz sentido, a resposta costuma ser um diretório e não o arquivo.** Rode
`namei -l` no caminho inteiro e leia a coluna de modos de cima a baixo.

## O `w` num diretório é o que surpreende as pessoas

**Apagar um arquivo é uma escrita no diretório, não no arquivo.**

Então você consegue apagar um arquivo que não consegue ler, não consegue escrever e não possui — se
puder escrever no diretório em que ele está. E não consegue apagar um arquivo que é seu, se o
diretório disser não.

Não é bug. Remover um arquivo é remover o nome dele de uma lista, e alterar uma lista é uma escrita
na lista. A aula 3 seção 11 já te disse isso pelo outro lado: `rm` é `unlink`.

Isso tem uma consequência grande, e é por ela que o `/tmp` existe no estado em que existe. Um
diretório em que qualquer um escreve é um diretório em que qualquer um apaga os arquivos dos
outros — o que tornaria o `/tmp` inútil. O conserto é um bit a mais, e é a seção 10.

## O que um modo quer dizer, em palavras

| modo | se lê como |
|---|---|
| `drwxr-xr-x` | 755 — o dono administra, todo mundo pode olhar e atravessar |
| `drwxr-x---` | 750 — o dono e o grupo; estranhos não veem nada |
| `drwx------` | 700 — seu. O `~/.ssh` é este |
| `drwx--x--x` | 711 — atravessar pelo nome, sem listagem |
| `drwxrwxrwt` | 1777 — o `/tmp`, e o `t` é a seção 10 |

**E um que é quase sempre um engano:** um diretório com `w` e sem `x`. Você pode acrescentar um
nome a uma lista em que não consegue entrar, o que significa criar arquivos que depois não consegue
abrir. É o que um `chmod -R` com modo de arquivo produz, e a seção 05 mostrou isso acontecendo.
