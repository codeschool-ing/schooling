---
title: O limite de que ninguém avisa
version: 1
---

A expectativa óbvia é que um texto longo dê um vetor do texto inteiro, talvez um mais borrado.
**Não dá. Um transformer lê um número fixo de pedaços e descarta o resto, sem erro e sem aviso.** O
all-MiniLM-L6-v2 lê 256 pedaços, e dois deles são `[CLS]` e `[SEP]`, então 254 pedaços de texto são
tudo o que um vetor consegue descrever.

Nenhum artigo da central de ajuda chega perto disso: o mais longo, medido abaixo, tem 102 pedaços.
Os corpos dos oito artigos de entrega juntos num texto só chegam:

```schooling-example
{
  "language": "python",
  "file": "length.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport numpy as np\nfrom tokenizers import Tokenizer\nfrom chromadb.utils.embedding_functions import DefaultEmbeddingFunction\nfrom minilm import embed, pieces\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]"
    },
    {
      "code": "def count(h):\n    text = h[\"title\"] + \". \" + h[\"body\"]\n    return len(text.split()), len(pieces(text))\nfor h in sorted(help, key=lambda h: -count(h)[1])[:4]:\n    print(h[\"id\"], h[\"lang\"], \"%d words, %d pieces\" % count(h))\nlong = \" \".join(h[\"body\"] for h in help if h[\"category\"] == \"shipping\")\nprint(\"shipping bodies joined:\", len(pieces(long)), \"pieces\")",
      "note": "Palavras e pedaços de cada artigo, título e corpo juntos; imprima os quatro com mais pedaços. Depois junte os corpos dos artigos de entrega num texto longo só."
    },
    {
      "code": "tok = Tokenizer.from_file(os.path.join(os.environ[\"MINILM_DIR\"], \"tokenizer.json\"))\ntok.no_truncation()\nstart, end = tok.encode(long).offsets[254]\nprint(\"the last piece read:\", repr(long[start:end]), \"in\", repr(long[end - 40:end + 30]))",
      "note": "Um tokenizador sem limite, para achar onde cai o 254º pedaço de texto. O índice 0 é `[CLS]`, então o índice 254 é o último pedaço que o modelo guarda."
    },
    {
      "code": "a = embed(long)\nb = embed(long + \" Every word after the limit is ignored, however important.\")\nc = embed(\"Refunds go back to the card you paid with. \" + long)\nprint(\"a sentence added at the end:  \", np.abs(a - b).max())\nprint(\"a sentence added at the start:\", np.abs(a - c).max())",
      "note": "O texto longo, o mesmo texto com uma frase depois e o mesmo texto com uma frase antes. Imprima a maior diferença em relação ao vetor original."
    },
    {
      "code": "chroma = np.array(DefaultEmbeddingFunction()([long]))\nprint(\"Chroma, same long text:\", chroma.shape, np.abs(chroma - a).max())",
      "note": "A função de embedding do Chroma, recebendo o mesmo texto longo."
    }
  ],
  "output": "ana@lab:~/emb$ python length.py\nh38 pt 48 words, 102 pieces\nh39 pt 44 words, 89 pieces\nh40 pt 44 words, 85 pieces\nh03 en 53 words, 65 pieces\nshipping bodies joined: 407 pieces\nthe last piece read: 'bent' in 'f a book arrives with a torn cover, bent corners or water damage, phot'\na sentence added at the end:   0.0\na sentence added at the start: 0.07395266\nChroma, same long text: (1, 384) 1.1920929e-07"
}
```

**O texto juntado tem 407 pedaços, e o modelo parou de ler em `bent`** ("dobrados"), no meio do
artigo sobre livros danificados. *corners or water damage, photograph* ("cantos ou dano por água,
fotografe") e tudo o que vem depois não estão no vetor. Uma frase acrescentada no fim não mudou
nada, uma maior diferença de `0.0` nos 384 números. A mesma frase acrescentada no começo mexeu no
vetor, porque os pedaços dela ocuparam lugares dentro dos 254 e empurraram outros tantos pedaços do
texto antigo para depois do corte.

Então uma busca por *water damage* não consegue achar este texto pelo vetor, diga o texto o que
disser.

**Os três artigos mais longos, nas primeiras linhas da saída, são os três em português**, e nenhum
deles é o mais longo em palavras: o h38 tem 48 palavras e 102 pedaços, enquanto o artigo inglês mais
longo em pedaços, o h03, tem 53 palavras e 65. Um modelo com vocabulário inglês quebra palavras em
português em pedaços mais numerosos e menores, então o mesmo limite comporta menos palavras de outra
língua.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Barras medidas em pedaços de palavra. Os oito artigos de entrega juntos têm 407 pedaços; o modelo lê os primeiros 254, até a palavra bent, e descarta os outros 153. Embaixo, o artigo sozinho mais longo, h38, em português, tem 102 pedaços para 48 palavras, e o inglês mais longo, h03, tem 65 pedaços para 53 palavras.\"><text x=\"40\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">corpos de entrega juntos</text><rect x=\"40\" y=\"42\" width=\"387\" height=\"34\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"427\" y=\"42\" width=\"233.1\" height=\"34\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"233.5\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lidos: 254 pedaços</text><text x=\"543.6\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">descartados: 153 pedaços</text><path d=\"M427 30 L427 160\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"433\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o limite</text><text x=\"421\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">bent</text><rect x=\"40\" y=\"116\" width=\"155.4\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"201.4\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">102</text><text x=\"231.4\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">h38, português, 48 palavras</text><rect x=\"40\" y=\"150\" width=\"99\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">65</text><text x=\"175\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">h03, inglês, 53 palavras</text><text x=\"40\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M40 184 L40 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"192.4\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><path d=\"M192.4 184 L192.4 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"344.8\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><path d=\"M344.8 184 L344.8 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"427\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">254</text><path d=\"M427 184 L427 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"497.1\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300</text><path d=\"M497.1 184 L497.1 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"649.5\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><path d=\"M649.5 184 L649.5 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M40 184 L680 184\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"660.2\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">407</text><text x=\"680\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pedaços de palavra</text></svg>", "caption": "O modelo lê 254 pedaços de texto, e o resto não está no vetor. O mesmo limite comporta menos palavras em português, porque um vocabulário inglês corta as palavras em português em mais pedaços."}
```

## Quem corta, e quem avisa

**O `minilm.py` corta em silêncio**, porque faz o que o sentence-transformers faz: o
`max_seq_length` da biblioteca é 256 para este modelo, e a documentação dela diz que uma entrada
mais longa é cortada. É um padrão razoável para uma biblioteca e perigoso para um pipeline, porque
quem sofre são os documentos longos, e nada na saída os aponta.

**O Chroma também corta em silêncio**, na versão que este laboratório roda. A função de embedding
dele tem uma verificação que levanta um `ValueError` para um texto com mais de 256 pedaços. A última
linha de `length.py` mostra que ela não disparou: o tokenizador do Chroma está configurado para
cortar em 256 antes de a verificação contar, então a verificação conta no máximo 256 e passa. O
vetor que ele devolveu bate com o do `minilm.py` para o mesmo texto longo até `1.1920929e-07`, ou
seja, é o mesmo vetor cortado.

## O que fazer

Conte antes de transformar em vetor. `minilm.pieces(text)` dá todos os pedaços de um texto, antes do
corte, e o tokenizador de cada modelo pode fazer o mesmo; um texto acima do limite deve ser cortado
de propósito, em vez de deixado para a biblioteca. A aula 3 cortou textos longos em trechos para a
busca, e o curso `rag` faz do tamanho do trecho uma decisão de projeto. O limite é uma propriedade
de cada modelo, escrita no card dele, e a próxima seção mostra onde lê-lo. A planilha de preços da
aula 8 mostrou como os limites dos provedores ficam longe uns dos outros.
