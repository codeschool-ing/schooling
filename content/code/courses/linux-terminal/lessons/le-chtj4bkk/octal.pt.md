---
title: 755 e 644, e de onde vêm os números
version: 1
---

Nove bits. Três por público. **Um número de três bits vai de 0 a 7**, e é por isso que permissões
são escritas em base 8 e não em algo mais familiar.

| | valor |
|---|---|
| `r` | **4** |
| `w` | **2** |
| `x` | **1** |

Some os que estão ligados, em cada grupo de três, e você tem o dígito:

| caracteres | conta | dígito |
|---|---|---|
| `rwx` | 4 + 2 + 1 | **7** |
| `rw-` | 4 + 2 | **6** |
| `r-x` | 4 + 1 | **5** |
| `r--` | 4 | **4** |
| `-wx` | 2 + 1 | 3 |
| `-w-` | 2 | 2 |
| `--x` | 1 | 1 |
| `---` | | **0** |

Três dígitos — dono, grupo, outros — e o modo inteiro é um número.

## Os quatro que você deve saber sem contar

```
-rw-r--r--   644
-rw-------   600
-rwxr-xr-x   755
drwxr-xr-x   755
```

`644` e `755` cobrem a maior parte de um sistema de arquivos Linux. Fale **"seis quatro quatro"** e
não "seiscentos e quarenta e quatro" — são três dígitos separados, e pronunciar como um número só é
como as pessoas acabam achando que 700 é maior que 644 em algum sentido útil.

O `stat` faz a conversão para você, nos dois sentidos:

```
ana@vm:~/perm$ stat -c '%a %A %n' public.txt private.txt script.sh locked
644 -rw-r--r-- public.txt
600 -rw------- private.txt
755 -rwxr-xr-x script.sh
755 drwxr-xr-x locked
```

`%a` é o octal, `%A` são os caracteres. **Guarde esse comando.** É o jeito mais rápido de conferir
a própria conta enquanto você aprende, e o jeito mais rápido de ler vinte arquivos de uma vez
depois que você já sabe.

## Lendo um número de volta para caracteres

Separe em três dígitos, e transforme cada um em três caracteres:

**640** → `6` é `rw-`, `4` é `r--`, `0` é `---` → `-rw-r-----`. O dono edita, o grupo lê, todo o
resto fica de fora. É o `teamonly.txt` da seção 55.

**775** → `rwx`, `rwx`, `r-x` → um diretório em que um grupo inteiro acrescenta coisas e todo mundo
pode olhar.

**700** → `rwx`, `---`, `---` → seu e de mais ninguém, que é o modo do `~/.ssh`.

## Por que 4, 2, 1 e não 1, 2, 3

Porque são **bits**, não posições num ranking. Cada um é um sim-ou-não separado, e os valores são
potências de dois para que cada combinação some um número diferente. Com 1, 2 e 3, um 3 seria
ambíguo — escrever mais executar, ou ler sozinho?

Isso também explica uma pergunta que as pessoas fazem uma vez: *por que o `w` vale mais que o `x`?*
Ele não vale mais. A ordem é `r`, `w`, `x` e os valores são `4`, `2`, `1`, e nada no 2 torna
escrever mais importante que executar. São rótulos de posição.

## O quarto dígito

Modos às vezes têm quatro:

```
root@vm:~# stat -c '%a %A %n' /usr/bin/passwd /tmp /srv/team
4755 -rwsr-xr-x /usr/bin/passwd
1777 drwxrwxrwt /tmp
2775 drwxrwsr-x /srv/team
```

O dígito da frente são os bits especiais — **4** setuid, **2** setgid, **1** sticky — e eles somam
do mesmo jeito. Seção 63. Quando você vir um modo com quatro dígitos, o primeiro não faz parte dos
nove.

E repare no que isso implica: **`chmod 755` num arquivo que era `4755` desliga o bit setuid**,
porque um número de três dígitos quer dizer que o quarto dígito é zero. Isso já quebrou programas
que funcionavam, e é por isso que a seção 58 recomenda a forma simbólica para uma mudança que você
quer cirúrgica.

## 777 quase nunca é a resposta

`chmod 777` quer dizer *qualquer um nesta máquina pode ler, alterar e executar isto*. Aparece o
tempo todo em resposta de fórum porque faz o erro imediato desaparecer.

**Ele funciona removendo a checagem em vez de consertar o problema.** O que estava de fato errado —
o dono errado, um `x` faltando num diretório dois níveis acima, um grupo em que ninguém estava —
continua errado; só deixou de importar, e todo o resto também.

Duas coisas a fazer em vez disso, nesta ordem: descobrir **qual bit** faltava, com o `namei -l` da
seção 56; e, se a resposta for mesmo "estas duas contas precisam compartilhar isto", é para isso
que servem os grupos (seção 61) e as ACLs (seção 66).

Existe um lugar em que `777` está certo, e é o `/tmp` — que é `1777`, e aquele `1` na frente é a
razão inteira de ele ser seguro. Seção 63.
