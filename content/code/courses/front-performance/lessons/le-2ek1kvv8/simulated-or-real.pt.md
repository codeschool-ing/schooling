---
title: Simulado, ou desacelerado de verdade
version: 1
---

**O Lighthouse não carregou a página numa rede lenta.** Olhe as requisições do último relatório: o HTML
terminou em poucos milissegundos, porque o `server.ts` está no mesmo computador. O *método de
throttling* padrão é o `simulate`: o Lighthouse carrega a página a toda velocidade, registra cada
requisição e cada tarefa, e depois **calcula** quanto a mesma carga levaria no celular lento dele, com
um modelo da rede e do processador. É rápido e dá a mesma resposta duas vezes, e por isso é o padrão.

O outro método é o `devtools`, que deixa o navegador lento de verdade, com as mesmas configurações, e
mede o que acontece. Rode cada um três vezes na mesma página:

```
ana@dev:~/planner$ for m in simulate devtools; do for i in 1 2 3; do npm run lighthouse -- http://localhost:3000/ --throttling-method=$m >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|LCP'; done; done
performance 75, throttling simulate
  LCP  4.3 s    weight 25
performance 75, throttling simulate
  LCP  4.3 s    weight 25
performance 75, throttling simulate
  LCP  4.3 s    weight 25
performance 100, throttling devtools
  LCP  1.3 s    weight 25
performance 100, throttling devtools
  LCP  1.3 s    weight 25
performance 100, throttling devtools
  LCP  1.3 s    weight 25
```

**Duas coisas para ler.** Cada método concorda consigo mesmo, a poucos pontos. E **os dois discordam
entre si em três segundos de LCP**: uns quatro para o modelo, pouco mais de um quando o navegador foi
desacelerado de verdade, e por isso uma nota de 75 contra uma de 100.

## Qual dos dois acertou

O último relatório é de `devtools`, então as requisições dele terminaram nos tempos que o navegador
desacelerado viu:

```
ana@dev:~/planner$ node tools/report.ts report.report.json | grep 'request /'
  request /                            done at  4026 ms, 633040 B
  request /assets/index-C9VFYfGa.js    done at  1372 ms, 17819 B
  request /assets/index-CGM1waBA.css   done at  1198 ms, 538 B
  request /favicon.svg                 done at  4765 ms, 9695 B
```

**O HTML levou quatro segundos para chegar e a página pintou depois de um.** Não há nada de errado nisso:
um navegador não espera o fim de um documento para começar a desenhá-lo. O aviso, o título e os cem
cursos estão no começo do HTML; o plano de cinco mil cursos, que é a maior parte dos bytes, está no fim.
O navegador pintou o que tinha enquanto o resto ainda vinha.

**O modelo não vê isso.** Ele supõe que a página não pode pintar antes de o documento chegar, o que vale
para a maioria das páginas e não vale para esta. Aqui o navegador de verdade acertou, e a simulação foi
pessimista em três segundos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Uma linha do tempo da página inicial pesada no navegador desacelerado. O HTML levou até 4026 ms para chegar. A folha de estilo chegou aos 1198 ms e o script aos 1372 ms, e a página pintou o maior conteúdo por volta dos 1300 ms, com o HTML ainda chegando. O modelo do Lighthouse pôs a mesma pintura por volta dos 4300 ms, depois do documento inteiro.\"><text x=\"110\" y=\"43\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o HTML</text><rect x=\"120.0\" y=\"34\" width=\"469.70000000000005\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"73\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">folha de estilo</text><rect x=\"191.28333333333333\" y=\"64\" width=\"68.48333333333332\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"103\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">script</text><rect x=\"191.28333333333333\" y=\"94\" width=\"88.78333333333333\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><line x1=\"271.66666666666663\" y1=\"26\" x2=\"271.66666666666663\" y2=\"140\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></line><text x=\"271.66666666666663\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pintou, de verdade · 1300 ms</text><line x1=\"621.6666666666667\" y1=\"26\" x2=\"621.6666666666667\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"4 3\"></line><text x=\"621.6666666666667\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pintou, no modelo · 4300 ms</text><line x1=\"120\" y1=\"196\" x2=\"680\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"680.0,196.0 672.6,199.1 672.6,192.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"680\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ms</text></svg>", "caption": "O navegador desenhou o alto da página enquanto o resto ainda vinha.", "same": ["script"]}
```

Isso não deixa os quatro segundos sem sentido. O script do planner é um módulo, e um módulo roda depois
que o documento inteiro foi lido, então naquele celular lento a página parece pronta depois de um
segundo e os botões começam a funcionar depois de quatro: a janela morta da aula 4, com três segundos.
A pintura foi cedo; a página, não.

## O que levar disso

- **Compare igual com igual.** Uma nota de `simulate` e uma de `devtools` não são duas medidas da mesma
  coisa. Escolha um método e mantenha-o num antes e depois.
- **Rode mais de uma vez e fique com a mediana.** A variação aqui foi pequena; num notebook ocupado, ou
  com throttling de `devtools`, ela pode chegar a dez pontos.
- **Quando um número surpreender, olhe do que ele é feito**, aqui as requisições e quando terminaram. Um
  modelo pode errar sobre uma página de um jeito que acerta para a maioria.
