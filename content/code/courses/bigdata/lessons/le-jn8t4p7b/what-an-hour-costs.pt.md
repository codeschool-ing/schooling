---
title: Quanto custa uma hora de cluster
version: 1
---

**Um cluster é cobrado pelo tempo em que as suas máquinas existem, ocupadas ou não.** Todo preço da
lista de um provedor de nuvem é alguma versão de *máquinas × horas × preço por hora de máquina*, mais
armazenamento por gigabyte-mês e rede por gigabyte. Os preços variam por provedor, região, tipo de
máquina e ano, e mudam; então esta seção usa **um único preço suposto do começo ao fim, US$ 0,20 por
hora para uma máquina de 4 cores e 16 GB**, um número redondo da ordem certa para uma máquina comum sob
demanda. Antes de decidir qualquer coisa de verdade, troque-o pelo preço da lista do seu provedor.

**O relatório, com preço.** Suponha que a versão de produção dele roda num cluster de 10 máquinas
assim, e que, como a do laboratório, a versão lenta leva oito vezes o tempo da ajustada:

| | execuções | horas de máquina por dia | um mês a US$ 0,20 |
|---|---|---|---|
| ajustado, 10 minutos por manhã | uma por dia | 10 × 1/6 = 1,7 | US$ 10 |
| lento, 80 minutos por manhã | uma por dia | 10 × 8/6 = 13,3 | US$ 80 |

**Setenta dólares por mês não são o motivo de o relatório ter sido consertado**; os analistas
esperando mais de uma hora toda manhã eram. O ajuste paga em dinheiro quando o job é grande ou frequente: o
mesmo fator de oito num job de 200 máquinas que roda de hora em hora é a diferença entre US$ 4.800 e
US$ 38.400 por mês.

**O cluster que nunca é desligado é o custo maior.** As mesmas 10 máquinas mantidas ligadas para o
relatório da manhã, todas as horas de um mês de 30 dias:

| | horas de máquina por mês | a US$ 0,20 |
|---|---|---|
| um cluster que só existe enquanto o relatório ajustado roda | 10 × 1/6 × 30 = 50 | US$ 10 |
| o mesmo cluster, sempre ligado | 10 × 24 × 30 = 7.200 | US$ 1.440 |

**É isso que o object storage da aula 3 tornou possível.** Quando os dados moram num object store, um
cluster pode ser criado para um job e apagado depois, e nada se perde, porque nada estava nele. O HDFS
nos discos do próprio cluster impede isso: o cluster é o armazenamento, então fica ligado. O
armazenamento ainda custa dinheiro, por gigabyte-mês, mas um terabyte guardado num object store custa
uma pequena fração de um cluster mantido ligado para guardá-lo. Os serviços gerenciados, aula 13,
iniciam um cluster em poucos minutos, e esses minutos também são cobrados: para um job de dez minutos,
três minutos a mais de partida são quase um terço a mais.

**E uma aplicação que segura o que não usa é o mesmo desperdício em escala menor**, a alocação dinâmica
da aula 2. Uma sessão de notebook que mantém 10 executores por um dia de trabalho de 8 horas e calcula
durante uma delas segura 70 horas de executor ociosas por dia; a um quarto de máquina cada, US$ 0,05 por
hora, são US$ 3,50 por dia para uma pessoa, e uma equipe de vinte paga isso todo dia útil. A medição da
aula 13, executores liberados meio minuto depois de o trabalho parar, é esse custo removido.
