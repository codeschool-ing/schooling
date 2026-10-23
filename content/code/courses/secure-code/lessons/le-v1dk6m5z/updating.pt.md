---
title: Atualizar como rotina
version: 1
---

Fixar versões troca o risco da surpresa pelo do abandono. Uma versão fixada nunca quebra sozinha, e
também nunca é corrigida sozinha. **A defesa é uma rotina, pequena o bastante para de fato
acontecer**, em vez de uma atualização grande a cada dois anos que ninguém tem coragem de começar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l17-loop\" aria-label=\"A rotina que mantém dependências fixadas seguras, desenhada como um ciclo de cinco passos. Fixar versões exatas. Um alerta é publicado para uma delas. A auditoria que roda a cada mudança falha e nomeia a versão corrigida. Subir a versão fixada para ela e rodar os testes. Fazer commit da nova versão, e o ciclo recomeça.\"><defs><marker id=\"l17-loop-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270\" y=\"20\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fixar versões exatas</text><rect x=\"510\" y=\"90\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um alerta é publicado</text><rect x=\"430\" y=\"180\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"198.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a auditoria falha, nomeando</text><text x=\"530.0\" y=\"211.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a versão corrigida</text><rect x=\"110\" y=\"180\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"198.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">subir a versão,</text><text x=\"210.0\" y=\"211.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rodar os testes</text><rect x=\"20\" y=\"90\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">commit da nova versão</text><path d=\"M450 40 L605 40 L605 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-loop-ah-paper-dim)\"></path><path d=\"M605 130 L605 155 L530 155 L530 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-loop-ah-paper-dim)\"></path><path d=\"M430 205 L310 205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-loop-ah-paper-dim)\"></path><path d=\"M160 180 L110 180 L110 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-loop-ah-paper-dim)\"></path><path d=\"M110 90 L110 40 L270 40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-loop-ah-paper-dim)\"></path></svg>", "caption": "Fixar uma versão é uma decisão que se renova, não uma que se toma uma vez."}
```

### Uma rotina que se sustenta

1. **Audite a cada mudança**, para um alerta novo aparecer até um dia depois de publicado, na mudança
   que estiver na frente de alguém. A aula 19 acrescenta isso às verificações do projeto.
2. **Atualize uma dependência por vez** quando der. Se os testes falharem depois de uma mudança, você
   sabe qual pacote foi.
3. **Leia o changelog entre a sua versão e a nova.** Um lançamento de correção (`3.1.4` para `3.1.6`)
   deveria corrigir coisas e não quebrar nada; um lançamento maior (`2.x` para `3.0`) pode quebrar
   coisas de propósito, e as notas dele dizem o quê.
4. **Rode os testes.** Os testes escritos em cada aula deste curso são o que torna uma atualização
   segura: se o escape, a validação ou uma recusa pararem de funcionar depois de uma atualização, um
   teste avisa antes de um paciente.
5. **Faça commit da nova versão com uma mensagem que nomeia o alerta.** Daqui a um ano,
   `Raise jinja2 to 3.1.6 for PYSEC-2026-1471` se explica sozinha; `update deps` não.

### Deixar um robô abrir a mudança

Serviços como o Dependabot do GitHub e o Renovate observam as versões fixadas de um repositório e
abrem um pull request quando sai uma versão nova ou um alerta. Isso transforma o passo 1 numa
notificação e os passos 2 a 5 na revisão de uma mudança pequena e de um propósito só. Nenhum dos dois
foi executado para este curso; os dois se configuram com um arquivo curto no repositório, e os dois
dependem dos testes para distinguir uma atualização segura de uma que quebra.

### Quando não há versão corrigida

Às vezes o alerta ainda não tem correção, ou o pacote não é mais mantido. As escolhas então são as da
primeira seção: verificar se a aplicação usa a parte afetada, pôr um controle compensatório na
frente, trocar a dependência, ou aceitar o risco por um período declarado. Cada uma é legítima; **a
que não é, é esquecer.** Escreva a decisão ao lado da versão fixada, com uma data para voltar a ela.
