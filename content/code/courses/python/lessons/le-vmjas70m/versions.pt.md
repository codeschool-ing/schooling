---
title: `==`, `>=`, `~=`, e o que um número de versão promete
version: 2
---

```localised
MAIOR . MENOR . CORREÇÃO
  2   .  31   .     0
```

Versionamento semântico é uma **promessa que o autor faz**: uma versão de correção conserta algo,
uma versão menor acrescenta algo sem quebrar o que existia, e uma versão maior tem permissão de
quebrar coisas. Tudo abaixo se apoia nessa promessa ser cumprida, e na maior parte do tempo ela é.

## Os especificadores, resolvidos num ambiente novo

```sh
requests==2.31.0    →  2.31.0
requests~=2.31.0    →  2.31.0
requests~=2.31      →  2.34.2
requests>=2.26      →  2.34.2
```

Quatro pedidos, três respostas diferentes, rodados esta tarde contra o índice de verdade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 278\" role=\"img\" aria-label=\"Quatro especificadores sobre a mesma faixa de versões. Dois sinais de igual admitem uma versão; o operador de versão compatível com três componentes deixa só a correção se mover; com dois componentes deixa a menor se mover também; e maior-ou-igual admite tudo dali para cima.\"> <text x=\"150\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2.26</text> <rect x=\"149\" y=\"34\" width=\"2\" height=\"8\" rx=\"0\" fill=\"var(--paper-dim)\"></rect> <text x=\"385\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2.31</text> <rect x=\"384\" y=\"34\" width=\"2\" height=\"8\" rx=\"0\" fill=\"var(--paper-dim)\"></rect> <text x=\"535\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2.34.2</text> <rect x=\"534\" y=\"34\" width=\"2\" height=\"8\" rx=\"0\" fill=\"var(--paper-dim)\"></rect> <text x=\"620\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3.0</text> <rect x=\"619\" y=\"34\" width=\"2\" height=\"8\" rx=\"0\" fill=\"var(--paper-dim)\"></rect> <rect x=\"150\" y=\"44\" width=\"470\" height=\"2\" rx=\"0\" fill=\"var(--wire)\"></rect> <text x=\"690\" y=\"214\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no que cada um resolveu, contra o índice de verdade</text> <text x=\"14\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">requests==2.31.0</text> <rect x=\"381\" y=\"62\" width=\"8\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"690\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2.31.0</text> <text x=\"14\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">requests~=2.31.0</text> <rect x=\"385\" y=\"102\" width=\"12\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"690\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2.31.0</text> <text x=\"14\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">requests~=2.31</text> <rect x=\"385\" y=\"142\" width=\"235\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"690\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2.34.2</text> <text x=\"14\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">requests&gt;=2.26</text> <rect x=\"150\" y=\"182\" width=\"470\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"690\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2.34.2</text> <text x=\"360\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Os dois do meio diferem por um componente e por três versões menores.</text> <text x=\"360\" y=\"255\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Uma regra que parece um erro de digitação é para anotar, não para lembrar.</text> </svg>", "caption": "Quatro pedidos, três respostas diferentes — e os dois que se parecem são justamente o par que mais difere."}
```

- **`==2.31.0`** — exatamente essa. Nenhuma surpresa e nenhum conserto também.
- **`~=2.31.0`** — "versão compatível": **o último componente pode se mover**, então isso quer
  dizer `>=2.31.0, ==2.31.*`. Versões de correção, nada além.
- **`~=2.31`** — a mesma regra com um componente a menos, então a versão *menor* pode se mover:
  `>=2.31, ==2.*`. É por isso que resolveu três versões menores à frente.
- **`>=2.26`** — qualquer coisa mais nova, inclusive uma versão maior que tinha permissão de
  quebrar você.

**`~=` é o que vale entender**, e a diferença entre as duas formas dele é a quantidade de
componentes que você escreveu, que é fácil de digitar errado e não produz erro.

## Os outros dois

| especificador | significa |
|---|---|
| `requests>=2.26,<3` | uma faixa, escrita por extenso |
| `requests!=2.32.0` | tudo menos uma versão que saiu quebrada |

Uma vírgula é um **e**. `>=2.26,<3` é a forma explícita de `~=2.26` e vale preferir justamente por
não poder ser mal lida.

## O que um especificador não fixa

```sh
$ python -m pip show requests
Requires: certifi, charset-normalizer, idna, urllib3
```

```sh
requests 2.31.0 asks for:
  urllib3 (<3, >=1.21.1)
  charset-normalizer (<4, >=2)
  certifi (>=2017.4.17)
```

Fixar `requests==2.31.0` exatamente fixa **um** pacote. O `urllib3` pode ser qualquer coisa abaixo
de 3, o `certifi` qualquer coisa desde 2017. Duas instalações do mesmo `requirements.txt`, com um
mês de diferença, podem produzir código diferente — que é a próxima seção.
