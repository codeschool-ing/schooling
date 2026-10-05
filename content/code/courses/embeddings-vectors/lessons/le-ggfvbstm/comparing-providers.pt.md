---
title: Três provedores lado a lado
version: 1
---

Escolher entre provedores lendo as páginas deles é escolher entre três formatos dos mesmos fatos. Os
fatos que decidem quase tudo são quatro: **quanto custa um milhão de tokens, quantos números tem um
vetor, que tamanho um texto pode ter e o que a API deixa você dizer sobre o texto.** Os três
primeiros estão numa planilha só.

As páginas de preço dos próprios provedores não puderam ser acessadas da máquina em que este curso
foi gravado. Em vez delas, `prices.py` lê **a planilha de preços do LiteLLM no commit
b9e71e990aed**, uma lista que um projeto de código aberto mantém com os preços e limites de cada
provedor. É a cópia de um terceiro, fixada num commit para que diga o mesmo no ano que vem; os preços
dos provedores podem não dizer.

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

`compare.py` fica com os três provedores das aulas 7 e 8 e acrescenta três colunas. Uma é os bytes
que um vetor float32 ocupa na dimensão da planilha. Outra é a conta para transformar em vetores um
milhão de documentos de 500 tokens cada, que é meio bilhão de tokens. A última é os gigabytes que
esse milhão de vetores ocupa.

```schooling-example
{
  "language": "python",
  "file": "compare.py",
  "parts": [
    {
      "code": "from prices import rows\n\nTOKENS = 1_000_000 * 500\nprint(f\"{'model':28} {'USD/MTok':>8} {'dims':>5} {'max in':>7} {'bytes':>6} {'500M tokens':>12} {'1M vecs GB':>10}\")\nfor r in rows():\n    if r[\"provider\"] not in (\"openai\", \"gemini\", \"cohere\"):\n        continue\n    dims = r[\"dims\"] or \"-\"\n    size = r[\"dims\"] * 4 if r[\"dims\"] else \"-\"\n    gb = f\"{r['dims'] * 4 * 1e6 / 1e9:.2f}\" if r[\"dims\"] else \"-\"\n    cost = TOKENS / 1e6 * r[\"usd_per_mtok\"]\n    print(f\"{r['model']:28} {r['usd_per_mtok']:8.3f} {dims:>5} {r['max_input_tokens']:>7} {size:>6} {cost:12.2f} {gb:>10}\")",
      "note": "`rows()` é a planilha como lista de dicionários. Fique com os três provedores destas duas aulas e calcule três colunas a partir dos números da própria planilha: quatro bytes por dimensão, o preço vezes 500 milhões de tokens e um milhão de vetores em gigabytes."
    }
  ],
  "output": "ana@lab:~/emb$ python compare.py\nmodel                        USD/MTok  dims  max in  bytes  500M tokens 1M vecs GB\ntext-embedding-3-small          0.020  1536    8191   6144        10.00       6.14\ntext-embedding-3-large          0.130  3072    8191  12288        65.00      12.29\ntext-embedding-ada-002          0.100  1536    8191   6144        50.00       6.14\ngemini/gemini-embedding-001     0.150  3072    2048  12288        75.00      12.29\ncohere/embed-v4.0               0.120  1536  128000   6144        60.00       6.14\nembed-english-v3.0              0.100     -     512      -        50.00          -\nembed-multilingual-v3.0         0.100     -     512      -        50.00          -"
}
```

## Lendo a tabela

**A conta do embedding se paga uma vez; os bytes se pagam enquanto a coleção existir.** Meio bilhão
de tokens custa 10,00 dólares com o text-embedding-3-small e 75,00 com o gemini-embedding-001. Os
vetores deles ocupam 6.144 e 12.288 bytes, e um milhão deles 6,14 e 12,29 GB antes de qualquer
índice: guardados em memória pela maioria dos índices, lidos por toda busca e guardados em dobro
enquanto um modelo está sendo trocado. A aula 18 põe as duas coisas numa conta só.

**Uma dimensão é um padrão, não um custo fixo.** A planilha lista o maior tamanho de cada modelo. O
text-embedding-3 e o gemini-embedding-001 aceitam um menor, como a aula 7 e esta aula mostraram, e o
Cohere documenta 256, 512, 1.024 e 1.536 para o embed-v4.0. Um modelo de 3.072 pode ser guardado em
768 se a sua própria medida disser que a perda é aceitável, e essa medida é a da aula 7 rodada nos
seus dados.

**O limite de entrada decide como você corta os documentos.** O gemini-embedding-001 lê 2.048 tokens
e os dois modelos v3 do Cohere, 512; os modelos da OpenAI leem 8.191 e o embed-v4.0, 128.000. Um
texto maior que o limite é cortado ou recusado, conforme o provedor e as configurações, e de um jeito
ou de outro o fim dele não está no vetor. `rag` é o curso que decide o tamanho dos trechos; o limite
é de onde vem o teto dele.

**Células vazias são vazias na planilha, não zeros.** A planilha não tem dimensão para os modelos v3
do Cohere; o Cohere documenta 1.024 para os dois. Só dois modelos da OpenAI têm preço de lote nela.

## O que a planilha não diz

Os quatro fatos não são a escolha inteira. **Se o modelo conhece a sua língua** é a primeira das
outras questões: a aula 1 mediu um modelo inglês avaliando um título em português como sem relação,
e três dos 40 artigos da central de ajuda estão em português. O embed-multilingual-v3.0 leva esse
nome exatamente por isso, e o gemini-embedding-001 é documentado como multilíngue. **Se ele ajuda a
sua busca** é a segunda, e só uma medida nas suas próprias perguntas responde, a que esta aula rodou
em `search.py` e `quantised.py`. E se os dados podem sair de casa é a pergunta com que a aula 9
começa.

O quarto fato da primeira lista, o que cada API deixa você dizer sobre o texto, é o que a aula 7 e
esta aula encontraram chamada a chamada:

| | OpenAI | Google | Cohere |
|---|---|---|---|
| diz para que serve o texto | não | `task_type`, opcional | `input_type`, obrigatório |
| dimensão menor a pedido | `dimensions` | `output_dimensionality` | `output_dimension` (embed-v4.0) |
| saídas inteiras e binárias | não | não | `embedding_types` |
