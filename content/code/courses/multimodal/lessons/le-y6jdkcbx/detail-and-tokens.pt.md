---
title: Detalhe, blocos e quanto custa uma imagem
version: 1
---

Um modelo de visão não cobra por byte. Cobra pelo quanto da imagem ele lê, e a OpenAI publicou a regra para o GPT-4o: **85 tokens pela imagem como um todo, mais 170 para cada bloco de 512 por 512 pixels** que a cobre, depois de dois redimensionamentos. O labmm conta por essa regra, então os números abaixo são o que a regra dá, calculados pela implementação do próprio laboratório.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A nota em três tamanhos, desenhada em escala. Primeiro como foi enviada, 1240 por 1754 pixels. Depois reduzida até o lado menor ter 768, dando 768 por 1086. Depois essa cópia coberta por uma grade de blocos de 512 pixels, dois na horizontal e três na vertical, seis blocos ao todo; os blocos da última coluna e da última linha passam da borda da página. Ao lado: 85 mais 6 vezes 170 dá 1105 tokens.\"><defs><marker id=\"l08til-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08til-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"161.20000000000002\" height=\"228.02\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1240 x 1754</text><line x1=\"189.20000000000002\" y1=\"140\" x2=\"221.20000000000002\" y2=\"140\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l08til-ah-phosphor)\"></line><rect x=\"230\" y=\"30\" width=\"99.84\" height=\"141.18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">768 x 1086</text><line x1=\"337.84000000000003\" y1=\"100\" x2=\"369.84000000000003\" y2=\"100\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l08til-ah-amber)\"></line><rect x=\"380\" y=\"30\" width=\"99.84\" height=\"141.18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"380.0\" y=\"30.0\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"380.0\" y=\"96.56\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"380.0\" y=\"163.12\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"446.56\" y=\"30.0\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"446.56\" y=\"96.56\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"446.56\" y=\"163.12\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"380\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">6 blocos de 512</text><text x=\"540\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">caber em 2048 x 2048</text><text x=\"540\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(já cabe)</text><text x=\"540\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lado menor para 768</text><text x=\"540\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1240 -&gt; 768</text><text x=\"540\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">contar blocos de 512</text><text x=\"540\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 x 3 = 6</text><text x=\"540\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">85 + 6 x 170</text><text x=\"540\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">= 1105 tokens</text><text x=\"20\" y=\"285\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Com detail low o modelo vê uma cópia pequena, e custa 85 seja qual for o tamanho.</text></svg>", "caption": "A regra de blocos que a OpenAI publicou para o GPT-4o, como o labmm conta: a página é redimensionada duas vezes antes de qualquer cobrança."}
```

Para a nota, de 1240 por 1754 pixels:

1. **Caber em 2048 por 2048.** Ela já cabe.
2. **Reduzir até o lado menor ter no máximo 768.** 1240 vira 768, e 1754 vira 1086.
3. **Contar os blocos de 512 pixels que a cobrem.** Dois na horizontal, três na vertical: 6.
4. **85 + 6 × 170 = 1.105 tokens.**

Com `detail: "low"` nada disso acontece: o modelo vê uma cópia pequena da imagem e ela custa **85 tokens**, seja qual for o tamanho. Com `"auto"` (o padrão) o provedor escolhe. Um programa consegue calcular tudo isso antes de mandar qualquer coisa:

```python
"""What a picture costs a vision model by the tile rule, before anything is sent."""
from labmm import gpt4o_tokens

PRICE = 2.5 / 1_000_000          # gpt-4o, dollars per input token, from the sheet
SIZES = [("the cover", 600, 900), ("the invoice", 1240, 1754), ("the invoice, half size", 620, 877),
         ("the photograph", 640, 416), ("a phone photo", 4000, 3000), ("a video frame", 1280, 720)]
print(f"{'':24}{'high':>6} {'tiles':>5} {'low':>5}   per 1,000 at high")
for name, w, h in SIZES:
    high, tiles = gpt4o_tokens(w, h, "high")
    low, _ = gpt4o_tokens(w, h, "low")
    print(f"{name:24}{high:6} {tiles:5} {low:5}   ${high * 1000 * PRICE:.2f}")
```

```
ana@lab:~/mm$ python tiles.py
                          high tiles   low   per 1,000 at high
the cover                  765     4    85   $1.91
the invoice               1105     6    85   $2.76
the invoice, half size     765     4    85   $1.91
the photograph             425     2    85   $1.06
a phone photo              765     4    85   $1.91
a video frame             1105     6    85   $2.76
```

Três lições estão nessa tabela. **Uma foto de celular de 4000 por 3000 custa os mesmos 765 tokens da capa**: o redimensionamento joga fora quase todos os seus 12 milhões de pixels antes de qualquer contagem, então mandá-la no tamanho cheio paga o upload e não compra nada. **A nota com metade da largura custa 765 em vez de 1.105**, e a aula 2 mediu que ela ainda se lê com 1,4% de erro de caracteres. E **cada 1.000 notas custam US$ 2,76 ao preço de entrada do gpt-4o**, de 2,5 dólares por milhão de tokens, lido da tabela. É barato por página e é o piso: o prompt, a resposta e qualquer nova tentativa vêm por cima (aula 13).

## Baixo detalhe é uma escolha de leitura

A mesma nota, perguntada sobre o total, nas duas configurações:

```
ana@lab:~/mm$ python look.py media/invoice-0931.png "What is the total on this invoice?" low
This is an invoice from Lantern & Quill Distributors to Marginalia Books. It lists four book titles with quantities and prices, and a total at the bottom, but at this resolution the figures are too small for me to read reliably.
[96 tokens in, 49 out]
ana@lab:~/mm$ python look.py media/invoice-0931.png "What is the total on this invoice?" high
The invoice is INV-0931 from Lantern & Quill Distributors, dated 2026-09-15. The total is BRL 758.50: a subtotal of 713.50 plus 45.00 shipping.
[1116 tokens in, 48 out]
```

**As duas respostas foram escritas pelo curso**, para mostrar a diferença: em baixo detalhe a resposta consegue dizer que tipo de documento é e quem o mandou, e não consegue ler os números. As contagens do labmm são reais: 96 tokens de entrada em baixo detalhe, 1.116 em alto, sendo os 11 a mais o texto da própria pergunta. Baixo detalhe serve para *o que é esta imagem?* e não para *o que ela diz?*.

**Outros modelos contam diferente.** O gpt-4o-mini cobra muito mais tokens pelos mesmos blocos a um preço menor por token, modelos mais novos contam em recortes pequenos em vez de blocos, e o Gemini tem regra própria (aula 9). O método é o que vale guardar: leia a regra do provedor, calcule o custo da sua imagem típica antes de mandar, e redimensione para o menor tamanho que ainda responde à pergunta.
