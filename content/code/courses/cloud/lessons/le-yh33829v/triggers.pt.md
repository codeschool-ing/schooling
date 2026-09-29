---
title: O que chama uma função
version: 1
---

Uma função não faz nada até alguma coisa invocá-la. **Quem a invoca se chama gatilho, ou origem de
eventos, e decide duas coisas: o formato do evento e se alguém está esperando a resposta.** Quatro
origens cobrem quase tudo para o que as funções são usadas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Quatro coisas que chamam uma função: uma requisição HTTP por um API gateway ou uma function URL, uma mensagem numa fila, um arquivo que chega num bucket e um agendamento. As quatro chegam como um evento passado ao mesmo handler. Só a requisição HTTP tem alguém esperando a resposta; nas outras três o resultado é o que a função gravou em algum lugar.\"><defs><marker id=\"sl-trig-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"210\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Uma requisição HTTP</text><text x=\"32\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">GET /hello?name=ana</text><path d=\"M230 47 L300 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-trig-ah)\"></path><rect x=\"20\" y=\"88\" width=\"210\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Uma mensagem numa fila</text><text x=\"32\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">SQS</text><path d=\"M230 115 L300 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-trig-ah)\"></path><rect x=\"20\" y=\"156\" width=\"210\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Um arquivo chega no bucket</text><text x=\"32\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">s3:ObjectCreated:Put</text><path d=\"M230 183 L300 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-trig-ah)\"></path><rect x=\"20\" y=\"224\" width=\"210\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Um agendamento</text><text x=\"32\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">rate(5 minutes)</text><path d=\"M230 251 L300 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-trig-ah)\"></path><rect x=\"310\" y=\"118\" width=\"140\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">sua função</text><text x=\"380\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">handler(event, context)</text><rect x=\"500\" y=\"20\" width=\"200\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">alguém está esperando</text><text x=\"512\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o valor devolvido é a resposta</text><rect x=\"500\" y=\"150\" width=\"200\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"512\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">ninguém está esperando</text><text x=\"512\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o resultado é o que ela gravou:</text><text x=\"512\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma linha, um arquivo, uma mensagem</text><text x=\"512\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">falhas são repetidas ou</text><text x=\"512\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">guardadas, sem aparecer a ninguém</text><path d=\"M450 135 L500 52\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-trig-ah)\"></path><path d=\"M450 165 L500 205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sl-trig-ah)\"></path></svg>", "caption": "Um handler, quatro portas. O evento tem um formato diferente em cada uma, e só uma delas tem alguém esperando do outro lado."}
```

- Uma requisição HTTP. A função responde a uma URL, seja por um API gateway, que põe roteamento,
  autenticação e limite de taxa na frente dela, seja por uma function URL, um endereço que a AWS dá
  diretamente a uma função. É o caso das duas seções anteriores, e o único dos quatro em que uma
  pessoa está esperando.
- Uma mensagem numa fila. Outra parte do sistema põe trabalho numa fila, o SQS na AWS, e a plataforma
  tira as mensagens de lá e as entrega à função em lotes. Uma mensagem em que a função falha volta
  para a fila e é tentada de novo.
- Um arquivo que chega num bucket. O armazenamento de objetos, assunto da aula 5, pode anunciar cada
  objeto novo, e o anúncio pode chamar uma função: sobe uma foto, uma função gera a miniatura. **O
  evento traz o bucket e a chave, não o conteúdo**; a própria função lê o objeto.
- Um agendamento. Uma regra como `rate(5 minutes)`, ou uma expressão cron, chama a função pelo
  relógio: uma limpeza toda noite, um relatório toda segunda-feira. É o cron sem uma máquina para
  rodar o cron.

Há outras, como mudanças numa tabela de banco de dados ou mensagens num stream, e elas seguem um dos
dois padrões abaixo.

## Alguém esperando, ou ninguém

**Haver ou não alguém esperando é a distinção que muda o jeito de escrever o handler.** Uma chamada
HTTP é síncrona: quem chamou espera, o valor devolvido vira a resposta, e um erro é algo que uma
pessoa vê. As outras três são assíncronas do ponto de vista do seu código. Ninguém está esperando, o
valor devolvido não vai a lugar útil nenhum, e o resultado é o que a função gravou: uma linha, um
arquivo, outra mensagem.

Uma falha numa chamada assíncrona não aparece para usuário nenhum, então a plataforma tenta de novo.
O que acontece quando as tentativas acabam é uma configuração: o evento é descartado, ou é guardado
numa dead-letter queue para alguém olhar. **Uma função sem dead-letter queue e sem alarme pode falhar
em todos os eventos durante uma semana sem ninguém saber**, porque não há usuário para reclamar.

## O mesmo evento, duas vezes

As novas tentativas têm uma consequência para o código: **o mesmo evento pode chegar mais de uma
vez.** A AWS documenta que a invocação assíncrona e as filas padrão do SQS entregam pelo menos uma
vez, então uma duplicata faz parte do contrato, não é defeito. Uma miniatura gerada duas vezes não faz
mal. Um e-mail enviado duas vezes, ou um cartão cobrado duas vezes, faz.

Um handler que faz algo que deve acontecer uma vez só precisa reconhecer um evento que já tratou,
normalmente registrando um id que vem no evento e conferindo esse id antes de agir. **Um handler
assim se chama idempotente: rodá-lo duas vezes com o mesmo evento deixa o mundo como rodá-lo uma vez
deixou.** A ideia pertence a todo sistema construído sobre filas; uma função atrás de uma fila é só
onde a maioria das pessoas a encontra primeiro.
