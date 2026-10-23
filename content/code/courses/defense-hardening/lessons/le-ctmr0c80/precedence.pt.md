---
title: Quando duas políticas discordam
version: 1
---

**Vários GPOs chegam à maioria das máquinas, e alguns definem a mesma coisa de jeitos diferentes.** A
linha de base do domínio diz que a tela bloqueia depois de quinze minutos; a política da UO da
recepção diz cinco. Qual das duas a máquina aplica não é questão de opinião: a Política de Grupo
processa os GPOs numa ordem fixa e, onde dois definem a mesma configuração, **o processado por último
vence.** Como na seção anterior, isto é o comportamento documentado pela Microsoft e nada foi
executado para este curso.

## A ordem: local, site, domínio, unidade organizacional

A ordem é lembrada como **LSDOU**:

1. a política **local** guardada na própria máquina;
2. os GPOs vinculados ao **site**;
3. os GPOs vinculados ao **domínio**;
4. os GPOs vinculados a cada **UO**, do topo da árvore até a UO em que a máquina está.

Como o último vence, vence o contêiner mais específico: a política de uma UO sobrescreve a do
domínio, e a de uma UO filha sobrescreve a da mãe. A política local, processada primeiro, perde para
todas; só importa numa máquina que não está num domínio. Dentro de um contêiner, os GPOs são
processados pela **ordem de vínculo**, e o GPO com ordem de vínculo 1 é processado por último e,
portanto, vence os outros vinculados ali.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l03-lsdou\" aria-label=\"Ordem de processamento da Política de Grupo para um computador na UO Recepção, dentro da UO Jatoba, dentro do domínio. Passo 1, a política local, põe o bloqueio de tela em 30 minutos. Passo 2, o site, não define nada. Passo 3, a linha de base do domínio, põe 15 minutos. Passo 4a, a UO Jatoba, não define nada. Passo 4b, a UO Recepção, põe 5 minutos. Cada passo posterior sobrescreve o anterior, então o computador bloqueia depois de 5 minutos, o valor do último e mais específico contêiner.\"><defs><marker id=\"l03-lsdou-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l03-lsdou-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"60.0\" width=\"120.0\" height=\"90.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"80.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">política local</text><text x=\"80.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bloqueia em 30 min</text><path d=\"M140.0 105.0 L160.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03-lsdou-dh-ah-paper-dim)\"></path><rect x=\"160.0\" y=\"60.0\" width=\"120.0\" height=\"90.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"220.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"220.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">site</text><text x=\"220.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(nada definido)</text><path d=\"M280.0 105.0 L300.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03-lsdou-dh-ah-paper-dim)\"></path><rect x=\"300.0\" y=\"60.0\" width=\"120.0\" height=\"90.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"360.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">linha de base do domínio</text><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bloqueia em 15 min</text><path d=\"M420.0 105.0 L440.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03-lsdou-dh-ah-paper-dim)\"></path><rect x=\"440.0\" y=\"60.0\" width=\"120.0\" height=\"90.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">4a</text><text x=\"500.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">UO Jatoba</text><text x=\"500.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(nada definido)</text><path d=\"M560.0 105.0 L580.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03-lsdou-dh-ah-paper-dim)\"></path><rect x=\"580.0\" y=\"60.0\" width=\"120.0\" height=\"90.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"640.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">4b</text><text x=\"640.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">UO Recepção</text><text x=\"640.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">bloqueia em 5 min</text><text x=\"360.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">processados nesta ordem; uma configuração posterior sobrescreve a anterior</text><rect x=\"470.0\" y=\"190.0\" width=\"230.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o computador da recepção</text><text x=\"585.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">bloqueia depois de 5 minutos</text><path d=\"M640.0 150.0 L620.0 190.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l03-lsdou-dh-ah-phosphor)\"></path><text x=\"20.0\" y=\"280.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">Enforced no vínculo do domínio faria o passo 3 vencer o 4a e o 4b</text></svg>", "caption": "Local, site, domínio, UO: o último processado vence, e é o mais específico.", "same": ["site"]}
```

## As duas chaves que mudam a ordem

**Enforced**, marcado num vínculo, faz as configurações daquele GPO vencerem qualquer GPO vinculado
mais abaixo na árvore, mesmo onde um de baixo define a mesma coisa. É como uma equipe de segurança
garante que a linha de base vinculada ao domínio não possa ser afrouxada por um administrador de UO.

**Block inheritance**, marcado numa UO, impede que os GPOs vinculados acima dela se apliquem a ela,
então a UO começa só com as próprias políticas. Não bloqueia um vínculo Enforced: o Enforced foi
feito para sobreviver exatamente a isso.

Usados juntos, descrevem uma hierarquia de quem pode decidir o quê: o domínio define as regras que
ninguém abaixo pode afrouxar, e as impõe; cada UO decide o resto. Uma UO bloqueada sem linha de base
imposta acima dela é uma parte da frota que a equipe de segurança não governa mais, e isso se
descobre lendo o `gpresult` numa máquina dela, não lendo os GPOs um por um.

## Loopback, para máquinas que pertencem ao seu trabalho

A User Configuration segue a pessoa, onde quer que ela faça logon. Numa máquina compartilhada, uma
recepção ou o computador de uma sala de reunião, isso está ao contrário: o trabalho da máquina é que
deveria decidir. O **processamento de loopback**, ligado no GPO do computador, aplica a User
Configuration dos GPOs que chegam ao *computador*. No modo **Replace** as políticas do próprio usuário
são ignoradas; no modo **Merge** as duas se aplicam e as do computador vencem num conflito.

## O que levar para o Linux

As mesmas três perguntas valem para qualquer configuração central: em que ordem as fontes são lidas,
qual vence um conflito e o que pode passar por cima da ordem. A próxima seção as faz ao Ansible, onde
as respostas estão escritas numa tabela de precedência e não numa árvore.
