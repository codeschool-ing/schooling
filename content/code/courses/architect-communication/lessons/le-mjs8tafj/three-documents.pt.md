---
title: Três documentos, e qual deles uma decisão pede
version: 1
---

**Um documento que pede uma decisão deve ter o tamanho da decisão, e não mais.** Um documento de
design de doze páginas para uma mudança que um time desfaz numa tarde desperdiça o tempo de leitura
de todo mundo. Uma mensagem de chat para uma mudança que altera como cinco times guardam dados deixa
de fora as pessoas que vão conviver com ela.

A Marola usa três formatos, e a maioria das empresas que põem as coisas por escrito acaba com algo
parecido, com outros nomes.

| | documento de uma página | proposta técnica | RFC |
|---|---|---|---|
| decide | uma mudança, por uma pessoa conhecida ou um grupo pequeno | um design, com alternativas comparadas | uma regra ou uma mudança que afeta muitos times |
| tamanho | uma página, lida em cinco minutos | de três a dez páginas | o que o assunto pedir, mais os comentários |
| quem comenta | quem aprova | os revisores nomeados no topo | qualquer pessoa afetada, dentro de um prazo fixo |
| termina com | um sim, um não ou uma data | um design aprovado | um registro aceito ou rejeitado |

Os eixos que decidem entre eles são **quantos times a mudança atinge** e **quão difícil é
revertê-la**. Uma mudança que um time reverte com pouco custo pede uma mensagem ou um documento de
uma página. Uma mudança difícil de desfazer, ou que muda o que outros times precisam fazer, pede uma
proposta escrita e, quando os "outros times" são quase a empresa inteira, uma RFC aberta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um gráfico com dois eixos: quantos times a mudança afeta, de um a muitos, e quão difícil é desfazê-la, de fácil a mais difícil. Um time e fácil de desfazer: uma mensagem. Quem decide, um custo e uma data: um documento de uma página. Mais difícil de desfazer: uma proposta técnica, com alternativas comparadas e revisores nomeados. Muitos times: uma RFC, em que qualquer afetado pode comentar por um prazo fixo.\"><defs><marker id=\"matrix-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M90 290 L690 290\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#matrix-ah)\"></path><path d=\"M90 290 L90 20\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#matrix-ah)\"></path><text x=\"390\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">times que a mudança afeta: um → muitos</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mais difícil</text><text x=\"20\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">de desfazer</text><text x=\"20\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fácil</text><rect x=\"110\" y=\"200\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uma mensagem</text><text x=\"200.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um time, barato de desfazer</text><rect x=\"310\" y=\"200\" width=\"180\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"400.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um documento de uma página</text><text x=\"400.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quem decide, um custo, uma data</text><rect x=\"310\" y=\"40\" width=\"180\" height=\"130\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uma proposta técnica</text><text x=\"400.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">alternativas comparadas,</text><rect x=\"510\" y=\"40\" width=\"170\" height=\"230\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"595.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uma RFC</text><text x=\"595.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qualquer afetado pode</text><text x=\"400\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">revisores nomeados</text><text x=\"595\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">comentar, por prazo fixo</text></svg>", "caption": "O tamanho do documento acompanha o tamanho da decisão: quantos times ela afeta, e quão difícil seria voltar atrás."}
```

## Por que escrever

A objeção é sempre a mesma: "Dá para resolver isso numa reunião." Às vezes dá. Um documento escrito
ganha de uma reunião em três pontos que importam para decisões que vão durar:

- **Ele obriga o raciocínio a terminar.** Uma reunião aceita "o rollback a gente vê depois". Uma
  página com uma seção vazia chamada *Rollback* não aceita.
- **Ele chega a quem não estava na sala**: o time em outro fuso horário, a engenheira que entra no
  ano que vem e se pergunta por que o planejador de rotas lê de uma réplica.
- **Ele é lido antes de qualquer discussão.** A Amazon conduz suas reuniões de liderança assim desde
  que Jeff Bezos proibiu apresentações de slides nelas, em 2004: um memorando narrativo de até seis
  páginas é entregue no começo e lido em silêncio por todos antes da discussão. Pense o que quiser
  do ritual, ele acaba com a reunião em que metade da sala lê o documento pela primeira vez enquanto
  o autor apresenta.

## O custo do tamanho errado

Pequeno demais é a falha comum nos times de engenharia: uma decisão tomada numa conversa de chat,
aceita por quem estava on-line, descoberta pelos outros quando quebra alguma coisa deles. **O teste
é quem vai ser pego de surpresa.** Se alguém de fora da conversa vai se surpreender com o
resultado, a decisão precisava de um documento que essa pessoa pudesse ter lido.

Grande demais é a falha comum de quem acabou de descobrir os documentos de design. Toda mudança
ganha um modelo com catorze títulos, quase todos respondidos com "N/A", e os times passam a fugir do
processo mantendo as mudanças abaixo do tamanho que o dispara. O objetivo dos formatos é caber na
decisão, e as próximas três seções tratam de cada um deles.
