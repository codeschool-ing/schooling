---
title: O caminho de uma consulta
version: 1
---

Quando uma busca parece lenta, o banco vetorial é o primeiro suspeito, porque é a parte com "busca"
na descrição do trabalho. Nos tamanhos com que a maioria das aplicações começa, ele costuma ser o
suspeito errado. Uma consulta passa por vários passos entre a pergunta e a resposta, e o jeito de
saber para onde vai o tempo é medir cada um. `path.py` faz uma pergunta ao armazenamento pequeno e
mede os passos em separado:

```schooling-example
{
  "language": "python",
  "file": "path.py",
  "parts": [
    {
      "code": "import time\nfrom minilm import embed\nfrom tinystore import Store\n\nstore = Store.load(\"store\")\nquestion = \"my parcel says delivered but it never came\"\nfor run in range(2):                       # print the second, warm run",
      "note": "Uma pergunta, feita duas vezes: a primeira rodada paga por carregar coisas na memória, então a segunda é a impressa."
    },
    {
      "code": "    t0 = time.perf_counter()\n    q = embed(question)[0]\n    t1 = time.perf_counter()\n    hits = store.search(q, k=3, model=\"all-MiniLM-L6-v2\", lang=\"en\")\n    t2 = time.perf_counter()\n    texts = [store.docs[store.where[id]] for id, _ in hits]\n    t3 = time.perf_counter()",
      "note": "Os três passos de uma consulta, medidos em separado: transformar a pergunta em vetor, buscar na coleção os três melhores em inglês e pegar pelo id os textos desses três."
    },
    {
      "code": "print(f\"embed the question  {(t1 - t0) * 1000:7.3f} ms\")\nprint(f\"search {len(store.ids)} vectors   {(t2 - t1) * 1000:7.3f} ms\")\nprint(f\"fetch the texts     {(t3 - t2) * 1000:7.3f} ms\")\nprint(hits[0][0], texts[0][:50])",
      "note": "Imprima o tempo de cada passo em milissegundos, e o melhor resultado."
    }
  ]
}
```

```
ana@lab:~/emb$ python path.py
embed the question    9.043 ms
search 39 vectors     0.155 ms
fetch the texts       0.005 ms
h09 A parcel marked as delivered that never arrived. C
```

**Transformar a pergunta em vetor levou 9,043 ms; buscar em 39 vetores levou 0,155 ms; pegar os
textos pelo id levou 0,005 ms.** A resposta é a certa, `h09`, o artigo sobre uma encomenda marcada
como entregue que nunca chegou, encontrado com o filtro `lang="en"` aplicado na mesma chamada.
Neste tamanho o modelo é o custo inteiro, e a busca é um erro de arredondamento ao lado dele.
Através de uma API hospedada, o primeiro passo também incluiria uma ida e volta pela internet, que
nenhum ajuste de banco toca.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O caminho de uma consulta, da esquerda para a direita: a pergunta vira vetor (9,043 ms), a coleção é buscada pelos melhores ids (0,155 ms sobre 39 vetores) e os textos são buscados pelo id (0,005 ms). Embaixo do passo de busca, o que um banco vetorial de verdade põe ali: um índice aproximado em vez de ler cada vetor, filtros nos metadados e, se for o caso, um reranker.\"><defs><marker id=\"qppt-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"90\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"55\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">pergunta</text><path d=\"M102 65 L126 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qppt-ah0)\"></path><rect x=\"130\" y=\"40\" width=\"130\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">vetor da pergunta</text><text x=\"195\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">9.043 ms</text><path d=\"M262 65 L296 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qppt-ah0)\"></path><rect x=\"300\" y=\"40\" width=\"120\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">busca</text><text x=\"360\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0.155 ms</text><path d=\"M422 65 L456 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qppt-ah0)\"></path><rect x=\"460\" y=\"40\" width=\"120\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">pegar o texto</text><text x=\"520\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">0.005 ms</text><path d=\"M582 65 L616 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qppt-ah0)\"></path><rect x=\"620\" y=\"40\" width=\"90\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"665\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">resposta</text><text x=\"440\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ids</text><text x=\"360\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">medido com 39 vetores</text><path d=\"M360 150 L360 168\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"170\" y=\"170\" width=\"380\" height=\"110\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"190\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que um banco vetorial põe neste passo:</text><text x=\"200\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">· um índice, não cada vetor (aula 15)</text><text x=\"200\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">· filtros de metadados (aula 17)</text><text x=\"200\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">· um reranker, se for o caso (aula 16)</text></svg>", "caption": "Uma consulta pelo armazenamento pequeno, medida por path.py. Transformar a pergunta em vetor é o passo lento neste tamanho; o passo de busca é o que cresce com a coleção, e o que um banco vetorial substitui."}
```

## Os passos, e no que cada um se transforma

**1. Transformar a pergunta em vetor, com o modelo da coleção.** O mesmo modelo que transformou os
documentos, como as seções anteriores insistiram, e em toda consulta: uma pergunta não pode ser
transformada em vetor com antecedência. Isso faz dela um custo por consulta, que as velocidades
medidas na aula 10 põem na ordem de grandeza certa: um texto pelo MiniLM nesta máquina leva
milissegundos.

**2. Achar candidatos.** O armazenamento pequeno lê todos os vetores, que é a busca exata da aula 3
e a primeira seção desta aula. Um banco vetorial troca esse passo por um **índice aproximado**, que
lê uma parte pequena da coleção e devolve quase os mesmos primeiros resultados. É o passo cujo
custo cresce com a coleção, e os 129,16 ms que `brute.py` mediu para um milhão de vetores são o
que o índice existe para evitar. A aula 15 mostra como um índice funciona e quanto custa o "quase".

**3. Filtrar.** `lang="en"` deixou os artigos em português de fora. O armazenamento pequeno confere
o filtro em cada registro e dá aos que não passam uma nota de menos infinito, o que é correto e
simples. Dentro de um índice aproximado é mais difícil, porque o índice acha primeiro os vetores
mais próximos e alguns deles podem não passar no filtro; a aula 17 mede o que isso faz com os
resultados.

**4. Reordenar, se for o caso.** Alguns sistemas pegam mais candidatos do que precisam e dão nova
nota a eles com um modelo mais lento e melhor antes de ficar com os poucos melhores. A aula 16
descreve isso. O armazenamento pequeno não tem esse passo.

**5. Devolver ids, depois buscar aquilo para que eles apontam.** A resposta da própria busca são
ids e notas. O texto que uma pessoa lê é uma busca pelo id, aqui numa lista do Python e num sistema
de verdade no banco ou nas tabelas da própria loja. É o passo mais barato, e aquele em que uma
cópia desatualizada aparece, se o texto e o vetor não foram escritos juntos.

Os bancos vetoriais das aulas 12 a 14 têm todos esse formato. O que os separa é como o passo 2 é
construído, onde os dados moram e quem cuida da máquina em que eles moram.
