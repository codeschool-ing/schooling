---
title: "A linha do tempo: o que as pessoas sabiam, não só o que aconteceu"
version: 1
---

**A linha do tempo de um postmortem registra, para cada momento, o que aconteceu, o que as pessoas
envolvidas conseguiam ver e o que decidiram.** Uma linha do tempo só de eventos ("19:05 tarefa
iniciada; 19:09 erros") é um log. As decisões, e aquilo em que se apoiavam, é que a transformam em
algo com que um time consegue aprender.

## Montada a partir de três fontes

Diego, o escriba daquela noite, tinha deixado anotações no canal do incidente. Lívia juntou essas
notas aos logs do próprio sistema e a conversas curtas com as quatro pessoas envolvidas, e fez a mesma
pergunta a cada uma: *o que você estava olhando, o que achava que estava acontecendo e o que decidiu?*

| horário | o que aconteceu | o que viam, e o que decidiram |
|---|---|---|
| 19:05 | Paulo inicia o backfill das zonas | o runbook diz para rodá-lo quando as zonas mudam; as zonas mudaram às 16:00; nada fala de horário de pico |
| 19:09 | as conexões do banco chegam ao limite; o checkout começa a falhar | ninguém está olhando as conexões; não há alerta sobre elas |
| 19:16 | alerta: taxa de erro do checkout acima de 5% por 5 minutos | Bruna, de plantão, é acionada; o alerta cita o checkout, não o banco |
| 19:19 | Bruna declara um incidente e abre o #inc-0306 | ela suspeita de um deploy ruim do checkout, a causa de sempre; não houve nenhum naquele dia |
| 19:31 | Lucas vê as conexões no limite, e o backfill entre os clientes do banco | ele pergunta no canal quem iniciou aquilo |
| 19:36 | Paulo, que já tinha ido para casa, vê o canal e responde | ele para a tarefa assim que alguém pede |
| 19:38 | o backfill é interrompido | |
| 19:41 | as conexões caem; o checkout se recupera | |

## O que a terceira coluna mostra

Leia a coluna da direita de cima para baixo e o incidente muda de cara:

- **A decisão de Paulo às 19:05 estava certa por tudo o que ele conseguia ver.** O problema era o
  runbook.
- **Durante sete minutos, nada mediu a causa.** O alerta que disparou media o sintoma, e apontou a
  comandante para o checkout, onde não havia nada de errado.
- **Doze minutos foram para uma hipótese razoável e errada**: um deploy ruim, porque é isso que
  costuma quebrar o checkout.
- **Quando a pessoa certa fez a pergunta certa, a correção levou sete minutos.** A parte lenta foi
  chegar à pergunta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma barra das 19:05 às 19:41 dividida em cinco partes: o job roda das 19:05 às 19:09; nada mede a causa das 19:09 às 19:16; quem responde olha o checkout das 19:16 às 19:31; perguntam quem começou o job das 19:31 às 19:38; o job é parado e o checkout recupera até 19:41.\"><defs><marker id=\"gapsbars-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"120.0\" y=\"40\" width=\"61.33333333333334\" height=\"40\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"183.33333333333334\" y=\"40\" width=\"108.83333333333329\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"294.16666666666663\" y=\"40\" width=\"235.5000000000001\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"531.6666666666667\" y=\"40\" width=\"108.83333333333326\" height=\"40\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"642.5\" y=\"40\" width=\"45.5\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"151.66666666666669\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">job rodando</text><text x=\"120.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:05</text><text x=\"238.75\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nada mede</text><text x=\"183.33333333333334\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:09</text><text x=\"412.9166666666667\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">olhando o checkout</text><text x=\"294.16666666666663\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:16</text><text x=\"587.0833333333334\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">perguntando quem</text><text x=\"531.6666666666667\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:31</text><text x=\"666.25\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">parar</text><text x=\"642.5\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:38</text><text x=\"690.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:41</text><text x=\"20\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">6 de março</text><text x=\"183.33333333333334\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">7 minutos sem sinal da causa</text><text x=\"294.16666666666663\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">15 minutos olhando o checkout, onde nada estava errado</text><text x=\"690.0\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">10 minutos da pergunta certa à recuperação</text></svg>", "caption": "Para onde foram os 32 minutos. A correção foi a parte mais curta; a maior parte do tempo foi não ver a causa e depois procurar no lugar de sempre."}
```

## Escrevendo sem culpa

As palavras da linha do tempo importam tanto quanto os fatos. "Paulo rodou a tarefa no horário de
pico" carrega um julgamento em *no horário de pico*: era pico, e ninguém tinha dito a ele que isso
importava. "Paulo inicia o backfill das zonas; o runbook não fala de horário de pico" afirma os dois
fatos e deixa o leitor ver onde está o problema. **Descreva o que as pessoas fizeram e o que conseguiam
ver; deixe a avaliação para a análise, onde ela é sobre o sistema.**

Em retrospecto, tudo parece óbvio. Toda linha do tempo deveria ser lida uma vez com esta pergunta:
*naquele minuto, sem saber como terminou, eu teria feito melhor?* Onde a resposta honesta é não, a
lição é sobre o sistema.
