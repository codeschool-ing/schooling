---
title: Três tipos de falha
version: 1
---

Até aqui, todo pipeline deste curso falhou na frente da Ana, que leu o erro e fez alguma coisa a
respeito. Um pipeline agendado falha às três da manhã, quando ninguém está lendo, e **o que acontece
depois precisa ter sido decidido à tarde**. O Airflow pode tentar de novo, desistir ou avisar
alguém, e qual dessas é a certa depende de por que a tarefa falhou.

O DAG novo desta lição busca os preços das editoras toda noite às 03:00, na API da lição 3. As
falhas dele caem em três tipos:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l10-failures\" aria-label=\"Três tipos de falha e o que cada um pede. Uma falha passageira, como um 503, um 429 ou um timeout, é tentada de novo mais tarde e não alerta ninguém, a menos que as tentativas acabem. Uma permanente, como um 401, um 400 ou um arquivo no formato errado, falha na hora e alerta. Uma falha no próprio código, como um erro de importação, impede o DAG de ser agendado e se resolve mudando o código.\"><text x=\"30.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">a falha</text><text x=\"200.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">por exemplo</text><text x=\"410.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">o que o Airflow deve fazer</text><path d=\"M30.0 44.0 L690.0 44.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"30.0\" y=\"61.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">passageira</text><text x=\"200.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">503 · 429 · timeout</text><text x=\"410.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tentar de novo, cada vez mais tarde</text><rect x=\"30.0\" y=\"113.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">permanente</text><text x=\"200.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">401 · 400 · um arquivo ruim</text><text x=\"410.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">falhar agora, e avisar</text><rect x=\"30.0\" y=\"165.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">no código</text><text x=\"200.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um erro de importação</text><text x=\"410.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nada roda: corrigir o código</text></svg>", "caption": "Pedir de novo só ajuda quando a causa pode sumir sozinha.", "same": ["503 · 429 · timeout"]}
```

- **Uma falha passageira** é uma que o mundo conserta sem a ajuda de ninguém. A API responde `503`
  porque está sendo reimplantada, ou `429` porque o pedido veio rápido demais, ou uma conexão
  estoura o tempo numa rede ocupada. O mesmo pedido um minuto depois dá certo. **É para isso que
  servem os retries**, e uma pessoa acordada por uma delas não acharia nada para fazer.
- **Uma falha permanente** é uma que pedir de novo não muda. Um `401` quer dizer que a chave está
  errada, e ela vai continuar errada daqui a um minuto e daqui a uma hora; um `400` quer dizer que o
  próprio pedido está malformado; um arquivo no formato errado vai estar no formato errado em toda
  leitura. Tentar de novo desperdiça a noite e atrasa o alerta. **A tarefa deve falhar na hora e
  dizer isso.**
- **Uma falha no código** para a tarefa antes de ela começar. Um arquivo de DAG que não importa não
  é uma tarefa falhando: é um DAG que o Airflow não enxerga, e nada nele é agendado.

O terceiro tipo apareceu primeiro, enquanto a Ana escrevia o DAG, então ele vem primeiro. O resto
da lição trata dos outros dois, um de cada vez: retries, falhar rápido, timeouts, e depois o que
avisa uma pessoa quando nada disso bastou.
