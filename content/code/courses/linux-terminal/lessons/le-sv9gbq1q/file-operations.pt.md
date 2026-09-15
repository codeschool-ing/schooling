---
title: Criar, copiar, mover e remover
version: 1
---

Seis comandos fazem tudo isso, e nenhum deles vai te perguntar se você tem certeza.

| | faz | a opção que importa |
|---|---|---|
| `mkdir` | cria um diretório | `-p` — cria os pais também |
| `touch` | cria um arquivo vazio, ou atualiza a hora dele | — |
| `cp` | copia | `-r` para diretórios, `-i` para ser perguntado |
| `mv` | move, e também renomeia | `-i` para ser perguntado |
| `rm` | remove | `-r` para diretórios, `-f` para parar de reclamar |
| `rmdir` | remove um diretório **vazio** | — |

## `mkdir` e `touch`

```
ana@vm:~/sandbox$ mkdir archive
ana@vm:~/sandbox$ touch report.txt
ana@vm:~/sandbox$ ls -l
total 0
-rw-r--r-- 1 ana ana 0 Sep 14 22:01 report.txt
```

`touch` num nome que não existe cria um arquivo vazio. Num nome que **existe**, não muda nada além
da marca de tempo:

```
ana@vm:~/sandbox$ ls -l old.txt
-rw-r--r-- 1 ana ana 0 Jan  1  2025 old.txt
ana@vm:~/sandbox$ touch old.txt
ana@vm:~/sandbox$ ls -l old.txt
-rw-r--r-- 1 ana ana 0 Sep 14 22:01 old.txt
```

É isso que o nome quer dizer — tocar num arquivo sem alterá-lo — e é assim que se faz algo parecer
recém-modificado para um sistema de build ou uma rotina de backup.

`mkdir -p` cria todos os níveis de um caminho de uma vez, e não reclama se alguns já existirem:

```
ana@vm:~/sandbox$ mkdir -p deep/a/b/c
```

Três diretórios, um comando. Num script, `-p` é quase sempre o que você quer, porque "crie isto se
ainda não existir" é o que você quis dizer, e a forma pelada falha quando já existe.

## `cp`, e o `-r` que você vai esquecer uma vez

```
ana@vm:~/sandbox$ cp report.txt report-copy.txt
ana@vm:~/sandbox$ cp report.txt archive/
```

Duas formas, e a diferença é o **destino**: para um nome, copia com aquele nome; para um diretório,
copia para dentro dele mantendo o nome. É uma regra só, e ela vale para o `mv` também.

Um diretório precisa de `-r`:

```
ana@vm:~/sandbox$ cp archive backup
cp: -r not specified; omitting directory 'archive'
ana@vm:~/sandbox$ cp -r archive backup
ana@vm:~/sandbox$ ls backup
report-2.txt  report.txt
```

Leia essa primeira mensagem com atenção: não é um erro, é o `cp` avisando que **pulou** alguma
coisa. Num comando copiando vinte itens, ele vai pular o diretório e copiar o resto, e o único
sinal é uma linha que você pode passar batido.

**As outras opções do `cp` que vale conhecer agora:**

| | faz |
|---|---|
| `-a` | arquivo morto: recursivo, e preserva permissões, dono e horários |
| `-i` | pergunta antes de sobrescrever |
| `-n` | nunca sobrescreve, em silêncio |
| `-v` | imprime cada arquivo conforme avança |
| `-u` | só copia se a origem for mais nova |

`cp -a` é o que se usa quando a cópia precisa ser indistinguível do original. O `cp` puro dá à
cópia a data de hoje e o seu umask, o que está ótimo para um arquivo de trabalho e errado para um
backup.

## `mv` renomeia *e* move, porque é a mesma operação

```
ana@vm:~/sandbox$ mv report-copy.txt report-2.txt
ana@vm:~/sandbox$ mv report-2.txt archive/
```

Não existe um comando `rename` no sistema base. **Renomear é mover dentro de um diretório** — você
está mudando qual nome, em qual diretório, aponta para os dados, e mover é exatamente isso.

Isso também explica algo que você vai notar: mover um arquivo de 4 GB dentro do mesmo sistema de
arquivos é instantâneo, e movê-lo para outro disco leva minutos. Dentro de um sistema de arquivos é
uma renomeação. Entre sistemas de arquivos é uma cópia e uma remoção vestidas de renomeação.

`mv` não precisa de `-r`. Um diretório se move como uma coisa só.

## Nada pergunta. Eis o que isso custa.

```
ana@vm:~/sandbox$ cat keep.txt
the good one
ana@vm:~/sandbox$ cp other.txt keep.txt
ana@vm:~/sandbox$ cat keep.txt
the other one
```

Sem confirmação. Sem mensagem. Sem lixeira. **`keep.txt` se foi**, e não há de onde restaurar, a
menos que você tenha um backup. O `mv` faz exatamente o mesmo:

```
ana@vm:~/sandbox$ mv other.txt keep.txt
ana@vm:~/sandbox$ ls
archive  deep  keep.txt  old.txt
```

Entraram dois arquivos, saiu um, e nada foi dito a respeito.

**`-i` faz perguntar:**

```
ana@vm:~/sandbox$ cp -i other.txt keep.txt
cp: overwrite 'keep.txt'? n
ana@vm:~/sandbox$ cat keep.txt
the good one
```

O `n` é digitado, e nada acontece. Várias distribuições já vêm com `alias cp='cp -i'` para a conta
root exatamente por causa disso, e a aula 9 mostra como configurar isso para você.

Mas **não construa um hábito em cima do alias**, por uma razão que pega as pessoas: um alias não
vale dentro de um script, nem por `ssh -c`, nem sob `sudo`. O hábito que viaja é menor — *antes de
uma sobrescrita, dê `ls` no destino.*

## `rm`, `rmdir` e `rm -rf`

```
ana@vm:~/sandbox$ rm report.txt
ana@vm:~/sandbox$ rm backup
rm: cannot remove 'backup': Is a directory
ana@vm:~/sandbox$ rm -r backup
```

`rmdir` remove um diretório **só se ele estiver vazio**, o que é uma funcionalidade:

```
ana@vm:~/sandbox$ rmdir deep
rmdir: failed to remove 'deep': Directory not empty
ana@vm:~/sandbox$ rmdir deep/a/b/c
```

Essa recusa é uma rede de segurança. Quando você *sabe* que um diretório deveria estar vazio, o
`rmdir` confere a hipótese para você e o `rm -r` não.

`-f` quer dizer "não reclame, não pergunte":

```
ana@vm:~/sandbox$ rm -f nosuchfile.txt
ana@vm:~/sandbox$ echo $?
0
ana@vm:~/sandbox$ rm nosuchfile.txt
rm: cannot remove 'nosuchfile.txt': No such file or directory
ana@vm:~/sandbox$ echo $?
1
```

Esse é o uso legítimo do `-f` e a razão de ele existir: num script, "remova isto se estiver aí" não
deveria falhar quando não está.

### `rm -rf` merece a fama que tem

Quer dizer *remova, recursivamente, sem perguntar, sem reclamar*. É uma ferramenta normal de
trabalho — é assim que se apaga um `node_modules` — e é o comando que já destruiu mais trabalho do
que todos os outros desta lista somados.

Três hábitos, e não custam nada:

**Rode como `ls` antes.** `ls -d /caminho/da/coisa` antes de `rm -rf /caminho/da/coisa`. Você está
conferindo que o caminho digitado é o caminho pretendido.

**Nunca deixe uma variável acabar vazia.** `rm -rf "$DIR/"` com `DIR` sem valor é `rm -rf /`. Isso
não é folclore; é um bug que já saiu em instaladores de verdade mais de uma vez. A seção de aspas e
`set -u` da aula 9 é onde isso se conserta direito.

**Desconfie de uma barra final e um asterisco juntos.** `rm -rf /algum/caminho /*` está a um espaço
perdido de `rm -rf /algum/caminho/*`, e os dois fazem coisas bem diferentes.

O `rm` do GNU moderno recusa `rm -rf /` de cara, o que ajuda em exatamente um dos jeitos de isso
dar errado.

## E uma última sobre diretórios

```
mv src dest
```

Se `dest` não existe, `src` é renomeado para `dest`. Se `dest` **existe** e é um diretório, `src` é
movido *para dentro* dele, e você fica com `dest/src`. O mesmo comando, dois resultados, decididos
por algo que não está na linha.

Essa é a armadilha que a seção 39 prometeu. A conferência é a mesma de todo o resto desta seção: dê
`ls` no destino antes.
