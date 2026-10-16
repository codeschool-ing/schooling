---
title: Os dados da fábrica: três registros e três relógios
version: 1
---

Todo número desta aula veio de algum lugar, e numa fábrica esse lugar importa mais que no varejo ou
num hospital. **Uma fábrica guarda três registros do mesmo evento**, feitos por três coisas
diferentes para três finalidades diferentes, e eles discordam de jeitos previsíveis quando se sabe
quem escreveu cada um.

| registro | quem escreve | quando | para que serve |
|---|---|---|---|
| os contadores e sensores da máquina | o controlador da máquina, automaticamente | a cada ciclo, ao segundo | fazer a máquina funcionar |
| o ERP | o depósito e o planejamento | quando um pedido é liberado, quando as caixas entram no estoque | estoque, notas fiscais e o cliente |
| a folha do turno | o operador, à mão | no fim do turno | o refugo, as paradas e os motivos delas |

## Um turno, três respostas

O segundo turno da IM-07, o mesmo desmontado no OEE. O contador da máquina registrou 1.350 ciclos. O
depósito lançou no ERP 1.296 tampas boas. A folha do turno do operador dizia que 40 tampas foram
refugadas. Digite as três:

| | A | B |
|---|---|---|
| 1 | Contador da máquina | 1350 |
| 2 | Refugo do operador | 40 |
| 3 | Encaixotado no depósito | 1296 |

Se o refugo do operador estivesse completo, as peças boas seriam o contador menos o refugo:

```localised
=B1-B2      1310
=B1-B2-B3      14
```

**Catorze tampas foram feitas, não saíram boas e não foram anotadas.** A explicação de costume, e a
que Rafael encontrou quando perguntou, é o refugo de partida: depois da troca de molde, as primeiras
injeções vão para uma caçamba enquanto a máquina chega à temperatura, e o operador, ocupado em
religar, anota o refugo da produção e não o refugo da partida.

Os dois números de qualidade que saem daí estão calculados certo:

```localised
=ARRED((B1-B2)/B1*100;1)      97
=ARRED(B3/B1*100;1)      96
```

97,0% pela folha do turno, 96,0% pelo contador e pelas caixas. A seção de OEE usou o segundo, e foi
uma escolha: **entre um número que uma máquina contou e um número que uma pessoa digitou no fim de um
turno cansativo, confie no contador**, e use o anotado à mão para o que só uma pessoa sabe informar,
que é o motivo. Um relatório que tirasse o refugo da folha do turno mostraria a IM-07 um ponto melhor
do que ela é, em todo turno, e as tampas que faltam somariam milhares por mês que ninguém consegue
achar.

## Três relógios

Os registros também discordam sobre o tempo. O controlador da máquina tem o seu próprio relógio,
acertado quando foi instalado e nem sempre depois. O ERP usa o relógio do servidor. A folha do turno
usa o que o operador escreveu, que em geral é o fim do turno. Quando Rafael juntou pela primeira vez
o registro de paradas do controlador com o livro de manutenção, uma quebra parecia ter sido
consertada sete minutos antes de começar; o relógio do controlador da IM-11 estava sete minutos
adiantado.

**Turnos atravessam a meia-noite**, e relatórios por dia do calendário não. O terceiro turno vai das
22:00 às 06:00, então um relatório da "produção de terça" ou o divide entre dois dias ou o atribui
inteiro ao dia em que começou, e dois relatórios que escolheram diferente nunca vão bater. A regra da
Serra Azul, escrita no topo de todo relatório de produção, é que o turno pertence à data em que
começou.

## A armadilha, e o que fazer com ela

A armadilha do setor é a da tabela do começo desta aula: **um número digitado fica na mesma tabela
que um número contado e parece igualmente sólido**. Nada num painel mostra que a coluna de refugo foi
escrita à mão às 21:55 e a coluna de peças por um controlador a cada ciclo.

As correções são sem graça e funcionam. Concilie os três registros a cada turno, como a planilha
acima faz, e ponha a diferença na tela do supervisor, para que 14 tampas sem explicação sejam
notadas na noite em que acontecem, e não no inventário do fim do mês. Tire as contagens da máquina
sempre que a máquina puder contar. Peça às pessoas o que só as pessoas sabem, o motivo de uma parada
ou de um refugo, e torne isso rápido: uma lista curta numa tela ao lado da máquina é melhor que uma
linha em branco numa folha. E escreva as regras, a data do turno e qual relógio vale, num lugar para
o qual todo relatório possa apontar. A aula 9 de `data-governance` trata de qualidade e linhagem de
dados para qualquer setor; a fábrica é só o lugar em que a letra de uma pessoa e o contador de uma
máquina se encontram numa mesma coluna.
