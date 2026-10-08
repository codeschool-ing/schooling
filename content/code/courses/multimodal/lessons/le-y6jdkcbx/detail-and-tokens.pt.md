---
title: Detalhe, blocos e quanto custa uma imagem
version: 2
---

Um modelo de visão não cobra por byte. Cobra pelo quanto da imagem ele lê, e a OpenAI publicou a regra para o GPT-4o: **85 tokens pela imagem como um todo, mais 170 para cada bloco de 512 por 512 pixels** que a cobre, depois de dois redimensionamentos. O `tokens.py` da aula 4 conta por essa regra, então os números abaixo são o que a regra dá; nada é enviado para calculá-los.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A nota em três tamanhos, desenhada em escala. Primeiro como foi enviada, 1240 por 1754 pixels. Depois reduzida até o lado menor ter 768, dando 768 por 1086. Depois essa cópia coberta por uma grade de blocos de 512 pixels, dois na horizontal e três na vertical, seis blocos ao todo; os blocos da última coluna e da última linha passam da borda da página. Ao lado: 85 mais 6 vezes 170 dá 1105 tokens.\"><defs><marker id=\"l08til-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08til-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"161.20000000000002\" height=\"228.02\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1240 x 1754</text><line x1=\"189.20000000000002\" y1=\"140\" x2=\"221.20000000000002\" y2=\"140\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#l08til-ah-phosphor)\"></line><rect x=\"230\" y=\"30\" width=\"99.84\" height=\"141.18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">768 x 1086</text><line x1=\"337.84000000000003\" y1=\"100\" x2=\"369.84000000000003\" y2=\"100\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l08til-ah-amber)\"></line><rect x=\"380\" y=\"30\" width=\"99.84\" height=\"141.18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"380.0\" y=\"30.0\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"380.0\" y=\"96.56\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"380.0\" y=\"163.12\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"446.56\" y=\"30.0\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"446.56\" y=\"96.56\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"446.56\" y=\"163.12\" width=\"66.56\" height=\"66.56\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"380\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">6 blocos de 512</text><text x=\"540\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">caber em 2048 x 2048</text><text x=\"540\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(já cabe)</text><text x=\"540\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lado menor para 768</text><text x=\"540\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1240 -&gt; 768</text><text x=\"540\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">contar blocos de 512</text><text x=\"540\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 x 3 = 6</text><text x=\"540\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">85 + 6 x 170</text><text x=\"540\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">= 1105 tokens</text><text x=\"20\" y=\"285\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Com detail low o modelo vê uma cópia pequena, e custa 85 seja qual for o tamanho.</text></svg>", "caption": "A regra de blocos que a OpenAI publicou para o GPT-4o, como o tokens.py da aula 4 conta: a página é redimensionada duas vezes antes de qualquer cobrança."}
```

Para a nota, de 1240 por 1754 pixels:

1. **Caber em 2048 por 2048.** Ela já cabe.
2. **Reduzir até o lado menor ter no máximo 768.** 1240 vira 768, e 1754 vira 1086.
3. **Contar os blocos de 512 pixels que a cobrem.** Dois na horizontal, três na vertical: 6.
4. **85 + 6 × 170 = 1.105 tokens.**

Com `detail: "low"` nada disso acontece: o modelo vê uma cópia pequena da imagem e ela custa **85 tokens**, seja qual for o tamanho. Com `"auto"` (o padrão) o provedor escolhe. Um programa consegue calcular tudo isso antes de mandar qualquer coisa:

```python
"""What a picture costs a vision model by the tile rule, before anything is sent."""
from tokens import gpt4o_tokens

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

Com `detail: "low"` o modelo da OpenAI lê uma cópia pequena da imagem. **O Ollama ignora o campo `detail`**, então o modelo do curso não consegue mostrar a configuração em si; o que ele consegue mostrar é o que ela faz, porque uma cópia pequena é algo que você mesmo faz. A nota na largura dela, na metade e num quarto, cada uma com a pergunta do total.

`sizes.py`:

```python
"""The invoice at three widths: how many tokens the model is charged, and whether it still reads the total."""
import base64
import io

from openai import OpenAI
from PIL import Image

page = Image.open("media/invoice-0931.png")
client = OpenAI()
for width in (1240, 620, 310):
    small = page.resize((width, round(page.height * width / page.width)), Image.LANCZOS)
    buf = io.BytesIO()
    small.save(buf, "PNG")
    url = "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()
    reply = client.chat.completions.create(
        model="qwen2.5vl:3b", temperature=0, seed=1,
        messages=[{"role": "user", "content": [
            {"type": "text", "text": "What is the total on this invoice? Answer with the amount only."},
            {"type": "image_url", "image_url": {"url": url}},
        ]}])
    print(f"{width:5} x {small.height:4}  {reply.usage.prompt_tokens:5} tokens in   {reply.choices[0].message.content.strip()}")
```

```
ana@lab:~/mm$ python sizes.py
 1240 x 1754   2807 tokens in   758.50
  620 x  877   1088 tokens in   758.50
  310 x  438   1088 tokens in   758.50
```

**Este modelo conta por pixels, com um piso.** A página inteira custou 2.807 tokens e metade da largura custou 1.088, uns dois quintos. Um quarto da largura custou os mesmos 1.088, porque o Qwen2.5-VL aumenta uma imagem abaixo do seu tamanho mínimo antes de lê-la, então dali para baixo uma imagem menor deixa de ser mais barata. Essa é a regra deste modelo, como a regra de blocos é a do GPT-4o, e todo provedor tem uma.

**E ele leu o total em todos os tamanhos**, até com 310 pixels de largura, onde o Tesseract da aula 2 errou nove caracteres em dez. Um modelo de visão e linguagem lida com uma página pequena e borrada muito melhor que o OCR, e é justamente isso que torna difícil duvidar da resposta dele: numa página em que uma pessoa já não consegue ler os dígitos, ele ainda responde no mesmo tom confiante. Aqui a resposta está certa. A aritmética da própria nota, na próxima seção, é como você descobriria se não estivesse.

Então baixo detalhe é uma escolha de leitura. Uma cópia pequena basta para *o que é esta imagem?*; para *o que ela diz?* é um risco que você mede nas suas próprias páginas, não uma configuração em que se confia.

**Outros modelos contam diferente.** O gpt-4o-mini cobra muito mais tokens pelos mesmos blocos a um preço menor por token, modelos mais novos contam em recortes pequenos em vez de blocos, e o Gemini tem regra própria (aula 9). O método é o que vale guardar: leia a regra do provedor, calcule o custo da sua imagem típica antes de mandar, e redimensione para o menor tamanho que ainda responde à pergunta.
