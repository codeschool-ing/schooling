---
title: O escritório em que este curso trabalha
version: 1
---

Todo chamado deste curso acontece num escritório pequeno, e toda sessão de terminal que você vai ler foi
gravada lá, em computadores de verdade. **Você lê as sessões; não precisa digitar nada delas.** O que
importa é a saída: o que um comando respondeu, e o que essa resposta descarta.

O escritório tem quatro computadores, todos com Ubuntu 24.04:

| nome | o que é |
|---|---|
| `host` | o computador da própria técnica. Ela se chama ana, e todas as sessões são dela |
| `pc1`, `pc2` | as mesas: os computadores em que a Carla, o Bruno, o Daniel e a Elisa trabalham |
| `srv1` | o servidor: a página da intranet que todo mundo abre pelo nome `intranet`, e na aula 7 um sistema de outra equipe |

O prompt diz onde o comando rodou. `ana@pc1:~$` é a ana digitando no `pc1`, alcançado a partir do
computador dela com ssh, como faria um técnico com acesso remoto. `elisa@pc1:~$` é a sessão da própria
Elisa.

Os quatro são máquinas virtuais numa rede só deles, `10.30.0.0/24`, sem rota para mais nada. Foi isso que
tornou seguro quebrá-los: **cada defeito foi preparado de propósito antes da gravação**, uma linha errada
num arquivo, um disco cheio, uma impressora parada por atolamento. Onde falta ao escritório algo que um de
verdade tem, a aula diz o que faz as vezes disso. Nenhum dos computadores tem área de trabalho, por
exemplo, então a tela compartilhada no suporte remoto é de terminal.

Você não precisa montá-lo, porque **a prática deste curso é de julgamento**: que pergunta fazer, que
checagem descarta mais, o que vai no chamado, quando parar e passar adiante. As questões depois de cada
aula verificam isso, e nenhuma delas precisa de terminal.

Se mesmo assim quiser rodar alguma coisa, use o Linux que você instalou no curso Sistemas
Operacionais, aula 3, "Instalação e configuração inicial de uma distribuição Linux". Os comandos que só
leem, como `getent hosts`, `lpstat` e `df -h`, funcionam lá e respondem sobre o seu computador, então os
números vão ser outros. Os três programas que este curso mostra inteiros, o script de fatos da aula 5,
a calculadora de horário comercial da aula 6 e o script de inventário da aula 11, rodam lá do jeito que
estão. O que citar `pc1`,
`pc2`, `srv1` ou `intranet` não roda: **esses nomes só existem no escritório**. E um comando que muda alguma
coisa, qualquer um rodado com `sudo`, é para um computador que você pode se dar ao luxo de quebrar.
