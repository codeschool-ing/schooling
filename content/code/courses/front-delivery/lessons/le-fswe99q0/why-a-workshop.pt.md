---
title: Por que um componente precisa de uma oficina
version: 1
---

**Um componente vive em mais estados do que qualquer tela sozinha mostra, e uma oficina é um lugar para
ver todos eles de uma vez.** A linha de sessão do planner é uma data, uma duração e ou a palavra *done* ou
um botão. No app rodando, você vê os estados que os dados por acaso têm nesta semana. Uma sessão de mais de
uma hora, uma semana sem nada planejado, uma linha no tema escuro: cada um só existe quando os dados e as
configurações se alinham, então cada um é o que ninguém olhou antes de ir para o ar.

O jeito comum de conferir um componente é rodar o app e clicar até a tela que o usa. Isso confere o
componente **num estado, num contexto**, depois que tudo em volta carregou. Uma oficina inverte isso: o
componente sozinho, cada estado interessante escrito como exemplo, cada um um link que alguém pode abrir.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"À esquerda: o app num momento mostra a linha de sessão num estado, não feita, tema claro. À direita: a oficina mostra a mesma linha em todo estado escrito, to do, done e long, cada um no tema claro e no escuro, seis quadros lado a lado.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o app, nesta semana</text><rect x=\"20\" y=\"34\" width=\"200\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">JavaScript</text><text x=\"32\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">10-15 · 45 min</text><rect x=\"132\" y=\"74\" width=\"76\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">Mark done</text><text x=\"32\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um estado,</text><text x=\"32\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que os dados tiverem</text><text x=\"260\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a oficina</text><rect x=\"260\" y=\"34\" width=\"140\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">To Do · light</text><text x=\"270\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">45 min</text><rect x=\"260\" y=\"114\" width=\"140\" height=\"66\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">To Do · dark</text><text x=\"270\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">45 min</text><rect x=\"410\" y=\"34\" width=\"140\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Done · light</text><text x=\"420\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">45 min · done</text><rect x=\"410\" y=\"114\" width=\"140\" height=\"66\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Done · dark</text><text x=\"420\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">45 min · done</text><rect x=\"560\" y=\"34\" width=\"140\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Long · light</text><text x=\"570\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2 h 15 min</text><rect x=\"560\" y=\"114\" width=\"140\" height=\"66\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Long · dark</text><text x=\"570\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2 h 15 min</text><text x=\"260\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">todo estado por escrito, em todo tema</text></svg>", "caption": "O app mostra os estados que os dados dele por acaso têm; a oficina mostra todo estado que alguém escreveu.", "same": ["JavaScript", "Mark done"]}
```

## O que é o Storybook

O **Storybook** é a oficina que a maioria das equipes usa. É uma aplicação que roda ao lado da sua, lê
arquivos de exemplos chamados **stories** e desenha cada story num quadro isolado, com uma barra lateral de
todos os componentes e painéis de documentação, controles e acessibilidade. Ele aceita React, Angular, Vue,
Svelte e HTML puro por "frameworks" separados, e as stories que você escreve aqui seriam quase iguais em
qualquer um deles: uma story é um componente mais os argumentos de um estado dele.

| o que você ganha | para que serve |
|---|---|
| um quadro por story | um estado visto sem o app em volta |
| controles | mudar os argumentos de uma story ao vivo, para testar um estado que ninguém escreveu |
| uma página de docs por componente | a documentação, gerada a partir das stories e dos comentários delas |
| o painel de acessibilidade | o axe, rodado na story que você está olhando |
| um build estático | a oficina inteira como uma pasta de arquivos, publicável como o planner |

Existem alternativas menores e de um framework só, como o Ladle para React e o Histoire para Vue e Svelte.
Elas seguem a mesma ideia; o formato de stories do Storybook virou o comum, e as outras o leem ou leem algo
bem parecido.

## Para que ele serve neste curso

O design system precisa de três coisas que uma oficina dá. **Um lugar onde todo componente fica visível**,
para uma designer e um desenvolvedor discutirem a mesma coisa. **Documentação que não tem como ficar
desatualizada**, porque é tirada do código. E **um conjunto de exemplos que testes conseguem visitar**, o
que transforma o pipeline da aula 3 num que pega um componente que mudou por acidente. A última dessas é a
seção sobre stories como testes.
