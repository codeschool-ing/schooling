---
title: Quando o PASTA se paga
version: 1
---

O PASTA custa mais que o STRIDE: mais estágios, mais pessoas, mais documentos, e um dono do
negócio que precisa abrir mão de uma manhã. O custo vale a pena quando uma destas é verdade:

| situação | por que o PASTA ajuda |
|---|---|
| o risco do sistema é sobretudo risco de **negócio**: dinheiro, regulação, reputação | os estágios 1 e 7 ligam cada ameaça ao que o negócio pode perder |
| quem decide o que é corrigido **não é técnico** | a ordenação vem com motivos nos termos dessas pessoas |
| a organização tem **inteligência de ameaças** que vale usar | o estágio 4 tem onde colocá-la |
| achados de scanners e pentests precisam ser **ligados** ao modelo | a coluna de CWE do estágio 5 é a ligação |
| o sistema é **grande e muda devagar** | os documentos continuam valendo tempo suficiente para pagar o custo |

E é a escolha errada quando:

- **a equipe precisa de uma resposta esta semana** para uma funcionalidade. STRIDE nos fluxos dela
  é uma hora.
- **ninguém do negócio vai aparecer.** Estágios 1 e 7 feitos só por engenheiros são palpites sobre
  as prioridades de outra pessoa, e o resultado parece ter autoridade sendo exatamente tão
  subjetivo quanto uma lista sem ordem.
- **o sistema muda a cada sprint.** Sete documentos por mudança viram motivo para não modelar
  nada, que é o pior resultado de todos.

### O que a Vereda manteve

A Vereda são quatro clínicas e uma consultora de segurança de meio período, e não roda o PASTA
completo a cada mudança. O que ela manteve é a parte que custou menos e mudou mais:

1. **O estágio 1, revisto uma vez por ano com o daniel**: os cinco objetivos e quanto custa falhar
   em cada um.
2. **STRIDE para os estágios 3 a 5**, por elemento no sistema inteiro e por interação nas
   fronteiras que importam, como na aula 3, com uma coluna de CWE quando há fraqueza conhecida.
3. **O estágio 7 para tudo o que entra novo na lista**: qual objetivo ameaça, e onde fica na
   ordenação.

É um formato comum para uma organização pequena, e tem nome na prática, ainda que não no livro:
*STRIDE dentro de uma moldura PASTA*. A aula 15 transforma o terceiro passo em parte de como as
funcionalidades são refinadas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l04-kept\" aria-label=\"A parte do PASTA que a Vereda manteve. O estágio 1, os objetivos de negócio, revisto uma vez por ano com o daniel. O STRIDE faz o trabalho dos estágios 3 a 5 a cada mudança. O estágio 7, a ordenação por impacto no negócio, é aplicado a tudo o que for novo na lista.\"><defs><marker id=\"l04-kept-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"210.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"125.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">estágio 1</text><text x=\"125.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma vez por ano, com o daniel</text><path d=\"M230.0 80.0 L255.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-kept-tm-ah-paper-dim)\"></path><rect x=\"255.0\" y=\"40.0\" width=\"210.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">estágios 3 a 5</text><text x=\"360.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">STRIDE, a cada mudança</text><path d=\"M465.0 80.0 L490.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-kept-tm-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"40.0\" width=\"210.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"595.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">estágio 7</text><text x=\"595.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">para o que for novo na lista</text><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">STRIDE dentro de uma moldura PASTA</text></svg>", "caption": "Os estágios do negócio são os baratos de manter e os caros de perder."}
```
