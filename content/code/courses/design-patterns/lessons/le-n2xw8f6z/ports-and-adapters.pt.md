---
title: Portas e adaptadores, a ideia
version: 1
---

**Portas e adaptadores é a inversão de dependência aplicada a uma aplicação inteira: as regras ficam
no meio, toda conversa com o mundo de fora passa por uma porta que as regras definem, e cada
tecnologia é um adaptador ligado a uma porta.** Alistair Cockburn a descreveu em 2005 e a desenhou
como um hexágono, e por isso ela também se chama arquitetura hexagonal. O hexágono não significa
nada além de deixar espaço para desenhar várias portas.

O mal-entendido comum é achar que se trata de uma organização de pastas, `domain/`, `ports/`,
`adapters/`, que um projeto adota no primeiro dia. As pastas são opcionais. A arquitetura é uma
regra sobre imports, a mesma que a seção anterior verificou com `grep`: nada no meio importa coisa
alguma da borda.

## Dois tipos de porta

A seção anterior construiu uma porta, `Notifier`. As regras a chamam, então a conversa vai para fora;
Cockburn chama isso de porta **conduzida**, e as classes de e-mail e SMS são adaptadores conduzidos.
A outra direção também existe. Algo precisa chamar as regras: uma tarefa agendada, uma requisição
web, uma pessoa num terminal. Esse lado é uma porta **que conduz**, e o código que transforma um
pedido vindo de fora numa chamada às regras é um adaptador que conduz.

`main.py` já era um, um adaptador bem simples que roda numa data fixa. Aqui está um segundo, para o
pessoal do balcão, que digita a data num terminal e quer os avisos por mensagem de texto:

```python
# cli.py
import sys
from datetime import date

from adapters import SmsNotifier
from main import LOANS
from notices import OverdueNotices

today = date.fromisoformat(sys.argv[1])
notifier = SmsNotifier({
    "Bia": "+55 11 5550-0142",
    "Caio": "+55 11 5550-0177",
    "Duda": "+55 11 5550-0103",
})
print(OverdueNotices(notifier).send(LOANS, today), "notices sent")
```

```
ana@laptop:~/patterns/solid-2$ python3 cli.py 2026-03-25
SMS to +55 11 5550-0142: 'Dom Casmurro' is 9 days late, 450 cents so far
SMS to +55 11 5550-0103: 'Vidas Secas' is 2 days late, 100 cents so far
2 notices sent
```

Outra data, outro adaptador conduzido e outro que conduz, e `notices.py` não foi tocado. Em 25 de
março Dom Casmurro está nove dias atrasado, Vidas Secas dois, e Iracema ainda está no prazo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l04-ports\" aria-label=\"As regras no meio, como notices.py com OverdueNotices, e uma porta Notifier na borda direita. À esquerda, o lado que conduz: main.py e cli.py chamam as regras. À direita, o lado conduzido: as regras chamam para fora pela porta Notifier, até EmailNotifier, SmsNotifier e, num teste, Recording. Nada no meio importa coisa alguma das bordas.\"><defs><marker id=\"l04-ports-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">lado que conduz</text><text x=\"620.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">lado conduzido</text><rect x=\"260.0\" y=\"80.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">notices.py</text><text x=\"360.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">OverdueNotices</text><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">as regras</text><rect x=\"430.0\" y=\"122.0\" width=\"80.0\" height=\"36.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">Notifier</text><rect x=\"50.0\" y=\"85.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main.py</text><path d=\"M170.0 100.0 L256.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-ports-dp-ah-paper-dim)\"></path><rect x=\"50.0\" y=\"165.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cli.py</text><path d=\"M170.0 180.0 L256.0 180.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-ports-dp-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"65.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">EmailNotifier</text><path d=\"M510.0 140.0 L535.0 140.0 L535.0 80.0 L556.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-ports-dp-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"125.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SmsNotifier</text><path d=\"M510.0 140.0 L535.0 140.0 L535.0 140.0 L556.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-ports-dp-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"185.0\" width=\"130.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"625.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Recording</text><path d=\"M510.0 140.0 L535.0 140.0 L535.0 200.0 L556.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-ports-dp-ah-paper-dim)\"></path><text x=\"625.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">num teste</text><text x=\"360.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nada no meio importa coisa alguma das bordas</text></svg>", "caption": "Portas e adaptadores: os adaptadores que conduzem chamam as regras, e as regras chegam a cada adaptador conduzido por uma porta que é delas."}
```

## O que o formato compra, e o que custa

Cada adaptador pode ser trocado sozinho. Um formulário web no lugar do terminal é um adaptador novo
que conduz; um gateway de SMS de verdade no lugar do `print` é um novo conduzido. As regras podem
ser testadas pelo lado que conduz, chamando-as diretamente, e pelo lado conduzido, com um dublê que
anota, que é exatamente o que `test_notices.py` fez.

O custo é uma porta para cada tipo de conversa, e código para traduzir em cada borda: o texto do
terminal vira uma `date`, o texto das regras vira o que a API do gateway quiser. Para um script que
manda um tipo de aviso, essa tradução é a maior parte do programa. O formato compensa quando as
regras são substanciais e as bordas são várias ou têm chance de mudar.

Esta lição para na ideia. `architecture-modeling`, o curso depois deste, desenha portas e
adaptadores como modelos de sistemas inteiros; a lição 12 deste curso põe um repositório atrás de
uma porta; e a lição 15 reencontra o mesmo formato como o núcleo funcional com uma casca imperativa
em volta.
