---
title: Lendo uma execução de verdade
version: 2
---

O workflow do `shipquote` nunca rodou no GitHub. O repositório que publica este curso roda o dele a
cada pull request e a cada merge, e o GitHub guarda um registro de cada execução que qualquer pessoa
pode ler pela API pública, já que o repositório é público. Esta seção lê uma delas: a execução
disparada pelo merge do pull request do curso anterior, em 6 de outubro de 2026.

`A` é só o endereço da API para as Actions deste repositório, para encurtar os comandos. Defina-o
com `A=https://api.github.com/repos/codeschool-ing/schooling/actions` e os comandos abaixo
funcionam no seu próprio terminal; o curl e o jq são os que a aula 1 instalou:

```
ana@laptop:~$ echo $A
https://api.github.com/repos/codeschool-ing/schooling/actions
ana@laptop:~$ curl -s $A/runs/37488673045 | jq -r "[.name, .event, .head_sha[:7], .conclusion, .run_started_at, .updated_at] | @tsv"
Continuous Integration	push	102e766	success	2026-10-06T15:34:36Z	2026-10-06T15:40:47Z
ana@laptop:~$ curl -s $A/runs/37488673045/jobs | jq -r ".jobs[] | [.name, .conclusion, .started_at, .completed_at] | @tsv"
Changes	success	2026-10-06T15:34:40Z	2026-10-06T15:34:49Z
Go	success	2026-10-06T15:34:52Z	2026-10-06T15:38:08Z
Browser	success	2026-10-06T15:34:52Z	2026-10-06T15:40:46Z
Infra	success	2026-10-06T15:34:52Z	2026-10-06T15:35:15Z
```

A execução é do workflow **Continuous Integration**, disparada por um `push`, no commit `102e766`, e
deu certo. Começou às 15:34:36 UTC e foi atualizada pela última vez às 15:40:47, pouco mais de seis
minutos.

Os jobs mostram a forma. `Changes` rodou primeiro, sozinho, por nove segundos: é o job que decide
quais dos outros a mudança pode afetar. Os outros três começaram todos às 15:34:52, no momento em que
`Changes` terminou, e rodaram **em paralelo**: `Infra` terminou em 23 segundos, `Go` em pouco mais de
três minutos, e `Browser` em quase seis. **A execução durou o tempo do job mais lento**, que é a
observação da aula 5 seção 10 sobre células em paralelo, medida.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do tempo da execução 37488673045 da CI deste repositório, de 15:34:36 a 15:40:47 UTC. Changes roda sozinho primeiro, por 9 segundos. Depois Infra, Go e Browser começam todos às 15:34:52 e rodam em paralelo: Infra leva 23 segundos, Go 3 minutos e 16 segundos e Browser 5 minutos e 54 segundos. A execução termina quando o Browser termina.\"><text x=\"128\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Changes</text><rect x=\"145.8\" y=\"40\" width=\"13.1\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"166.92183288409703\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9s</text><text x=\"128\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Infra</text><rect x=\"163.3\" y=\"82\" width=\"33.5\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"204.76549865229111\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">23s</text><text x=\"128\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Go</text><rect x=\"163.3\" y=\"124\" width=\"285.3\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\"></rect><text x=\"456.57142857142856\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3m16s</text><text x=\"128\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Browser</text><rect x=\"163.3\" y=\"166\" width=\"515.3\" height=\"24\" rx=\"3\" fill=\"var(--amber)\"></rect><text x=\"681.5\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5m54s</text><path d=\"M140.0 210 L140.0 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"140.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+0 min</text><path d=\"M227.3 210 L227.3 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"227.33153638814017\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+1 min</text><path d=\"M314.7 210 L314.7 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"314.66307277628033\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+2 min</text><path d=\"M402.0 210 L402.0 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"401.99460916442047\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+3 min</text><path d=\"M489.3 210 L489.3 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"489.32614555256066\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+4 min</text><path d=\"M576.7 210 L576.7 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"576.6576819407009\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+5 min</text><path d=\"M664.0 210 L664.0 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"663.9892183288409\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">+6 min</text><path d=\"M140 210 L680 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"140\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">minutos desde o início da execução; ela termina quando o job mais lento termina</text></svg>", "caption": "Os mesmos quatro jobs da listagem acima, desenhados contra o relógio. Um job curto decide, três rodam lado a lado, e o mais longo dos três é o tamanho da execução."}
```

## Dentro de um job

Os passos de cada job carregam a própria hora de início e de fim. Eis os cinco passos mais lentos do
job `Go`, em segundos:

```
ana@laptop:~$ curl -s $A/runs/37488673045/jobs | jq -r ".jobs[] | select(.name == \"Go\") | .steps[] | [.number, .name, ((.completed_at | fromdate) - (.started_at | fromdate))] | @tsv" | sort -t$'\t' -k3 -nr | head -5
19	The tests, with a database behind them	141
6	Nothing drops an error on the floor	12
4	Run actions/setup-go@b7ad1dad31e06c5925ef5d2fc7ad053ef454303e	9
2	Initialize containers	7
3	Run actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0	5
```

Um passo domina: **141 segundos** para a suíte de testes Go contra um PostgreSQL real, o passo
chamado *The tests, with a database behind them* (os testes, com um banco por trás). O seguinte, uma
verificação de que nenhum erro é descartado em silêncio, levou 12. Preparar o Go, subir o contêiner
do banco e fazer checkout do código levam segundos cada. É um perfil típico, e diz onde olhar primeiro
se o job ficar lento: não na preparação, que um cache encurtaria, mas na própria suíte.

## Passos com o nome do que prometem

Repare nos nomes dos passos. Este repositório não chama um passo de `Run tests` ou `go test`; dá a
ele o nome da propriedade que confere: *The tests, with a database behind them*, *Nothing drops an
error on the floor* (nada joga um erro no chão). Quando um passo fica vermelho numa lista de trinta,
o nome é a primeira coisa que alguém lê, e um nome que diz o que deixou de ser verdade poupa abrir o
log. É o mesmo conselho que a aula 1 deu para nomear testes, um nível acima.

## Para que serve o registro

A API devolve os mesmos dados que a página desenha: jobs, passos, tempos, conclusões. Lê-los de um
script é como equipes respondem perguntas que a página não responde: qual job ficou mais lento este
mês, com que frequência a `main` fica vermelha, quanto um pull request espera pelas verificações. Na
trilha `tech-lead`, o `delivery-metrics` transforma medidas assim nos quatro números que ensina.
