---
title: O `sed`, e o único comando que é noventa por cento dele
version: 1
---

O `sed` é um editor de fluxo: ele lê linhas, aplica comandos a elas, e imprime o resultado. Ele tem
uma linguagem inteira e você vai usar um comando dela.

## O `s`, de substituir

```
ana@vm:~/work$ echo "the cat sat on the mat" | sed "s/cat/dog/"
the dog sat on the mat
```

A forma é `s/o-quê/por-quê/opções`, e há duas opções que valem conhecer.

**O `g` não é o padrão**, que é a primeira surpresa:

```
ana@vm:~/work$ echo "the cat sat on the cat" | sed "s/cat/dog/"
the dog sat on the cat
ana@vm:~/work$ echo "the cat sat on the cat" | sed "s/cat/dog/g"
the dog sat on the dog
```

**Sem o `g`, o `sed` substitui a primeira ocorrência de cada linha.** Isso ocasionalmente é o que
você quer e normalmente não é, e é um bug que só aparece em linhas em que a coisa aparece duas vezes.

O `i` é a outra: o `s/cat/dog/gi` ignora a caixa.

## O separador é o que você digitar

```
ana@vm:~/work$ echo "a/b/c" | sed "s|/|-|g"
a-b-c
```

**O `s|…|…|` e o `s#…#…#` funcionam exatamente como o `s/…/…/`.** O caractere imediatamente depois do
`s` é o separador daquele comando.

Isso importa o tempo todo, porque as coisas que você mais substitui são caminhos, e um caminho cheio
de barras dentro de um `s/…/…/` precisa de escape em cada uma delas. O `s|/usr/local|/opt|` é
legível; o `s/\/usr\/local/\/opt/` é a mesma coisa e ninguém consegue conferir a olho.

## Endereços: quais linhas

Ponha algo na frente do comando e ele se aplica só àquelas linhas:

```
ana@vm:~/work$ sed -n "3p" logs/app.log
app handled a request
ana@vm:~/work$ sed -n "2,4p" logs/app.log
app ready
app handled a request
app started
```

**O `-n` desliga a impressão automática**, então `-n` com `p` quer dizer "imprima só estas". Sem o
`-n`, o `sed "3p"` imprime toda linha e a linha três duas vezes.

| | |
|---|---|
| `3` | linha 3 |
| `2,4` | linhas 2 a 4 |
| `$` | a última linha |
| `/padrão/` | toda linha que casar |
| `2,$` | da linha 2 até o fim |

```
ana@vm:~/work$ sed "1d" data/sales.csv | head -2
north,ana,Q1,171,8721
north,bruno,Q1,49,4116
```

**O `1d` apaga a primeira linha**, que é a expressão idiomática para descartar cabeçalho ao lado do
`tail -n +2` da seção 05. Qualquer um serve; o `sed 1d` é mais curto e o `tail -n +2` é mais rápido
num arquivo grande.

```
ana@vm:~/work$ sed -n "/error/p" logs/app.log
```

Nada, porque aquele arquivo não tem linha contendo `error` — e o `sed -n /padrão/p` é o `grep`, mais
devagar. **Use o `grep` para achar e o `sed` para mudar.**

## Mudando toda linha

```
ana@vm:~/work$ sed "s/^/> /" logs/app.log | head -2
> app started
> app ready
```

O `^` casa com o começo de uma linha e tem zero caracteres de largura, então substituí-lo
**insere**. O `s/$/;/` acrescenta no fim. Esses dois são como se põe um prefixo ou um sufixo em toda
linha de algo.

Um real, transformando endereços em redes:

```
ana@vm:~/work$ cut -d" " -f1 logs/access.log | sed "s/\.[0-9]*$/.0\/24/" | sort -u | head -4
10.0.1.0/24
198.51.100.0/24
203.0.113.0/24
```

"Substitua um ponto e os dígitos no fim da linha por `.0/24`." Mil e duzentos endereços viram três
redes. Repare no `\/` — a substituição contém uma barra e o separador é uma barra, então ela teve que
ser escapada. O `s|\.[0-9]*$|.0/24|` evita isso.

## No lugar

```
ana@vm:~/work$ cp logs/app.log /tmp/edit.log
ana@vm:~/work$ sed -i "s/app/service/g" /tmp/edit.log
ana@vm:~/work$ head -3 /tmp/edit.log
service started
service ready
service handled a request
```

**O `-i` edita o arquivo em vez de imprimir na saída padrão**, e é a resposta ao problema do
`sort arquivo > arquivo` da seção 03.

Ele também é a opção com que se toma cuidado, porque não há desfazer. O `-i.bak` guarda uma cópia:

```
ana@vm:~/work$ cp logs/app.log /tmp/edit2.log
ana@vm:~/work$ sed -i.bak "s/app/service/g" /tmp/edit2.log
ana@vm:~/work$ ls /tmp/edit2*
/tmp/edit2.log  /tmp/edit2.log.bak
```

**O hábito que vale formar: rode sem o `-i` primeiro.** O `sed 's/…/…/g' arquivo | head` te mostra o
que ele faria, não custa nada, e pega o padrão que casou com mais do que você queria.

E uma nota de portabilidade que morde: **o `sed` BSD no macOS exige um argumento para o `-i`**, então
`sed -i '' 's/…/…/' arquivo` lá e `sed -i 's/…/…/' arquivo` no Linux. Um script com `-i` não é
portável entre os dois sem cuidado.

## O resto do `sed`

O `sed` tem desvios, rótulos, um espaço de retenção e comandos multilinha. É uma linguagem completa e
gente já escreveu programas surpreendentes nela.

**Você não precisa de nada disso.** Quando um comando do `sed` precisa de uma segunda linha, a
resposta é o `awk`, e quando o `awk` precisa de uma segunda variável a resposta é um script. O `sed`
que você vai escrever pelo resto da carreira é:

```
sed 's/old/new/g'                   # substitute
sed -n '5,10p'                      # print a range
sed '1d'                            # drop a line
sed -i.bak 's|/old/path|/new|g'     # edit files in place, with a backup
```

Quatro comandos, e o último é o que vale conferir duas vezes antes de rodar.
