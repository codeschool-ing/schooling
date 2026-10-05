---
title: Aprendido, não escrito
version: 1
---

Ninguém escreveu que *money back* fica perto de *refund*. O modelo aprendeu isso com exemplos, e o
jeito como aprendeu decide o que ele consegue e o que não consegue fazer.

## Treinado com pares

Um modelo de embedding de frases é treinado com **pares de textos que andam juntos**: uma pergunta e
a resposta aceita, um título e seu artigo, duas legendas da mesma foto, uma frase e sua paráfrase. O
treino aproxima os vetores de cada par e os afasta dos vetores dos outros textos do mesmo lote. Isso
se chama treino **contrastivo**, porque cada passo contrasta um parceiro certo com muitos errados.

Depois de pares suficientes, o modelo precisa pôr *money back* perto de *refund*, porque nos dados de
treino os dois apareciam o tempo todo nos dois lados de pares que combinavam. Ele nunca viu a
definição de nenhum dos dois. Viu quais textos as pessoas colocavam juntos.

Daí saem duas consequências, e o resto do curso esbarra nelas o tempo todo.

- **O modelo sabe o que os dados de treino sabiam.** O all-MiniLM-L6-v2 foi treinado em inglês. A
  próxima seção mostra o que ele faz com português.
- **Perto quer dizer *perto do jeito que os pares de treino eram perto*.** Se os pares eram
  perguntas e respostas, uma pergunta cai perto da resposta. Se eram paráfrases, um texto cai perto
  da sua reformulação. A aula 8 mostra os provedores perguntando qual dos dois você está fazendo,
  exatamente por isso.

## Dois jeitos de montar o vetor

O all-MiniLM-L6-v2 é um **transformer**: ele divide o texto em pedaços, dá a cada pedaço um vetor
inicial e depois passa por seis camadas em que cada pedaço olha para todos os outros e ajusta o
próprio vetor. Só depois disso os pedaços viram um vetor só, pela média. O vetor final de cada
pedaço depende dos vizinhos, e é por isso que esse tipo de modelo se chama **contextual**.

O outro modelo que o curso roda, o **WordLlama**, pula as camadas. Cada token tem um vetor fixo,
aprendido no treino, e o vetor de um texto é a média dos vetores dos seus tokens. Esse tipo se chama
**estático**. Ele é muito menor e muito mais rápido, e a aula 10 mede quanto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Dois caminhos lado a lado. Estático, como no WordLlama: os cinco tokens de the dog bit the man são buscados numa tabela de vetores fixos, e os cinco vetores viram um só pela média, com 256 números; a ordem se perde. Contextual, como no all-MiniLM-L6-v2: os pedaços recebem vetores iniciais, passam por seis camadas em que cada pedaço olha para todos os outros, e só então viram um só pela média, normalizado, com 384 números.\"><defs><marker id=\"twopt-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">estático (WordLlama)</text><rect x=\"20\" y=\"50\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"47\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">the</text><path d=\"M47 76 L47 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twopt-ah0)\"></path><rect x=\"82\" y=\"50\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"109\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dog</text><path d=\"M109 76 L109 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twopt-ah0)\"></path><rect x=\"144\" y=\"50\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"171\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bit</text><path d=\"M171 76 L171 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twopt-ah0)\"></path><rect x=\"206\" y=\"50\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"233\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">the</text><path d=\"M233 76 L233 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twopt-ah0)\"></path><rect x=\"268\" y=\"50\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">man</text><path d=\"M295 76 L295 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twopt-ah0)\"></path><rect x=\"20\" y=\"102\" width=\"302\" height=\"30\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"171\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">busca um vetor fixo</text><path d=\"M322 117 L380 117\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twopt-ah0)\"></path><rect x=\"382\" y=\"102\" width=\"110\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">média</text><path d=\"M492 117 L540 117\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twopt-ah0)\"></path><rect x=\"542\" y=\"102\" width=\"130\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"607\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">256 números</text><text x=\"437\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a ordem se perde aqui</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">contextual (all-MiniLM-L6-v2)</text><rect x=\"20\" y=\"210\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"47\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">the</text><path d=\"M47 236 L47 260\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twopt-ah0)\"></path><rect x=\"82\" y=\"210\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"109\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dog</text><path d=\"M109 236 L109 260\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twopt-ah0)\"></path><rect x=\"144\" y=\"210\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"171\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bit</text><path d=\"M171 236 L171 260\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twopt-ah0)\"></path><rect x=\"206\" y=\"210\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"233\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">the</text><path d=\"M233 236 L233 260\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twopt-ah0)\"></path><rect x=\"268\" y=\"210\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">man</text><path d=\"M295 236 L295 260\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twopt-ah0)\"></path><rect x=\"20\" y=\"262\" width=\"302\" height=\"30\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"171\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">6 camadas: cada pedaço olha os outros</text><path d=\"M322 277 L380 277\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twopt-ah0)\"></path><rect x=\"382\" y=\"262\" width=\"110\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">média</text><path d=\"M492 277 L540 277\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twopt-ah0)\"></path><rect x=\"542\" y=\"262\" width=\"130\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"607\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">384 números</text><text x=\"171\" y=\"308\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a ordem molda cada vetor aqui</text></svg>", "caption": "Um modelo estático tira a média de vetores fixos, então as mesmas palavras em qualquer ordem dão o mesmo vetor. Um modelo contextual deixa os pedaços se enxergarem antes da média, e é assim que a ordem entra.", "same": ["contextual (all-MiniLM-L6-v2)"]}
```

A diferença aparece assim que a ordem das palavras importa:

```schooling-example
{
  "language": "python",
  "file": "order.py",
  "parts": [
    {
      "code": "from minilm import embed\nfrom wordllama import WordLlama\n\na, b = \"the dog bit the man\", \"the man bit the dog\"\nwl = WordLlama.load()",
      "note": "Duas frases com as mesmas cinco palavras em outra ordem, e o modelo estático carregado ao lado do contextual."
    },
    {
      "code": "m = embed([a, b])\nprint(\"minilm    \", round(float(m[0] @ m[1]), 4))",
      "note": "A nota do modelo contextual para o par."
    },
    {
      "code": "w = wl.embed([a, b], norm=True)\nprint(\"wordllama \", round(float(w[0] @ w[1]), 4))",
      "note": "A nota do modelo estático. `norm=True` pede ao WordLlama vetores de comprimento 1, para que o produto escalar seja comparável com a linha de cima."
    },
    {
      "code": "print(wl.tokenizer.encode(a, add_special_tokens=False).tokens)",
      "note": "Os tokens dos quais o WordLlama tirou a média, sem o marcador que ele põe no começo."
    }
  ]
}
```

```
ana@lab:~/emb$ python order.py
minilm     0.9795
wordllama  1.0
['▁the', '▁dog', '▁bit', '▁the', '▁man']
```

**O WordLlama dá nota 1,0 às duas frases, como se fossem idênticas**, e pelo próprio desenho ele
está certo. As duas frases têm exatamente os mesmos cinco tokens, que a última linha mostra, e uma
média não liga para a ordem. O all-MiniLM-L6-v2 enxerga uma diferença, 0,9795, porque as camadas
deixam *dog* e *man* saberem de que lado de *bit* estão.

Repare como essa diferença é pequena. Mesmo o modelo contextual dá a *the dog bit the man* ("o
cachorro mordeu o homem") e *the man bit the dog* ("o homem mordeu o cachorro") quase a mesma nota,
porque as frases dividem todas as palavras e o assunto. Um embedding mede **sobre o que um texto
fala** muito melhor do que **o que ele afirma**, e esse é o tema da próxima seção.
