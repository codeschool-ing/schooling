---
title: Dívida de segurança, por idade, e a tendência
version: 1
---

Dívida de segurança é tudo o que se sabe e ainda não foi tratado: os achados abertos, mais as exceções
que a aula 7 concedeu com data. A expressão vem de dívida técnica, e serve pelo mesmo motivo. **Um
achado antigo custa mais para corrigir do que um novo.** Quem escreveu o código mudou de time, a
dependência está três versões maiores atrás em vez de uma, e o achado já foi visto tantas vezes que
ninguém o lê. Então a visão útil da dívida não é o tamanho dela, e sim a idade.

### O relatório

```
ana@vm:~/metrics$ python3 measure.py debt
severity  open  0-30 31-90 91-180  181+ past SLA
critical     3     3     0      0     0        0
high        10     8     2      0     0        2
medium      26     7    10      4     5        9
low         20     4     7      2     7        7
```

59 achados abertos, divididos por severidade e em quatro faixas de idade: até um mês, até um
trimestre, até meio ano, e mais antigos. A última coluna conta os que já passaram do SLA.

Leia de baixo para cima, pela direita. **Doze achados estão abertos há mais de 181 dias**, cinco
médios e sete baixos, e eles são a dívida no sentido que a palavra tem: não trabalho em andamento, e
sim trabalho que não vai acontecer a menos que alguém decida que vai. Os 9 achados médios fora do SLA
de 90 dias são a linha mais urgente da tabela, porque são promessas já quebradas sobre achados sérios
o bastante para importar.

As duas primeiras linhas parecem saudáveis. Os três achados críticos abertos têm menos de um mês, e
nenhum achado crítico está fora do SLA hoje. É assim que parece um time que corrige pela ordem de
severidade, e é também por isso que um relatório de dívida precisa ser dividido por severidade: os 59
como um número só seriam puxados pelas linhas de média e baixa e não diriam nada sobre os críticos
estarem sendo tratados.

### Faixas, não uma idade média

Uma idade média dos achados abertos seria um número só, e se moveria pelos motivos errados: corrigir
um achado muito antigo a baixa tanto quanto corrigir muitos novos. As faixas preservam o formato. Um
time cuja coluna `181+` cresce está acumulando achados que nunca vai corrigir, diga o que disser a
mediana do tempo até remediar, e esse é o padrão a pegar cedo. Onde ficam os limites das faixas
importa menos do que mantê-los fixos, para a mesma tabela poder ser comparada de um trimestre para o
outro.

### A tendência

```
ana@vm:~/metrics$ python3 measure.py trend
quarter   opened closed open at end
2025-10      143     79          64
2026-01      113    116          61
2026-04      126    128          59
2026-07      127    126          60
```

Por trimestre: achados abertos, achados fechados, e quantos estavam abertos no último dia do
trimestre.

A primeira linha é um artefato dos dados, e todo conjunto de dados real tem um. O ano gerado começa em
1º de outubro de 2025 sem nada aberto, então o primeiro trimestre enche a lista a partir do zero: 143
abertos, 79 fechados, 64 abertos no fim. Uma tendência que começa no dia em que a medição começou
sempre começa com uma subida, e ler essa subida como "as coisas pioraram" é um erro comum no primeiro
relatório que um programa produz.

Do segundo trimestre em diante, a empresa fecha mais ou menos tantos achados quanto abre, e o total
aberto se mantém perto de sessenta: 61, 59, 60. **Uma linha plana de achados abertos quer dizer que o
time acompanha o ritmo, não que está chegando a algum lugar.** Vale reconhecer os outros dois
formatos:

| formato | o que significa |
|---|---|
| abertos no fim subindo, trimestre após trimestre | chega mais do que se fecha; o acúmulo não vai se resolver sozinho |
| abertos no fim estável | o time acompanha o que chega; os achados antigos continuam onde estão |
| abertos no fim caindo | o acúmulo está sendo pago, ou alguma coisa parou de achar coisas |

A última linha tem duas leituras, e elas são opostas. Um total aberto em queda é boa notícia quando o
fechamento subiu, e má notícia quando a abertura caiu porque um scanner foi desligado ou um alvo saiu
do inventário. **Confira a cobertura antes de comemorar uma linha que cai**: é o número que separa os
dois casos, e a seção anterior mostra como.

### O que fazer com a dívida

Cada achado na coluna `181+` merece uma das três decisões que a aula 1 desenhou: corrigir, pôr em
exceção com dono e data, ou fechar como falso positivo com o motivo. O que ele não deveria é ficar
aberto e sem dono por mais um trimestre. As exceções entram na dívida mesmo não estando "abertas",
porque uma exceção é a decisão de carregar o risco até uma data, e a data é quando ele volta.
