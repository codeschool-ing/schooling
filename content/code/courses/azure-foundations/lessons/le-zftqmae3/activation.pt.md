---
title: Ativando um papel, e o que fica registrado
version: 1
---

**A ativação é o momento em que uma atribuição elegível vira ativa, por um tempo.** A pessoa pede o
papel, o PIM confere as condições que as configurações do papel exigem, e o papel fica ativo até as
horas pedidas acabarem. Nada nesta seção foi executado, pelo motivo que a anterior deu; os passos e
os limites são da documentação da Microsoft.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l10-activation\" aria-label=\"Uma ativação de um papel elegível, como linha do tempo. ana é elegível a Owner na shop-prod. No primeiro passo ana pede quatro horas, com segundo fator, justificativa e número de chamado. No segundo passo outro engenheiro aprova. Daí em diante o papel está ativo, pelas quatro horas pedidas. No fim ele se desliga sozinho e ana volta a ser elegível. Abaixo da linha, cada passo é gravado no histórico de auditoria.\"><path d=\"M40.0 120.0 L690.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"40.0\" y=\"96.0\" width=\"130.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">elegível</text><text x=\"105.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhum poder ainda</text><circle cx=\"250.0\" cy=\"120.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"250.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pedido</text><text x=\"250.0\" y=\"147.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">segundo fator</text><text x=\"250.0\" y=\"160.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">justificativa, chamado</text><circle cx=\"400.0\" cy=\"120.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"400.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">aprovação</text><text x=\"400.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">outro engenheiro</text><rect x=\"450.0\" y=\"96.0\" width=\"170.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"535.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">ativo</text><text x=\"535.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">no máximo 4 horas</text><circle cx=\"650.0\" cy=\"120.0\" r=\"7\" fill=\"var(--paper-dim)\"></circle><text x=\"650.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">expira</text><text x=\"650.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">elegível de novo</text><rect x=\"40.0\" y=\"210.0\" width=\"650.0\" height=\"56.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"56.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">histórico de auditoria</text><text x=\"365.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quem · qual papel · onde · por quanto tempo · por quê</text></svg>", "caption": "O papel fica ativo pelas horas pedidas, e cada passo deixa uma linha para trás."}
```

## O que as configurações do papel podem exigir

Todo papel no PIM tem **configurações**, escolhidas por papel e por escopo por quem administra o PIM,
e elas decidem o que uma ativação custa a quem pede:

- **uma duração máxima**, de **1 a 24 horas**. A pessoa pede qualquer número de horas até ela, e o
  papel se desliga sozinho no fim, lembre alguém disso ou não;
- **autenticação multifator na ativação.** A documentação da Microsoft acrescenta um aviso que vale
  repetir: quem já passou por um segundo fator antes na sessão pode não ser perguntado de novo. Onde
  toda ativação precisa se provar de novo, a configuração a usar é um **authentication context** do
  acesso condicional, que a lição 11 situa;
- **uma justificativa**, uma frase dizendo por quê, e opcionalmente um **número de chamado** do
  sistema de incidentes ou de mudanças, para a ativação poder ser ligada ao motivo dela;
- **aprovação.** Um ou mais aprovadores precisam aceitar o pedido antes de o papel ficar ativo. A
  Microsoft recomenda pelo menos dois aprovadores, para o pedido não esperar as férias de uma pessoa,
  e um aprovador não precisa de papel nenhum para aprovar.

Cada configuração é uma troca entre atrito e controle, e o jeito honesto de escolher é pelo que o
papel consegue quebrar. Reader em produção não precisa de nenhuma delas e nem deveria estar no PIM.
Owner em produção justifica as quatro: uma aprovação às três da manhã é mais lenta que um papel
permanente, e essa lentidão é o ponto, porque um atacante com uma sessão roubada precisa conseguir que
uma segunda pessoa concorde.

## As configurações da loja

`ana` e outros dois engenheiros de plataforma são **elegíveis** a Owner na assinatura `shop-prod`,
com prazo de seis meses. As configurações do papel pedem:

| configuração | valor | por quê |
|---|---|---|
| ativação máxima | 4 horas | um incidente ou uma mudança, não um dia de trabalho |
| segundo fator | exigido | o papel vale a pena roubar |
| justificativa e chamado | exigidos | cada ativação pode ser ligada ao seu motivo |
| aprovação | um dos outros dois engenheiros | ninguém concede Owner a si mesmo |

Os desenvolvedores de plantão são **elegíveis** ao papel estreito que a lição 9 escreveu,
`Shop App Restarter`, no `rg-shop-prod`, com justificativa e sem aprovação: reiniciar o web app de
madrugada não pode esperar alguém acordar, e o que ele consegue quebrar é pouco.

## O que o PIM deixa para trás

**Todo pedido, aprovação, recusa, ativação e expiração é gravado no histórico de auditoria do PIM**,
com quem, qual papel, em qual escopo, por quanto tempo e com qual justificativa. Esse registro é
metade do motivo de o PIM existir. "Quem tinha Owner em produção na terça passada às 2 da manhã, e por
quê?" tem resposta, e a resposta cita uma pessoa e um chamado em vez de "todo mundo da equipe de
plataforma, sempre".

O PIM também pode mandar **notificações**: aos administradores quando um papel é ativado, aos
aprovadores quando um pedido espera por eles. E pode rodar **revisões de acesso**, uma pergunta
periódica a um revisor, "estas pessoas ainda devem ser elegíveis?", que é como uma elegibilidade de
seis meses é renovada de propósito em vez de por padrão. Um papel que ninguém ativou em seis meses é o
mais fácil de remover, e a revisão é onde alguém percebe.
