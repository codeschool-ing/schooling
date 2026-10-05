---
title: Quanto custa
version: 1
---

Uma API de embeddings cobra **só tokens de entrada**. Não há resposta para pagar além do vetor, e
o vetor tem o preço do comprimento do texto que entrou. Então o custo de transformar qualquer coisa
em vetores é uma multiplicação: tokens vezes o preço por token.

## Os preços, de uma planilha

A página de preços da própria OpenAI não estava ao alcance da máquina em que o curso foi gravado.
Os preços aqui vêm da **planilha do LiteLLM no commit b9e71e990aed**, uma lista de preços de
provedores que um projeto de código aberto mantém, lida num commit fixo para que os mesmos números
saiam no ano que vem. O `prices.py`, ao lado do curso, a imprime:

```
ana@lab:~/emb$ python3 prices.py
LiteLLM price sheet at commit b9e71e990aed, USD per million input tokens
model                          provider                      USD/MTok   batch  dims  max in
text-embedding-3-small         openai                           0.020   0.010  1536    8191
text-embedding-3-large         openai                           0.130   0.065  3072    8191
text-embedding-ada-002         openai                           0.100       -  1536    8191
gemini/gemini-embedding-001    gemini                           0.150       -  3072    2048
cohere/embed-v4.0              cohere                           0.120       -  1536  128000
embed-english-v3.0             cohere                           0.100       -     -     512
embed-multilingual-v3.0        cohere                           0.100       -     -     512
voyage/voyage-3.5              voyage                           0.060       -     -   32000
voyage/voyage-3.5-lite         voyage                           0.020       -     -   32000
mistral/mistral-embed          mistral                          0.100       -     -    8192
```

Os preços são em dólares americanos por milhão de tokens. A coluna **batch** é o preço pela Batch
API da OpenAI, em que você envia um arquivo de requisições e recolhe os resultados depois, dentro
de um dia. A planilha a lista pela metade do preço comum para os dois modelos text-embedding-3 e
não tem preço em lote para o ada-002. A Batch API não foi rodada aqui; o labembed não a imita.

Preços mudam. Uma planilha num commit fixo é um ponto de referência para conferir uma conta, não um
orçamento: antes de fechar um orçamento, leia a página do provedor no dia.

## A central de ajuda, e um milhão de documentos

```schooling-example
{
  "language": "python",
  "file": "cost.py",
  "parts": [
    {
      "code": "import json\nimport tiktoken\n\nenc = tiktoken.get_encoding(\"cl100k_base\")\nhelp = [json.loads(l) for l in open(\"data/help.jsonl\")]\ntokens = sum(len(enc.encode(h[\"title\"] + \". \" + h[\"body\"])) for h in help)\nprices = {p[\"model\"]: p for p in json.load(open(\"prices.json\"))}\nprint(\"help centre:\", tokens, \"tokens\")",
      "note": "Conte os tokens da central de ajuda com `cl100k_base` e leia os preços que `prices.py --json` escreveu."
    },
    {
      "code": "for name in (\"text-embedding-3-small\", \"text-embedding-3-large\", \"text-embedding-ada-002\"):\n    p = prices[name]\n    batch = p[\"batch_usd_per_mtok\"]\n    print(f\"{name:23}  help centre ${tokens * p['usd_per_mtok'] / 1e6:.6f}\"\n          f\"  a million 500-token documents ${500 * p['usd_per_mtok']:,.2f}\"\n          + (f\" (batch ${500 * batch:,.2f})\" if batch else \"\"))",
      "note": "Para cada modelo da OpenAI na planilha: a central de ajuda uma vez, e um milhão de documentos de 500 tokens cada, que são 500 milhões de tokens. O preço em lote aparece onde a planilha tem um."
    }
  ]
}
```

```
ana@lab:~/emb$ python3 prices.py --json > prices.json
ana@lab:~/emb$ python cost.py
help centre: 2205 tokens
text-embedding-3-small   help centre $0.000044  a million 500-token documents $10.00 (batch $5.00)
text-embedding-3-large   help centre $0.000287  a million 500-token documents $65.00 (batch $32.50)
text-embedding-ada-002   help centre $0.000220  a million 500-token documents $50.00
```

**A central de ajuda inteira custa alguns milésimos de centavo** com o text-embedding-3-small. Vale
saber disso por um motivo: transformar de novo um conjunto pequeno de textos nunca é a parte cara
de trocar de modelo. As partes caras estão em outro lugar, e a aula 18 as conta.

Um milhão de documentos de 500 tokens é meio bilhão de tokens, que custa US$ 10,00 com o modelo
pequeno, US$ 65,00 com o grande e metade de qualquer um deles pela Batch API. Duas coisas deixam as
contas de verdade maiores que essa aritmética. Os documentos costumam ser divididos em pedaços que
se sobrepõem, então o mesmo texto vira vetor mais de uma vez. E cada pergunta que um usuário digita
também vira vetor, então uma caixa de busca movimentada continua cobrando depois que os documentos
acabaram, poucos tokens por vez.

A primeira está sob o seu controle e a segunda é barata por chamada. Nenhuma muda o método: conte
os tokens com o tokenizador do provedor, multiplique pelo preço do dia e guarde a contagem de
`usage` para conferir a fatura.
