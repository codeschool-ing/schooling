---
title: O `uniq`, que não faz o que o nome dele diz
version: 1
---

O `uniq` agrupa linhas idênticas **adjacentes**. Ele não é um removedor de duplicatas; é um contador
de sequências, e a diferença é o bug mais comum em comandos de uma linha.

```
ana@vm:~/work$ printf "a\na\nb\na\n" | uniq
a
b
a
ana@vm:~/work$ printf "a\na\nb\na\n" | sort | uniq
a
b
```

**Três linhas saindo de um comando chamado `uniq`.** Os dois `a` da frente eram adjacentes e foram
agrupados; o `a` do fim não estava ao lado deles, então ele sobreviveu.

**Isso não é um bug e não te avisa.** Em entrada não ordenada o `uniq` dá uma resposta errada que
parece certa, e a única defesa é o hábito: **`sort` antes do `uniq`, sempre.**

O motivo de ele funcionar assim é que isso deixa o `uniq` tratar um fluxo de qualquer tamanho em
memória constante. Um removedor de duplicatas de verdade teria que lembrar de toda linha que viu.

## O `-c`, que é o ponto inteiro

```
ana@vm:~/work$ cut -d" " -f7 logs/access.log | sort | uniq -c | sort -rn | head -6
    287 /health
    261 /
    147 /api/orders
    110 /static/app.js
    104 /static/app.css
     76 /index.html
```

**O `sort | uniq -c | sort -rn` é o pipeline mais útil desta aula**, e vale aprendê-lo como uma
unidade só: *conte os valores distintos e me mostre os mais comuns.*

Leia como três passos: junte coisas iguais, conte cada grupo, ordene pela contagem.

Ele responde, mudando só o campo:

| | |
|---|---|
| quais caminhos são mais movimentados | `cut -d" " -f7` |
| quais endereços fazem mais barulho | `cut -d" " -f1` |
| quais códigos de status voltaram | `cut -d" " -f9` |
| quais comandos você mais digita | `history \| awk '{print $2}'` |

**O segundo `sort -rn` é onde o `-n` da seção 09 ganha o salário.** O `uniq -c` põe a contagem
primeiro, então ordenar sem o `-n` poria `100` antes de `99`.

## O `-d` e o `-u`, que são opostos

```
ana@vm:~/work$ cut -d" " -f1 logs/access.log | sort | uniq -d | head -3
10.0.1.10
10.0.1.11
10.0.1.12
ana@vm:~/work$ cut -d" " -f1 logs/access.log | sort | uniq -u | head -3
```

| | |
|---|---|
| `-d` | só as linhas que aparecem **mais de uma vez** |
| `-u` | só as linhas que aparecem **exatamente uma vez** |

O segundo comando não imprimiu nada, e isso é uma resposta: **todo endereço deste log aparece mais de
uma vez.** Um resultado vazio do `uniq -u` diz "nenhum valor aqui é único", o que numa lista de IDs
de usuário ou de somas de verificação muitas vezes é exatamente o que você queria saber.

O `-d` é o achador de duplicatas. O `sort arquivo | uniq -d` numa lista de qualquer coisa que
deveria ser única — IDs, endereços de e-mail, nomes de arquivo — nomeia as colisões numa linha.

## O `-i` e o `-f`

O `uniq -i` ignora a caixa. O `uniq -f1` ignora o primeiro campo na comparação, que é como se agrupam
linhas que diferem só num horário ou contagem inicial:

```
sort file | uniq -c | sort -rn | uniq -f1 -d
```

Isso é de nicho. Os três para guardar são o `-c`, o `-d` e o `-u`.

## A armadilha da ordem, por inteiro

Aqui está o bug na vida real. Você quer os dez caminhos mais movimentados:

```
ana@vm:~/work$ cut -d" " -f7 logs/access.log | uniq -c | sort -rn | head -4
      5 /
      5 /
      5 /
      4 /health
```

O mesmo pipeline **com o `sort` deixado de fora**. O `uniq -c` em entrada não ordenada conta
*sequências*, então um caminho que aparece duzentas e sessenta vezes espalhadas pelo arquivo produz
dezenas de contagens pequenas separadas — e o `/` aparece três vezes em quatro linhas de saída, cada
vez alegando ter sido visto cinco vezes.

Compare com a versão correta no topo desta seção: `287 /health`, `261 /`. Nenhum número aqui está
certo.

**E nada naquela saída parece incorreto à primeira vista.** As contagens são plausíveis e os caminhos
são reais. O `/` repetindo três vezes é a única pista, e numa listagem de vinte linhas você não a
veria. Este é o argumento para rodar um pipeline novo em poucas linhas primeiro, onde dá para
conferir a resposta a olho.

## Contando sem o `uniq`

O `awk` consegue contar numa passagem só, sem ordenar, porque ele tem array associativo:

```
ana@vm:~/work$ awk '{c[$7]++} END {for (p in c) print c[p], p}' logs/access.log | sort -rn | head -4
287 /health
261 /
147 /api/orders
110 /static/app.js
```

A mesma resposta do topo desta seção, e sem `sort` antes da contagem — então num arquivo muito grande
ele é bem mais rápido, e não precisa da entrada agrupada.

**O `sort | uniq -c` é mais fácil de digitar e o `awk` é mais rápido em entradas grandes.** Os dois
estão corretos; a seção 14 é o segundo.
