---
title: Decidindo, e o custo de decidir errado
version: 1
---

**A decisão não é "web ou nativo" para sempre. É qual caminho para este app, agora, com estas
pessoas.** Um embrulho é a resposta certa muito mais vezes do que a fama dele diz, e a errada em alguns
casos fáceis de reconhecer depois de nomeados.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l06-decide\" aria-label=\"Três perguntas em ordem. Primeira: o núcleo do app acontece fora da tela dele, em widgets, num relógio, em trabalho em segundo plano? Se sim, nativo ou React Native. Se não, segunda: o núcleo é uma interação que a web faz mal num celular, como listas compridas o dia todo ou gestos pesados? Se sim, meça primeiro, e se o teto for da plataforma, nativo ou React Native. Se não, terceira: o app faz algo que o site dele não faz? Se sim, embrulhe. Se não, o site, talvez como Progressive Web App, pode ser a resposta certa, sem loja nenhuma.\"><defs><marker id=\"l06-decide-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"48.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o núcleo acontece</text><text x=\"115.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">fora da tela?</text><rect x=\"260\" y=\"30\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"48.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o núcleo é o que a web</text><text x=\"355.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">faz mal num celular?</text><rect x=\"500\" y=\"30\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"48.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ele faz o que o</text><text x=\"595.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">site dele não faz?</text><path d=\"M210 55 L260 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decide-ah-paper-dim)\"></path><text x=\"235\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">não</text><path d=\"M450 55 L500 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decide-ah-paper-dim)\"></path><text x=\"475\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">não</text><rect x=\"20\" y=\"170\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"188.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nativo, ou</text><text x=\"115.0\" y=\"201.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">React Native</text><rect x=\"260\" y=\"170\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"188.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">meça primeiro:</text><text x=\"355.0\" y=\"201.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">de quem é o teto?</text><rect x=\"500\" y=\"130\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">embrulhe</text><rect x=\"500\" y=\"200\" width=\"190\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"595.0\" y=\"215.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o site, talvez</text><text x=\"595.0\" y=\"228.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">como PWA</text><path d=\"M115 80 L115 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decide-ah-paper-dim)\"></path><text x=\"128\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">sim</text><path d=\"M355 80 L355 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decide-ah-paper-dim)\"></path><text x=\"368\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">sim</text><path d=\"M260 195 L210 195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l06-decide-ah-paper-dim)\"></path><path d=\"M560 80 L560 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decide-ah-paper-dim)\"></path><text x=\"573\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">sim</text><path d=\"M680 80 L680 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-decide-ah-paper-dim)\"></path><text x=\"668\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">não</text></svg>", "caption": "Três perguntas, nesta ordem. A maioria dos apps chega à terceira, e a maioria desses está certa em ser embrulhada.", "same": ["React Native"]}
```

## Embrulhe quando

- **o app é principalmente telas de informação e formulários**, que é a maioria dos apps: listas,
  detalhes, um checkout, um planner;
- **a equipe é uma equipe web**, e uma segunda base de código em Swift e Kotlin seria mantida por
  ninguém;
- **o app web existe e funciona**, e o celular acrescenta algumas capacidades que um plugin cobre;
- **o tempo importa mais que os últimos dez por cento de sensação**, como importa numa primeira versão.

## Vá para o nativo, ou para o React Native, quando

- **o núcleo do app acontece fora da tela dele**: widgets, um relógio, trabalho em segundo plano,
  integração profunda com o sistema, da tabela de duas seções atrás;
- **o núcleo é uma interação que a web faz mal num celular**: listas compridas roladas o dia todo, gestos
  pesados, gráficos em tempo real, uma câmera com processamento em cada quadro;
- **a medida diz que o teto é da plataforma**, depois de o desenho do próprio app ter sido corrigido, que
  é a ordem em que a seção de medida insiste.

## O que errar custa, em cada direção

**Embrulhar um app que precisava ser nativo** custa a revisão, as avaliações e depois uma reescrita que
começa tarde, muitas vezes com a página da loja para manter. Os sinais aparecem cedo, na lista de
conferência e na medida, e é por isso que elas vêm antes do envio.

**Escrever nativo um app que podia ter sido embrulhado** custa duas bases de código desde o primeiro dia,
cada recurso escrito duas vezes e testado duas vezes, e uma equipe que precisa conhecer três plataformas
em vez de uma. Esse custo é mais silencioso e muito mais comum: ele não reprova numa revisão, só deixa
cada semana mais cara.

**O React Native é o meio dos dois**, e as aulas 7 a 9 são sobre o que ele compra. Ele mantém uma
linguagem e uma equipe, e devolve os controles da própria plataforma, ao preço de reescrever as telas.
Para o planner, depois desta aula, o veredito honesto é que o embrulho está certo: nada nele acontece
fora da tela a não ser o lembrete, que um plugin já trata. As próximas aulas constroem a versão nativa
mesmo assim, para a comparação ser feita com as duas nas suas mãos.
