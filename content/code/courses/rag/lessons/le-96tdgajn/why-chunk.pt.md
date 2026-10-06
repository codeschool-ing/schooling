---
title: Por que os documentos são cortados
version: 1
---

A aula 1 cortou cada documento nos títulos sem dizer por quê, e a objeção óbvia é que nada a obrigava.
Por que não gerar o embedding de cada documento inteiro e recuperar documentos inteiros? Há dois
motivos, e um deles é um limite duro que a maioria das pessoas só descobre por acaso.

## O modelo de embeddings lê um número fixo de pedaços

O all-MiniLM-L6-v2 lê no máximo 256 pedaços de palavra. Não é uma preferência flexível: o tokenizador
corta a entrada em 256, e tudo depois desse ponto nunca chega ao modelo. Todo modelo de embeddings tem
um limite assim; os hospedados têm limites maiores, alguns milhares de pedaços, e ainda finitos. O
`truncation.py` mede o que isso significa para o regulamento de devoluções:

```
ana@lab:~/rag$ python truncation.py
pieces in the whole policy: 1043
words the model reads: 219 of 884
similarity, whole policy and its first 219 words: 1.0000
similarity, whole policy and the policy plus a sentence at the end: 1.0000
```

**O regulamento tem 1.043 pedaços, e o modelo lê os primeiros 256, que são 219 das suas 884
palavras.** O vetor do regulamento inteiro e o vetor das suas primeiras 219 palavras são idênticos,
similaridade 1,0000, porque são a mesma entrada depois que o tokenizador termina. A última linha é a
alarmante: acrescentar *Returns are never accepted.* ao fim do regulamento não mexeu o vetor dele em
nada. Diga o que disser um documento depois das primeiras 219 palavras, o embedding dele não tem como
saber.

É uma falha silenciosa do pior tipo. Nada dá erro, todo documento ganha um vetor, e uma busca sobre
documentos inteiros funciona bem para perguntas sobre a primeira página e nada para o resto. Uma
pergunta sobre reembolsos, que o regulamento só alcança bem depois das primeiras 219 palavras, seria
comparada com um vetor que nunca os viu.

## Um vetor é uma média

O segundo motivo vale até para um modelo com limite grande. Um embedding resume a entrada inteira num
ponto, e um texto longo sobre muitas coisas cai num ponto que não é sobre nenhuma delas em particular:
perto de devoluções, perto de reembolsos, perto de vendedores do marketplace, e perto de nenhuma
pergunta sobre qualquer uma delas. A aula 1 do `embeddings-vectors` chamou isso de significado
transformado em vetor, e um vetor tem espaço para um significado de cada vez.

Um pedaço pequeno sobre uma coisa cai perto das perguntas sobre essa coisa. É isso que o torna
encontrável, e é o motivo inteiro para cortar.

## E o prompt tem orçamento

A terceira consideração vem da outra ponta do pipeline. O que for recuperado vai para o prompt, e a
aula 3 mediu esse custo: 332 tokens por pergunta para três seções inteiras. Recupere documentos
inteiros e isso vira milhares, a maioria sobre outra coisa. Pedaços menores gastam o contexto com
texto que trata da pergunta.

## A tensão

Cortar menor torna cada pedaço mais fácil de achar e mais barato de mandar. Também tira contexto: a
aula 2 achou a frase "A key may make 120 requests per minute" impossível de encontrar depois de
separada do título, *Rate limits*. **Toda decisão de corte troca facilidade de achar por contexto**, e
o resto desta aula mede essa troca neste corpus, com cinco jeitos de cortar e uma tabela que os
compara.

O programa que todos usam é o `chunking.py`, um módulo de funções pequenas mostradas nas seções que as
usam, e um carregador que lê cada documento e seu cabeçalho:

```schooling-example
{
  "language": "python",
  "file": "chunking.py",
  "parts": [
    {
      "code": "import glob\nimport re\n\nimport numpy as np\nfrom minilm import embed",
      "note": "numpy para o corte semântico, e o mesmo modelo de embeddings de todas as outras aulas."
    },
    {
      "code": "def load():\n    \"\"\"{id: (metadata, body)} for every document, the front matter read into a dict.\"\"\"\n    docs = {}\n    for path in sorted(glob.glob(\"data/docs/*.md\")):\n        head, body = open(path).read().split(\"\\n---\\n\", 1)\n        meta = dict(line.split(\": \", 1) for line in head.splitlines()[1:])\n        docs[meta[\"id\"]] = (meta, body.strip())\n    return docs",
      "note": "O cabeçalho de cada documento vira um dicionário, e o corpo fica separado dele, para que `id`, `audience` e `status` sejam dados, não texto para virar embedding."
    }
  ]
}
```
