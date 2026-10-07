---
title: Fatores contribuintes, não uma causa raiz
version: 1
---

**Incidentes em sistemas complexos raramente têm uma causa só. Eles acontecem quando várias fraquezas,
cada uma inofensiva sozinha, se alinham na mesma noite.** Procurar "a causa raiz" encontra uma delas,
em geral a última, em geral uma pessoa, e deixa as outras no lugar para a próxima vez.

## Os furos que se alinharam

James Reason, estudando acidentes em hospitais, na aviação e na indústria, descreveu isso com uma
imagem hoje conhecida como modelo do queijo suíço: cada defesa é uma fatia com furos, e um acidente
acontece quando os furos de várias fatias se alinham. Em 6 de março, seis furos se alinharam:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Seis fatias em fila, cada uma com um furo: o runbook, o limite do job, o limite do banco, os alertas, o primeiro palpite e o risco conhecido. Uma linha do backfill às 19:05 passa pelos seis furos até o checkout fora.\"><defs><marker id=\"cheese-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"170\" y=\"40\" width=\"34\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"179\" y=\"104\" width=\"16\" height=\"22\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"187\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">runbook</text><rect x=\"260\" y=\"40\" width=\"34\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"269\" y=\"104\" width=\"16\" height=\"22\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"277\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">limite do job</text><rect x=\"350\" y=\"40\" width=\"34\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"359\" y=\"104\" width=\"16\" height=\"22\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"367\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">limite do banco</text><rect x=\"440\" y=\"40\" width=\"34\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"449\" y=\"104\" width=\"16\" height=\"22\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"457\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">alertas</text><rect x=\"530\" y=\"40\" width=\"34\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"539\" y=\"104\" width=\"16\" height=\"22\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"547\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">primeiro palpite</text><rect x=\"620\" y=\"40\" width=\"34\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"629\" y=\"104\" width=\"16\" height=\"22\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"637\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">risco conhecido</text><path d=\"M20 115 L700 115\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\" marker-end=\"url(#cheese-ah)\"></path><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">backfill às 19:05</text><text x=\"700\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">checkout fora</text><text x=\"20\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">feche qualquer furo e a linha para ali</text></svg>", "caption": "O modelo do queijo suíço de Reason, aplicado a 6 de março. Cada defesa tinha um furo inofensivo sozinho; aquela noite foi a vez em que eles se alinharam.", "same": ["runbook"]}
```

1. **O runbook** dizia quando rodar o backfill, mas não quando não rodar.
2. **A tarefa** não tinha limite para quantas conexões podia abrir.
3. **O banco** não tinha limite por serviço, então um único cliente podia ficar com todas as conexões.
4. **Os alertas** mediam os erros do checkout, não as conexões do banco, e por isso a causa ficou
   invisível nos primeiros sete minutos.
5. **O suspeito de sempre**: deploys do checkout tinham causado a maioria dos incidentes anteriores,
   então os primeiros doze minutos foram para lá.
6. **O risco conhecido**: o risco aceito na aula 4, de o banco ficar sem conexões no pico enquanto a
   réplica de abril não chegava. O sistema já funcionava perto do limite.

Tire qualquer um desses furos e a noite é outra. Com um limite por serviço, o backfill fica lento e o
checkout fica bem. Com um alerta de conexões, a causa aparece às 19:09. Com uma linha no runbook, a
tarefa roda às 23:00.

## Por que os "cinco porquês" não bastam

Os *cinco porquês*, perguntar "por quê?" repetidas vezes até chegar a uma causa, vieram do sistema de
produção da Toyota e ainda são muito ensinados. São úteis para passar da primeira resposta. A
fraqueza deles, apontada por pesquisadores de segurança, é que seguem **uma única cadeia**, e a cadeia
escolhida depende de quem pergunta:

> Por que o checkout falhou? O banco ficou sem conexões. Por quê? O backfill ficou com elas. Por quê?
> Foi rodado no pico. Por quê? O Paulo rodou. Por quê? Ele não verificou.

Cinco porquês, uma cadeia, e ela termina numa pessoa. Perguntado de outro jeito, o segundo "por quê?"
poderia ter sido "por que uma única tarefa conseguiu ficar com todas as conexões?", e isso leva ao
limite do banco, um furo cujo fechamento também teria segurado a próxima tarefa que ninguém escreveu
ainda. **Pergunte "por quê?" em todos os ramos, e pare no sistema, não na pessoa.**

## Uma constatação é uma frase sobre o sistema

Cada fator contribuinte no relato é escrito como uma propriedade do sistema: "o banco não tem limite
de conexões por serviço", e não "ninguém configurou um limite de conexões". A primeira frase convida a
uma correção; a segunda convida à pergunta "quem deveria ter feito?", que é culpa por outro caminho.
