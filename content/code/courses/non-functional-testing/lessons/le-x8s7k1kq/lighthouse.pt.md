---
title: O Lighthouse nas duas páginas
version: 1
---

O **Lighthouse** é o auditor de páginas do Google: ele abre uma página no Chrome, grava tudo o que
o navegador fez enquanto a carregava e transforma essa gravação nas métricas das seções
anteriores, numa nota e numa lista do que corrigir. Ele roda na linha de comando, o que o torna
usável num pipeline, e o mesmo motor está no painel Lighthouse das ferramentas de desenvolvedor do
Chrome e por trás do PageSpeed Insights.

## Instalando, e um navegador para ele

O Lighthouse é um programa Node.js, e o Node está na máquina desde a aula 7. Ele precisa de um
Chrome ou Chromium para conduzir, e a VM não tem navegador. O mais simples de conseguir é o
Chromium que o Playwright baixa, o mesmo navegador que a aula 10 de `web-automation` usou. Três
linhas, no seu segundo terminal (a bilheteria roda no primeiro):

```sh
sudo npm install -g lighthouse@13.5.0
mkdir -p ~/browser && cd ~/browser && npm init -y && npm install playwright@1.56.0 && npx playwright install --with-deps chromium
cd ~/boxoffice
```

A primeira instala o Lighthouse para todos os usuários. A segunda cria um projetinho cujo único
trabalho é guardar o Playwright, e então pede ao Playwright o Chromium dele e as bibliotecas de
sistema de que o navegador precisa. **Estas linhas rodaram na máquina de gravação com uma
exceção**: o navegador em si não pôde ser baixado ali, então o mesmo build foi copiado de outra
instalação do Playwright 1.56.0. As bibliotecas foram instaladas pelo mesmo comando. Confira os
dois:

```
ana@nft:~/boxoffice$ lighthouse --version
13.5.0
ana@nft:~/boxoffice$ ~/.cache/ms-playwright/chromium-1194/chrome-linux/chrome --version
Chromium 141.0.7390.37 
```

O Lighthouse procura o Chrome nos lugares de costume, e um navegador dentro do cache do Playwright
não está em nenhum deles. Mandado rodar sem saber onde ele está, para na hora:

```
ana@nft:~/boxoffice$ lighthouse http://127.0.0.1:8000/ --quiet 2>&1 | head -1
Runtime error encountered: The CHROME_PATH environment variable must be set to a Chrome/Chromium executable no older than Chrome stable.
```

A variável que ele cita recebe o caminho do navegador. Ponha no `~/.profile`, para todo terminal
novo ter a variável, e leia de volta:

```
ana@nft:~/boxoffice$ echo 'export CHROME_PATH=$HOME/.cache/ms-playwright/chromium-1194/chrome-linux/chrome' >> ~/.profile
ana@nft:~/boxoffice$ source ~/.profile && echo $CHROME_PATH
/home/ana/.cache/ms-playwright/chromium-1194/chrome-linux/chrome
```

**Mais uma flag é necessária no Ubuntu 24.04, e vale entendê-la antes de digitar.** O Chromium
isola o código de cada página web num sandbox, e montar esse sandbox exige user namespaces sem
privilégio, que o Ubuntu 24.04 restringe pelo AppArmor para programas que ele não instalou. Um
Chromium baixado, então, se recusa a iniciar a menos que seja mandado dispensar o sandbox:
`--no-sandbox`. Isso é aceitável para um navegador de teste que só abre a sua própria página em
`127.0.0.1`, e não é jeito de ninguém navegar na web. O Playwright inicia o Chromium dele sem o
sandbox por padrão pelo mesmo motivo. `--headless=new` roda o navegador completo sem janela, já
que a VM não tem tela.

## A página lenta

O comando é comprido porque cada flag tira algo de que esta aula não precisa: `--quiet` cala o log
de progresso, `--only-categories=performance` pula as auditorias de acessibilidade, SEO e boas
práticas, e `--output=json` com `--output-path` grava o relatório em JSON num arquivo. O relatório
HTML que o Lighthouse grava por padrão é feito para uma pessoa com um navegador, e um relatório
JSON é feito para um programa, que é o que o `jq` é.

O `jq` consegue tirar os números com um filtro guardado num arquivo. Crie o
`~/boxoffice/metrics.jq`:

```
# boxoffice/metrics.jq
# The score and the five timings this lesson reads out of a Lighthouse report.
{
  score: .categories.performance.score,
  FCP: .audits["first-contentful-paint"].displayValue,
  LCP: .audits["largest-contentful-paint"].displayValue,
  TBT: .audits["total-blocking-time"].displayValue,
  CLS: .audits["cumulative-layout-shift"].displayValue,
  "Speed Index": .audits["speed-index"].displayValue
}
```

Toda auditoria do relatório tem um `displayValue`, o número como o relatório HTML o imprime, e um
`numericValue` em milissegundos (ou sem unidade, no caso do CLS), que é o que se compara num
programa. Rode o Lighthouse na página lenta e depois leia:

```
ana@nft:~/boxoffice$ lighthouse http://127.0.0.1:8000/ --quiet --only-categories=performance --output=json --chrome-flags="--headless=new --no-sandbox" --output-path=slow.json
ana@nft:~/boxoffice$ jq -f metrics.jq slow.json
{
  "score": 0.37,
  "FCP": "2.8 s",
  "LCP": "13.1 s",
  "TBT": "1,430 ms",
  "CLS": "0.139",
  "Speed Index": "4.6 s"
}
```

Nota 0.37, que o relatório HTML desenharia como 37 de 100, em vermelho. LCP de 13.1 s contra um
limite de 2,5, CLS de 0.139 contra 0,1, e TBT de 1,430 ms numa página cujo único script é um laço.

## A página corrigida

```
ana@nft:~/boxoffice$ lighthouse http://127.0.0.1:8000/fast.html --quiet --only-categories=performance --output=json --chrome-flags="--headless=new --no-sandbox" --output-path=fast.json
ana@nft:~/boxoffice$ jq -f metrics.jq fast.json
{
  "score": 1,
  "FCP": "0.7 s",
  "LCP": "0.9 s",
  "TBT": "0 ms",
  "CLS": "0",
  "Speed Index": "0.7 s"
}
```

**Todos os números estão na faixa boa, e a nota é 1.** O LCP caiu de 13.1 s para 0.9 s, o TBT
para 0 ms, o CLS para 0. O conteúdo das duas páginas é o mesmo; a diferença são os quatro
defeitos.

## Lendo o porquê

A nota diz quão ruim, e as auditorias dizem por quê. Cada auditoria do JSON traz um campo
`details` com as evidências, e quatro delas apontam direto para os defeitos:

```
ana@nft:~/boxoffice$ jq -c '.audits["long-tasks"].details.items[] | [.url, .duration]' slow.json
["http://127.0.0.1:8000/slow.js",2000]
["http://127.0.0.1:8000/",1606.0000000000005]
["Unattributable",50]
ana@nft:~/boxoffice$ jq -r '.audits["layout-shifts"].details.items[].subItems.items[].cause' slow.json
Media element lacking an explicit size
ana@nft:~/boxoffice$ jq -r '.audits["lcp-breakdown-insight"].details.items[1].snippet' slow.json
<img src="hero.png" alt="The stage, lit for tonight's show">
ana@nft:~/boxoffice$ jq -c '.audits["resource-summary"].details.items[] | select(.requestCount > 0) | [.resourceType, .requestCount, .transferSize]' slow.json
["total",4,2435280]
["image",1,2431680]
["other",1,1747]
["document",1,1448]
["script",1,405]
```

- **`long-tasks`** lista as tarefas longas da thread principal. O `slow.js` levou 2000 ms e o
  script da própria página 1606, embora um fique 500 ms em laço e o outro 400. O celular que o
  Lighthouse finge ser tem um processador quatro vezes mais lento que a máquina onde ele roda, e
  a próxima seção mostra onde esse número mora. Os 1606 ms da página vêm depois da primeira
  pintura, e são a maior parte do TBT; o `slow.js` roda antes de qualquer pintura, então atrasa o
  FCP e o LCP.
- **`layout-shifts`** cita a causa do movimento que encontrou: uma imagem sem tamanho explícito.
  Leia como suspeita, não como veredito. A causa é um palpite do Lighthouse, e esta página tem dois
  defeitos que movem conteúdo, a imagem sem tamanho e o banner atrasado. O `fast.html` corrigiu os
  dois, e por isso o CLS dele é 0.
- **`lcp-breakdown-insight`** diz qual elemento foi o largest contentful paint: a imagem pesada.
- **`resource-summary`** conta requisições e bytes por tipo. Quatro requisições, 2435280 bytes,
  dos quais 2431680 são a imagem. A aula 11 põe um orçamento exatamente nesses números.

## De onde vem a nota

A nota não é uma quinta métrica. É uma média ponderada das cinco, cada uma antes convertida numa
nota entre 0 e 1 contra uma curva construída a partir do desempenho de sites reais. Os pesos
estão no relatório:

```
ana@nft:~/boxoffice$ jq -c '.categories.performance.auditRefs[] | select(.weight > 0) | [.id, .weight]' slow.json
["first-contentful-paint",10]
["largest-contentful-paint",25]
["total-blocking-time",30]
["cumulative-layout-shift",25]
["speed-index",10]
```

O TBT leva 30%, e o LCP e o CLS 25% cada, então esses três decidem a maior parte da nota. **Trate
a nota como um resumo para pessoas e as métricas como o requisito.** Uma nota 0,9 não diz se o LCP
está abaixo de 2,5 s, e o requisito da aula 1 nomeia o LCP, não uma nota.
