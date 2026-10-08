---
title: Por quanto tempo guardar um log
version: 1
---

A pergunta parece técnica e não é. **Por quanto tempo um log fica guardado é decidido por três coisas**:
o que a lei e os contratos exigem no mínimo, o que uma investigação precisa, e o que a lei de privacidade
permite no máximo. O disco é a última restrição, e a aula 1 mediu como as fontes pequenas são baratas.

**O piso vem da lei e dos contratos.** No Brasil, o **Marco Civil da Internet** (Lei 12.965/2014) fixa
dois: um provedor de conexão guarda os registros de conexão por **um ano** (art. 13), e um provedor de
aplicações que atua como empresa guarda os registros de acesso a aplicações por **seis meses** (art. 15).
O padrão **PCI DSS**, que vincula quem lida com cartões de pagamento, pede **doze meses** de logs de
auditoria, os três mais recentes disponíveis de imediato. Um regulador setorial, um contrato com cliente
ou uma apólice de seguro podem acrescentar os seus.

**A necessidade vem de quão tarde os problemas são descobertos.** Um comprometimento descoberto em março
que começou em novembro é invisível num log guardado por sessenta dias, e a pergunta "quando começou" fica
sem resposta. Investigações voltam semanas ou meses no tempo, então o período útil é mais longo do que a
maioria dos primeiros palpites.

**O teto vem da lei de privacidade.** Um log cheio de endereços e nomes de conta é dado pessoal. A
**LGPD** não fixa número para logs, mas o princípio da **necessidade** (art. 6º) e o dever de eliminar os
dados quando acaba a finalidade (art. 16) fazem de guardar tudo para sempre uma decisão que alguém precisa
justificar. Uma política de retenção diz as duas pontas, e o motivo de cada uma.

A resposta de costume são dois níveis, desenhados aqui para uma empresa que é provedora de aplicação e
também aceita pagamento com cartão:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Um plano de retenção desenhado como duas faixas num eixo de treze meses. Quente: os três primeiros meses, pesquisáveis no SIEM. Morno: do mês 4 ao 13, arquivos comprimidos que podem ser carregados de volta. Apagado depois disso. Dois pisos legais estão marcados: seis meses para um provedor de aplicação pelo Marco Civil da Internet, e doze meses pelo PCI DSS.\"><rect x=\"30\" y=\"60\" width=\"152.3076923076923\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"106.15384615384615\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">quente</text><text x=\"106.15384615384615\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pesquisável</text><rect x=\"182.3076923076923\" y=\"60\" width=\"507.6923076923077\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"436.15384615384613\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">morno: comprimido, restaurável</text><text x=\"436.15384615384613\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lido só quando pedido</text><path d=\"M30 130 L690 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M30.0 126 L30.0 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"30.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M182.3076923076923 126 L182.3076923076923 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"182.3076923076923\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><path d=\"M334.6153846153846 126 L334.6153846153846 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"334.6153846153846\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><path d=\"M639.2307692307692 126 L639.2307692307692 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"639.2307692307692\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12</text><path d=\"M690.0 126 L690.0 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13</text><text x=\"690\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">meses</text><path d=\"M334.6153846153846 40 L334.6153846153846 60\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"334.6153846153846\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Marco Civil, art. 15: 6 meses</text><path d=\"M639.2307692307692 106 L639.2307692307692 186\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"633.2307692307692\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">PCI DSS: 12 meses</text><text x=\"690\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois, apagado</text></svg>", "caption": "Um plano tem um piso posto pela lei e pelos contratos, e um teto posto pelo princípio da necessidade."}
```

O armazenamento **quente** é o próprio SIEM: rápido de pesquisar, caro por gigabyte, três meses. O
**morno** são arquivos comprimidos em discos mais baratos ou num armazenamento de objetos: lento para
carregar de volta, mas está lá. O que passa do teto é apagado, e a eliminação também fica registrada.
Anote, por fonte, em que nível ela mora e por quanto tempo; uma política que diz "os logs são guardados
por um ano" sem dizer quais logs é uma política que ninguém consegue conferir.
