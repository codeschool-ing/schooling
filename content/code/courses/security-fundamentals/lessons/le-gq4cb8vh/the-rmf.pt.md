---
title: O Risk Management Framework
version: 1
---

O segundo documento do NIST é de outra natureza. O **Risk Management Framework (RMF)**, descrito no
**NIST SP 800-37** (revisão 2, de dezembro de 2018), é um processo passo a passo para gerir o risco de
segurança e de privacidade de **um sistema de informação** pela vida inteira dele. Ele é obrigatório para
órgãos federais dos Estados Unidos e seus contratados, e muito aproveitado em outros lugares pela
estrutura.

Ele tem **sete passos**:

```schooling-figure
{"svg": "<svg id=\"sf-rmf-steps\" viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Os sete passos do Risk Management Framework do NIST. Preparar vem primeiro. Depois um ciclo: categorizar, selecionar, implementar, avaliar, autorizar e monitorar, com monitorar voltando a categorizar quando o sistema ou os riscos dele mudam.\"><defs><marker id=\"sf-rmf-steps-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">preparar</text><rect x=\"160\" y=\"30\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">categorizar</text><rect x=\"330\" y=\"30\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">selecionar</text><rect x=\"500\" y=\"30\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"565.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">implementar</text><rect x=\"500\" y=\"150\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"565.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">avaliar</text><rect x=\"330\" y=\"150\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">autorizar</text><rect x=\"160\" y=\"150\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">monitorar</text><path d=\"M120 110 L225 70\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-rmf-steps-ah-wire)\"></path><path d=\"M290 50 L330 50\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-rmf-steps-ah-wire)\"></path><path d=\"M460 50 L500 50\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-rmf-steps-ah-wire)\"></path><path d=\"M565 70 L565 150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-rmf-steps-ah-wire)\"></path><path d=\"M500 170 L460 170\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-rmf-steps-ah-wire)\"></path><path d=\"M330 170 L290 170\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-rmf-steps-ah-wire)\"></path><path d=\"M225 150 L225 70\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#sf-rmf-steps-ah-wire)\"></path><text x=\"235\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quando algo muda</text></svg>", "caption": "Preparar uma vez; depois o ciclo roda pela vida toda do sistema."}
```

| passo | o que acontece | o portal da loja, se fosse tocado assim |
|---|---|---|
| **Preparar** (*Prepare*) | montar o contexto: papéis, estratégia de risco, controles comuns | o apetite dos sócios; quem é a autoridade que autoriza |
| **Categorizar** (*Categorize*) | classificar o sistema pelo impacto de perder confidencialidade, integridade e disponibilidade | holerites: impacto alto em confidencialidade, moderado em integridade, baixo em disponibilidade |
| **Selecionar** (*Select*) | escolher os controles que a categorização pede, e ajustá-los | login com MFA, verificação de permissão, log, segmentação |
| **Implementar** (*Implement*) | pôr os controles no lugar e documentar como | as aulas 5 a 9, por escrito |
| **Avaliar** (*Assess*) | testar que os controles funcionam como pretendido | os testes de laboratório das aulas 4, 7 e 8; um exercício roxo |
| **Autorizar** (*Authorize*) | uma autoridade sênior aceita o risco que sobra e permite que o sistema rode | o bruno, como dono do risco, assina |
| **Monitorar** (*Monitor*) | continuar vigiando os controles e o risco, e reavaliar quando as coisas mudam | o log e os alertas; revisão quando o portal muda |

Dois passos merecem atenção.

**Categorizar** é a tríade da aula 1, formalizada. O RMF usa uma norma chamada FIPS 199 para classificar
confidencialidade, integridade e disponibilidade como impacto baixo, moderado ou alto, e o mais alto dos
três define quão exigentes os controles precisam ser. O ponto é que os controles saem do que o sistema
guarda, e não de um checklist genérico.

**Autorizar** é a aceitação da aula 3, formalizada. Uma pessoa sênior nomeada, a **autoridade que
autoriza** (*authorizing official*), analisa a avaliação e o risco residual e assina uma **autorização
para operar**. Sem ela, o sistema não pode ir para produção. Isso põe a decisão exatamente onde a aula 3
a pôs: com quem é dono do risco, e não com os engenheiros que montaram o sistema.

### Os controles de onde o RMF escolhe

O passo **Selecionar** usa o **NIST SP 800-53**, o catálogo de controles de segurança e privacidade do
NIST, organizado em vinte famílias (controle de acesso, auditoria e responsabilização, resposta a
incidentes e assim por diante). Ele é muito mais detalhado que o Anexo A da ISO 27001 e é escrito para
sistemas federais dos Estados Unidos; fora desse mundo é usado sobretudo como biblioteca de referência
quando um controle precisa ser especificado em detalhe.
