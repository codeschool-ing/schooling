---
title: O que é o Defender for Cloud, e o que é gratuito
version: 1
---

**O Defender for Cloud faz dois trabalhos que vale manter separados.** Um é **postura**: ele lê como os seus recursos estão
configurados e compara com um padrão, recomendando mudanças, antes de qualquer coisa acontecer. O outro é **proteção de
carga de trabalho**: ele observa recursos enquanto rodam e levanta **alertas** quando algo parece um ataque. O primeiro é
sobre portas deixadas abertas; o segundo, sobre alguém passando por uma.

O **CSPM básico** (Foundational CSPM), a metade de postura no nível básico, vem ligado em toda assinatura e não custa nada:
ele avalia os recursos contra o **Microsoft cloud security benchmark**, produz recomendações e calcula a **secure score**.
Todo o resto é plano pago, cobrado por recurso protegido, e ligado por assinatura e por tipo de recurso:

| plano | o que acrescenta |
|---|---|
| **Defender CSPM** | análise de caminhos de ataque, um grafo de segurança consultável, varredura sem agente de VMs e contêineres |
| Defender for Servers | detecção de ameaças e avaliação de vulnerabilidades em VMs |
| Defender for App Service, SQL, Storage | alertas de uso suspeito de cada serviço |
| Defender for Key Vault | alertas de acesso incomum a segredos e chaves |
| Defender for Containers | postura e proteção em execução para AKS e registros |

Este curso não tem assinatura, então **nada do Defender foi executado**: nenhuma recomendação, pontuação ou alerta desta lição
veio do Defender, e os exemplos são escritos pelo curso e dizem isso. O que dá para praticar sem ele é o raciocínio: como uma
pontuação é calculada, e qual recomendação vem primeiro.

Ligar todo plano em todo lugar é a decisão fácil e uma cara. A loja liga o Defender nos serviços que guardam dados e dão para
a internet, App Service, SQL e Key Vault, só em produção, e deixa desenvolvimento na faixa gratuita. A lição 22 tem o hábito
de pôr preço numa decisão dessas antes de tomá-la.
