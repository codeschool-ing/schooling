---
title: Manutenção: de consertar a prever
version: 1
---

A quebra de 28 minutos no turno da IM-07 é uma entrada num registro longo, e a decisão a que esse
registro serve é quando parar uma máquina de propósito para que ela não pare sozinha. **Há três
jeitos de tomar essa decisão, e cada um precisa de mais dados que o anterior.**

| | quando o trabalho é feito | do que precisa |
|---|---|---|
| **corretiva** | depois que a máquina quebra | um técnico e peças de reposição |
| **preventiva** | por calendário ou por contador: a cada 500 horas, a cada 200.000 ciclos | o intervalo do fabricante, ou o histórico de quebras da própria fábrica |
| **preditiva** | quando a condição da máquina diz que uma quebra está vindo | leituras de sensores ao longo do tempo, e quebras registradas com as causas, para casar as leituras com o que veio depois |

A manutenção corretiva não é falha de gestão: para uma peça barata cuja quebra não para nada
importante, usar até quebrar é a escolha certa. A preventiva troca peças que talvez durassem mais, e
esse é o custo dela. A preditiva tenta trocá-las na hora certa, e é a que as pessoas querem dizer
quando falam que uma fábrica "usa dados".

## Dois números para como uma máquina quebra

O relatório trimestral de manutenção de Rafael tem dois números por máquina. O **MTBF**, tempo médio
entre falhas (*mean time between failures*), é as horas de operação divididas pelo número de
quebras: quanto tempo a máquina roda, em média, antes de parar sozinha. O **MTTR**, tempo médio de
reparo (*mean time to repair*), é as horas em reparo divididas pelo número de quebras: quanto tempo
ela fica parada quando para. Dos dois sai a parcela do tempo em que a máquina está disponível:

disponibilidade = MTBF ÷ (MTBF + MTTR)

Digite julho a setembro de 2025 de duas máquinas:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Máquina | Horas | Quebras | Horas de reparo |
| 2 | IM-07 | 1860 | 6 | 27 |
| 3 | IM-11 | 1790 | 15 | 52,5 |

Em E2, F2 e G2, copiados até a linha 3:

```localised
=ARRED(B2/C2;1)      310
=ARRED(D2/C2;1)      4,5
=ARRED(E2/(E2+F2)*100;1)      98,6
```

A IM-11 fica com MTBF de 119,3 horas, MTTR de 3,5 e disponibilidade de 97,1%. Essa disponibilidade
conta só quebras, e é por isso que fica muito acima dos 86,0% da seção de OEE: aquela também contou
a troca de molde e mediu um turno só.

**As duas disponibilidades estão a 1,5 ponto uma da outra, e as máquinas não se parecem em nada.** A
IM-11 quebra duas vezes e meia mais que a IM-07; os reparos dela são mais rápidos, e isso esconde a
diferença num número só. Reparos rápidos de quebras frequentes costumam ser o mesmo defeito pequeno
consertado de novo e de novo, uma resistência ou um sensor, e cada quebra custa mais que o tempo de
reparo: a máquina precisa voltar à temperatura, e as primeiras peças depois de religar vão para o
refugo. **Um relatório que mostrasse só a disponibilidade colocaria as duas máquinas quase
empatadas**; o MTBF ao lado mostra que uma delas tem um problema que ninguém resolveu.

## Do que a manutenção preditiva precisa

O gerente da fábrica leu o relatório e perguntou se a IM-11 podia ganhar sensores e um modelo que
previsse as quebras dela. A resposta de Rafael começou pelos dados, e é a resposta que este curso
daria para qualquer setor: um modelo aprende quais leituras vêm antes de quais quebras, e só aprende
com quebras que foram registradas com a causa.

Das 15 quebras da IM-11, 9 foram registradas no livro de manutenção como "máquina parada", sem causa.
**60% do histórico com que um modelo aprenderia não diz nada sobre o que deu errado.** Nenhum sensor
instalado hoje conserta isso, porque as leituras de antes daquelas quebras também não existem.

Então Rafael propôs o passo anterior ao modelo: pelos próximos seis meses, toda quebra é registrada
com uma causa escolhida numa lista curta, e os dois sensores que a máquina já tem, temperatura do
óleo hidráulico e pressão de injeção, são gravados a cada minuto em vez de aparecer no painel e ser
descartados. **A manutenção preditiva se compra com histórico**, e o histórico tem de começar antes
que alguém consiga prever qualquer coisa. Um cientista de dados pode então construir o modelo (a
aula 3 diz quem faz o quê); o trabalho de BI é garantir que exista algo a partir do qual construí-lo.
