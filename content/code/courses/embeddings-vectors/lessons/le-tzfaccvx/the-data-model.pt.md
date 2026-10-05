---
title: O modelo de dados
version: 1
---

Todo banco vetorial organiza os dados do mesmo jeito, com nomes diferentes. **Uma coleção guarda
registros, e um registro é um id, um vetor, metadados e, quase sempre, o texto.** O Chroma e o
Qdrant chamam o recipiente de coleção, o Pinecone de índice, o pgvector de tabela, o LanceDB de
tabela também; as aulas 12 a 14 passam por cada um. As partes de um registro são as mesmas em todos
eles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um diagrama aninhado de uma coleção. A caixa de fora é a coleção, com os fatos fixados na criação: o modelo all-MiniLM-L6-v2, a dimensão 384 e a comparação, um produto escalar de vetores de comprimento 1. Dentro dela, registros em linhas, cada um com quatro partes: um id, um vetor de 384 números, metadados com categoria, língua e data, e o texto. Três linhas de exemplo são h14, h15 e h18; h18 aparece tracejado e apagado como lápide, ainda no array até o próximo salvamento.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"310\" rx=\"6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\" font-weight=\"600\">uma coleção</text><text x=\"26\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fixado na criação:</text><text x=\"170\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">all-MiniLM-L6-v2</text><text x=\"320\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">384</text><text x=\"360\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">produto escalar de vetores de comprimento 1</text><text x=\"65\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">id</text><text x=\"195\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vetor</text><text x=\"395\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">metadados</text><text x=\"595\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">texto</text><text x=\"26\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um registro</text><rect x=\"30\" y=\"116\" width=\"64\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"100\" y=\"116\" width=\"184\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"290\" y=\"116\" width=\"204\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"500\" y=\"116\" width=\"184\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"62\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h14</text><text x=\"192\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">[ … ]</text><text x=\"392\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">returns  en  2026-02-02</text><text x=\"592\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">How to return a book. You have…</text><rect x=\"30\" y=\"168\" width=\"64\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"100\" y=\"168\" width=\"184\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"290\" y=\"168\" width=\"204\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"500\" y=\"168\" width=\"184\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"62\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h15</text><text x=\"192\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">[ … ]</text><text x=\"392\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">returns  en  2026-10-05</text><text x=\"592\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">When your refund arrives. We…</text><rect x=\"30\" y=\"220\" width=\"64\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"100\" y=\"220\" width=\"184\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"290\" y=\"220\" width=\"204\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"500\" y=\"220\" width=\"184\" height=\"38\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"62\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">h18</text><text x=\"192\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">[ … ]</text><text x=\"392\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">returns  en  2026-01-08</text><text x=\"592\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Returning a gift. The person…</text><text x=\"30\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">apagado: uma lápide até o próximo salvamento</text><text x=\"192\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">384 números</text></svg>", "caption": "Uma coleção fixa o modelo, a dimensão e a comparação uma vez. Todo registro dentro dela tem as mesmas quatro partes, e um registro apagado fica como lápide até o armazenamento ser compactado.", "same": ["How to return a book. You have…", "When your refund arrives. We…", "Returning a gift. The person…", "id"]}
```

## O registro

**O id é seu, e é a ligação.** Uma busca devolve ids e notas; tudo o que uma pessoa lê vem de
seguir o id de volta até a fonte. Em `tinystore.py` o id é o próprio id do artigo, `h15`, e é isso
que torna uma atualização possível: escrever `h15` de novo quer dizer *este artigo mudou*, e não
*aqui vai outro*. Um armazenamento que inventa os ids por você deixa uma segunda tabela de busca
para manter em dia, o mesmo problema da lista separada ao lado de uma matriz do NumPy.

**O vetor é a única parte que a busca compara.** Ele é o que o modelo produziu a partir do texto, e
não significa nada sem saber que modelo foi esse.

**Os metadados são o que você usa para filtrar e ordenar**: a categoria, a língua e a data aqui, e
numa loja de verdade o estoque, o preço, o cliente a quem um item pertence. Eles ficam ao lado do
vetor para que "só artigos em inglês" faça parte da mesma consulta, como `path.py` faz na última
seção desta aula. A aula 17 trata de como um banco combina esse filtro com a busca, e de por que a
ordem dos dois importa.

**O texto é opcional, e guardá-lo é uma escolha.** Mantê-lo no registro poupa uma segunda busca
para pegar o que foi encontrado. Mantê-lo só no banco da própria loja evita duas cópias que podem
divergir. O Chroma o guarda como `document`; com outros, você o põe nos metadados ou o deixa em
outro lugar.

## A coleção fixa três coisas de uma vez

**Uma coleção guarda os vetores de um modelo, então o modelo e a dimensão dela ficam fixos quando
ela é criada**, e a comparação que ela usa também. `tinystore.py` normaliza todo vetor e compara
por produto escalar, que para vetores de comprimento 1 é a similaridade de cosseno, como a aula 2
mostrou. O Chroma pede a comparação como um `space` na criação da coleção, e o pgvector a embute no
operador e no índice. Mudar qualquer uma das três significa uma coleção nova, que é a migração da
aula 10.

O armazenamento pequeno garante as duas primeiras:

```schooling-example
{
  "language": "python",
  "file": "refuse.py",
  "parts": [
    {
      "code": "from minilm import embed\nfrom wordllama import WordLlama\nfrom tinystore import Store\n\nstore = Store.load(\"store\")\nprint(store.model, store.dim, len(store.ids), \"records\")",
      "note": "Carregue o armazenamento e imprima o que a coleção diz de si mesma."
    },
    {
      "code": "other = WordLlama.load().embed([\"how do I get my money back\"], norm=True)[0]\ntry:\n    store.upsert(\"h99\", other, {}, \"how do I get my money back\")\nexcept ValueError as e:\n    print(\"ValueError:\", e)",
      "note": "Tente guardar um vetor do WordLlama numa coleção do MiniLM."
    },
    {
      "code": "q = embed(\"how do I get my money back\")[0]\ntry:\n    store.search(q, model=\"lab-minilm\")\nexcept ValueError as e:\n    print(\"ValueError:\", e)",
      "note": "Busque com um vetor do MiniLM mas diga outro modelo, como faria um código que esqueceu que modelo a coleção guarda."
    }
  ]
}
```

```
ana@lab:~/emb$ python refuse.py
all-MiniLM-L6-v2 384 40 records
ValueError: all-MiniLM-L6-v2 vectors have 384 numbers, got (256,)
ValueError: this collection holds all-MiniLM-L6-v2 vectors, not lab-minilm
```

**A primeira recusa é a fácil.** Um vetor do WordLlama tem 256 números, a coleção espera 384, e
nenhuma aritmética junta os dois. Todo banco de verdade recusa isso também, com a própria mensagem.

**A segunda recusa é a que salva você.** O vetor da pergunta veio do all-MiniLM-L6-v2, e
`lab-minilm` é o nome que o labembed dá a esse mesmíssimo modelo. O armazenamento não tem como
saber disso: ele compara nomes, não pesos, e recusa. É o lado certo para errar: uma busca que
confiasse em qualquer vetor recebido também aceitaria um de outro modelo com a mesma dimensão, a
falha silenciosa que a aula 10 mediu. Então o nome precisa ser uma string só, escrita do mesmo
jeito em todo lugar. O armazenamento só confere isso na saída. `upsert` confere a dimensão e
confia em quem chama quanto ao modelo, uma brecha que um sistema de verdade fecha transformando
texto em vetor num lugar só.

A maioria dos bancos de verdade nunca pergunta o nome do modelo. O Chroma é o que chega mais perto:
ele consegue transformar o texto em vetor para você com uma função de embedding ligada à coleção,
que a aula 12 mostra. O pgvector e o Qdrant só sabem a dimensão. Onde o banco não guarda o nome do
modelo, quem guarda é você: no nome da coleção, nos metadados dela ou numa tabela ao lado.
