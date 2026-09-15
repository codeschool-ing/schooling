---
title: Arquivos compactados: `tar`, `gzip`, `zip`
version: 1
---

`tar -xzvf` é o encantamento mais copiado da internet e um dos menos compreendidos. São quatro
letras, cada uma com uma função, e quando você consegue lê-las nunca mais precisa procurar.

**A primeira coisa a saber é que empacotar e comprimir são duas operações separadas.**

| | faz | produz |
|---|---|---|
| `tar` | põe muitos arquivos em um, preservando nomes, permissões e datas | `.tar` — **não menor** |
| `gzip`, `bzip2`, `xz` | deixam **um arquivo** menor | `.gz`, `.bz2`, `.xz` |
| `zip` | os dois de uma vez | `.zip` |

É por isso que `.tar.gz` tem duas extensões: é um arquivo tar que depois foi passado pelo gzip. E é
por isso também que o `gzip` sozinho não aceita um diretório — ele comprime um arquivo, e o `tar` é
o que transforma um diretório em um arquivo.

## Lendo as letras

```
tar -czf project.tar.gz src notes
tar -xzf project.tar.gz
tar -tzf project.tar.gz
```

| letra | quer dizer | nota |
|---|---|---|
| `c` | **criar** | escolha exatamente uma entre c, x, t |
| `x` | e**x**trair | |
| `t` | lis**t**ar | |
| `z` | gzip | `j` para bzip2, `J` para xz |
| `f` | **file**, e o nome dele vem em seguida | **o `f` tem de ser o último** — ele come a próxima palavra |
| `v` | verboso: imprime cada nome | opcional, e barulhento num arquivo grande |

**`f` por último** é a única regra que importa, porque `tar -cfz` tenta em silêncio criar um
arquivo chamado `z`. Todo o resto é livre.

O `tar` moderno também detecta a compressão sozinho, então `tar -xf project.tar.gz` funciona sem o
`z`. Digite mesmo assim — é o que todo exemplo que você copiar vai ter, e não custa nada.

## Criar e listar

```
ana@vm:~/ar$ tar -cf project.tar src notes
ana@vm:~/ar$ tar -tvf project.tar
drwxr-xr-x ana/ana           0 2026-09-14 22:29 src/
-rw-r--r-- ana/ana          29 2026-09-14 22:29 src/util.h
-rw-r--r-- ana/ana          65 2026-09-14 22:29 src/util.c
-rw-r--r-- ana/ana         194 2026-09-14 22:29 src/main.c
drwxr-xr-x ana/ana           0 2026-09-14 22:29 notes/
-rw-r--r-- ana/ana          20 2026-09-14 22:29 notes/draft.txt
-rw-r--r-- ana/ana          34 2026-09-14 22:29 notes/2025-01-plan.md
-rw-r--r-- ana/ana          26 2026-09-14 22:29 notes/2025-02-plan.md
```

`-t` lista, `-v` torna a listagem longa — e é a listagem da seção 41 de novo, com dono e grupo
escritos como `ana/ana`. **É isso que o `tar` preserva e o `zip` não**: permissões, propriedade,
horários, links simbólicos, e os caminhos exatamente como foram dados.

**Sempre dê `-t` num arquivo antes de dar `-x`.** Olhe aquela listagem: os caminhos começam em
`src/` e `notes/`, o que quer dizer que extrair ali espalha dois diretórios dentro do diretório
atual. Um arquivo cujo conteúdo não está dentro de um único diretório de primeiro nível se chama
*tarbomb*, e é uma bagunça de limpar — trinta arquivos soltos misturados ao que já estava ali.

As defesas são as duas gratuitas:

```
ana@vm:~/ar$ mkdir out
ana@vm:~/ar$ tar -xzf project.tar.gz -C out
ana@vm:~/ar$ ls out
notes  src
```

`-C` diz *entre neste diretório antes*. Extraia num diretório novo e vazio e um tarbomb é
inofensivo.

`--strip-components=1` remove elementos iniciais do caminho, que é como se extrai
`alguma-coisa-1.4.2/src/...` para `src/...` sem o invólucro com número de versão:

```
ana@vm:~/ar$ tar -xzf project.tar.gz -C out --strip-components=1
ana@vm:~/ar$ ls out
2025-01-plan.md  2025-02-plan.md  draft.txt  main.c  notes  src  util.c  util.h
```

Esse merece um olhar demorado, porque mostra o custo também: com o primeiro componente removido, o
conteúdo de `src/` e o de `notes/` caem lado a lado em `out`, e os dois diretórios da extração
anterior continuam ali. O `--strip-components` é uma ferramenta afiada, e o `-t` antes te diz se
você precisa dela.

## Qual compressão

```
ana@vm:~/ar$ ls -l logs/app.log
-rw-r--r-- 1 ana ana 1405960 Sep 14 22:29 logs/app.log
ana@vm:~/ar$ tar -cf logs.tar logs
ana@vm:~/ar$ tar -czf logs.tar.gz logs
ana@vm:~/ar$ tar -cjf logs.tar.bz2 logs
ana@vm:~/ar$ tar -cJf logs.tar.xz logs
ana@vm:~/ar$ ls -lh logs.tar logs.tar.gz logs.tar.bz2 logs.tar.xz
-rw-r--r-- 1 ana ana 1.4M Sep 14 22:29 logs.tar
-rw-r--r-- 1 ana ana  44K Sep 14 22:29 logs.tar.bz2
-rw-r--r-- 1 ana ana 425K Sep 14 22:29 logs.tar.gz
-rw-r--r-- 1 ana ana  12K Sep 14 22:29 logs.tar.xz
```

Repare primeiro que **o `logs.tar` tem o mesmo tamanho do que entrou.** O `tar` não comprimiu nada;
ele só empacotou.

Depois os três que comprimiram. Essas taxas são boas demais, porque aquele arquivo é o mesmo bloco
de texto repetido quarenta vezes, e repetição é exatamente o que um compressor come — mas a
*ordem* é a lição de verdade e ela vale em toda parte:

| | uso típico | velocidade |
|---|---|---|
| `gzip` (`z`) | **o padrão.** Tudo consegue ler | rápido |
| `bzip2` (`j`) | mais antigo, mais lento, largamente superado | lento |
| `xz` (`J`) | o menor. Lento de fazer, tranquilo de ler | muito lento para comprimir |
| `zstd` (`--zstd`) | moderno: quase a velocidade do gzip, quase o tamanho do xz | rápido |

Use `gzip` a menos que tenha um motivo. Use `xz` para algo escrito uma vez e baixado muitas, que é
por que pacotes de distribuição usam. O `zstd` é o que está tomando conta discretamente, e vale
conhecer o nome quando você encontrar um `.tar.zst`.

## O `gzip` sozinho comprime um arquivo, no lugar

```
ana@vm:~/ar$ gzip -k notes/draft.txt
ana@vm:~/ar$ ls -l notes/draft.txt notes/draft.txt.gz
-rw-r--r-- 1 ana ana 20 Sep 14 22:29 notes/draft.txt
-rw-r--r-- 1 ana ana 50 Sep 14 22:29 notes/draft.txt.gz
```

Duas coisas ali. **`-k` mantém o original** — sem ele o `gzip` substitui o arquivo, o que surpreende
as pessoas. E o arquivo comprimido é *maior* que o original: vinte bytes de texto mais um cabeçalho
de gzip. Compressão tem um custo fixo, e em arquivos minúsculos ela perde.

`gzip -d` descomprime, e o `gunzip` também. Ele não sobrescreve:

```
ana@vm:~/ar$ gzip -d notes/draft.txt.gz
gzip: notes/draft.txt already exists;   not overwritten
```

Mais educado do que o `cp` foi na seção 42, e pelo menos uma vez você está sendo consultado.

Existem também o `zcat`, o `zless` e o `zgrep`, que leem um `.gz` sem desempacotar antes. Em
`/var/log`, onde os logs de ontem já estão comprimidos, o `zgrep` é a diferença entre buscar no
último mês e buscar só em hoje.

## `zip`, e quando usar

```
ana@vm:~/ar$ zip -qr project.zip src notes
ana@vm:~/ar$ unzip -l project.zip
Archive:  project.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  2026-09-14 22:29   src/
       29  2026-09-14 22:29   src/util.h
       65  2026-09-14 22:29   src/util.c
      194  2026-09-14 22:29   src/main.c
        0  2026-09-14 22:29   notes/
       20  2026-09-14 22:29   notes/draft.txt
       50  2026-09-14 22:29   notes/draft.txt.gz
       34  2026-09-14 22:29   notes/2025-01-plan.md
       26  2026-09-14 22:29   notes/2025-02-plan.md
---------                     -------
      418                     9 files
```

`-r` de recursivo — **o `zip` precisa e o `tar` não**, que é a primeira coisa em que se tropeça.
`-q` de quieto. `unzip -l` lista, `unzip -d algumlugar` extrai para um diretório, e é `-d` em vez de
`-C` porque são dois programas sem parentesco que resolveram o mesmo problema.

**Use `zip` quando o arquivo vai para alguém no Windows ou no macOS**, onde ele abre com um duplo
clique. Use `tar` para tudo que fica no Linux, porque ele preserva as permissões e a propriedade de
que um deploy ou um backup depende.

E um aviso honesto: o `unzip` não vem instalado em toda parte, e o `zip` também não. O `tar` vem
sempre.

## O `file` encerra qualquer discussão sobre o que você tem

```
ana@vm:~/ar$ file project.tar project.tar.gz project.tar.xz project.zip
project.tar:    POSIX tar archive (GNU)
project.tar.gz: gzip compressed data, from Unix, original size modulo 2^32 10240
project.tar.xz: XZ compressed data, checksum CRC64
project.zip:    Zip archive data, at least v1.0 to extract, compression method=store
```

A seção 43 disse que a extensão é uma pista. Alguém vai te entregar um `.zip` que é um `.tar.gz`,
ou um `.tar.gz` que nunca foi comprimido, e o `file` é como se para de adivinhar.
