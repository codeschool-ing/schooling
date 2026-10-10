---
title: Três sinais e dois métodos
version: 1
---

Tudo neste curso até aqui aconteceu antes de uma versão ir ao ar. O teste de carga rodou contra
uma máquina sua, a auditoria leu uma página que você servia, o scanner olhou um repositório que
você enxergava. **A produção é onde chegam os defeitos que você não testou**, com usuários que
ninguém modelou, em redes que ninguém escolheu, num horário que ninguém planejou. Monitoramento é
como uma equipe fica sabendo antes que esses usuários escrevam, e é o terço de operabilidade do
curso: na tabela da aula 1, *quando ele se comporta mal em produção, alguém fica sabendo primeiro?*

Um sistema rodando consegue falar de si de três jeitos, e eles respondem a perguntas diferentes.
Equipes que coletam um deles e chamam isso de monitoramento costumam descobrir qual pergunta não
conseguem responder na noite em que precisam dela.

## Métricas, logs e traces

**Uma métrica é um número amostrado ao longo do tempo**: requisições respondidas, requisições que
falharam, quanto levaram, quão ocupado está o processador. Ela é agregada antes de ser guardada,
então um milhão de requisições custa o mesmo punhado de números que dez. Isso deixa as métricas
baratas o bastante para guardar por meses e rápidas o bastante para alertar, e também é o limite
delas: uma métrica diz que 3% das reservas falharam nos últimos cinco minutos, e não consegue dizer
quais.

**Um log é o registro de um evento.** Uma linha por requisição, por erro, por reserva. Ele responde
à pergunta que a métrica joga fora, *o que aconteceu com esta aqui*, e custa na proporção do
tráfego: um sistema movimentado escreve gigabytes por dia, e buscar neles pede uma ferramenta feita
para isso.

**Um trace acompanha uma requisição por todas as partes que a atenderam.** Cada parte é um *span*,
com um início e uma duração, e os spans se aninham: a requisição, dentro dela a consulta ao banco,
dentro desta nada, ao lado dela a chamada ao provedor de pagamento. Num sistema de vinte serviços, o
trace é o único registro que mostra que uma finalização de compra lenta gastou o tempo no quarto
deles. A boxoffice é um processo só, e ela já carrega um trace de uma linha: o cabeçalho
`Server-Timing` que a aula 1 mostrou, `db;dur=…, pay;dur=…, total;dur=…`, é a mesma ideia sem
ferramenta em volta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l22-signals\" aria-label=\"Uma requisição de reserva, POST /bookings, no meio, e os três registros que ela deixa. Como métrica, soma um a um contador rotulado com a rota e o status, e um a um balde de duração: barato, e diz quantas e quão rápidas, nunca qual. Como linha de log, é um registro JSON com o seu próprio id de requisição, status e milissegundos: diz o que aconteceu com esta requisição. Como trace, é uma barra para a requisição inteira com uma barra dentro para cada parte, o banco e o pagamento: diz para onde foi o tempo.\"><defs><marker id=\"l22-signals-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270.0\" y=\"20.0\" width=\"180.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">POST /bookings</text><path d=\"M360.0 62.0 L120.0 96.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-signals-nf-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"100.0\" width=\"200.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"120.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">métrica</text><rect x=\"20.0\" y=\"138.0\" width=\"200.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"120.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">quantas, quão rápidas</text><path d=\"M360.0 62.0 L360.0 96.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-signals-nf-ah-paper-dim)\"></path><rect x=\"260.0\" y=\"100.0\" width=\"200.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"360.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">log</text><rect x=\"260.0\" y=\"138.0\" width=\"200.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"360.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o que houve com esta</text><path d=\"M360.0 62.0 L600.0 96.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-signals-nf-ah-paper-dim)\"></path><rect x=\"500.0\" y=\"100.0\" width=\"200.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"600.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">trace</text><rect x=\"500.0\" y=\"138.0\" width=\"200.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"600.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">para onde foi o tempo</text><text x=\"120.0\" y=\"162.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">requests_total{</text><text x=\"120.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">route=&quot;/bookings&quot;,</text><text x=\"120.0\" y=\"187.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">status=&quot;201&quot;} +1</text><text x=\"120.0\" y=\"228.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">duration_bucket{</text><text x=\"120.0\" y=\"241.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">le=&quot;0.1&quot;} +1</text><text x=\"360.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{&quot;request_id&quot;:</text><text x=\"360.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;ana-test-1&quot;,</text><text x=\"360.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;route&quot;: &quot;/bookings&quot;,</text><text x=\"360.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;status&quot;: 201,</text><text x=\"360.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;ms&quot;: 68.8}</text><rect x=\"512.0\" y=\"160.0\" width=\"176.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"520.0\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">request</text><rect x=\"512.0\" y=\"190.0\" width=\"50.0\" height=\"18.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></rect><text x=\"537.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">db</text><rect x=\"566.0\" y=\"190.0\" width=\"116.0\" height=\"18.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"></rect><text x=\"624.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">pay</text><path d=\"M512.0 236.0 L688.0 236.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"512.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">0</text><text x=\"688.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">tempo</text></svg>", "caption": "Uma requisição, três registros. Cada um responde a uma pergunta que os outros dois não respondem.", "same": ["log", "trace"]}
```

Os três se ligam por um id. Uma linha de log que carrega o id da requisição pode ser achada a partir
do trace que carrega o mesmo id, e uma métrica pode levar uma amostra de ids de trace ao lado dos
números. **Sem o id, cada sinal é uma ilha**, e quem está de plantão passa os primeiros vinte
minutos casando horários a olho.

## RED para um serviço, USE para um recurso

Duas listas curtas dizem quais métricas coletar primeiro, e elas olham o sistema de lados opostos.

| método | para | os três números |
|---|---|---|
| **RED** | um serviço, visto por quem o chama | **R**ate, a taxa de requisições; **E**rrors, os erros entre elas; **D**uration, a duração de cada uma |
| **USE** | um recurso sobre o qual o serviço roda | **U**tilisation, quão ocupado ele está; **S**aturation, quanto trabalho está na fila por ele; **E**rrors, os erros que ele relata |

O RED é de Tom Wilkie, do mundo dos microsserviços: para cada endpoint, quantas, quantas falharam,
quanto levaram. É o que o usuário sente, então é o que um alerta deve vigiar, e a aula 24 se apoia
exatamente nisso. O USE é de Brendan Gregg, do trabalho de desempenho em sistemas operacionais: para
cada recurso — processadores, memória, discos, links de rede — quão ocupado, quão enfileirado, quão
quebrado. É onde você olha depois que o RED diz que algo está errado.

**Um recurso é qualquer coisa pela qual o trabalho espera, e não só hardware.** Na boxoffice, o
processador é um, e o `booking_lock` também, o lock que toda reserva segura enquanto paga: a
utilização dele é a fração do tempo em que alguém o segura, e a saturação é quantas reservas estão
esperando na porta. A aula 9 mede exatamente essa espera. Uma máquina com 40% de CPU e um lock
saturado é uma bilheteria lenta, e uma verificação USE que só olha o hardware diz que ela está
saudável.

Os números que o RED pede são os que a aula 8 ensinou a ler. A taxa é a vazão, os erros são a taxa
de erro, e a duração é uma distribuição, o que quer dizer um percentil e nunca uma média. **Um
painel mostrando o tempo médio de resposta está cometendo o erro de que trata a aula 8**, na escala
de um sistema de produção inteiro.

## Uma linha de log para uma máquina ler

Um log escrito para uma pessoa parece uma frase: `Booked seat 12 of show 990 for ana in 68 ms`. É
fácil ler uma e muito difícil buscar em um milhão delas, porque toda pergunta vira uma expressão
regular que quebra no dia em que alguém reescreve a mensagem.

Um **log estruturado** escreve o mesmo evento como campos, um objeto JSON por linha:

```json
{"ts": "2026-10-10T07:25:35.959+00:00", "level": "info", "request_id": "ana-test-1", "method": "POST", "route": "/bookings", "status": 201, "ms": 68.8}
```

Agora "toda reserva que levou mais de 500 ms" é um filtro em `ms`, "toda falha na rota de reservas"
é um filtro em `route` e `status`, e nenhum dos dois quebra quando o texto muda, porque não há texto.
O `request_id` é o campo que paga o resto: ele volta para o cliente num cabeçalho, então uma
reclamação, um chamado de suporte ou uma verificação sintética que falhou podem citá-lo, e a única
linha que importa é achada em um segundo entre milhões.

Duas coisas nunca vão numa linha de log, seja qual for o formato: uma senha ou um token, e qualquer
coisa que identifique uma pessoa além do que a investigação precisa. Logs são copiados para mais
lugares, e guardados por mais tempo, que o banco de dados que eles descrevem.
