---
title: O que vira embedding
version: 2
---

A aula 4 escolheu onde cortar. Antes de um pedaço virar vetor há mais uma escolha, e é fácil fazê-la
sem perceber: **que texto o modelo de embeddings lê de fato.** A resposta óbvia é o texto do pedaço. A
resposta melhor, medida abaixo, é o texto do pedaço com o caminho de títulos na frente.

## O texto do próprio pedaço não basta

A aula 2 encontrou o problema. A frase "A key may make 120 requests per minute" mora sob o título *Rate
limits*, e a pergunta era sobre o limite de requisições; depois que o pedaço é separado do título, nada
nele usa as palavras que a pergunta usou. A aula 4 mostrou a versão geral: um pedaço do parágrafo dos
livros danificados diz *a book* e *14 days* e nunca diz que trata do regulamento de devoluções da
Marginalia.

O caminho de títulos da aula 4, *Returns and refunds policy > Damaged, faulty and wrong items*, é
exatamente o contexto que falta, e custa uma dúzia de palavras. O `header.py` gera o embedding dos
pedaços estruturados da aula 4 duas vezes, uma só com o texto e outra com o caminho na linha de cima, e
roda as 26 perguntas com resposta contra cada um:

```schooling-example
{
  "language": "python",
  "file": "header.py",
  "parts": [
    {
      "code": "import json\n\nfrom chunking import load, structured\nfrom vectors import embed\n\nquestions = [q for q in map(json.loads, open(\"data/eval.jsonl\")) if q[\"facts\"]]\nnorm = lambda t: \" \".join(t.split())\nqv = embed([q[\"question\"] for q in questions])",
      "note": "As 26 perguntas que têm resposta, com embedding gerado uma vez, como no `compare.py` da aula 4."
    },
    {
      "code": "for size in (60, 120):\n    chunks = [(path, text) for _, body in load().values() for path, text in structured(body, size)]\n    for label, inputs in ((\"text only\", [t for _, t in chunks]),\n                          (\"path + text\", [p + \"\\n\" + t for p, t in chunks])):\n        scores = qv @ embed(inputs).T\n        found = sum(any(f in norm(chunks[i][1]) for i in s.argsort()[::-1][:3] for f in q[\"facts\"])\n                    for q, s in zip(questions, scores))\n        print(f\"structured {size:3}, {label:12} found {found}/{len(questions)}\")",
      "note": "Cada tamanho vira embedding duas vezes, como texto sozinho e com o caminho de títulos na linha de cima. Os fatos são procurados só no texto nos dois casos, então não é o caminho que é achado."
    }
  ]
}
```

```
ana@vm:~/rag$ python header.py
structured  60, text only    found 24/26
structured  60, path + text  found 26/26
structured 120, text only    found 25/26
structured 120, path + text  found 25/26
```

**Com o caminho na frente, os pedaços de 60 palavras acharam todas as respostas**, contra 24 antes. Os
de 120 ficaram em 25: um pedaço maior já leva mais do próprio contexto, então o caminho acrescenta
menos. Os pedaços menores ganham mais porque perdem mais ao serem cortados.

## A decisão que este curso toma

Daqui em diante, o índice guarda **pedaços estruturados de até 60 palavras, com o caminho de títulos no
embedding**. A tabela da aula 4 deu ao estruturado 60 o contexto mais barato entre as estratégias que
acharam mais de 15 respostas, 170 tokens por pergunta, e o caminho o leva a 26 de 26. É o melhor
resultado das duas aulas, nos dois critérios.

Três detalhes de como isso é feito importam mais do que parece.

**O caminho entra no embedding e é guardado à parte.** O texto mandado ao modelo de embeddings é `path +
"\n" + text`, e o banco guarda `path` e `text` em colunas separadas. O prompt da aula 7 pode então
imprimir o caminho como cabeçalho da fonte, uma vez, em vez de repeti-lo dentro do texto de cada pedaço.

**A pergunta vira embedding como está.** Nada é acrescentado à pergunta para ela parecer um pedaço. As
duas são comparadas como são, o que funciona porque o caminho são algumas palavras ao lado de um texto
bem mais longo, e move o vetor do pedaço na direção do assunto, não de um formato.

**O mesmo modelo, sempre.** Um pedaço com embedding do `all-minilm` só pode ser comparado com uma
pergunta com embedding do `all-minilm`. Vetores de dois modelos vivem em espaços diferentes, e
compará-los produz números que parecem similaridades e não significam nada. A tabela desta aula registra
o modelo ao lado de cada vetor, e a verificação no fim da aula recusa um índice com mais de um.

## Outras coisas que se põem na frente

O caminho de títulos é a forma mais barata do que às vezes se chama **cabeçalhos contextuais de
pedaço**. Existem duas versões mais elaboradas. Uma põe o título do documento e um resumo de uma linha
do documento na frente de cada pedaço. Outra, que a Anthropic publicou como *contextual retrieval*, faz
um modelo de linguagem escrever uma ou duas frases para cada pedaço explicando onde ele fica no
documento inteiro, e gera o embedding disso junto com o pedaço. As duas precisam de uma chamada de
modelo por pedaço na indexação, 137 delas para este corpus, e nenhuma foi rodada aqui. A medição acima é o argumento para tentar primeiro a versão barata: neste corpus ela fechou a
diferença inteira.
