---
title: As partes de uma regra de alerta
version: 1
---

**Uma regra de alerta observa um escopo, avalia uma condição num horário e dispara um alerta quando a condição é
cumprida.** Todo o resto é detalhe sobre essas três coisas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma regra de alerta desenhada como esteira. Um escopo, o workspace log-shop, alimenta uma consulta avaliada a cada 5 minutos sobre os últimos 5 minutos. O resultado é comparado com uma condição: mais de 0 linhas. Se for cumprida, um alerta de severidade 1 é disparado, e ele passa pelas alert processing rules, que podem remover os action groups numa janela de manutenção, antes de chegar ao action group ag-shop-oncall, que manda e-mail e posta num webhook de chat.\"><defs><marker id=\"ah-rule\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"120\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">escopo</text><text x=\"80\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">log-shop</text><rect x=\"165\" y=\"40\" width=\"140\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">consulta</text><text x=\"235\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a cada 5 min</text><rect x=\"330\" y=\"40\" width=\"120\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"390\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">condição</text><text x=\"390\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">rows &gt; 0</text><rect x=\"475\" y=\"40\" width=\"225\" height=\"60\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"587\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">alerta disparado</text><text x=\"587\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">severidade 1</text><path d=\"M140 70 L163 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-rule)\"></path><path d=\"M305 70 L328 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-rule)\"></path><path d=\"M450 70 L473 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-rule)\"></path><rect x=\"330\" y=\"140\" width=\"200\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">processing rules</text><text x=\"430\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">silêncio na manutenção</text><rect x=\"555\" y=\"140\" width=\"145\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"627\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">action group</text><text x=\"627\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e-mail, webhook</text><path d=\"M587 100 L440 138\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-rule)\"></path><path d=\"M530 170 L553 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-rule)\"></path></svg>", "caption": "A regra decide que algo está errado; o action group decide quem fica sabendo; as processing rules ficam entre os dois."}
```

O Azure Monitor tem vários tipos de regra; dois importam mais aqui. Um **alerta de métrica** observa uma métrica de
plataforma, o tipo de sinal da lição 8: barato, rápido, avaliado a cada minuto, e limitado ao que uma métrica consegue
dizer. Um **alerta de pesquisa de log** roda uma consulta KQL num workspace: tão expressivo quanto a linguagem, e limitado
pela velocidade com que os logs chegam, que é de minutos e não de segundos. A loja usa alertas de métrica para coisas como
a CPU de uma VM e alertas de pesquisa de log para tudo sobre o que os clientes viveram, porque só os logs sabem quais
requisições falharam.

Um alerta de pesquisa de log tem quatro configurações que vale entender antes de escrever um:

- **frequência de avaliação**: de quanto em quanto tempo a consulta roda;
- **tamanho da janela**: quanto para trás cada execução olha;
- **a condição**: como o resultado da consulta vira sim ou não, como *o número de linhas é maior que 0*, ou *o valor numa
  coluna está acima de um limite*;
- **períodos com falha**: quantas avaliações seguidas precisam dar sim antes de o alerta disparar, a defesa contra um único
  minuto ruim.

Um alerta tem uma **severidade**, de 0 (crítico) a 4 (verboso), que é o jeito da loja de dizer quem é acordado e quem lê de
manhã. E ele é **com estado** quando o `autoMitigate` está ligado: dispara uma vez, fica disparado enquanto a condição vale e
se resolve sozinho quando uma avaliação volta não. Sem isso, todo sim é um alerta novo, e um incidente de quarenta minutos
são oito e-mails.

Regras são cobradas por regra por mês, e um alerta de pesquisa de log pela frequência com que roda. Nenhuma foi criada aqui;
o resto desta lição as escreve e confere o que elas teriam feito.
