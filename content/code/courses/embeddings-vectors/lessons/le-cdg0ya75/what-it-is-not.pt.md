---
title: O que um embedding não é
version: 1
---

Um embedding é bom numa coisa: pôr perto uns dos outros os textos sobre o mesmo assunto. A maioria
dos erros com embeddings vem de esperar mais do que isso. Quatro expectativas são comuns e erradas,
e cada uma pode ser medida.

```schooling-example
{
  "language": "python",
  "file": "limits.py",
  "parts": [
    {
      "code": "from minilm import embed\n\npairs = [\n    (\"I want a refund\", \"I do not want a refund\"),\n    (\"I want a refund\", \"Please give me my money back\"),\n    (\"How to return a book\", \"Como devolver um livro\"),\n    (\"How to return a book\", \"How to return a lamp\"),\n]\nfor a, b in pairs:\n    v = embed([a, b])\n    print(f\"{float(v[0] @ v[1]):6.3f}  {a!r} / {b!r}\")",
      "note": "Quatro pares, cada um avaliado do mesmo jeito de antes: transformar os dois textos em vetores e tirar o produto escalar. Cada par testa uma expectativa."
    }
  ]
}
```

```
ana@lab:~/emb$ python limits.py
 0.892  'I want a refund' / 'I do not want a refund'
 0.627  'I want a refund' / 'Please give me my money back'
-0.015  'How to return a book' / 'Como devolver um livro'
 0.492  'How to return a book' / 'How to return a lamp'
```

## Não é uma leitura do que o texto diz

**I want a refund** ("quero um reembolso") e **I do not want a refund** ("não quero um reembolso")
ficam em 0,892, mais alto que *I want a refund* contra *Please give me my money back* ("por favor,
me devolvam o dinheiro"), em 0,627. O primeiro par diz coisas opostas sobre o mesmo assunto; o
segundo diz a mesma coisa com outras palavras. O modelo considera o par oposto mais próximo.

Isso não é um defeito deste modelo. A negação, as quantidades (*um livro* contra *quarenta livros*)
e quem fez o que a quem mudam o que uma frase afirma sem mexer no assunto, e o assunto é o que os
embeddings capturam melhor. Um sistema que precisa saber se a cliente quer um reembolso precisa ler
o texto, o que é trabalho de um modelo de linguagem, ou de um classificador treinado para isso, que
a aula 4 constrói.

## Não é independente de língua

**How to return a book** contra a tradução em português, **Como devolver um livro**, fica em
−0,015: tão sem relação quanto dois textos podem ser. Contra *How to return a lamp* ("como devolver
uma luminária"), que fala de outro objeto, fica em 0,492.

O all-MiniLM-L6-v2 foi treinado em inglês, então o português, para ele, é uma sequência de pedaços
de palavra para os quais ele não tem pares. Um modelo **multilíngue**, treinado com pares entre
línguas, poria os dois títulos perto um do outro. Essa é uma propriedade que você escolhe ao
escolher o modelo, e a aula 9 mostra como lê-la na descrição de um modelo antes de depender dela.

## Não é comparável entre modelos

Um vetor só significa algo ao lado de outros vetores **do mesmo modelo**. O all-MiniLM-L6-v2 dá 384
números e o WordLlama dá 256, então os dois nem podem ser multiplicados entre si. Dois modelos com a
mesma dimensão não estão melhor: as coordenadas de um não têm nada a ver com as do outro, e um
produto escalar entre eles é um número que não mede nada.

Então o modelo faz parte dos dados. Guarde qual modelo produziu cada vetor, e quando o modelo mudar,
**todo vetor guardado precisa ser calculado de novo**. A aula 18 põe preço nisso.

## Não é anônimo

Um embedding não é o texto, e o texto não pode ser lido de volta só de olhar para ele. Isso levou
gente a tratar vetores como seguros para compartilhar quando o texto não é. A pesquisa sobre
**inversão de embeddings** diz o contrário: um artigo de 2023, *Text Embeddings Reveal (Almost) As
Much As Text*, treinou um modelo para reconstruir textos curtos a partir dos vetores e recuperou
muitos deles palavra por palavra. O vetor da mensagem de uma cliente é dado pessoal do mesmo jeito
que a mensagem. Guarde-o sob as mesmas regras: quem pode ler, por quanto tempo fica guardado e
quando é apagado.
