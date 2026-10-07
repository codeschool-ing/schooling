---
title: Quatro perguntas
version: 1
---

A modelagem de ameaças tem fama de exercício pesado: um especialista, uma semana de oficinas e um
documento de cem páginas que ninguém abre de novo. Esse retrato descreve um jeito ruim de fazer.
**Modelar ameaças é analisar uma representação de um sistema para achar o que pode dar errado
com ele, antes ou durante a construção, e decidir o que fazer com cada coisa encontrada.** Pode
levar vinte minutos diante de um quadro branco, e na maioria das vezes essa é a versão que vale a
pena.

A descrição mais clara do método cabe numa linha. Adam Shostack, que conduziu a modelagem de
ameaças na Microsoft por anos e escreveu o livro de referência da área, reduziu tudo a **quatro
perguntas**:

1. **No que estamos trabalhando?**
2. **O que pode dar errado?**
3. **O que vamos fazer a respeito?**
4. **Fizemos um trabalho bom o bastante?**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-four-questions\" aria-label=\"As quatro perguntas em ciclo. Um: no que estamos trabalhando, respondida com um modelo do sistema. Dois: o que pode dar errado, respondida com uma lista de ameaças. Três: o que vamos fazer a respeito, respondida com mitigações e decisões. Quatro: fizemos um trabalho bom o bastante, respondida com uma revisão. Uma seta da quarta volta à primeira quando o sistema muda.\"><defs><marker id=\"l01-four-questions-tm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-four-questions-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l01-four-questions-tm-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"50.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"97.5\" y=\"77.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1  No que estamos</text><text x=\"97.5\" y=\"92.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">trabalhando?</text><rect x=\"30.0\" y=\"150.0\" width=\"135.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"97.5\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um modelo do sistema</text><path d=\"M97.5 120.0 L97.5 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-paper-dim)\"></path><rect x=\"195.0\" y=\"50.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"272.5\" y=\"77.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2  O que pode</text><text x=\"272.5\" y=\"92.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">dar errado?</text><rect x=\"205.0\" y=\"150.0\" width=\"135.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"272.5\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma lista de ameaças</text><path d=\"M272.5 120.0 L272.5 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-paper-dim)\"></path><rect x=\"370.0\" y=\"50.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"447.5\" y=\"77.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3  O que vamos</text><text x=\"447.5\" y=\"92.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fazer a respeito?</text><rect x=\"380.0\" y=\"150.0\" width=\"135.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"447.5\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mitigações, decisões</text><path d=\"M447.5 120.0 L447.5 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-paper-dim)\"></path><rect x=\"545.0\" y=\"50.0\" width=\"155.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"622.5\" y=\"77.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4  Fizemos um trabalho</text><text x=\"622.5\" y=\"92.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">bom o bastante?</text><rect x=\"555.0\" y=\"150.0\" width=\"135.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"622.5\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma revisão</text><path d=\"M622.5 120.0 L622.5 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-paper-dim)\"></path><path d=\"M175.0 85.0 L195.0 85.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-phosphor)\"></path><path d=\"M350.0 85.0 L370.0 85.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-phosphor)\"></path><path d=\"M525.0 85.0 L545.0 85.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-phosphor)\"></path><path d=\"M622.0 184.0 L622.0 240.0 L97.0 240.0 L97.0 184.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l01-four-questions-tm-ah-amber)\"></path><text x=\"360.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">quando o sistema muda, recomece</text><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">As quatro perguntas de Shostack</text></svg>", "caption": "Cada pergunta tem uma resposta que dá para segurar na mão. A quarta é a que as equipes pulam."}
```

Cada método deste curso é um jeito de responder a uma delas com mais cuidado. Um diagrama de
fluxo de dados (aula 2) responde à primeira. STRIDE (aula 3), PASTA (aula 4), árvores de ataque e
LINDDUN (aula 5) são jeitos estruturados de responder à segunda. Requisitos de segurança (aula
8), números de risco (aulas 9 a 11) e decisões registradas (aula 12) respondem à terceira. A
quarta é uma revisão, e a aula 15 transforma essa revisão num hábito em vez de um evento.

### Cada resposta é algo que dá para segurar

As perguntas são úteis porque cada uma tem uma saída concreta, e dá para saber se a saída existe:

| pergunta | o que respondê-la produz |
|---|---|
| No que estamos trabalhando? | um desenho do sistema: suas partes, os dados que circulam entre elas, onde a confiança muda |
| O que pode dar errado? | uma lista de ameaças, cada uma ligada a uma parte do desenho |
| O que vamos fazer a respeito? | para cada ameaça, uma decisão: mitigar, eliminar, transferir ou aceitar, com um responsável |
| Fizemos um trabalho bom o bastante? | uma verificação de que o desenho ainda bate com o sistema e de que toda ameaça tem decisão |

Uma reunião que termina sem a segunda coluna foi uma conversa sobre segurança. Pode ter sido útil,
e não é um modelo de ameaças.

### O manifesto

Em 2020 um grupo de profissionais, Shostack entre eles, publicou o **Threat Modeling Manifesto**.
Vale ler as suas cinco declarações de valores, porque cada uma dá nome ao mau hábito que
substitui:

- uma cultura de achar e corrigir problemas de projeto **acima da conformidade de checklist**;
- pessoas e colaboração **acima de processos, metodologias e ferramentas**;
- uma jornada de entendimento **acima de uma fotografia de segurança ou de privacidade**;
- fazer modelagem de ameaças **acima de falar sobre ela**;
- refinamento contínuo **acima de uma entrega única**.

A segunda linha importa para este curso. Você vai conhecer uma dúzia de métodos com nome e uma
ferramenta, e nenhum deles é o objetivo. São andaimes para pessoas que conhecem o sistema,
sentadas juntas, perguntando o que pode dar errado com ele. Um método aplicado por alguém que
nunca viu o sistema produz uma lista de ameaças genéricas que serve igualmente mal a qualquer
sistema.

### Quem faz as perguntas

**As pessoas que constroem e operam o sistema**, com alguém que entende de segurança na sala ou
revisando depois. Quem desenvolve sabe que o job de lembretes roda com a senha do dono do banco
porque foi mais rápido. Quem opera sabe que o console de administração é alcançável pelo Wi-Fi da
clínica. Quem é especialista em segurança sabe qual desses fatos importa. Ninguém tem os três
sozinho, e é por isso que um modelo desenhado por uma pessoa acha menos que um desenhado por três.
