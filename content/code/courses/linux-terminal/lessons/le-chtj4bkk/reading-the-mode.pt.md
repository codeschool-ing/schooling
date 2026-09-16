---
title: Lendo um modo, caractere por caractere
version: 1
---

Dez caracteres, e eles são a primeira coisa de cada linha de uma listagem longa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A string de modo -rwxr-xr-- dividida em quatro partes: um caractere inicial de tipo e depois três grupos de três caracteres rotulados o dono, o grupo e todo o resto, com os dígitos octais 7, 5 e 4 embaixo deles.\"><rect x=\"182\" y=\"16\" width=\"356\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"207.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--amber)\">-</text><text x=\"241.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--phosphor)\">r</text><text x=\"275.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--phosphor)\">w</text><text x=\"309.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--phosphor)\">x</text><text x=\"343.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--paper)\">r</text><text x=\"377.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--paper)\">-</text><text x=\"411.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--paper)\">x</text><text x=\"445.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--paper-dim)\">r</text><text x=\"479.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--paper-dim)\">-</text><text x=\"513.0\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"26\" fill=\"var(--paper-dim)\">-</text><path d=\"M207.0 82 L207.0 100\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"207.0\" y=\"118\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">tipo</text><path d=\"M227.0 88 L227.0 82 L323.0 82 L323.0 88\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"275.0\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o dono</text><text x=\"275.0\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"17\" fill=\"var(--phosphor)\">7</text><path d=\"M329.0 88 L329.0 82 L425.0 82 L425.0 88\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"377.0\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o grupo</text><text x=\"377.0\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"17\" fill=\"var(--phosphor)\">5</text><path d=\"M431.0 88 L431.0 82 L527.0 82 L527.0 88\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"479.0\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">todo o resto</text><text x=\"479.0\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"17\" fill=\"var(--phosphor)\">4</text><text x=\"360\" y=\"172\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">ler 4, escrever 2, executar 1 — somados dentro de cada grupo de três</text></svg>", "caption": "Dez caracteres: um para o tipo da coisa, depois três públicos de três. Só uma das três linhas vale para você, e é a primeira que casa."}
```

## Caractere 1: o tipo, que não é permissão

A aula 3 seção 06 tratou disso e vale repetir, porque as pessoas contam nove caracteres e encontram
dez:

| | |
|---|---|
| `-` | um arquivo comum |
| `d` | um diretório |
| `l` | um link simbólico |
| `c`, `b` | um dispositivo |
| `s`, `p` | um socket, um pipe nomeado |

Um link simbólico é sempre `lrwxrwxrwx`, e isso não é um problema de segurança: **as permissões
que valem são as do alvo.** Os bits do próprio link nunca são consultados.

## Caracteres 2 a 10: três linhas de três

Cada linha é lida na mesma ordem fixa, `r`, depois `w`, depois `x`, e um `-` quer dizer que o bit
está desligado. **Posição é significado.** `r-x` e `-wx` diferem por quais vagas estão preenchidas,
não por quais letras aparecem.

Quatro modos que você vai ver o tempo todo, e para que serve cada um:

| modo | octal | o que é |
|---|---|---|
| `-rw-r--r--` | 644 | um arquivo comum: o dono edita, todo mundo lê |
| `-rw-------` | 600 | um arquivo privado: uma chave, uma senha, um token |
| `-rwxr-xr-x` | 755 | um programa ou script: todo mundo roda, o dono altera |
| `drwxr-xr-x` | 755 | um diretório comum |

Aprenda esses quatro como formas. A maior parte do que você encontra é um deles, e um arquivo que
não é nenhum deles merece um segundo olhar.

## Lendo em voz alta, a partir da coisa real

```
bruno@vm:/srv/perm$ ls -l
total 16
-rw------- 1 ana ana   9 Sep 14 22:45 private.txt
-rw-r--r-- 1 ana ana  22 Sep 14 22:45 public.txt
-rwxr-xr-x 1 ana ana  34 Sep 14 22:45 script.sh
-rw-r----- 1 ana team 13 Sep 14 22:45 teamonly.txt
```

**`private.txt` — `-rw-------`.** Um arquivo. A dona lê e escreve. O grupo não recebe nada. Todo o
resto não recebe nada. A `ana` e o root, e a lista é essa.

**`public.txt` — `-rw-r--r--`.** Um arquivo. A dona lê e escreve; todo mundo que alcançar lê. Só a
`ana` altera.

**`script.sh` — `-rwxr-xr-x`.** Um arquivo com `x` nas três linhas: qualquer um pode executar. Só a
`ana` pode editar. Essa combinação é a cara de quase todo programa em `/usr/bin`.

**`teamonly.txt` — `-rw-r-----`.** Um arquivo. A `ana` lê e escreve. O grupo `team` lê. Todo o resto
não recebe nada, que é o `---` no fim, e é por isso que a carla foi recusada na seção 02.

## O `x` é o que tem dois significados

Num **arquivo**, `x` quer dizer *isto pode ser executado*. Sem ele, o arquivo é dado, seja lá o que
tenha dentro:

```
ana@vm:~/x$ ls -l script.sh
-rw-r--r-- 1 ana ana 34 Sep 14 22:49 script.sh
ana@vm:~/x$ ./script.sh
bash: ./script.sh: Permission denied
ana@vm:~/x$ chmod +x script.sh
ana@vm:~/x$ ls -l script.sh
-rwxr-xr-x 1 ana ana 34 Sep 14 22:49 script.sh
ana@vm:~/x$ ./script.sh
the script ran
```

O arquivo não mudou. Um bit mudou.

Num **diretório**, `x` quer dizer outra coisa, e a seção 06 é sobre ela. Não leve nada daqui
para lá.

## Os dois caracteres extras que você vai encontrar

```
-rwsr-xr-x 1 root root 64152 May 30  2024 /usr/bin/passwd
drwxrwsr-x 2 root team  4096 Sep 14 22:44 /srv/team
drwxrwxrwt 38 root root 36864 Sep 14 22:45 /tmp
```

Um `s` onde deveria haver um `x`, e um `t` no fim. Esses são os bits especiais, eles são a seção 10,
e por ora o que importa notar é que **eles ocupam uma vaga de `x`** — então um `s` minúsculo quer
dizer que o bit especial está ligado *e* a execução também, e um `S` maiúsculo quer dizer que o bit
especial está ligado e a execução não, o que é quase sempre um engano.

E um `+` no fim dos nove:

```
-rw-r-----+ 1 ana ana 11 Sep 14 22:46 report.txt
```

Isso quer dizer que o arquivo carrega uma **lista de controle de acesso** — permissões extras que
os nove caracteres não conseguem expressar. Seção 13. Quando o acesso a um arquivo não bate com o
modo dele, procure o mais.

## Como responder "eu posso?" sem adivinhar

Três perguntas, em ordem, e a seção 02 te deu as duas primeiras:

1. **Quem eu sou?** `id` — e leia a lista de grupos, não só o nome.
2. **Qual linha vale?** Dono, depois grupo, depois outros. A primeira que casa, e só ela.
3. **Eu consigo chegar lá?** Todo diretório do caminho precisa de `x`. Essa é a que as pessoas
   esquecem, e a seção 06 é onde ela ganha uma seção própria.

O `namei -l` percorre um caminho e imprime o modo de cada passo, o que responde às três de uma vez:

```
bruno@vm:~$ namei -l /srv/closed/readable.txt
f: /srv/closed/readable.txt
drwxr-xr-x root root /
drwxr-xr-x root root srv
drwx------ ana  ana  closed
                      readable.txt - Permission denied
```

Quatro linhas, e a terceira é a resposta: `closed` é `drwx------` e pertence à `ana`, então o bruno
nem chega ao arquivo — diga o modo do arquivo o que disser. Compare com um caminho que funciona:

```
bruno@vm:~$ namei -l /srv/perm/teamonly.txt
f: /srv/perm/teamonly.txt
drwxr-xr-x root root /
drwxr-xr-x root root srv
drwxr-xr-x root root perm
-rw-r----- ana  team teamonly.txt
```

Todos os diretórios dão `x` a todo mundo, então a caminhada chega ao arquivo e o modo do arquivo
decide. **Este é o comando mais útil que existe para uma recusa que você não entende**, e quase
ninguém sabe que ele existe.
