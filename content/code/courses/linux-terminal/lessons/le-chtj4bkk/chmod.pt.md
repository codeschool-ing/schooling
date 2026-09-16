---
title: `chmod`, e o que a recursão faz com diretórios
version: 1
---

O `chmod` aceita o modo de dois jeitos. **Numérico** define os nove bits de uma vez. **Simbólico**
altera os que você nomear e deixa o resto em paz. Não são intercambiáveis, e saber qual dos dois
você quer é a maior parte de usá-lo bem.

```
chmod 644 report.txt      # numérico: o modo inteiro vira este
chmod u+x script.sh       # simbólico: acrescenta um bit, não encosta em mais nada
```

## Simbólico, que tem três partes

```
chmod  [ugoa]  [+-=]  [rwx]  arquivo
```

**Quem**: `u` dono, `g` grupo, `o` outros, `a` os três. Omita e vale `a`, filtrado pelo seu umask —
que é a seção 09, e um bom motivo para ser explícito.

**Como**: `+` acrescenta, `-` remove, `=` define exatamente isto e limpa o resto daquela linha.

**O quê**: `r`, `w`, `x` — e mais dois, abaixo.

```
ana@vm:~/cm$ ls -l a.txt
-rw-r--r-- 1 ana ana 5 Sep 14 22:52 a.txt
ana@vm:~/cm$ chmod u+x a.txt
ana@vm:~/cm$ ls -l a.txt
-rwxr--r-- 1 ana ana 5 Sep 14 22:52 a.txt
ana@vm:~/cm$ chmod g+w,o-r a.txt
ana@vm:~/cm$ ls -l a.txt
-rwxrw---- 1 ana ana 5 Sep 14 22:52 a.txt
ana@vm:~/cm$ chmod a=r a.txt
ana@vm:~/cm$ ls -l a.txt
-r--r--r-- 1 ana ana 5 Sep 14 22:52 a.txt
```

Três comandos, três verbos diferentes. O `+x` acrescentou um bit. O `g+w,o-r` fez duas alterações
de uma vez — **separadas por vírgula, sem espaços**. E o `a=r` definiu cada linha como exatamente
`r--`, o que apagou o `w` e o `x` que estavam lá.

O `=` é o afiado. É a única forma simbólica capaz de **tirar** permissões sem você nomeá-las.

Mais duas formas que vale ter:

```
ana@vm:~/cm$ chmod u=rw,g=r,o= a.txt
ana@vm:~/cm$ ls -l a.txt
-rw-r----- 1 ana ana 5 Sep 14 22:52 a.txt
ana@vm:~/cm$ chmod g=u a.txt
ana@vm:~/cm$ ls -l a.txt
-rw-rw---- 1 ana ana 5 Sep 14 22:52 a.txt
```

`o=` sem nada depois quer dizer *nenhuma permissão para outros*, e é o jeito mais curto de fechar a
porta para estranhos. `g=u` quer dizer *dê ao grupo o que o dono tem*, copiando uma linha na outra.

E copiar de outro arquivo:

```
ana@vm:~/cm$ chmod --reference=run.sh a.txt
ana@vm:~/cm$ ls -l a.txt run.sh
-rwxr-xr-x 1 ana ana  5 Sep 14 22:52 a.txt
-rwxr-xr-x 1 ana ana 20 Sep 14 22:52 run.sh
```

O `--reference` é como se faz um arquivo igualar outro sem ler o modo e redigitar — útil quando
você tem vinte arquivos e um deles está certo.

## Numérico, que substitui tudo

`chmod 640 report.txt` define o modo como exatamente `-rw-r-----`, seja lá o que fosse antes. Não
existe forma parcial: você está declarando os nove bits.

**Use numérico quando você sabe a resposta.** `chmod 644`, `chmod 755`, `chmod 600` — são formas, e
declarar uma forma numa palavra é mais claro do que chegar nela em três passos.

**Use simbólico quando você quer mudar uma coisa.** `chmod +x` num script que você baixou diz
exatamente o que você quis dizer e não tem como abrir o arquivo para o mundo por acidente.

Há uma armadilha que vale repetir da seção 04: **um número de três dígitos limpa os bits
especiais.** `chmod 755` num arquivo que era `4755` desliga o setuid em silêncio. A forma simbólica
não faz isso.

## `-R`, e o engano que ele facilita

O `-R` aplica a mudança a um diretório e a tudo abaixo dele. É a ferramenta certa para "esta árvore
inteira deve pertencer ao grupo", e é uma arma carregada por um motivo: **arquivos e diretórios não
querem os mesmos bits.**

Veja:

```
ana@vm:~/cm$ ls -l
total 12
-rw-r--r-- 1 ana ana    5 Sep 14 22:52 a.txt
-rwxr-xr-x 1 ana ana   20 Sep 14 22:52 run.sh
drwxr-xr-x 2 ana ana 4096 Sep 14 22:52 sub
ana@vm:~/cm$ chmod -R 644 .
chmod: cannot read directory '.': Permission denied
ana@vm:~/cm$ ls -l
ls: cannot open directory '.': Permission denied
```

Leia o que aconteceu. `644` é um modo sensato **para um arquivo**. Aplicado ao diretório, ele tirou
o `x`, e sem `x` um diretório não pode ser percorrido — então o `chmod` não conseguiu seguir para
dentro dele, e o shell que estava lá dentro deixou de conseguir listar. Um comando, e a árvore se
trancou.

Dá para recuperar de fora, e este é o conserto que vale decorar:

```
ana@vm:~$ ls -ld cm
drw-r--r-- 3 ana ana 4096 Sep 14 22:52 cm
ana@vm:~$ chmod -R u+rwX,go+rX cm
ana@vm:~$ ls -ld cm cm/sub
drwxr-xr-x 3 ana ana 4096 Sep 14 22:52 cm
drwxr-xr-x 2 ana ana 4096 Sep 14 22:52 cm/sub
ana@vm:~$ ls -l cm
total 12
-rw-r--r-- 1 ana ana    5 Sep 14 22:52 a.txt
-rwxr-xr-x 1 ana ana   20 Sep 14 22:52 run.sh
drwxr-xr-x 2 ana ana 4096 Sep 14 22:52 sub
```

**O `X` — maiúsculo — é o truque inteiro.** Ele quer dizer *executar, mas só para diretórios e para
arquivos que já têm execução em algum lugar*. Então os diretórios recuperaram o `x`, o `run.sh`
manteve o dele, e o `a.txt` continuou `644` como devia.

```
chmod -R u+rwX,go+rX arvore/
```

Essa linha é o padrão recursivo seguro, e vale guardar num lugar em que você a encontre. A versão
insegura que as pessoas usam primeiro é `chmod -R 755`, que torna executável cada arquivo de texto
da árvore.

## Quem pode mudar um modo

**O dono, e o root.** Não o grupo, por mais generosos que os bits pareçam. Poder escrever num
arquivo não te deixa mudar quem mais pode escrever nele — isso tornaria o modelo inteiro sem
sentido.

```
bruno@vm:/srv/perm$ ls -l teamonly.txt
-rw-r----- 1 ana team 13 Sep 14 22:45 teamonly.txt
bruno@vm:/srv/perm$ chmod g+w teamonly.txt
chmod: changing permissions of 'teamonly.txt': Operation not permitted
```

O bruno está no `team`. Ele consegue ler o arquivo. Ele não decide quem mais pode.

Repare na palavra: **`Operation not permitted`, e não `Permission denied`.** A segunda quer dizer
que os bits disseram não; a primeira quer dizer que você não tem o direito de sequer tentar. A
seção 07 é sobre como a propriedade muda de mãos, e a seção 11 é sobre a única conta que ignora
tudo isso.
