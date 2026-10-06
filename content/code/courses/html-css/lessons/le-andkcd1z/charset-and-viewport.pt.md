---
title: Duas linhas que todo head precisa: charset e viewport
version: 1
---

Dois elementos `<meta>` aparecem no head de praticamente toda página da web, e cada um resolve um problema que é invisível na máquina onde a página foi escrita.

## `charset`: que bytes são que letras

Um arquivo é feito de bytes, e a letra *ã* de *São Paulo* não é um byte em toda codificação. Em **UTF-8**, que é o que todo editor moderno salva, são dois bytes; no antigo **ISO-8859-1**, é um. O navegador precisa saber que codificação o arquivo usa antes de transformar bytes em texto, e `<meta charset="utf-8">` diz isso a ele.

Três versões da mesma página mostram o que acontece. A primeira declara UTF-8 e foi salva em UTF-8. A segunda declara UTF-8 e foi salva em ISO-8859-1, que é o que acontece quando um arquivo passa por um editor antigo. A terceira não declara nada.

```
ana@laptop:~/site$ probe charset.html text .where
p.where  "Pinheiros, São Paulo"
ana@laptop:~/site$ probe latin1.html text .where
p.where  "Pinheiros, S�o Paulo"
ana@laptop:~/site$ probe no-charset.html text .where
p.where  "Pinheiros, São Paulo"
```

A primeira está certa. Na segunda, **a declaração mentiu**: o navegador confiou nela, encontrou um byte que não é UTF-8 válido onde deveria estar o *ã* e desenhou o caractere de substituição, �, no lugar. A terceira está certa, e isso merece cuidado: sem declaração, o Chromium adivinhou a codificação pelos bytes, e neste arquivo acertou. Um palpite não é uma decisão. Outro navegador, outro arquivo com menos letras acentuadas ou um servidor que manda o próprio cabeçalho de codificação podem adivinhar diferente, e a página que você conferiu na sua máquina não é a página que o seu leitor recebe.

Então a regra é salvar todo arquivo em UTF-8 e dizer isso nos primeiros 1024 bytes do arquivo, o que na prática quer dizer **a primeira linha dentro do `<head>`**. Ponha antes do título, porque o título é texto e o navegador precisa da codificação para lê-lo.

## `viewport`: a largura da página no celular

Quando os smartphones chegaram, quase todo site era feito para uma tela de desktop de uns mil pixels de largura. Desenhada no tamanho real num celular, uma página dessas mostraria o canto superior esquerdo e mais nada. Então os navegadores móveis fingem: **sem instruções, eles montam a página como se a tela tivesse 980 pixels de largura, e depois encolhem o resultado para caber.**

`probe --mobile` faz o Chromium se comportar como o navegador de um celular, aqui um de 390 pixels de largura, que é um celular comum. A mesma página, sem e com a tag viewport:

```
ana@laptop:~/site$ probe --mobile --width 390 --height 844 --dpr 3 no-viewport.html window box h1
window: 980×2121, device pixel ratio 3
h1  x 8      y 21.44  width 964    height 37
ana@laptop:~/site$ probe --mobile --width 390 --height 844 --dpr 3 viewport.html window box h1
window: 390×844, device pixel ratio 3
h1  x 8      y 21.44  width 374    height 37
```

Sem a tag a janela tem 980 de largura, e um layout de 980 pixels é desenhado numa tela de 390 a 390/980, ou seja, 40 por cento do tamanho. O título tem 32 pixels no CSS e sai com uns 13 no vidro, menor do que um texto corrido deveria ser. Com a tag a janela tem 390 de largura, a página é montada para essa largura e o título aparece com os 32 inteiros.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 392\" role=\"img\" aria-label=\"Dois celulares, cada um com 390 pixels CSS de largura. À esquerda, uma página sem a meta tag viewport: o navegador a monta com 980 pixels de largura e a encolhe para caber, e o título, de 964 pixels, aparece a 40 por cento do tamanho. À direita, a mesma página com a tag: é montada com 390 de largura e o título, de 374, aparece em tamanho real.\"><text x=\"125\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">sem a tag viewport</text><text x=\"125\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">window: 980×2121</text><rect x=\"30\" y=\"50\" width=\"190\" height=\"330\" rx=\"18\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"2\"></rect><rect x=\"40\" y=\"70\" width=\"170\" height=\"290\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"41.39\" y=\"73.72\" width=\"167.22\" height=\"6.42\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"125\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o h1, 964 de largura,</text><text x=\"125\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">encolhido a 40%</text><text x=\"425\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">com a tag viewport</text><text x=\"425\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">window: 390×844</text><rect x=\"330\" y=\"50\" width=\"190\" height=\"330\" rx=\"18\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"2\"></rect><rect x=\"340\" y=\"70\" width=\"170\" height=\"290\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"343.49\" y=\"79.35\" width=\"163.03\" height=\"16.13\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"425\" y=\"87.41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">h1</text><text x=\"425\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o h1, 374 de largura,</text><text x=\"425\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">em tamanho real</text><text x=\"560\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Os dois têm 390</text><text x=\"560\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">pixels CSS de largura.</text><text x=\"560\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Só a página montada</text><text x=\"560\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">pelo navegador muda.</text></svg>", "caption": "O mesmo título de 32px, lido no mesmo celular: uma das páginas foi montada para desktop e encolhida."}
```

A tag que faz isso é sempre a mesma:

```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```

`width=device-width` faz a largura do layout ser a largura do celular, e `initial-scale=1` começa sem zoom. **Nunca acrescente `maximum-scale=1` nem `user-scalable=no`** para impedir o zoom: quem não consegue ler texto pequeno dá zoom para ler, e essa tag tira isso dessa pessoa. A aula 11 é onde mora o resto da responsividade; esta linha é o que torna qualquer parte dela possível, porque uma página encolhida para caber não consegue responder a nada.
