---
title: FAIR
version: 1
---

A aula 9 multiplicou dois números por risco. O **FAIR, Factor Analysis of Information Risk**, é o
que essa multiplicação vira quando é levada a sério. Ele traz um vocabulário padrão para as
quantidades envolvidas, um jeito de desmontar cada uma quando ela é difícil demais de estimar
direto, e o hábito de trabalhar com faixas em vez de valores únicos. Foi criado por Jack Jones em
meados dos anos 2000 e é mantido pelo The Open Group como dois padrões, a taxonomia de risco (O-RT)
e o método de análise de risco (O-RA).

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l10-fair-tree\" aria-label=\"A taxonomia do FAIR como árvore. O risco se divide em frequência de eventos de perda e magnitude da perda. A frequência de eventos de perda se divide em frequência de eventos de ameaça, quantas vezes alguém tenta, e vulnerabilidade, a chance de uma tentativa virar perda. A frequência de eventos de ameaça se divide em frequência de contato e probabilidade de ação. A vulnerabilidade se divide em capacidade da ameaça e força de resistência. A magnitude da perda se divide em perda primária, sofrida diretamente, e perda secundária, causada pela reação dos outros.\"><rect x=\"300.0\" y=\"10.0\" width=\"120.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">risco</text><rect x=\"90.0\" y=\"80.0\" width=\"200.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"190.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">frequência de eventos de perda</text><rect x=\"475.0\" y=\"80.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"560.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">magnitude da perda</text><rect x=\"15.0\" y=\"154.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">frequência de</text><text x=\"100.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">eventos de ameaça</text><rect x=\"215.0\" y=\"154.0\" width=\"150.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"290.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">vulnerabilidade</text><rect x=\"420.0\" y=\"154.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"490.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">perda primária</text><rect x=\"570.0\" y=\"154.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"640.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">perda secundária</text><rect x=\"4.0\" y=\"234.0\" width=\"96.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"52.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">frequência</text><text x=\"52.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">de contato</text><rect x=\"104.0\" y=\"234.0\" width=\"96.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"152.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">probabilidade</text><text x=\"152.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">de ação</text><rect x=\"202.0\" y=\"234.0\" width=\"96.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"250.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">capacidade</text><text x=\"250.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">da ameaça</text><rect x=\"302.0\" y=\"234.0\" width=\"96.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"350.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">força de</text><text x=\"350.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">resistência</text><path d=\"M360.0 46.0 L190.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M360.0 46.0 L560.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M190.0 116.0 L100.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M190.0 116.0 L290.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M560.0 116.0 L490.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M560.0 116.0 L640.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M100.0 190.0 L52.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M100.0 190.0 L152.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M290.0 190.0 L250.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M290.0 190.0 L350.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"560.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">seis formas de perda: produtividade, resposta,</text><text x=\"560.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reposição, multas, vantagem competitiva,</text><text x=\"560.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reputação</text></svg>", "caption": "A aula 9 estimou direto as duas caixas de cima. O FAIR deixa você estimar qualquer caixa mais abaixo quando a de cima é difícil demais de chutar."}
```

### A taxonomia

No topo, as mesmas duas metades da aula 9, com os nomes do FAIR:

- **frequência de eventos de perda**: quantas vezes uma perda acontece por ano, os "eventos por ano"
  da aula 9;
- **magnitude da perda**: quanto custa uma perda, o "custo por evento" da aula 9.

Cada uma se desdobra mais, e o desdobramento é a parte útil, porque **às vezes uma caixa de baixo é
mais fácil de estimar que a de cima.** A T02, contas de pacientes tomadas, é um bom exemplo. "Quantas
contas são tomadas por ano?" foi respondida com reclamações, mas as reclamações só contam os
pacientes que perceberam. O FAIR divide a pergunta:

| caixa | a pergunta | a evidência da Vereda |
|---|---|---|
| **frequência de eventos de ameaça** | com que frequência alguém tenta? | o log de login: rajadas de logins falhos quase toda semana |
| **vulnerabilidade** | que fração das tentativas vira perda? | quantas das senhas tentadas estavam em listas de vazamentos, e quantas contas as usavam |

Cada caixa tem evidência própria, e o produto é uma estimativa melhor que um número tirado de uma
caixa de reclamações.

A magnitude da perda se divide em **perda primária**, sofrida diretamente quando o evento acontece (a
investigação, o tempo da equipe), e **perda secundária**, causada pela reação dos outros (os
pacientes que vão embora, o regulador, os advogados). O FAIR também nomeia **seis formas de perda**,
que funcionam como checklist para as tabelas de impacto da aula 9: produtividade, resposta,
reposição, multas e condenações, vantagem competitiva e reputação.

### O que o FAIR pede de você

Faixas. Cada caixa é estimada como faixa, como a aula 9 recomendou, porque a saída do método é uma
distribuição, e não um ponto. E honestidade nas unidades: frequências por ano, perdas em dinheiro.
Uma análise FAIR que escreve "alto" numa caixa deixou de ser uma.

O que ele não pede é que você preencha todas as caixas. A maioria das análises reais estima no nível
mais alto onde há evidência, e desdobra só as caixas onde uma estimativa direta seria um chute. A
Vereda desdobrou a T02 e estimou as outras oito diretamente.
