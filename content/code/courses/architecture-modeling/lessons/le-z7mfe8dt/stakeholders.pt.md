---
title: Stakeholders, incluindo os que ninguém convidou
version: 1
---

**Stakeholder é qualquer pessoa ou grupo com relação com a mudança, a necessidade ou a solução**, e
os erros caros em requisitos costumam vir do stakeholder que ninguém pensou em consultar. O BABOK
trata a identificação deles como uma tarefa própria, e não como uma lista de presença.

## Encontrando-os

Comece pelos óbvios e então pergunte, para cada um, *de quem mais essa pessoa depende, ou quem ela
afeta?* Para a conciliação:

- **Joana**, que faz a conferência hoje: a pessoa a quem a mudança devolve os dois dias.
- **O diretor financeiro**, que assina o fechamento mensal e aprova a mudança.
- **O time de Pagamentos**, dono da integração com o gateway que o job vai ler.
- **Os auditores externos**, que examinam amostras da conciliação a cada trimestre.
- **A empresa de pagamento**, cujos arquivos de liquidação são a entrada, e que pode mudar o formato
  deles.
- **Os agentes de guichê**, que reembolsam em dinheiro no balcão: encontrados ao perguntar a Joana o
  que causa as divergências que ela não consegue explicar.
- **A Plataforma**, que vai operar o job e ser acionada quando ele falhar.

Os dois últimos não estavam na primeira reunião. **Cada um deles poderia ter impedido a solução de
funcionar**: sem os agentes, os reembolsos em dinheiro continuam invisíveis; sem a Plataforma, um
job noturno que ninguém sabe operar é um incidente novo à espera.

## Mapeando-os

Um **mapa de stakeholders** posiciona cada stakeholder em dois eixos, a influência sobre a mudança e
o interesse nela, e sugere como engajar cada quadrante:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l07-stakeholder-map\" aria-label=\"Um mapa de stakeholders da conciliação, com influência no eixo vertical e interesse no horizontal. Muita influência e muito interesse, gerenciar de perto: o diretor financeiro. Muita influência, pouco interesse, manter satisfeito: o tech lead de Pagamentos e a Plataforma. Pouca influência, muito interesse, manter informado: Joana e os agentes de guichê. Pouca influência, pouco interesse, monitorar: a empresa de pagamento. Os auditores externos ficam entre os dois quadrantes de cima.\"><rect x=\"110.0\" y=\"20.0\" width=\"580.0\" height=\"280.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M400.0 20.0 L400.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M110.0 160.0 L690.0 160.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"120.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">manter satisfeito</text><text x=\"410.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">gerenciar de perto</text><text x=\"120.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">monitorar</text><text x=\"410.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">manter informado</text><text x=\"60.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">influência</text><text x=\"60.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">alta</text><text x=\"60.0\" y=\"294.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">baixa</text><text x=\"400.0\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">interesse →</text><circle cx=\"532.0\" cy=\"70.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"540.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Diretor financeiro</text><circle cx=\"192.0\" cy=\"70.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"200.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Tech lead de Pagamentos</text><circle cx=\"192.0\" cy=\"112.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"200.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Plataforma</text><circle cx=\"362.0\" cy=\"50.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"370.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Auditores externos</text><circle cx=\"502.0\" cy=\"210.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"510.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Joana</text><circle cx=\"522.0\" cy=\"250.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"530.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Agentes de guichê</text><circle cx=\"172.0\" cy=\"230.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"180.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Empresa de pagamento</text></svg>", "caption": "O quadrante diz como engajar, não quanto alguém importa. Os agentes de guichê têm pouca influência sobre o projeto e são essenciais para os requisitos dele.", "same": ["Joana"]}
```

- **muita influência, muito interesse**: gerenciar de perto; eles decidem e se importam. O diretor
  financeiro.
- **muita influência, pouco interesse**: manter satisfeito; podem bloquear se forem pegos de
  surpresa. O tech lead de Pagamentos.
- **pouca influência, muito interesse**: manter informado; vão conviver com o resultado. Joana e os
  agentes.
- **pouca influência, pouco interesse**: monitorar. A empresa de pagamento, por enquanto.

O quadrante não é um julgamento sobre a pessoa. Os agentes de guichê têm pouca influência sobre o
projeto e são essenciais para os requisitos dele; o mapa diz como engajá-los, que é ir até eles e
conversar, porque eles não vão aparecer no workshop.

## Quem decide

A última pergunta é sobre decisões, não sobre informação: **quem aprova os requisitos, quem é
consultado, quem só é informado?** Uma tabela **RACI** responde, dizendo para cada decisão quem é
*Responsável* (*Responsible*) por executá-la, quem é *Accountable* (quem responde pelo resultado),
quem é *Consultado* (*Consulted*) e quem é *Informado* (*Informed*). Uma regra faz a tabela
funcionar: **exatamente um A por linha**. Um requisito que duas pessoas podem aprovar é um requisito
que não tem dono.
