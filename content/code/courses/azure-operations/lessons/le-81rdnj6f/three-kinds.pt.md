---
title: Métricas, logs e o activity log
version: 1
---

**O Azure Monitor não é um repositório; são vários, e eles se enchem de jeitos diferentes.** Errar isso é como uma
equipe descobre, no primeiro incidente, que os logs que queria nunca foram guardados.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Três tipos de sinal. Métricas de plataforma fluem de todo recurso para o repositório de métricas automaticamente, guardadas por 93 dias. Logs de recurso são produzidos por todo recurso e descartados a menos que um diagnostic setting os encaminhe para um workspace do Log Analytics, uma conta de armazenamento ou um event hub. O activity log registra operações do plano de controle na assinatura, guardadas por 90 dias, e também pode ser encaminhado ao workspace. Dados de dentro de uma máquina virtual chegam ao workspace pelo Azure Monitor Agent e por uma data collection rule.\"><defs><marker id=\"ah-three\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"170\" height=\"220\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"105\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">um recurso</text><text x=\"105\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">métricas de plataforma</text><text x=\"105\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">logs de recurso</text><text x=\"105\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">activity log</text><text x=\"105\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dentro de uma VM</text><rect x=\"500\" y=\"70\" width=\"200\" height=\"40\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">métricas, 93 dias</text><rect x=\"500\" y=\"160\" width=\"200\" height=\"50\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">workspace do Log Analytics</text><path d=\"M190 90 L498 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-three)\"></path><text x=\"345\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">automático</text><path d=\"M190 140 L498 172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-three)\"></path><text x=\"330\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">diagnostic setting</text><path d=\"M190 190 L498 185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-three)\"></path><text x=\"330\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">diagnostic setting</text><path d=\"M190 230 L498 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-three)\"></path><text x=\"345\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">agente + data collection rule</text><text x=\"345\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">senão, descartados</text></svg>", "caption": "As métricas chegam sozinhas. Os logs só chegam aonde algo os encaminha."}
```

**Métricas de plataforma** são números que todo recurso emite sozinho: as requisições e o tempo de resposta de um
App Service, as transações de uma conta de armazenamento, a CPU de uma VM do ponto de vista do host. Elas são
coletadas sem nada para configurar, com granularidade de um minuto na maioria dos recursos, e guardadas por **93
dias**. São baratas de guardar e rápidas de consultar, e respondem "quanto" e "quão rápido", nunca "qual
requisição".

**Logs de recurso** são o registro detalhado do que um recurso fez: cada requisição HTTP que um App Service atendeu,
cada consulta que um banco rodou. Todo recurso os produz, e **o Azure os descarta a menos que um diagnostic setting
os encaminhe para algum lugar**: um workspace do Log Analytics para consultar, uma conta de armazenamento para
guardar barato, um event hub para transmitir a outro sistema. Nada é encaminhado por padrão, e nada encaminhado antes
de a configuração existir pode ser recuperado.

O **activity log** é o registro da assinatura das operações do plano de controle: quem criou, mudou ou apagou o quê,
pelo Resource Manager. O Azure o guarda por **90 dias** sem pedir; encaminhá-lo a um workspace o guarda por mais
tempo e o deixa consultável ao lado de todo o resto, e a lição 21 depende disso.

O que acontece **dentro** de uma máquina virtual, os contadores do próprio sistema e o log dele, não é nenhum destes.
É coletado pelo **Azure Monitor Agent** rodando na VM, instruído sobre o que coletar por uma **data collection rule**.
A última seção desta lição escreve uma.

Os quatro acabam, quando encaminhados, no mesmo lugar: um **workspace do Log Analytics**, onde viram tabelas que você
consulta em KQL. A lição 9 é sobre o workspace e o que ele custa; a lição 10 é sobre a linguagem.
