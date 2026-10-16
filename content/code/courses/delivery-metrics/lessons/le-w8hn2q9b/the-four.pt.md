---
title: As quatro, definidas com precisão suficiente para calcular
version: 1
---

Cada métrica parece óbvia até duas pessoas tentarem calculá-la a partir dos mesmos dados e chegarem a números diferentes. Estas são as definições que este curso usa, com as escolhas que cada uma esconde.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 230\" role=\"img\" data-fig=\"l05-timeline\" aria-label=\"Uma linha do tempo de uma mudança: commit, integração, deploy, uma falha percebida, serviço restaurado. O lead time de mudanças vai do commit ao deploy. O tempo para restaurar vai do deploy com falha à restauração. A frequência de deploy conta os deploys, e a taxa de falha de mudanças é a fração deles que falha.\"><path d=\"M40.0 100.0 L640.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"60.0\" cy=\"100.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"60.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">commit</text><circle cx=\"210.0\" cy=\"100.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"210.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">integração</text><circle cx=\"360.0\" cy=\"100.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"360.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">deploy</text><circle cx=\"470.0\" cy=\"100.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"470.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">falha percebida</text><circle cx=\"620.0\" cy=\"100.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"620.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">restaurado</text><path d=\"M60.0 132.0 L360.0 132.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M60.0 126.0 L60.0 138.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M360.0 126.0 L360.0 138.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"210.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">lead time de mudanças</text><path d=\"M210.0 30.0 L360.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M210.0 24.0 L210.0 36.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M360.0 24.0 L360.0 36.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"285.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que este curso mede, a partir da integração</text><path d=\"M360.0 170.0 L620.0 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M360.0 164.0 L360.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M620.0 164.0 L620.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"490.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">tempo para restaurar</text><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a frequência de deploy conta estes; a taxa de falha é a fração que falha</text></svg>", "caption": "Duas das métricas são durações nesta linha e duas são contagens dos deploys nela.", "same": ["commit", "deploy"]}
```

## Frequência de deploy

**Quantos deploys para produção num período**, normalmente citado por dia ou por semana. Um deploy é uma mudança chegando ao ambiente que os usuários de fato usam. Um deploy num ambiente de teste não conta, e integrar no branch principal também não: código que foi integrado e está esperando o trem de quinta-feira não foi entregue.

A escolha que ela esconde é **o que conta como um deploy**. Um time com cinco serviços que faz deploy dos cinco de uma vez pode contar um ou cinco. Os dois são defensáveis; trocar de um para o outro no meio de um trimestre multiplica a métrica por cinco da noite para o dia.

## Lead time de mudanças

**O tempo de uma mudança ser commitada até essa mudança rodar em produção.** Mede o pipeline e a revisão: tudo o que acontece com o código terminado antes de um usuário recebê-lo. Não é o lead time da aula 2, que começa quando um pedido é registrado, e o nome em comum é uma armadilha que vale nomear toda vez que você o citar.

A escolha que ela esconde é **qual commit**. O primeiro commit de um branch inclui o tempo de desenvolvimento; o commit de merge mede só o que vem depois da revisão. Os arquivos do time de Billing registram o merge, então este curso mede a partir dali, e o número é proporcionalmente menor do que seria a partir do primeiro commit.

## Taxa de falha de mudanças

**A fração dos deploys que causam uma falha em produção que precisa de remediação**: um rollback, um hotfix, um patch, um incidente. É uma fração dos deploys, não uma contagem de incidentes, então um time que faz deploy com mais frequência pode ter mais falhas e uma taxa menor.

A escolha que ela esconde é **o que conta como falha**. Um deploy revertido por causa de um erro de digitação numa mensagem de log, um deploy que causou uma indisponibilidade quatro dias depois, um deploy que estava certo mas cuja funcionalidade ninguém queria: um time precisa decidir de antemão quais desses ele conta. A aula 7 mostra o que acontece quando a decisão é tomada depois.

## Tempo para restaurar

**Para um deploy com falha, quanto tempo até o serviço ser restaurado para os usuários**, normalmente citado como mediana, porque algumas recuperações longas dominam qualquer média. Restaurado significa que os usuários não são mais afetados, o que muitas vezes acontece bem antes de a causa ser corrigida. Fazer rollback é restaurar; achar o bug não é necessário.

A escolha que ela esconde é **quando o relógio começa**: quando o deploy aconteceu, quando alguém percebeu ou quando um incidente foi declarado. Começar na detecção esconde a detecção lenta, que muitas vezes é a maior parte. A aula 14 desmonta um incidente nessas partes.

## Duas de cada, de propósito

As métricas vêm em pares que puxam uma contra a outra. Fazer deploy com mais frequência é fácil se você deixa de se importar se os deploys falham; nunca falhar é fácil se você nunca faz deploy. **Só as quatro juntas descrevem a entrega**, e um relatório que mostra as duas métricas de velocidade sem as duas de estabilidade, ou o contrário, está mostrando meio quadro escolhido por alguém.
