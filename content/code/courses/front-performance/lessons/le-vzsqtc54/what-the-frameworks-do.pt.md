---
title: O que os frameworks fazem
version: 1
---

**Tudo nesta aula é um passo que cada um dos quatro frameworks da aula 2 pode dar por você**, e cada um dá
um conjunto diferente deles. Conhecer os passos é o que permite dizer quais o seu deu. Esta seção foi lida
na documentação de cada framework e, onde diz *conferido*, no pacote instalado nos projetos da aula 2;
nada dela foi rodado.

## Imagens

| | o componente | o que ele faz sozinho | o que você ainda decide |
|---|---|---|---|
| **Next.js** | `<Image>` de `next/image` | redimensiona sob demanda no próprio servidor, escreve o `srcset`, manda WebP por padrão (conferido), faz carregamento lazy se não for mandado o contrário, exige `width` e `height` ou `fill` | o `sizes`; e o `preload` na imagem do LCP, a prop que substituiu o `priority` no Next.js 16 (conferido) |
| **Nuxt** | `<NuxtImg>` e `<NuxtPicture>`, do módulo `@nuxt/image`, instalado à parte | redimensiona por um provider, por padrão o IPX, um servidor feito sobre o sharp; o `<NuxtPicture>` escreve o `<source>` por formato | o `sizes`, os formatos, e `preload` e `loading` em cada imagem |
| **SvelteKit** | `<enhanced:img>`, do pacote `@sveltejs/enhanced-img` | no build, com o sharp: as cópias, AVIF e WebP, o `srcset`, e `width` e `height` tirados do arquivo | o `sizes` e o `fetchpriority`; só funciona com imagens do projeto, não com as de um servidor |
| **Angular** | a diretiva `NgOptimizedImage`, `ngSrc` num `<img>` | exige `width` e `height`, faz carregamento lazy por padrão, e com `priority` põe `fetchpriority="high"` e, quando renderizada no servidor, acrescenta um preload (conferido) | as próprias cópias: ela escreve um `srcset` para o loader de um serviço de imagens e não redimensiona |

## Fontes

| | o que faz |
|---|---|
| **Next.js** | o `next/font` baixa a fonte no build e a serve pela aplicação, com `display: "swap"` e `adjustFontFallback` ligados por padrão (conferido): ele escreve uma face reserva para Arial ou Times New Roman com o `size-adjust` da seção "Uma fonte reserva que ocupa o mesmo espaço", calculado a partir dos arquivos da fonte |
| **Nuxt** | o `@nuxt/fonts` lê as famílias de fonte que o seu CSS cita, baixa e as serve pela aplicação, e calcula faces reserva com a biblioteca fontaine |
| **SvelteKit** | nada próprio; o Fontsource e o CSS desta aula são o caminho comum |
| **Angular** | o build de produção embute na página o CSS do Google Fonts, e embute o CSS crítico com o Beasties, como a seção "A folha de estilo, dentro da página" disse |

## Lendo-os

**Nenhum dá todos os passos**, e as lacunas diferem: o Next.js e o Angular deixam o `sizes` com você, o
SvelteKit deixa a fonte, o Angular deixa o redimensionamento para um serviço. E cada padrão é uma decisão que
alguém tomou para a maioria das páginas: carregamento lazy por padrão é certo para uma página de miniaturas
e errado para a primeira imagem dela, e é por isso que os quatro têm um jeito de dizer "esta é a do LCP" e
nenhum consegue saber qual é. O LCP request discovery do Lighthouse é a conferência de que você disse.
