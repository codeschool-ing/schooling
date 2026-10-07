---
title: SOC 2, lido do lado do cliente
version: 1
---

Um relatório SOC 2 é uma **asseguração**: uma firma independente de CPAs examina os controles de uma
organização de serviços contra os Trust Services Criteria do AICPA e escreve uma opinião. Não é um
certificado e não tem nota de aprovação. É um documento longo escrito para os clientes da
organização, e a Vereda é uma das clientes do gateway.

A maioria das empresas do tamanho da Vereda nunca encomenda um. Elas os recebem, de todo fornecedor
cujo sistema guarda ou move os seus dados, e **ler um é a habilidade de modelagem de ameaças**: o
relatório de um fornecedor é uma descrição do que acontece do outro lado de uma fronteira de
confiança no seu próprio diagrama.

### O que ele cobre

Os critérios vêm em cinco categorias. **Segurança** é sempre incluída, e os seus critérios, os
critérios comuns, são numerados de CC1 a CC9: o CC6, por exemplo, é acesso lógico e físico, onde um
segundo fator seria testado. **Disponibilidade, integridade de processamento, confidencialidade e
privacidade** entram quando a organização escolhe. O relatório do gateway cobre segurança e
disponibilidade, então nada nele foi examinado quanto a confidencialidade ou privacidade.

Há dois tipos, e a diferença é a que importa:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l13-soc2-period\" aria-label=\"Dois tipos de relatório SOC 2 numa linha do tempo. Um relatório Tipo I olha o desenho dos controles numa única data. Um relatório Tipo II testa se eles funcionaram ao longo de um período: o do gateway cobre de 1º de julho de 2025 a 30 de junho de 2026, e foi entregue em agosto de 2026. Os meses depois do período são cobertos só pela carta-ponte do próprio gateway, que nenhum auditor testou.\"><path d=\"M60.0 160.0 L680.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M128.9 160.0 L128.9 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"128.9\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">jul 2025</text><path d=\"M232.2 160.0 L232.2 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"232.2\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">out 2025</text><path d=\"M335.6 160.0 L335.6 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"335.6\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">jan 2026</text><path d=\"M438.9 160.0 L438.9 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"438.9\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">abr 2026</text><path d=\"M542.2 160.0 L542.2 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"542.2\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">jul 2026</text><path d=\"M645.6 160.0 L645.6 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"645.6\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">out 2026</text><circle cx=\"128.9\" cy=\"45.0\" r=\"6\" fill=\"var(--paper-dim)\"></circle><text x=\"140.9\" y=\"45.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Tipo I: o desenho, numa data</text><rect x=\"128.9\" y=\"80.0\" width=\"413.3\" height=\"20.0\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"136.9\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Tipo II: testado ao longo de doze meses</text><rect x=\"542.2\" y=\"80.0\" width=\"103.3\" height=\"20.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"546.2\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">carta-ponte: só a palavra do gateway</text><circle cx=\"576.7\" cy=\"140.0\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"566.7\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">relatório entregue</text></svg>", "caption": "Um relatório Tipo II diz que os controles funcionaram durante o período dele, e não diz nada sobre os meses desde então."}
```

- Um relatório **Tipo I** diz que os controles estavam adequadamente desenhados numa data. Ninguém os
  viu funcionar.
- Um relatório **Tipo II** também testa se eles **funcionaram de fato ao longo de um período**,
  normalmente de seis a doze meses, por amostragem: tantas revisões de acesso, tantas mudanças, tantos
  incidentes.

O relatório do gateway é Tipo II, de 1º de julho de 2025 a 30 de junho de 2026. Chegou à carla em
agosto. Para os meses desde então, o gateway mandou uma **carta-ponte**, uma declaração dele mesmo de
que nada relevante mudou. Nenhum auditor testou essa carta, e ela deve ser lida como o que é.

### Cinco coisas para ler, nesta ordem

O gateway e o relatório dele são inventados para este curso, e os trechos descritos abaixo são
ilustrativos, não citações de um relatório real.

1. **A opinião.** Uma opinião sem ressalvas diz que a descrição é fiel e que os controles foram
   desenhados, e no Tipo II funcionaram, como descrito. Uma opinião com ressalvas nomeia onde não
   foram, e esse parágrafo é o mais importante do relatório.
2. **A descrição do sistema.** Quais serviços estão no escopo. A do gateway cobre o processamento de
   cartão e Pix e a entrega de webhooks, que é a parte de que a Vereda depende. Um relatório que
   cobrisse só o processamento de cartão não diria nada sobre a T01.
3. **As organizações subcontratadas.** O gateway roda num provedor de nuvem e o **exclui** (o
   chamado carve-out): os controles do provedor ficam de fora, e o relatório os presume. A Vereda
   precisaria do relatório do próprio provedor para fechar essa lacuna.
4. **As exceções.** A seção 4 lista cada teste e o resultado. A do gateway tem uma exceção: em duas de
   25 revisões de acesso amostradas, a conta de alguém que saiu foi removida com atraso. Isso não é
   uma falha do relatório; é informação.
5. **Os controles complementares da entidade usuária.** Esta é a parte escrita para a Vereda.

### Metade de um controle

Os controles de uma organização de serviços muitas vezes só funcionam se o cliente fizer a sua parte,
e o relatório lista essas partes como **controles complementares da entidade usuária**, os CUECs. O
do gateway tem três que tocam o portal da Vereda:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l13-cuec\" aria-label=\"Os controles do gateway e os que o relatório dele espera dos clientes, dos dois lados da fronteira de confiança entre a Vereda e o gateway. O gateway assina todo webhook que manda, protege a sua API e guarda as suas chaves; o auditor dele testou isso. O relatório então lista o que os clientes precisam fazer para isso protegê-los: verificar a assinatura do webhook, que é o R01 e o controle C3 da Vereda; manter a chave da API em segredo; e revisar quem pode usar o painel do gateway. Os dois últimos não têm requisito no modelo da Vereda.\"><defs><marker id=\"l13-cuec-tm-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"180.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o gateway: testado pelo auditor dele</text><text x=\"540.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Vereda: controles complementares</text><rect x=\"40.0\" y=\"50.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">assina todo webhook que manda</text><rect x=\"40.0\" y=\"110.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">limita e registra a sua API</text><rect x=\"40.0\" y=\"170.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">troca as suas chaves de assinatura</text><rect x=\"400.0\" y=\"50.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"414.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">verifica a assinatura</text><text x=\"668.0\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R01 · C3</text><rect x=\"400.0\" y=\"110.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"414.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">guarda a chave da API em segredo</text><text x=\"668.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">sem requisito</text><rect x=\"400.0\" y=\"170.0\" width=\"280.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"414.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">revisa quem usa o painel</text><text x=\"668.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">sem requisito</text><path d=\"M360.0 40.0 L360.0 230.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"366.0\" y=\"244.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">fronteira de confiança</text><path d=\"M320.0 70.0 L400.0 70.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-cuec-tm-ah-phosphor)\"></path></svg>", "caption": "Um relatório SOC 2 é metade de um controle. A outra metade está listada nele como trabalho do cliente, e só o cliente pode conferir se está feita."}
```

Postos ao lado do modelo, eles são um mapeamento no sentido contrário. O primeiro, **verificar a
assinatura do webhook**, é o R01 e o controle C3: o gateway assina todo webhook, o auditor dele testou
isso, e nada disso protege a Vereda até o portal conferir a assinatura. **O C3 está na fase 2 do
plano.** Até ele sair, o controle testado do gateway é metade de um controle.

Os outros dois não têm requisito nenhum no modelo. Manter em segredo a chave da API do gateway, e
revisar quem da equipe pode entrar no painel do gateway, tratam de um elemento que o DFD desenhou como
uma entidade externa e nunca olhou por dentro. São perguntas novas, achadas lendo o relatório de um
fornecedor contra uma fronteira de confiança, e a aula 15 as acrescenta ao modelo como a primeira
coisa que acontece quando ele é mantido vivo.
