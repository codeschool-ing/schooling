---
title: Certificação
version: 1
---

Uma organização não se certifica sozinha. Um **organismo de certificação**, acreditado para a 27001 por
um organismo nacional de acreditação (no Brasil, a Coordenação Geral de Acreditação do Inmetro, a
Cgcre), audita o SGSI e, se ele estiver conforme, emite um certificado. O processo tem uma forma padrão:

```schooling-figure
{"svg": "<svg id=\"sf-cert-cycle\" viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"O ciclo de certificação em três anos. Antes do certificado: estágio 1, documentação, depois estágio 2, implementação. Ano 1 e ano 2: uma auditoria de manutenção em cada. Ano 3: recertificação, e um novo ciclo começa.\"><defs><marker id=\"sf-cert-cycle-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M20 90 L700 90\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sf-cert-cycle-ah-paper-dim)\"></path><circle cx=\"70\" cy=\"90\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></circle><text x=\"70\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">estágio 1</text><text x=\"70\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">documentos</text><circle cx=\"190\" cy=\"90\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"190\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">estágio 2</text><text x=\"190\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">certificado</text><circle cx=\"340\" cy=\"90\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></circle><text x=\"340\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ano 1</text><text x=\"340\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">manutenção</text><circle cx=\"490\" cy=\"90\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></circle><text x=\"490\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ano 2</text><text x=\"490\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">manutenção</text><circle cx=\"640\" cy=\"90\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"640\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">ano 3</text><text x=\"640\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">recertificação</text><text x=\"415\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">um certificado de três anos</text><path d=\"M190 140 L640 140\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "Válido por três anos, visitado todo ano."}
```

| etapa | o que é examinado | resultado típico |
|---|---|---|
| **estágio 1** | a documentação e a prontidão: escopo, política, método de risco, SoA, se o SGSI está pronto para ser auditado | uma lista do que corrigir antes do estágio 2 |
| **estágio 2** | se o SGSI de fato funciona: entrevistas, amostras, evidência de que os controles operam e de que o ciclo das cláusulas 9 e 10 gira | constatações; certificação se não houver não conformidade maior aberta |
| **auditorias de manutenção** | todo ano, uma amostra do SGSI, sempre incluindo o ciclo de melhoria | o certificado é mantido, ou suspenso |
| **recertificação** | no terceiro ano, uma auditoria mais completa do SGSI inteiro | um novo certificado de três anos |

Então um certificado **vale por três anos e é visitado todo ano**. Esse ritmo é a ideia de sistema de
gestão da seção 03 na prática: o certificado é evidência de que o ciclo continua girando, e não de que a
organização acertou num dia.

### O que custa a uma loja pequena

A certificação exige um esforço que cresce menos que proporcionalmente ao tamanho. Uma loja de nove
pessoas ainda precisa de escopo, política, avaliação de riscos, SoA, registros, auditoria interna e
análise crítica pela direção. Boa parte disso este curso já produziu, mas transformar em um SGSI coerente
leva meses, e as auditorias em si custam dinheiro todo ano.

O conselho honesto para uma organização do tamanho da loja tem dois passos. Primeiro, **use a 27001 e a
27002 sem se certificar**: as cláusulas como roteiro para tocar a segurança direito, o Anexo A como
catálogo para conferir os controles. Isso captura a maior parte do valor. Segundo, certifique-se **quando
alguém precisar do certificado**: o contrato de um cliente, uma licitação, um mercado que espera isso. Aí
o escopo deveria ser a parte da loja com que aquele cliente se importa, e não maior.

### Lendo o certificado de outra empresa

Três coisas a conferir quando um fornecedor manda um: que o **escopo** cobre o serviço que você está
comprando; que o certificado está **em vigor** (as datas de emissão e validade, e que é contra a edição
de 2022); e que o organismo de certificação é **acreditado**. Essa última se confere junto ao organismo de
acreditação que o nomeia. Um certificado de um organismo não acreditado é um documento, e não uma
garantia.
