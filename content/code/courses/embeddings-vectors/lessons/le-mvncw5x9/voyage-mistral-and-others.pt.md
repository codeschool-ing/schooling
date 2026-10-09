---
title: Voyage, Mistral e o resto da tabela
version: 1
---

OpenAI, Google e Cohere são os fornecedores que quase todo mundo conhece primeiro, e são uma parte
pequena do que está à venda. A tabela de onde este curso tira os preços lista muito mais modelos
de embedding do que as aulas 7 e 8 usaram. Lê-la é um jeito rápido de ver o formato do mercado:
quem vende modelos gerais, quem vende modelos para um tipo de texto e quem vende por token o modelo
aberto de outra pessoa.

O fim da saída de `prices.py`, que a aula 7 rodou, tem os dois nomes que o título desta seção
promete:

```
ana@lab:~/emb$ python prices.py
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

**A Voyage AI vende o `voyage-3.5` a 0,060 dólar por milhão de tokens e o `voyage-3.5-lite` a
0,020**, o mesmo que o `text-embedding-3-small`. O `mistral-embed` da Mistral sai a 0,100. Os dois
leem entradas longas: 32.000 tokens na Voyage e 8.192 na Mistral, muito mais que os pedaços de
palavra que a aula 9 mostrou que o all-MiniLM-L6-v2 lê.

**Um traço é uma lacuna na tabela, não um zero.** A coluna `dims` está vazia para os dois
fornecedores porque a tabela não registra a dimensão deles, e `batch` está vazia porque ela não
registra preço de lote com desconto para eles. Nenhum dos dois quer dizer que a coisa não existe. Um
valor que falta na tabela de um terceiro é uma pergunta para a documentação do próprio fornecedor.
Vale o mesmo para o formato de requisição da Voyage, que recebe um `input_type` de `query` ou
`document`, como o da Cohere na aula 8. O `setup.sh` da aula 1 não instala o SDK de nenhum dos dois, e
nenhuma das duas APIs estava ao alcance da máquina em que este curso foi gravado, então nenhum código deles aparece aqui.

## O que mais a tabela tem

`prices.py` mostra dez linhas porque o curso escolheu dez. A tabela tem muitas mais, e `sheet.py`
lê a tabela direto, pela mesma função:

```schooling-example
{
  "language": "python",
  "file": "sheet.py",
  "parts": [
    {
      "code": "from prices import sheet\n\nd = sheet()\nemb = [k for k, v in d.items() if v.get(\"mode\") == \"embedding\"]\nprint(\"embedding rows:\", len(emb))\nprint(\"rows naming jina:\", [(k, v[\"mode\"]) for k, v in d.items() if \"jina\" in k])",
      "note": "`sheet()` é a função que `prices.py` usa para ler a tabela do LiteLLM no commit fixado. Conte as linhas cujo modo é `embedding` e liste toda linha cujo nome contém `jina`, qualquer que seja o modo."
    },
    {
      "code": "rows = [\"voyage/voyage-code-3\", \"voyage/voyage-law-2\", \"voyage/voyage-finance-2\",\n        \"mistral/codestral-embed\", \"fireworks_ai/nomic-ai/nomic-embed-text-v1.5\",\n        \"together_ai/BAAI/bge-base-en-v1.5\", \"novita/baai/bge-m3\"]\nfor k in rows:\n    v = d[k]\n    usd = v[\"input_cost_per_token\"] * 1e6\n    dims = v.get(\"output_vector_size\") or \"-\"\n    print(f\"{k:44} {usd:6.3f} {dims:>5} {v['max_input_tokens']:>6}\")",
      "note": "Sete linhas que `prices.py` não mostra: quatro modelos treinados para um tipo de texto e três modelos abertos vendidos por empresas de hospedagem. Preço em dólares por milhão de tokens, dimensão, entrada máxima em tokens."
    }
  ]
}
```

```
ana@lab:~/emb$ python sheet.py
embedding rows: 149
rows naming jina: [('jina-reranker-v2-base-multilingual', 'rerank')]
voyage/voyage-code-3                          0.180     -  32000
voyage/voyage-law-2                           0.120     -  16000
voyage/voyage-finance-2                       0.120     -  32000
mistral/codestral-embed                       0.150     -   8192
fireworks_ai/nomic-ai/nomic-embed-text-v1.5   0.008     -   8192
together_ai/BAAI/bge-base-en-v1.5             0.008   768    512
novita/baai/bge-m3                            0.010     -   8192
```

**149 linhas da tabela são modelos de embedding, e nenhuma é da Jina.** A única linha com o nome
da Jina é `jina-reranker-v2-base-multilingual`, e o modo dela diz `rerank`: um modelo que dá nova
nota a uma lista curta de resultados, que a aula 16 descreve. É por isso que a seção anterior não
cita preço da Jina.

As linhas que o programa escolheu caem em dois grupos, e cada um é um tipo diferente de escolha.

**Modelos treinados para um tipo de texto.** A Voyage vende `voyage-code-3`, `voyage-law-2` e
`voyage-finance-2`, e a Mistral vende `codestral-embed`. Eles são vendidos com a promessa de que um
modelo treinado em código, contratos ou relatórios financeiros posiciona esses textos melhor que um
modelo geral. Também custam mais nesta tabela: 0,180 pelo modelo de código da Voyage contra 0,060
pelo geral. Se a promessa vale para os seus textos é uma medição, feita do jeito que a aula 9 mediu
o MiniLM contra o WordLlama: com as suas perguntas e os seus julgamentos.

**Modelos abertos vendidos por token.** O `nomic-embed-text-v1.5`, da Nomic, e o
`bge-base-en-v1.5` e o `bge-m3`, do BAAI, são modelos abertos cujos pesos qualquer um pode baixar,
que é o assunto da aula 9. Aqui eles são vendidos por empresas de hospedagem, Fireworks, Together e
Novita, por 0,008 a 0,010 dólar por milhão de tokens. É a terceira opção entre pagar quem fez o
modelo e rodá-lo você mesmo: as máquinas de outra pessoa, rodando pesos que você também poderia
rodar. Isso mantém o modelo portátil, já que os mesmos pesos continuam disponíveis se você trocar
de hospedagem. Se os vetores de duas hospedagens do mesmo modelo podem ser misturados depende de
cada uma rodá-lo com a mesma precisão, e essa é uma pergunta para fazer à hospedagem antes de
misturar, e não depois.

**A linha do `bge-base-en-v1.5` também mostra como um limite curto aparece numa lista de preços**:
768 dimensões e 512 tokens de entrada. Barato por token, e um artigo longo precisa ser cortado em
pedaços antes de caber.

Nenhuma dessas linhas é uma recomendação, e nada nesta seção foi medido. A última seção desta aula,
*Escolher um modelo*, diz como transformar uma lista assim numa decisão.
