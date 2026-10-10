---
title: O R8 a 360 pixels
version: 1
---

Conferir o R8 num celular não precisa de um celular para começar. **Todo navegador de desktop atual
tem um modo responsivo**, que encolhe a área em que a página é desenhada para qualquer largura que
você digitar e redesenha a página como um navegador daquele tamanho faria. É a conferência de
compatibilidade mais rápida que existe, e na página inicial do boxoffice ela acha um defeito em
menos de um minuto.

## Abrindo o modo responsivo

Com o boxoffice rodando, abra `http://127.0.0.1:8000` e então:

- no Chrome ou no Edge, abra as ferramentas de desenvolvedor com F12 (Cmd+Option+I num Mac) e tecle
  Ctrl+Shift+M (Cmd+Shift+M num Mac), ou clique no ícone de um celular e um tablet no alto, à
  esquerda das ferramentas. Aparece uma barra acima da página; escolha Responsive no primeiro menu
  dela se ele mostrar o nome de um aparelho, e digite 360 na caixa de largura;
- no Firefox, Ctrl+Shift+M (Cmd+Option+M num Mac) abre direto o Responsive Design Mode, com uma
  caixa de largura no alto;
- no Safari, o menu Develop tem Enter Responsive Design Mode, depois que o menu Develop for ligado
  nos ajustes do Safari.

Este curso fez a conferência no Chromium 141, o navegador de código aberto a partir do qual o
Chrome é feito; os passos do Firefox e do Safari estão descritos e não foram executados.

## O que 360 pixels mostram

A 360 pixels a página mantém o título, Shows, e a tabela começa como sempre, mas só duas das cinco
colunas cabem: o nome do espetáculo, e a data e a hora, que terminam bem na borda. **O preço, os
lugares restantes e os links Book ficam fora da tela, à direita.** Arraste a página para o lado, ou
deslize o dedo num celular, e eles aparecem; os links abaixo da tabela, Shows, Sign up e Outbox,
continuam onde estavam.

Quanto fica fora da tela é algo que o próprio navegador diz. Abra a aba Console das mesmas
ferramentas de desenvolvedor, digite `document.documentElement.scrollWidth` e tecle Enter. Ele
responde com a largura da página inteira em pixels CSS, e no Chromium a 360 pixels a resposta foi
**776**: a página tem mais que o dobro da largura da janela em que está.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 250\" role=\"img\" data-fig=\"l07-narrow-screen\" aria-label=\"A página inicial do boxoffice desenhada em escala numa janela de 360 pixels de largura. A página tem 776 pixels de largura. Dentro da janela ficam o título Shows e as duas primeiras colunas da tabela, Show e When. As colunas Price, Seats left e os links Book ficam fora da janela, à direita, a uma rolagem para o lado.\"><rect x=\"30.0\" y=\"20.0\" width=\"620.8\" height=\"162.0\" rx=\"14\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"30.0\" y=\"20.0\" width=\"288.0\" height=\"162.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\"></rect><text x=\"42.8\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"700\" fill=\"var(--paper)\">Shows</text><text x=\"48.4\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">Show</text><text x=\"48.4\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">The Seagull</text><text x=\"48.4\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Hamlet</text><text x=\"212.4\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper-dim)\">When</text><text x=\"212.4\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2026-10-10 20:00</text><text x=\"212.4\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2026-10-17 20:00</text><text x=\"389.2\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper-dim)\">Price</text><text x=\"389.2\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 60,00</text><text x=\"389.2\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">R$ 80,00</text><text x=\"487.6\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper-dim)\">Seats left</text><text x=\"487.6\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">120</text><text x=\"487.6\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">80</text><text x=\"593.2\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper-dim)\"></text><text x=\"593.2\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">Book</text><text x=\"593.2\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">Book</text><text x=\"42.8\" y=\"146.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">Shows · Sign up · Outbox</text><text x=\"484.4\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">fora da tela</text><text x=\"484.4\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a uma rolagem para o lado</text><path d=\"M30.0 208.0 L318.0 208.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M30.0 203.0 L30.0 213.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M318.0 203.0 L318.0 213.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"174.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a janela: 360</text><path d=\"M30.0 234.0 L650.8 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M30.0 229.0 L30.0 239.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M650.8 229.0 L650.8 239.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"340.4\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a página: 776</text></svg>", "caption": "A página inicial a 360 pixels, desenhada nas larguras que o Chromium mediu. A janela mostra o nome e a data; o preço, os lugares e o link Book ficam na parte da página fora dela."}
```

## Por que acontece

O próprio estilo da página diz por quê, e dá para lê-lo sem navegador. No segundo terminal:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o 'table.shows{[^}]*}'
table.shows{width:760px}
```

A tabela de espetáculos é mandada ter 760 pixels de largura, qualquer que seja a janela. Some os 16
pixels de margem que a página guarda à esquerda e a página tem 776 pixels de largura, o número que o
console deu. No Windows sem um shell Unix, o Exibir código-fonte do navegador mostra a mesma regra,
no bloco `<style>` perto do topo.

Uma outra causa de página que não cabe no celular pode ser descartada do mesmo jeito. Uma página sem
a linha de viewport no cabeçalho é diagramada pelos navegadores de celular como se a tela fosse a de
um desktop e depois encolhida, o que deixa tudo minúsculo em vez de cortado. O boxoffice tem a
linha:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<meta name="viewport"[^>]*>'
<meta name="viewport" content="width=device-width, initial-scale=1">
```

Então a página pede, sim, para ser diagramada na largura do celular, e é a tabela fixa que se
recusa.

## Onde o problema começa

360 é a largura que o R8 cita, e não é onde o problema começa. Medida do mesmo jeito no Chromium, a
página ainda tem 776 pixels de largura numa janela de 768, largura comum de um tablet em pé, e numa
janela de 775. A 776 ela cabe. **Toda janela mais estreita que 776 pixels rola para o lado**, que é o
raciocínio de valor-limite da aula 4 aplicado a uma largura: a borda está entre 775 e 776, e os 360
do R8 ficam bem dentro do lado que falha.

As outras páginas passam a 360. Sign up e Book cabem, com a página exatamente da largura da janela.
A caixa de saída não, depois que guarda um e-mail: no Chromium a largura dela deu 423, porque o link
de confirmação é uma linha longa que não quebra. Isso merece uma anotação e não é um defeito contra o
R8, porque a caixa de saída é a página da versão de teste e não uma das páginas do teatro, como disse
a seção 04 da aula 1.

## É um defeito?

O R8 diz que toda página funciona numa tela de celular de 360 pixels de largura. Na página inicial,
nessa largura, o preço e o link Book, as duas coisas que a página existe para mostrar, exigem uma
rolagem para o lado para serem encontrados, e nada na tela avisa que há algo para rolar. Isso é um
desvio do R8, é o risco E de layout no celular do plano da aula 1, e é um defeito: **a tabela de
espetáculos tem 760 pixels de largura, então o celular rola para o lado**.

O que Ana anota enquanto o defeito está diante dela é o que um relato precisa, e a aula 15 o
transforma num: o requisito, R8; o navegador e a versão, Chromium 141; a largura, 360; o que ela viu;
a largura medida, 776; a regra, `table.shows{width:760px}`; e uma captura de tela, que a barra
responsiva do Chrome oferece no menu da ponta direita. A correção é com Rui.

Um limite continua. O modo responsivo do Chrome desenha com o motor do Chrome em qualquer largura,
então mostra o que o Chrome de um celular faria e não o que o Safari de um iPhone faria. A próxima
seção trata da diferença.
