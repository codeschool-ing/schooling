---
title: Atualizações durante o incidente
version: 1
---

**Uma atualização durante um incidente diz o que foi afetado, o que está sendo feito e quando sai a
próxima atualização, e ela sai quando disse que sairia, mesmo que nada tenha mudado.** O conteúdo
pode ser magro. O ritmo, não. Silêncio durante um incidente é lido como "ninguém está cuidando disso"
ou como "está pior do que estão dizendo", e nenhuma das duas leituras ajuda.

## As quatro linhas

Toda atualização que Lívia escreveu em 6 de março, interna ou pública, tinha as mesmas quatro partes:

1. **Impacto**, nos termos do leitor: "A maioria dos clientes não consegue concluir o checkout."
2. **O que está sendo feito**: "Os engenheiros estão trabalhando nisso." Depois, algo específico:
   "Encontramos a causa e estamos interrompendo."
3. **O que se sabe e o que não se sabe**, separados: "A navegação e as cestas funcionam. Ainda não
   sabemos a causa."
4. **A próxima atualização**, com horário: "Próxima atualização até 19:45."

A primeira atualização pública, às 19:27:

> **Investigating** (investigando). Desde cerca de 19:10, a maioria dos clientes não consegue concluir
> o checkout. A navegação e as cestas não foram afetadas; os itens da sua cesta estão guardados.
> Estamos trabalhando nisso e vamos atualizar aqui até 19:45.

## O ritmo

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma linha do tempo das 19:00 às 20:00 com duas faixas. O que aconteceu: o job começa às 19:05, o alerta às 19:16, o incidente é declarado às 19:19, o job é parado às 19:38, o checkout recupera às 19:41; o checkout falhou por 32 minutos a partir das 19:09. O que foi dito: a frase do suporte às 19:26, investigando às 19:27, identificado às 19:40, resolvido às 19:56.\"><defs><marker id=\"inctimelin-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M60 150 L690 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><text x=\"60.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">19:00</text><text x=\"217.5\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">19:15</text><text x=\"375.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">19:30</text><text x=\"532.5\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">19:45</text><text x=\"690\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20:00</text><polygon points=\"154.5,112 490.5,112 490.5,140 154.5,140\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></polygon><text x=\"322.5\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">checkout falhando: 32 min</text><text x=\"14\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que</text><text x=\"14\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">aconteceu</text><path d=\"M112.5 38 L112.5 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"112.5\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">job começa</text><path d=\"M228.0 68 L228.0 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"228.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">alerta</text><path d=\"M259.5 98 L259.5 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"259.5\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">incidente declarado</text><path d=\"M459.0 38 L459.0 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"459.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">job parado</text><path d=\"M490.5 68 L490.5 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"490.5\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">recupera</text><text x=\"14\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que</text><text x=\"14\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">foi dito</text><path d=\"M333.0 152 L333.0 186\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><text x=\"327.0\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">frase do suporte</text><path d=\"M343.5 152 L343.5 216\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><text x=\"343.5\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">investigando</text><path d=\"M480.0 152 L480.0 186\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><text x=\"480.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">identificado</text><path d=\"M648.0 152 L648.0 216\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><text x=\"648.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">resolvido</text><text x=\"60\" y=\"285\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sexta, 6 de março, horário de Recife; o canal da diretoria também recebeu atualização a cada quinze minutos</text></svg>", "caption": "Duas faixas de uma noite. A primeira palavra pública veio dezoito minutos depois de a falha começar; dali em diante, a diretoria ouviu algo a cada quinze minutos e o público pelo menos a cada vinte."}
```

Lívia postou na página de status às 19:27, 19:40 e 19:56, e internamente no canal da diretoria a cada
quinze minutos. Os rótulos públicos seguiam uma convenção comum, a que a maioria dos serviços de
página de status usa: **Investigating** (investigando), **Identified** (identificado),
**Monitoring** (monitorando), **Resolved** (resolvido). Cada rótulo diz ao leitor em que ponto o
incidente está sem que ele precise ler o texto.

| horário | atualização pública |
|---|---|
| 19:27 | **Investigating** (investigando). A maioria dos clientes não consegue concluir o checkout; estamos trabalhando nisso; próxima atualização até 19:45. |
| 19:40 | **Identified** (identificado). Encontramos a causa, uma tarefa em segundo plano sobrecarregando um banco de dados, e a interrompemos. O checkout está começando a se recuperar. Próxima atualização até 20:00. |
| 19:56 | **Resolved** (resolvido). O checkout funciona normalmente desde 19:41. Se um pagamento falhou entre 19:10 e 19:41, você não foi cobrado; tente de novo, por favor. Vamos publicar um resumo na segunda-feira. |

## O que não entra numa atualização

- **Um palpite sobre a causa.** Às 19:31, Lucas suspeitou do backfill. Lívia não escreveu "achamos
  que é uma tarefa em lote"; esperou a confirmação, às 19:38. Uma causa errada, publicada, precisa
  ser corrigida em público, e a correção é lembrada por mais tempo que o incidente.
- **Uma estimativa de quando vai estar resolvido**, a menos que alguém tenha certeza. "Próxima
  atualização até 19:45" é uma promessa que Lívia consegue cumprir; "resolvido em 15 minutos" não é.
- **Nomes internos, sistemas e culpados.** "Uma tarefa em segundo plano sobrecarregando um banco de
  dados" é exato, completo e não aponta para ninguém.
- **"Alguns clientes", quando é a maioria.** Diminuir o impacto é percebido por todo cliente afetado,
  e são eles que estão lendo.
