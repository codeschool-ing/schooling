---
title: Um sistema de gestão, não um checklist
version: 1
---

A ideia no centro da 27001 é o **sistema de gestão de segurança da informação (SGSI)**, em inglês
*ISMS*: o jeito da organização de decidir, fazer, conferir e melhorar a segurança. Ele não é um software
nem um conjunto de controles. São as políticas, os papéis, os processos e os registros que mantêm os
controles adequados enquanto a organização e os riscos dela mudam.

É por isso que a 27001 fala relativamente pouco de firewall e muito de gestão. Os requisitos estão nas
**cláusulas 4 a 10**, e todas são obrigatórias para a certificação:

```schooling-figure
{"svg": "<svg id=\"sf-isms-clauses\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"As cláusulas da ISO 27001 como um ciclo. A cláusula 4, contexto, e a 5, liderança, o enquadram. Depois a 6, planejamento; a 7, apoio; a 8, operação; a 9, avaliação de desempenho; a 10, melhoria; e de volta ao planejamento.\"><defs><marker id=\"sf-isms-clauses-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"680\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">4 contexto da organização  ·  5 liderança</text><rect x=\"30\" y=\"90\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">6 planejamento</text><rect x=\"290\" y=\"90\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">7 apoio</text><rect x=\"550\" y=\"90\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"620.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">8 operação</text><rect x=\"420\" y=\"170\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"490.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">9 avaliação</text><rect x=\"160\" y=\"170\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">10 melhoria</text><path d=\"M170 110 L290 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-isms-clauses-ah-wire)\"></path><path d=\"M430 110 L550 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-isms-clauses-ah-wire)\"></path><path d=\"M620 130 L620 190 L560 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-isms-clauses-ah-wire)\"></path><path d=\"M420 190 L300 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-isms-clauses-ah-wire)\"></path><path d=\"M160 190 L100 190 L100 130\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-isms-clauses-ah-wire)\"></path><text x=\"360\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">planejar · fazer · verificar · agir</text></svg>", "caption": "As cláusulas 4 e 5 enquadram o sistema; da 6 à 10 giram num ciclo que não para."}
```

| cláusula | título | o que pede, na livraria |
|---|---|---|
| **4** | contexto da organização | o que a loja é, quem se importa com a segurança dela, e o escopo do SGSI |
| **5** | liderança | os sócios se comprometem, assinam a política de segurança e definem papéis |
| **6** | planejamento | avaliar e tratar riscos (aula 3), e definir objetivos de segurança |
| **7** | apoio | pessoas, competência, conscientização, comunicação e informação documentada |
| **8** | operação | executar o tratamento de riscos: os controles de fato funcionam |
| **9** | avaliação de desempenho | monitorar e medir, auditoria interna (aula 13), análise crítica pela direção |
| **10** | melhoria | tratar não conformidades, tomar ação corretiva, melhorar continuamente |

Lidas de cima para baixo, as cláusulas são um ciclo: entender a situação, se comprometer, planejar, dar
recursos, fazer, conferir, melhorar, e de novo. Textos mais antigos chamam isso de **planejar, fazer,
verificar, agir** (PDCA). O texto atual não nomeia mais o ciclo, e o ciclo continua sendo como as
cláusulas se encaixam.

### O que as cláusulas exigem e um checklist não

Três requisitos fazem um SGSI diferente de uma lista de boas práticas:

- **a avaliação de riscos guia os controles** (cláusula 6). A organização escolhe controles porque a
  própria avaliação de riscos diz que precisa deles, e não porque aparecem num catálogo. O registro de
  riscos da aula 3 é o coração disso.
- **a liderança responde** (cláusula 5). A alta direção precisa mostrar comprometimento, e não delegar o
  assunto inteiro à TI. Um auditor vai pedir para falar com os sócios, e não só com a ana.
- **o sistema se confere e se corrige** (cláusulas 9 e 10). Auditorias internas, uma análise crítica pela
  direção em intervalos planejados, e ações corretivas com evidência de que foram feitas. Um certificado
  não se mantém acertando uma vez; mantém-se percebendo e corrigindo o que dá errado.

As cláusulas também exigem **informação documentada**: o escopo, a política, o método e os resultados da
avaliação de riscos, a declaração de aplicabilidade (duas seções adiante) e registros mostrando que os
processos rodaram. A evidência da aula 13 é o que preenche esses requisitos.
