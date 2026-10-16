---
title: Três perguntas antes de uma promoção
version: 1
---

**Failover** é tornar um standby o primário porque o primário falhou. O comando que faz isso leva
um segundo. A decisão antes dele é toda a habilidade, e ela se resume a três perguntas, nesta
ordem:

1. **O primário se foi mesmo?** "Não consigo alcançá-lo" é um fato sobre o caminho entre você e o
   primário, não sobre o primário. Um servidor que está vivo e isolado de você continua aceitando
   escritas de quem ainda consegue alcançá-lo, e promover um standby nessa hora cria dois primários.
2. **Quanto o standby tem?** A distância entre a posição dele e a última que se sabe que o primário
   alcançou é o dado que uma promoção perde, e o RPO da lição 8 diz se isso é aceitável ou se vale a pena esperar o
   primário voltar.
3. **Alguma coisa vai promover uma segunda vez?** Outro standby, outra pessoa, um script: uma vez que
   um standby é o primário, todo outro caminho para uma promoção tem que ser fechado, e o primário
   antigo tem que ser impedido de voltar como primário.

**Switchover** é a versão planejada: o primário está saudável, e você passa o papel dele para um
standby de propósito, para uma manutenção ou um teste. Ele responde às três perguntas por construção,
e é por isso que é o jeito certo de ensaiar; as últimas seções desta lição fazem um.

Esta lição faz os dois **à mão**, no par da lição 11: o primário na 5432 e o `standby1` na 5434.
Um programa que responde às três perguntas sozinho é o assunto da lição 16, e o que acontece quando
ele erra a resposta da primeira é a lição 17.
