---
title: Juntar dois arquivos, e achar a diferença
version: 1
---

Tudo até aqui trabalhou num fluxo só. Estes cinco trabalham em dois, e cada um responde uma pergunta
diferente sobre como duas listas se relacionam.

| | |
|---|---|
| `paste` | põe **lado a lado**, linha por linha |
| `join` | casa **por uma chave**, como um join de banco de dados |
| `comm` | o que está nos dois, e o que está só num |
| `diff` | o que mudou, linha por linha |
| `split` | o contrário: um arquivo em vários |

## O `paste`

```
ana@vm:~/work$ printf "ana\nbruno\ncarla\n" > /tmp/left.txt
ana@vm:~/work$ printf "1\n2\n3\n" > /tmp/right.txt
ana@vm:~/work$ paste /tmp/left.txt /tmp/right.txt
ana     1
bruno   2
carla   3
ana@vm:~/work$ paste -d, /tmp/left.txt /tmp/right.txt
ana,1
bruno,2
carla,3
```

Linha um com linha um, linha dois com linha dois, separadas por tabulação a menos que o `-d` diga
outra coisa. **Ele não olha o conteúdo de jeito nenhum** — é posicional, então os dois arquivos
precisam já estar na mesma ordem.

O `-s` é o outro modo, e é o que vale lembrar:

```
ana@vm:~/work$ paste -sd, /tmp/left.txt
ana,bruno,carla
```

**O `paste -sd,` transforma uma coluna numa linha separada por vírgulas**, que é o oposto exato do
`tr , '\n'` da seção 12. A seção 08 usou `paste -sd+ | bc` para somar uma coluna, que é o mesmo
truque com outro separador.

## O `join`

```
ana@vm:~/work$ printf "ana north\nbruno north\ndiego south\n" | sort > /tmp/a.txt
ana@vm:~/work$ printf "ana 40\nbruno 12\nelena 7\n" | sort > /tmp/b.txt
ana@vm:~/work$ join /tmp/a.txt /tmp/b.txt
ana north 40
bruno north 12
```

O `a.txt` tem nomes e regiões, o `b.txt` tem nomes e números, e o `join` casou os dois pelo primeiro
campo. O `diego` e a `elena` aparecem só num arquivo cada, então não estão na saída.

**Os dois arquivos precisam estar ordenados pelo campo de junção.** O `join` os lê em conjunto, como
uma intercalação, que é o que o faz funcionar em arquivos maiores que a memória — e o que o faz ficar
silenciosamente errado em entrada não ordenada. Ordene os dois antes, e o aviso de locale da seção 09
se aplica: ordene-os do *mesmo* jeito.

O `-a` mantém as linhas sem par, que é um join externo:

```
ana@vm:~/work$ join -a1 -a2 -e "-" -o "0,1.2,2.2" /tmp/a.txt /tmp/b.txt
ana north 40
bruno north 12
diego south -
elena - 7
```

O `-a1 -a2` mantém as linhas sem par dos dois lados, o `-e "-"` preenche os buracos, e o `-o` diz
quais campos imprimir: `0` é a chave, `1.2` é o campo 2 do arquivo 1, `2.2` é o campo 2 do arquivo 2.

**Até aí é o quanto vale forçar o `join`.** Ele é chato, e no momento em que houver três arquivos ou
uma chave composta, a resposta é o `sqlite3`, que lê CSV direto e faz isso em SQL.

## O `comm`

```
ana@vm:~/work$ cut -d" " -f1 /tmp/a.txt > /tmp/an.txt; cut -d" " -f1 /tmp/b.txt > /tmp/bn.txt
ana@vm:~/work$ comm -12 /tmp/an.txt /tmp/bn.txt
ana
bruno
ana@vm:~/work$ comm -23 /tmp/an.txt /tmp/bn.txt
diego
```

O `comm` imprime três colunas: só no arquivo 1, só no arquivo 2, nos dois. Os números **suprimem**
uma coluna, o que se lê ao contrário até você aprender:

| | |
|---|---|
| `comm -12` | suprime 1 e 2, sobrando **os dois** — a interseção |
| `comm -23` | suprime 2 e 3, sobrando **só no arquivo 1** |
| `comm -13` | sobrando **só no arquivo 2** |

**O `comm -23 a b` é "o que está em a e não está em b"**, e é o jeito mais rápido de comparar duas
listas de qualquer coisa — pacotes instalados contra um manifesto, usuários contra um conjunto
esperado, arquivos aqui contra arquivos lá.

Os dois arquivos precisam estar ordenados, e diferente do `join`, **o `comm` te avisa quando não
estão**:

```
ana@vm:~/work$ printf "b\na\nc\n" > /tmp/u1.txt; printf "a\nb\n" > /tmp/u2.txt
ana@vm:~/work$ comm /tmp/u1.txt /tmp/u2.txt
        a
                b
comm: file 1 is not in sorted order
a
c
comm: input is not in sorted order
```

Ele produz saída errada *e* reclama, que é melhor que o `join`, que produz saída errada em silêncio.
Ordene as duas entradas e nenhuma das duas questões aparece.

## O `diff`

```
ana@vm:~/work$ diff /tmp/an.txt /tmp/bn.txt
3c3
< diego
---
> elena
```

O `3c3` é "linha 3 mudou para linha 3". O `<` é o primeiro arquivo, o `>` é o segundo. O `d` é
apagado e o `a` é acrescentado.

**O `diff -u` é o formato que você quer de fato**, porque é o que patches e revisão de código usam:
contexto em volta da mudança, `-` e `+` em vez de `<` e `>`.

A diferença para o `comm`: **o `diff` se importa com ordem e posição, o `comm` se importa com
pertencimento.** Dois arquivos com as mesmas linhas em ordem diferente são idênticos para o
`comm -12` e completamente diferentes para o `diff`.

Outras opções que valem: o `-r` para árvores de diretório inteiras, o `-q` para dizer só se eles
diferem, o `-w` para ignorar espaço em branco, e o `-y` para uma visão lado a lado.

## O `split`

```
split -l 10000 huge.log part_       # 10,000 lines each, part_aa, part_ab, …
split -b 100M archive.tar chunk_    # 100 MB each
split -n 4 file piece_              # four pieces
```

A operação oposta. Os usos dele são estreitos e reais: dividir algo grande demais para enviar, cortar
um arquivo em pedaços para processamento paralelo, ou pegar uma amostra gerenciável.

O `cat part_* > rejuntado` põe de volta, e os sufixos alfabéticos são por que isso funciona.

## Qual pegar

| | |
|---|---|
| duas listas, o que está nas duas | `comm -12` |
| duas listas, o que está só na primeira | `comm -23` |
| dois arquivos, o que mudou | `diff -u` |
| duas tabelas, casadas por uma chave | `join`, ou `sqlite3` |
| duas colunas numa tabela | `paste` |
| uma coluna numa linha | `paste -sd,` |

**E lembre da pré-condição**: o `join` e o `comm` exigem entrada ordenada. O `comm` reclama quando
não está; o `join` não.
