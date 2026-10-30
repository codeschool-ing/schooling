---
title: Os dois planos pagos, e o que acrescentam
version: 1
---

**A Azure DDoS Protection tem dois níveis pagos**, e eles diferem no que se prendem e em como são cobrados, não muito no que
detectam:

| | **DDoS Network Protection** | **DDoS IP Protection** |
|---|---|---|
| preso a | um **plano de proteção DDoS**, ligado a redes virtuais; todo IP público nelas fica coberto | cada IP público, um a um |
| cobrado | uma taxa mensal fixa pelo plano, cobrindo um número definido de IPs públicos, mais um valor por IP a mais | por IP protegido, por mês |
| equipe de resposta rápida e proteção de custo | incluídas | não incluídas |

O que os dois acrescentam sobre a proteção de infraestrutura gratuita:

- **ajuste adaptativo**: limites aprendidos com o seu próprio tráfego, para um ataque ser detectado no volume que machuca *você*;
- **telemetria e alertas**: métricas como *sob ataque DDoS ou não* por IP público, e relatórios de mitigação e logs de fluxo por
  diagnostic settings, que os alertas da lição 12 conseguem observar;
- com o Network Protection, a **resposta rápida a DDoS**, a equipe da Microsoft para chamar durante um ataque em curso, e a
  **proteção de custo**, um crédito pelos custos de escala que um ataque causou.

Nada disso pode ser ligado sem uma assinatura, então **nada nesta lição foi executado**. O plano é um recurso e uma propriedade
em cada rede virtual, o tipo de Bicep que as lições anteriores compilaram; escrevê-lo aqui não acrescentaria nada, e a decisão é
a parte interessante.
