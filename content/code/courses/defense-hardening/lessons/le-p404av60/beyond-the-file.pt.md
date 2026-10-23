---
title: Do arquivo ao comportamento
version: 1
---

**Um antivírus pergunta se um arquivo é ruim. Um EDR pergunta se o que a máquina está fazendo é
ruim.** A aula 7 terminou no limite da primeira pergunta: um programa que ninguém viu antes, um
script que nunca toca o disco ou uma ferramenta comum usada para a coisa errada não têm assinatura
para bater. A segunda pergunta não precisa de uma. Um shell iniciado pela conta do servidor web é
suspeito seja qual for o arquivo desse shell, porque o servidor web nunca precisa de shell.

EDR quer dizer **endpoint detection and response**, detecção e resposta no endpoint, e o nome lista
as partes na ordem em que trabalham:

| parte | o que faz | nesta aula |
|---|---|---|
| telemetria | um sensor na máquina registra o que acontece: processos iniciados, logins, arquivos gravados, conexões abertas | `sensor.py`, menos de quarenta linhas de Python |
| detecção | regras rodam sobre a telemetria e geram um alerta quando uma bate | `detect.py`, três regras |
| resposta | alguém, ou o produto em nome dessa pessoa, age na máquina: para um processo, guarda evidência, corta a máquina da rede | três comandos e um arquivo do `nftables` |
| caça | uma pessoa faz à telemetria guardada uma pergunta que nenhuma regra fez ainda | uma consulta com `jq`, depois das regras |

**A imagem comum de um EDR é a de um antivírus melhor, e ela deixa escapar a parte mais
importante.** Um EDR guarda a telemetria, cada processo com os pais, por dias ou meses, num servidor
longe da máquina. Esse registro é o que deixa quem responde responder às perguntas que importam
depois de um alerta: o que iniciou isto, o que mais isto iniciou, e algo parecido aconteceu em outra
máquina. Um antivírus que bloqueia um arquivo não deixa rastro assim.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l08-loop\" aria-label=\"As partes de um EDR em ciclo. Na máquina, um sensor registra processos, logins, arquivos e conexões como telemetria. A telemetria é enviada para fora da máquina e guardada. Regras rodam sobre ela e geram um alerta. Uma pessoa lê o alerta e age na máquina: guarda a evidência, para o processo, isola o host. Uma segunda seta, da telemetria guardada, vai para a caça, uma pessoa fazendo uma pergunta que nenhuma regra fez.\"><defs><marker id=\"l08-loop-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-loop-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"190.0\" height=\"150.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">web</text><rect x=\"40.0\" y=\"80.0\" width=\"150.0\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"115.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sensor</text><text x=\"115.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">processos, logins,</text><text x=\"115.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">arquivos, conexões</text><rect x=\"270.0\" y=\"80.0\" width=\"120.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"330.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">telemetria, guardada</text><rect x=\"430.0\" y=\"80.0\" width=\"120.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"490.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">regras</text><rect x=\"580.0\" y=\"80.0\" width=\"110.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"635.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">alerta</text><path d=\"M190.0 100.0 L270.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-loop-dh-ah-paper-dim)\"></path><path d=\"M390.0 100.0 L430.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-loop-dh-ah-paper-dim)\"></path><path d=\"M550.0 100.0 L580.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-loop-dh-ah-paper-dim)\"></path><path d=\"M635.0 120.0 L635.0 225.0 L115.0 225.0 L115.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l08-loop-dh-ah-amber)\"></path><text x=\"375.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">resposta: guardar evidência, parar, isolar</text><path d=\"M330.0 120.0 L330.0 165.0 L420.0 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l08-loop-dh-ah-paper-dim)\"></path><text x=\"428.0\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">caça: uma pergunta que nenhuma regra fez</text><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">detecção e resposta</text></svg>", "caption": "O sensor só anota. Tudo o que decide acontece fora da máquina.", "same": ["sensor"]}
```

## O que esta aula constrói, e o que não constrói

Você vai construir um EDR pequeno no `web` com coisas que já estão lá: `/proc`, o journal, Python e
`nftables`. Ele funciona, e falha de jeitos instrutivos, porque um produto de verdade faz escolhas
diferentes justamente nos pontos em que este é fraco. A última seção diz quais.

O incidente que você vai detectar é encenado por você, no seu laboratório, com um comando
inofensivo: a conta do portal inicia um shell, tenta um download de um endereço onde nada responde
e deixa rodando uma cópia de `/bin/sleep` a partir de `/tmp`. Ninguém invade nada. O que importa
para o sensor é que esse é o formato de uma intrusão de verdade por uma aplicação web vista de
dentro, e que o portal nunca faz nada disso por conta própria.

Suba o laboratório com as três máquinas que esta aula usa:

```sh
sudo bash hostlab.sh up web desk admin
```

O `web` é o portal como o `build` o deixou, com os achados da aula 1 de volta no lugar, porque toda
aula começa de uma cópia nova. Nenhum deles muda o que esta aula mede.
