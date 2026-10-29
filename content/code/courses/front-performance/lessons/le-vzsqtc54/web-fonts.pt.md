---
title: Uma fonte web, e o que ela custa enquanto carrega
version: 1
---

**Uma fonte web é um arquivo que a página baixa antes de poder desenhar o texto naquela tipografia.** Até
lá o navegador tem duas escolhas, e a página escolhe com o descritor `font-display` da regra
`@font-face`:

| `font-display` | enquanto a fonte carrega | o custo |
|---|---|---|
| `block` | o texto é desenhado invisível, por até três segundos | uma página sem palavras; o LCP espera a fonte |
| `swap` | o texto é desenhado na hora numa fonte reserva, e redesenhado na fonte depois | o texto muda debaixo do leitor, e pode se mexer |
| `optional` | como o `swap`, mas a fonte só é usada se chegar quase na hora | a fonte pode nem aparecer numa primeira visita |

Deixar de fora deixa o navegador decidir, e os navegadores nem sempre decidiram igual, então diga qual.

## IBM Plex Sans no planner

A tipografia do planner é a IBM Plex Sans, gratuita sob a SIL Open Font License. O projeto Fontsource
publica ela, e toda outra fonte aberta, como pacotes npm com os arquivos prontos para servir, então dá
para fixá-la como qualquer ferramenta:

```
ana@dev:~/planner$ npm install --save-exact --save-dev @fontsource/ibm-plex-sans@5.3.0

added 3 packages, and audited 146 packages in 739ms

34 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

O pacote traz todo peso em todo alfabeto. O planner precisa de dois arquivos, o regular e o negrito, do
alfabeto latino; copie-os para `public/fonts/`:

```
ana@dev:~/planner$ mkdir -p public/fonts && for w in 400 700; do cp node_modules/@fontsource/ibm-plex-sans/files/ibm-plex-sans-latin-$w-normal.woff2 public/fonts/plex-$w.woff2; done
```

**WOFF2 é o formato para servir**: uma fonte comprimida para a web, lida por todo navegador atual. Servir a
cópia do próprio planner, em vez de apontar para um serviço de fontes, mantém a fonte no mesmo servidor da
página, sem uma segunda conexão para abrir e sem outra empresa sabendo que página foi lida.

No `src/style.css`, ponha a fonte primeiro na lista do body, trocando a primeira linha:

```css
body { font: 16px/1.5 "IBM Plex Sans", system-ui, sans-serif; margin: 0 auto; max-width: 40rem; padding: 1rem; }
```

e acrescente as duas faces no fim, com `block` primeiro, para ver:

```css
@font-face { font-family: "IBM Plex Sans"; src: url("/fonts/plex-400.woff2") format("woff2"); font-weight: 400; font-display: block; }
@font-face { font-family: "IBM Plex Sans"; src: url("/fonts/plex-700.woff2") format("woff2"); font-weight: 700; font-display: block; }
```

Faça o build, reinicie e meça a página inicial, cujo LCP é o texto do aviso, num celular com toda
requisição 300 milissegundos mais lenta:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/ --phone --slow
[vitals] CLS 0.000 good 
[vitals] LCP 944 ms good #notice
```

## Block, depois swap

**O LCP esperou a fonte.** O texto estava lá, com layout feito e invisível, até a fonte chegar. A cascata
diz quando foi:

```
ana@dev:~/planner$ node tools/waterfall.ts http://localhost:3000/ --slow
/                              305 ms     691 B  ######
/assets/index-Du7rLN0M.js      619 ms    6918 B        ######
/assets/index-B7yWkOCo.css     618 ms     385 B        ######
/fonts/plex-400.woff2          945 ms   22611 B               ######
/fonts/plex-700.woff2          946 ms   22842 B               ######
```

**As fontes só começam depois de a folha de estilo chegar**: o navegador fica sabendo de uma fonte por uma
regra `@font-face`, e só a pede quando sabe que algum texto da página a usa. Então a fonte é um terceiro
degrau, depois do HTML e do CSS. Troque os dois `font-display: block` por `font-display: swap`, faça o
build, reinicie e meça:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/ --phone --slow
[vitals] LCP 640 ms good #notice
[vitals] CLS 0.001 good #app>ul.courses>li>TEXT
```

**Trezentos milissegundos antes, e um CLS que não é mais zero.** O texto foi pintado na fonte reserva e
depois redesenhado na Plex, cujas letras não têm a mesma largura, e uma linha da lista de cursos se mexeu.
Pouco aqui; numa página de parágrafos, cada linha cuja quebra muda mexe todas as linhas abaixo dela.

## Pedindo cedo

O degrau que a fonte espera é a folha de estilo. **`<link rel="preload">`** conta ao navegador de um arquivo
antes de qualquer coisa citá-lo, então ele é pedido junto com os outros arquivos do HTML. No `index.html`,
acrescente estas duas linhas logo antes do `<title>`:

```html
    <link rel="preload" href="/fonts/plex-400.woff2" as="font" type="font/woff2" crossorigin />
    <link rel="preload" href="/fonts/plex-700.woff2" as="font" type="font/woff2" crossorigin />
```

O `as="font"` dá a ela a prioridade de uma fonte, e o `crossorigin` é obrigatório mesmo no mesmo servidor,
porque fontes são sempre pedidas em modo CORS e um preload sem ele seria baixado uma segunda vez. Faça o
build, reinicie e meça:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/ --phone --slow
[vitals] LCP 636 ms good #notice
[vitals] CLS 0.000 good 
```

**As fontes agora chegam com a folha de estilo**, o texto é pintado uma vez, em Plex, e nada se mexe. Numa
rede de celular de verdade a fonte ainda pode atrasar, e então o swap ainda acontece: o que o torna
inofensivo é a próxima seção.
