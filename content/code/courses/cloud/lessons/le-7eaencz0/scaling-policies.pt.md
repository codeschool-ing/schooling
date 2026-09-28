---
title: "Políticas de escala, e os minutos que elas não eliminam"
version: 1
---

O número desejado de um grupo pode ser mudado à mão, mas a graça de um grupo é que ele se move
sozinho. Uma **política de escala** é a regra que o move. Há três tipos, e cada um responde a
pergunta "de quantas precisamos agora?" de um jeito.

## Target tracking: manter um número perto de um alvo

Você nomeia uma métrica e um valor: manter a CPU média do grupo em 50%. O grupo então faz a conta que
uma pessoa faria. Se quatro instâncias estão com média de 80%, o mesmo trabalho espalhado a 50%
precisa de 4 × 80 / 50 = 6,4 instâncias, e como não existe 0,4 de máquina, ele pede 7. Quando a carga
cai e sete instâncias estão com média de 20%, a mesma conta diz que três bastam.

Target tracking é o tipo para começar, porque você declara o resultado e não os passos. A métrica não
precisa ser CPU; requisições por instância, contadas no balanceador, muitas vezes é melhor para um
serviço web, porque mede o próprio trabalho em vez de um dos efeitos dele.

## Step scaling: limites e quantidades

O **step scaling** é a forma mais antiga e mais explícita. Você põe alarmes em limites e diz o que
fazer em cada um: acima de 70% de CPU média, acrescente uma instância; acima de 85%, três; abaixo de
30%, tire uma. Dá controle exato e exige que você acerte cada número; o target tracking faz as contas
por você.

## Agendado: o relógio, não a carga

**Uma ação agendada** muda as contagens num horário: às 07:30 dos dias úteis, ponha o mínimo em seis;
às 20:00, volte para dois. Ela nem olha a carga. É a única das três que age antes de a carga chegar, e
é exatamente por isso que existe.

## O atraso

**Toda política que observa uma métrica segue a carga; nenhuma a antecipa.** Entre o momento em que a
carga sobe e o momento em que uma instância nova assume uma parte dela, várias coisas acontecem em
ordem:

1. a métrica é coletada, em geral uma vez por minuto, e a política espera pontos suficientes para ter
   certeza de que a subida é real e não um pico isolado;
2. o grupo pede instâncias e o provedor as posiciona e inicia;
3. cada uma dá boot e depois roda o user data;
4. a verificação de saúde do balanceador passa, e o tráfego começa a chegar.

O primeiro passo leva um minuto ou mais, e o terceiro é o que você controla: uma imagem embutida dá
boot pronta, enquanto uma que instala o software no boot soma cada instalação à espera. Somado, são
minutos, não segundos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um gráfico com o tempo na horizontal e a carga na vertical, sem números. A curva de carga sobe rápido. A linha de capacidade é uma escada que só sobe alguns minutos depois que a carga a ultrapassa, então há uma faixa sombreada em que a carga fica acima da capacidade. Depois a carga cai e a capacidade desce mais devagar.\"><defs><marker id=\"lag-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 262 L700 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lag-ah)\"></path><path d=\"M70 262 L70 30\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lag-ah)\"></path><text x=\"700\" y=\"280\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tempo</text><text x=\"78\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">requisições por segundo</text><path d=\"M215 180 L230 170 L260 130 L290 100 L330 86 L380 82 L430 90 L430 100 L380 100 L380 140 L320 140 L320 180 Z\" fill=\"var(--amber)\" fill-opacity=\"0.22\" stroke=\"none\"></path><path d=\"M70 180 L320 180 L320 140 L380 140 L380 100 L430 100 L430 72 L560 72 L560 100 L620 100 L620 140 L690 140\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M70 210 L140 206 L190 196 L230 170 L260 130 L290 100 L330 86 L380 82 L430 90 L480 120 L520 160 L560 190 L620 204 L690 208\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"600\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">capacidade</text><text x=\"640\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\" font-weight=\"600\">carga</text><path d=\"M236 172 L236 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"236\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">alarme dispara</text><path d=\"M320 52 L320 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M238 236 L318 236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-start=\"url(#lag-ah)\" marker-end=\"url(#lag-ah)\"></path><text x=\"244\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">boot + user data + verificação</text><text x=\"324\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instância nova atendendo</text><text x=\"84\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">carga acima da capacidade</text><path d=\"M150 130 L262 164\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lag-ah)\"></path><text x=\"700\" y=\"16\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-style=\"italic\">forma ilustrativa, carga inventada</text></svg>", "caption": "Um desenho da forma, não uma medição: a carga é inventada. A capacidade sobe em instâncias inteiras, e cada degrau chega minutos depois do alarme que o pediu, porque uma instância nova precisa dar boot, rodar o user data e passar na verificação de saúde. A cunha sombreada é o tempo em que as instâncias que já existem carregam mais do que foram dimensionadas para carregar."}
```

Durante esses minutos as instâncias que já estão rodando carregam a carga extra sozinhas. É para isso
que serve o alvo de 50%: **a folga é o que absorve o atraso**. Um grupo que acompanha a CPU em 90% é
eficiente até o primeiro pico, e então toda instância fica saturada durante todo o tempo que os
reforços levam para dar boot. Folga custa dinheiro toda hora; a falta dela custa os minutos da cunha
sombreada, e são esses os minutos que os usuários percebem.

Três coisas encurtam a cunha, e nenhuma a elimina:

- um boot mais rápido: uma imagem embutida, um user data mais leve;
- uma métrica que se move antes: a contagem de requisições sobe antes da CPU;
- um agendamento para a carga que dá para prever: a subida de segunda de manhã que acontece toda
  segunda.

A AWS também oferece predictive scaling, que prevê os próximos dias a partir das semanas anteriores e
escala antes da previsão. É um agendamento escrito por um modelo, e ajuda exatamente na medida em que
a carga se repete.

## Descer é mais lento de propósito

Os grupos tiram instâncias com mais cautela do que acrescentam. Tirar cedo demais e acrescentar de
novo poucos minutos depois se chama **flapping**, e cada volta paga um boot e um aquecimento que não
atenderam ninguém. As políticas esperam mais, e olham uma janela mais longa, antes de reduzir. O
desenho mostra isso: a capacidade sobe o mais rápido que consegue e desce mais tarde.

Reduzir também quer dizer que uma instância é encerrada enquanto pode estar atendendo alguém. O
balanceador para de mandar requisições novas para ela e dá tempo para as que estão em andamento
terminarem antes de ela sair. O que ela guardava e não estava em outro lugar se perde, e é aí que
começa a próxima seção.
