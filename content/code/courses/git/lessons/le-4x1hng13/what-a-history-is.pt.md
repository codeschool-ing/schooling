---
title: Um histórico é uma corrente de fotografias, cada uma com um motivo
version: 1
---

Aqui está o mesmo relatório guardado pelo Git em vez de uma pasta. Você vai fazer um desses na
aula 2. Por enquanto basta saber ler um:

```
ana@vm:~/notes$ git log --oneline
d03056f Name the quarter in the title
3c94cf5 Say by how much the north missed, and add the table it comes from
084e07d Use the corrected sales figure from finance
32507e0 Start the quarterly report
```

Quatro linhas, a mais nova primeiro, e cada uma é um **commit**: um estado salvo do projeto com uma
frase dizendo por que ele foi salvo. A pasta de cópias tinha cinco arquivos e nenhuma frase. Isto
tem um arquivo no disco, `report.txt`, e quatro motivos.

## O que um commit guarda

Peça o mais novo por inteiro e ele mostra o que a forma curta deixou de fora:

```
ana@vm:~/notes$ git log -1
commit d03056feb82202fe7dc86cbb7dcbae7a8e7d2222
Author: Ana Souza <ana@example.com>
Date:   Wed Sep 9 08:47:00 2026 -0300

    Name the quarter in the title
```

São quatro das cinco perguntas respondidas em cinco linhas. **Quem** é o autor, com nome e
endereço. **Quando** é a data, até o segundo e com o fuso horário. **Por quê** é a mensagem, escrita
por quem fez a mudança no momento em que a fez, enquanto ainda lembrava. **Qual** é o texto comprido
depois de `commit`.

**O id é calculado, não atribuído.** O Git pega tudo o que o commit contém: os arquivos, o autor, a
data, a mensagem e o commit anterior. Ele passa tudo isso por uma função de hash, que transforma
qualquer quantidade de dados em quarenta caracteres hexadecimais. Mude uma letra em qualquer lugar e
o id sai completamente diferente. Então ninguém distribui ids e duas pessoas não conseguem escolher
o mesmo: o mesmo commit tem o mesmo id em qualquer máquina do mundo. O `d03056f` do log curto são
só os sete primeiros caracteres, o que quase sempre basta para distinguir um commit do outro.

A quinta pergunta era **o que mudou junto**. Aqui está o commit do Bruno, com os arquivos que ele
mexeu:

```
ana@vm:~/notes$ git log -1 --stat HEAD~1
commit 3c94cf5b08d9dbcf6dc0253f2b0bed1af7ee86dc
Author: Bruno Lima <bruno@example.com>
Date:   Tue Sep 8 15:22:00 2026 -0300

    Say by how much the north missed, and add the table it comes from

 regions.csv | 3 +++
 report.txt  | 2 +-
 2 files changed, 4 insertions(+), 1 deletion(-)
```

A frase no relatório e a tabela de onde ela veio entraram como **uma mudança só**. Voltar para o dia
anterior a esse commit tira as duas, e avançar traz as duas de volta. Uma pasta de cópias nem
consegue expressar isso, porque cada cópia é um arquivo.

## Cada commit aponta para o anterior

Essa parte o log não imprime, e é ela que transforma uma lista de salvamentos num histórico. O Git
mostra o commit exatamente como o guarda:

```
ana@vm:~/notes$ git cat-file -p HEAD
tree cf4340aebd7b8c9451595d3fc8df4b1d05063e99
parent 3c94cf5b08d9dbcf6dc0253f2b0bed1af7ee86dc
author Ana Souza <ana@example.com> 1788954420 -0300
committer Ana Souza <ana@example.com> 1788954420 -0300

Name the quarter in the title
```

`parent` é o id do commit do Bruno. O commit do Bruno aponta o da Ana antes dele, e assim por diante
até o primeiro, que não tem pai nenhum. **Um histórico é essa corrente**, lida de trás para a frente
a partir do mais novo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 372\" role=\"img\" aria-label=\"Quatro commits empilhados, do mais novo em cima ao mais antigo embaixo. Cada um mostra o id curto, a mensagem, o autor e a data. Uma seta chamada pai vai de cada commit até o anterior. O commit mais antigo não tem pai.\"><defs><marker id=\"ch-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">o mais novo — onde o log começa</text><rect x=\"40\" y=\"40\" width=\"580\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">d03056f</text><text x=\"118\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Name the quarter in the title</text><text x=\"118\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Ana Souza · Wed Sep 9 08:47</text><path d=\"M84 90 L84 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\"></path><text x=\"94\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pai</text><rect x=\"40\" y=\"120\" width=\"580\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">3c94cf5</text><text x=\"118\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Say by how much the north missed, and add the table it comes from</text><text x=\"118\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Bruno Lima · Tue Sep 8 15:22</text><path d=\"M84 170 L84 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\"></path><text x=\"94\" y=\"186\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pai</text><rect x=\"40\" y=\"200\" width=\"580\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"220\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">084e07d</text><text x=\"118\" y=\"220\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Use the corrected sales figure from finance</text><text x=\"118\" y=\"238\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Ana Souza · Thu Sep 3 17:40</text><path d=\"M84 250 L84 278\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\"></path><text x=\"94\" y=\"266\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pai</text><rect x=\"40\" y=\"280\" width=\"580\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">32507e0</text><text x=\"118\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Start the quarterly report</text><text x=\"118\" y=\"318\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Ana Souza · Tue Sep 1 09:12</text><text x=\"54\" y=\"352\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sem pai: o primeiro commit</text></svg>", "caption": "O log lê a corrente de cima para baixo. Cada commit aponta o anterior, e o primeiro não aponta nada."}
```

A corrente também é o motivo de se poder confiar nos ids. O id de cada commit é calculado sobre o id
do pai, então editar em silêncio um commit antigo mudaria o id dele, o que mudaria o id de todos os
commits depois dele. **Não dá para alterar o histórico sem que isso apareça.** A aula 4 volta a
isso, porque alguns dos jeitos de desfazer um erro fazem exatamente isso, de propósito.

## Uma fotografia, não uma lista de mudanças

A primeira linha dessa saída, `tree`, é a outra metade da imagem, e ela corrige uma crença com que
quase todo mundo chega. A crença é que um commit guarda *o que mudou* — um diff, como as duas saídas
de `diff` da seção anterior. Ele guarda o projeto inteiro:

```
ana@vm:~/notes$ git cat-file -p HEAD~1^{tree}
100644 blob 8ad7960399318dfee980e2f2da0b2b4c4d9b3e8f	regions.csv
100644 blob 5a9a6711826c2029248f0b77e3db30c6a919e6b5	report.txt
ana@vm:~/notes$ git cat-file -p HEAD^{tree}
100644 blob 8ad7960399318dfee980e2f2da0b2b4c4d9b3e8f	regions.csv
100644 blob 13bfa124a5e9109630313a709bc5adb19d9909da	report.txt
```

A primeira lista é o projeto como o Bruno deixou, a segunda como a Ana deixou na manhã seguinte. O
commit da Ana mudou só o título do relatório, e **a árvore dele continua listando os dois
arquivos.** Todo commit é um retrato completo de todos os arquivos.

Olhe o `regions.csv` nas duas listas: o mesmo id. O arquivo não mudou, então o conteúdo dele dá o
mesmo hash, e o Git o guarda uma vez só e aponta para ele a partir dos dois commits. É assim que uma
fotografia de tudo, toda vez, continua pequena — **um arquivo que não mudou nunca é guardado duas
vezes.** E quando você pergunta o que mudou, o Git compara duas fotografias e calcula, que é o
assunto da aula 3.

Você não vai digitar `cat-file` de novo neste curso. Ele está aqui porque mostra, sem nada no
caminho, as três coisas de que um commit é feito: uma fotografia dos arquivos, os metadados que
respondem quem, quando e por quê, e um ponteiro para o commit anterior.
