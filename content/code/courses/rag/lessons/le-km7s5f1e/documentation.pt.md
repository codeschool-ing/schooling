---
title: Documentação técnica
version: 1
---

O primeiro trabalho que a maioria das equipes dá a um sistema de recuperação é a própria documentação:
uma referência de API, um conjunto de manuais, uma wiki de como as coisas são implantadas. Parece o
caso fácil. Os documentos são escritos por engenheiros, são estruturados, e quem lê são engenheiros
que vão conferir a resposta. É o caso em que a busca por significado é mais fraca, e o motivo está no
vocabulário.

## Um programa que busca por seção

Todas as execuções desta aula usam o `sections.py`, a busca da aula 1 transformada em módulo: os
documentos cortados nos títulos `## `, com embeddings gerados uma vez, buscados pela similaridade de
cosseno, e as três melhores postas num prompt para o extract-1.

```schooling-example
{
  "language": "python",
  "file": "sections.py",
  "parts": [
    {
      "code": "import glob\nimport re\nimport sys\n\nfrom minilm import embed\nfrom openai import OpenAI\n\nsections = []\nfor path in sorted(glob.glob(\"data/docs/*.md\")):\n    doc = path.split(\"/\")[-1][:-3]\n    for part in re.split(r\"\\n(?=## )\", open(path).read())[1:]:\n        sections.append((f\"{doc} > {part.splitlines()[0][3:]}\", part))\nvectors = embed([text for _, text in sections])",
      "note": "Os documentos cortados em cada título `## `, cada seção com o nome do documento e do título, e todas viram embeddings uma vez só, quando o módulo é importado."
    },
    {
      "code": "def search(question, k=3):\n    scores = vectors @ embed(question)[0]\n    return [(sections[i][0], sections[i][1], float(scores[i])) for i in scores.argsort()[::-1][:k]]",
      "note": "O `search` dá nota a cada seção contra a pergunta e devolve as `k` melhores, com nomes, textos e notas."
    },
    {
      "code": "def answer(question, k=3):\n    found = search(question, k)\n    for rank, (name, _, score) in enumerate(found, 1):\n        print(f\"[{rank}] {score:.3f}  {name}\")\n    sources = \"\".join(f\"[{rank}] {name}\\n{text}\\n\" for rank, (name, text, _) in enumerate(found, 1))\n    reply = OpenAI().chat.completions.create(model=\"extract-1\", messages=[\n        {\"role\": \"system\", \"content\": \"Answer from the sources and cite them by number.\"},\n        {\"role\": \"user\", \"content\": f\"{sources}Question: {question}\"}])\n    print(reply.choices[0].message.content)",
      "note": "O `answer` imprime o que a busca achou, depois põe isso num prompt numerado e imprime a resposta do extract-1."
    },
    {
      "code": "if __name__ == \"__main__\":\n    answer(sys.argv[1])",
      "note": "Rodado como programa, responde à pergunta da linha de comando."
    }
  ]
}
```

## Perguntando por um código de erro

A referência da API de afiliados termina com uma tabela de códigos de erro. Um desenvolvedor cuja
integração acabou de registrar `E-4104` pergunta o que ele significa:

```
ana@lab:~/rag$ python sections.py "What does error E-4104 mean?"
[1] 0.478  affiliate-api > Changes in 2.3
[2] 0.393  affiliate-api > Errors
[3] 0.380  affiliate-api > Rate limits
E-4102 429 more than 120 requests in the last minute [2] Version 2.3, released on 10 February 2026, added the lang parameter to /search and the error E-4105. [1] E-5001 500 an error on our side; retry after a few seconds [2]
ana@lab:~/rag$ grep -n "E-4104" data/docs/*.md
data/docs/affiliate-api.md:61:than 24 months in the past, or in the future, return E-4104.
data/docs/affiliate-api.md:85:| E-4104 | 400 | the month is out of range or not in the form YYYY-MM |
```

**A resposta cita três códigos de erro, e nenhum deles é o E-4104.** A busca pôs o registro de
mudanças acima da tabela de erros, porque *Changes in 2.3* fala de um erro e de uma versão, e a
pergunta também; a tabela veio em segundo. Dessa tabela, o extract-1 copiou as linhas mais parecidas
com a pergunta, e para um modelo de embeddings `E-4102`, `E-4104` e `E-5001` são quase a mesma string.
O `grep` achou a linha exata num instante, duas vezes.

Esse é o problema da documentação numa execução só. Um modelo de embeddings representa do que um texto
*trata*, e faz isso muito bem; ele é fraco em separar duas strings que diferem num caractere, porque
quase nada no treinamento lhe ensinou que `E-4104` e `E-4102` significam coisas diferentes. Documentação
técnica é cheia dessas strings: códigos de erro, nomes de função, flags, números de versão, chaves de
configuração. **Perguntas sobre documentação muitas vezes são perguntas sobre um identificador exato, e
um identificador exato é aquilo para que a busca lexical foi feita.** A aula 6 põe uma busca lexical ao
lado da vetorial e junta as duas.

## Perguntando por um conceito

A mesma referência responde a perguntas conceituais também, e ali a busca por embeddings se sai melhor
em achar e pior em responder:

```
ana@lab:~/rag$ python sections.py "What is the rate limit of the affiliate API?"
[1] 0.517  affiliate-api > Base URL and authentication
[2] 0.445  affiliate-api > Rate limits
[3] 0.335  affiliate-api > Commission
The sources do not say.
```

A seção chamada *Rate limits* veio em segundo, atrás de *Base URL and authentication*, e o extract-1
não achou nenhuma frase próxima o bastante da pergunta. A frase de que ele precisava, "A key may make
120 requests per minute", nunca usa as palavras *rate* nem *limit*: quem usa é o título. Depois que a
seção é separada do título, nada no texto dela diz do que ela trata. A aula 4 volta a isso, e a aula 5
mostra a solução barata de gerar o embedding de cada pedaço com os títulos acima dele.

## O que a documentação pede de um pipeline

- **Identificadores exatos têm de ser achados exatamente.** No mínimo, um híbrido de busca lexical e
  vetorial.
- **O código tem de sobreviver ao corte.** Um exemplo de código cortado ao meio é pior que nenhum,
  então o corte tem de respeitar os blocos; aula 4.
- **Versões importam.** A referência acima é a versão 2.3, e a 2.2 ainda é servida. Uma resposta sobre
  o parâmetro `lang` está errada para quem usa a 2.2, então a versão pertence ao lado do pedaço.
- **Quem lê vai rodar a resposta.** Um desenvolvedor cola o trecho num terminal em um minuto. Uma
  resposta errada custa um pouco de tempo e é descoberta depressa, o que faz da documentação o caso em
  que errar sai mais barato. Continua sendo o caso em que mais se erra.
