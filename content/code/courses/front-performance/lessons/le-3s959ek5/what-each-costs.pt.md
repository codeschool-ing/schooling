---
title: Quanto cada uma custa
version: 1
---

**No seu próprio computador os dois servidores são instantâneos, e é exatamente por isso que
medi-los ali não diz nada.** Cada requisição do planner viaja alguns centímetros. Um celular numa
rede móvel espera um décimo de segundo ou mais a cada ida e volta antes de um único byte voltar, e
a diferença entre os dois jeitos de renderizar é uma contagem dessas idas e voltas.

`look.ts --slow` faz o navegador esperar 300 milissegundos a mais em cada requisição, o que as
ferramentas de desenvolvedor do Chromium chamam de **latência**: o tempo antes do primeiro byte, não
a velocidade do download. Os dois servidores ainda estão rodando das seções anteriores, o preview
na porta 4173 e o `server.ts` na 3000. Ligue o preview de novo num terceiro terminal se você o
parou.

## Renderizada no cliente, mais lenta

```
ana@dev:~/planner$ node tools/look.ts http://localhost:4173/ --slow
requests: / /assets/index-Dv4jVJdV.js /assets/index-1yLCgpWc.css /courses.json
first contentful paint: 948 ms
text on the screen:
Study planner
HTML and CSS · 2 sessions
JavaScript · 2 sessions
Git · 2 sessions
Weeks
Week of 2026-10-19: 210 min, 105 done
Week of 2026-10-26: 40 min, 0 done
```

## Renderizada no servidor, mais lenta

```
ana@dev:~/planner$ node tools/look.ts http://localhost:3000/ --slow
requests: / /assets/index-Dv4jVJdV.js /assets/index-1yLCgpWc.css /courses.json
first contentful paint: 640 ms
text on the screen:
Study planner
HTML and CSS · 2 sessions
JavaScript · 2 sessions
Git · 2 sessions
Weeks
Week of 2026-10-19: 210 min, 105 done
Week of 2026-10-26: 40 min, 0 done
```

**A página renderizada no servidor pintou primeiro, e o motivo está na lista de requisições, não
nos servidores.** As duas fizeram as mesmas quatro requisições. A renderizada no cliente não
conseguia pintar antes de o HTML, depois o script, depois os dados voltarem, um depois do outro,
porque cada um só era descoberto quando o anterior chegava. A renderizada no servidor pintou assim
que o HTML e a sua folha de estilo chegaram, e o script e os dados vieram depois, sem nada
esperando por eles. **948 milissegundos contra 640 são mais ou menos três esperas de 300 contra
duas**, mais os poucos milissegundos que o trabalho em si levou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Duas cascatas de requisições com 300 milissegundos somados a cada uma. No cliente: o HTML, depois o script e a folha de estilo, depois os dados, três esperas seguidas, e a primeira pintura aos 948 milissegundos. No servidor: o HTML, depois a folha de estilo, e a primeira pintura aos 640 milissegundos, enquanto o script e os dados chegam depois dela.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">no cliente</text><rect x=\"150.0\" y=\"46\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"156.0\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">/</text><rect x=\"305.0\" y=\"69\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"311.0\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">index-….js</text><rect x=\"305.0\" y=\"92\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"311.0\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">index-….css</text><rect x=\"460.0\" y=\"115\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"466.0\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">/courses.json</text><line x1=\"624.0\" y1=\"40\" x2=\"624.0\" y2=\"135\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></line><text x=\"618.0\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pintura 948 ms</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">no servidor</text><rect x=\"150.0\" y=\"176\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"156.0\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">/</text><rect x=\"305.0\" y=\"199\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"311.0\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">index-….css</text><rect x=\"305.0\" y=\"222\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"311.0\" y=\"231\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">index-….js</text><rect x=\"460.0\" y=\"245\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"466.0\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">/courses.json</text><line x1=\"470.0\" y1=\"170\" x2=\"470.0\" y2=\"268\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></line><text x=\"476.0\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pintura 640 ms</text></svg>", "caption": "As duas páginas fizeram as mesmas requisições. Só a renderizada no cliente teve de esperar a terceira para poder desenhar. As barras têm 300 ms de desenho; as duas pinturas são as medidas."}
```

Os números são desta máquina, neste dia. Na sua vão diferir em dezenas de milissegundos; o que não
vai diferir é que a pintura renderizada no cliente espera uma ida e volta a mais, e que uma
requisição de dados de verdade, de um banco de verdade, soma o seu próprio tempo a essa ida.

## A metade da conta que fica com o servidor

Renderizar no servidor mudou o trabalho de lugar, não o eliminou. O `curl` sabe dizer quanto tempo
um servidor levou antes do primeiro byte, o que ele chama de `time_starttransfer`:

```
ana@dev:~/planner$ for i in 1 2 3; do curl -s -o /dev/null -w '%{time_starttransfer}\n' http://localhost:3000/; done
0.002319
0.001859
0.001862
```

Uns dois milissegundos, para três cursos lidos de um arquivo num disco rápido. **O que cresce não é
esse número, e sim quantas vezes ele é pago**: uma vez por visualização de página, pelo seu
servidor, onde uma página renderizada no cliente não custava ao servidor nada além de entregar um
arquivo. Uma página que precisa de uma consulta lenta ao banco para renderizar faz cada primeira
visão esperar essa consulta antes do primeiro byte, e esse é o único momento em que a renderização
no cliente consegue pintar algo, um spinner ou um quadro vazio, mais cedo.

## O resumo

| | a primeira pintura espera | o servidor faz por visualização | um crawler vê | um cache pode guardar a página |
|---|---|---|---|---|
| no cliente | o HTML, o script e os dados, um de cada vez | entrega arquivos | uma página vazia | sim, os mesmos arquivos para todo mundo |
| no servidor | o HTML e a sua folha de estilo | renderiza a página | a página | só se ela for igual para todo mundo |
| híbrida | o HTML e a sua folha de estilo | renderiza a primeira página | a página | como no servidor |
| no build (aula 3) | o HTML e a sua folha de estilo | entrega arquivos | a página | sim |
