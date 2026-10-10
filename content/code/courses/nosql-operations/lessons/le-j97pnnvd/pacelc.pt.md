---
title: PACELC, o preço pago quando nada está quebrado
version: 1
---

O CAP descreve uma tarde ruim. **O PACELC descreve todas as outras tardes**, e para a maioria dos
sistemas é ali que o custo da consistência é de fato pago.

O nome é uma frase. Daniel Abadi a escreveu em 2010 e a publicou em 2012: **se há uma Partição,
escolha entre Disponibilidade (A) e Consistência; senão (Else), escolha entre Latência e
Consistência.** A primeira metade é o CAP. A segunda é a observação que o CAP deixa de fora: mesmo
com uma rede perfeita, manter cópias em acordo custa tempo em toda escrita, e um sistema precisa
decidir se paga esse tempo.

## Para onde vai o tempo

Uma escrita só é consistente entre cópias depois que as outras cópias a têm. Então um sistema que
promete "depois de ouvir que deu certo, todas as cópias concordam" precisa esperar as outras cópias
responderem antes de dizer qualquer coisa. Essa espera é de pelo menos uma ida e volta pela rede
até a cópia mais lenta que ele espera.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" aria-label=\"A linha do tempo de uma escrita. À esquerda, a cópia em São Paulo responde ao cliente assim que tem a escrita e a envia a Lisboa depois. À direita, a cópia em São Paulo primeiro envia a escrita a Lisboa, espera Lisboa confirmar e só então responde ao cliente, pelo menos uma ida e volta depois.\"><defs><marker id=\"pac1-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"pac1-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"pac1-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"175\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">senão latência: responder na hora</text><text x=\"50\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cliente</text><line x1=\"50\" y1=\"52\" x2=\"50\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"170\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">São Paulo</text><line x1=\"170\" y1=\"52\" x2=\"170\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Lisboa</text><line x1=\"300\" y1=\"52\" x2=\"300\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"50\" y1=\"70\" x2=\"168\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#pac1-ah-phosphor)\"></line><text x=\"110.0\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">escrita</text><line x1=\"170\" y1=\"95\" x2=\"52\" y2=\"105\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#pac1-ah-phosphor)\"></line><text x=\"110.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ok</text><line x1=\"170\" y1=\"120\" x2=\"298\" y2=\"165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#pac1-ah-paper-dim)\" stroke-dasharray=\"4 3\"></line><text x=\"260\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">chega depois</text><text x=\"525\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">senão consistência: esperar Lisboa</text><text x=\"400\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cliente</text><line x1=\"400\" y1=\"52\" x2=\"400\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"520\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">São Paulo</text><line x1=\"520\" y1=\"52\" x2=\"520\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"650\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Lisboa</text><line x1=\"650\" y1=\"52\" x2=\"650\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"400\" y1=\"70\" x2=\"518\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#pac1-ah-phosphor)\"></line><text x=\"460.0\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">escrita</text><line x1=\"520\" y1=\"90\" x2=\"648\" y2=\"135\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#pac1-ah-amber)\"></line><line x1=\"650\" y1=\"145\" x2=\"522\" y2=\"190\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#pac1-ah-amber)\"></line><text x=\"593.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">≥ 80 ms</text><text x=\"593.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">ida e volta</text><line x1=\"520\" y1=\"205\" x2=\"402\" y2=\"220\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#pac1-ah-phosphor)\"></line><text x=\"460.0\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ok</text></svg>", "caption": "A mesma escrita, respondida de dois jeitos. Esperar a cópia distante é o que faz todas as cópias concordarem, e custa pelo menos uma ida e volta em toda escrita.", "same": ["São Paulo", "ok", "≥ 80 ms"]}
```

Ponha números na loja. São Paulo e Lisboa ficam a cerca de 7.900 km uma da outra. A luz numa fibra
óptica percorre cerca de 200.000 km por segundo, então uma mensagem de ida e volta não leva menos
que uns 80 ms, antes de qualquer switch, roteador ou servidor ocupado somar a sua parte. Uma escrita
que espera a confirmação de Lisboa custa isso, no mínimo, a cada cliente em São Paulo, em cada
escrita. Uma escrita que responde assim que São Paulo a tem custa um ou dois milissegundos, e Lisboa
alcança um instante depois.

Essa é a segunda escolha:

- **Senão Consistência (EC):** esperar as outras cópias. Toda escrita fica mais lenta, e uma
  leitura em qualquer lugar a enxerga.
- **Senão Latência (EL):** responder na hora e replicar em segundo plano. Toda escrita é rápida e,
  por uma janela curta, uma leitura em outra cópia pode devolver o valor antigo.

A janela do segundo caso costuma ser de milissegundos. Não é zero, e uma aplicação que a supõe zero
tem um bug que só aparece sob carga, só às vezes e nunca no notebook do desenvolvedor, onde todas as
cópias estão numa máquina só. A aula 5 trata do que uma aplicação precisa fazer para conviver com
essa janela.

## Quatro letras para um sistema, e por que descrevem uma configuração

O PACELC classifica um sistema pelas duas escolhas juntas. Um sistema que recusa durante uma
partição e espera as cópias no resto do tempo é **PC/EC**; um que responde durante uma partição e
não espera no resto do tempo é **PA/EL**. Esses dois são os pares comuns, porque um sistema disposto
a pagar latência todo dia em geral também prefere recusar a divergir no dia ruim.

A armadilha é ler as letras como propriedade de um produto. Os três produtos deste curso deixam você
mudar a resposta, e a próxima seção é sobre fazer isso de propósito.
