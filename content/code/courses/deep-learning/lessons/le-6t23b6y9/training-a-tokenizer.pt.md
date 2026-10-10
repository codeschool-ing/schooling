---
title: Treinando um tokenizador de verdade no corpus
version: 1
---

**A biblioteca `tokenizers` faz o que o `bpe.py` fez, em Rust, com os detalhes de que um tokenizador
de verdade precisa.** O principal é que ela trabalha com bytes, não com caracteres, então o vocabulário
inicial são os 256 valores possíveis de um byte, e nenhum texto, em nenhuma língua ou alfabeto, cai
fora dele. Ela treina no seu próprio arquivo, e nada é baixado. Salve isto como `~/dl/tok.py`:

```schooling-example
{
  "language": "python",
  "file": "tok.py",
  "parts": [
    {
      "code": "\"\"\"tok: a byte-level BPE tokenizer trained on corpus.txt, at several vocabulary sizes.\"\"\"\nfrom tokenizers import Tokenizer, decoders, models, pre_tokenizers, trainers",
      "note": "`tokenizers` é a biblioteca que a aula 1 instalou. Nada é baixado aqui: o tokenizador é treinado no seu próprio arquivo."
    },
    {
      "code": "def train(size):\n    tok = Tokenizer(models.BPE())\n    tok.pre_tokenizer = pre_tokenizers.ByteLevel(add_prefix_space=False)\n    tok.decoder = decoders.ByteLevel()\n    trainer = trainers.BpeTrainer(vocab_size=size, show_progress=False,\n                                  initial_alphabet=pre_tokenizers.ByteLevel.alphabet())\n    tok.train([\"corpus.txt\"], trainer)\n    return tok",
      "note": "BPE em nível de byte. O pré-tokenizador corta o texto nos espaços e na pontuação e o transforma em bytes, então o vocabulário começa com os 256 valores de byte e nenhum texto é desconhecido. `vocab_size` diz quando parar de fundir."
    },
    {
      "code": "text = open(\"corpus.txt\").read()\nprint(f\"corpus: {len(text)} characters, {len(text.encode())} bytes\")\nfor size in [256, 300, 400, 500, 600, 800, 1000]:\n    tok = train(size)\n    n = len(tok.encode(text).ids)\n    print(f\"asked {size:4d}  learnt {tok.get_vocab_size():4d}  tokens {n:5d}  characters a token {len(text) / n:.2f}\")",
      "note": "O mesmo corpus, treinado em sete tamanhos, e quantos tokens ele vira em cada um."
    },
    {
      "code": "tok = train(500)\ntok.save(\"tok.json\")\nfor sentence in [\"On Monday the baker sells bread.\", \"On Sunday the weaver sells blankets.\"]:\n    enc = tok.encode(sentence)\n    print(len(enc.ids), \"tokens\", enc.ids)\n    print(\"  \", [tok.decode([i]) for i in enc.ids])",
      "note": "O tamanho 500 é salvo como `tok.json` para o resto da aula. O `decode` de um único id mostra o texto que aquele token representa, com o espaço da frente."
    }
  ]
}
```

```
PENDING tok
```

## Tamanho do vocabulário contra comprimento

Em 256, o vocabulário são só os bytes, e o corpus tem 3.261 tokens, um por byte, exatamente a contagem
de caracteres que o `split.py` imprimiu: todo caractere dele é ASCII simples, um byte cada. Cada degrau
para cima encurta o texto: 1.886 tokens em 300, 1.002 em 500, 758 em 700.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 320\" role=\"img\" aria-label=\"Tokens em que o corpus se transforma contra o tamanho do vocabulário. De 256 bytes isolados até 700 tokens a contagem cai de 3261 para 758, rápido no começo e devagar depois; passado 700 o treinador não tem mais o que fundir.\"><path d=\"M90 260 L600 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 260 L90 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90.0 260 L90.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"90.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">200</text><path d=\"M175.0 260 L175.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"175.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">300</text><path d=\"M260.0 260 L260.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"260.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">400</text><path d=\"M345.0 260 L345.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"345.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">500</text><path d=\"M430.0 260 L430.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"430.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">600</text><path d=\"M515.0 260 L515.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"515.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">700</text><path d=\"M600.0 260 L600.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"600.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">800</text><path d=\"M85 260.0 L90 260.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M85 197.14285714285714 L90 197.14285714285714\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"197.14285714285714\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1000</text><path d=\"M85 134.28571428571428 L90 134.28571428571428\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"134.28571428571428\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2000</text><path d=\"M85 71.42857142857144 L90 71.42857142857144\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"71.42857142857144\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3000</text><text x=\"345.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">tamanho do vocabulário</text><text x=\"90\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">tokens no corpus</text><path d=\"M137.6 55.0 L515.0 212.4\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"137.6\" cy=\"55.022857142857134\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"145.6\" y=\"43.022857142857134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3261</text><circle cx=\"515.0\" cy=\"212.3542857142857\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"523.0\" y=\"200.3542857142857\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">758</text><path d=\"M515.0 212.3542857142857 L600.0 212.3542857142857\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"464.0\" y=\"172.3542857142857\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">toda palavra inteira: nada mais a fundir</text><text x=\"147.6\" y=\"57.022857142857134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">bytes isolados</text></svg>", "caption": "Quanto mais fusões o tokenizador aprende, menos tokens o mesmo texto vira, até não sobrar nada para fundir."}
```

**As primeiras fusões rendem mais.** Ir de 256 para 300 entradas tira 1.375 tokens; ir de 600 para
700 tira 100. Em 800 e em 1.000 o treinador para em 700 entradas. O pré-tokenizador cortou o texto
nos espaços e na pontuação antes de qualquer fusão, uma fusão nunca atravessa esse corte, e em 700
toda palavra do corpus já é um token só. Os 758 que sobram são as próprias palavras e sinais de
pontuação.

Escolher o tamanho é uma troca com três lados. **Um vocabulário maior dá sequências mais curtas**, e
cada passo de um modelo custa tempo por token. **Ele também dá uma tabela de embeddings maior**, uma
linha por entrada, que a próxima seção mostra ser um bloco de parâmetros. E cada entrada aparece menos
no treino, então a linha de um token raro aprende com poucos exemplos. Modelos de linguagem ficam em
algum ponto entre dezenas de milhares e algumas centenas de milhares de entradas; esta aula fica em 500
porque o corpus dela é uma página.

## No que uma frase se transforma

As últimas linhas são o que o modelo receberia. `On Monday the baker sells bread.` tem 7 tokens, um
por palavra e um para o ponto final, com ids de 13 a 371. **O espaço pertence ao token que vem depois
dele**: ` Monday` com o espaço é uma entrada, e `Monday` no começo de uma linha seria outra. É assim que
a decodificação devolve os espaços sem adivinhar.

`On Sunday the weaver sells blankets.` tem 15. `Sunday` aparece uma vez no corpus, raro demais para
ganhar uma fusão própria neste tamanho, então sai como ` S`, `u` e `nday`. `weaver` e `blankets` nunca
estiveram no corpus e se quebram em quatro pedaços cada. **Nenhum `<unk>` em lugar nenhum**: o alfabeto
de bytes no fundo garante isso, e o custo de uma palavra estranha é comprimento, nunca um buraco.

Os ids em si não querem dizer nada. 288 é ` baker` por causa da ordem em que este treino fez as fusões,
e um tokenizador treinado em outro texto o numeraria de outro jeito. É por isso que um modelo e o
tokenizador dele são sempre distribuídos juntos, e por isso a próxima coisa a explicar é como uma rede
transforma um número arbitrário em algo com que consegue calcular.
