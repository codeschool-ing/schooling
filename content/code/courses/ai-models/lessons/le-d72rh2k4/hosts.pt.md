---
title: Onde conseguir uma Llama
version: 1
---

Um modelo aberto é acessado pela máquina de alguém: a sua (aulas 3 e 14) ou a de um host. O Maverick,
em todos os hosts que a tabela conhece:

```
ana@desk:~/desk$ python sheet.py where llama-4-maverick
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
databricks/databricks-llama-4-maverick               databricks                  0.50001 1.5000300000000002
lambda_ai/llama-4-maverick-17b-128e-instruct-fp8     lambda_ai                      0.05      0.1
novita/meta-llama/llama-4-maverick-17b-128e-instruct novita                         0.27     0.85
oci/meta.llama-4-maverick-17b-128e-instruct-fp8      oci                            0.72     0.72
openrouter/meta-llama/llama-4-maverick               openrouter                   0.1875   0.6525
vercel_ai_gateway/meta/llama-4-maverick              vercel_ai_gateway               0.2      0.6
vertex_ai/meta/llama-4-maverick-17b-128e-instruct-ma vertex_ai-llama_models         0.35     1.15
vertex_ai/meta/llama-4-maverick-17b-16e-instruct-maa vertex_ai-llama_models         0.35     1.15
watsonx/meta-llama/llama-4-maverick-17b              watsonx                       0.371    1.484
watsonx/meta-llama/llama-4-maverick-17b-128e-instruc watsonx                       0.371    1.484
```

Dez entradas, e a faixa que a aula 2 seção 05 fez a gente esperar: de **US$ 0,05 na entrada e US$ 0,10
na saída** num host a **US$ 0,72 e US$ 0,72** em outro, mais de catorze vezes de distância na entrada
para pesos que deveriam ser os mesmos. Dois dos nomes trazem `fp8`, uma precisão reduzida escolhida pelo
host, então "os mesmos" já é uma pergunta.

A tabela também mostra os limites da tabela do LiteLLM como fonte:

- `0.50001` e `1.5000300000000002` são a cara de um número de ponto flutuante quando alguém
  multiplicou um preço em vez de digitá-lo. Leia como US$ 0,50 e US$ 1,50.
- Uma entrada do Vertex se chama `maverick-17b-16e`. Dezesseis especialistas é a contagem do Scout na
  seção 03, não a do Maverick; um nome na lista de um terceiro é uma afirmação a conferir, como
  qualquer outra.

## Escolhendo um host para um modelo aberto

O modelo é fixo, então o host se escolhe por todo o resto, na ordem da aula 4:

1. **Limites**: o processamento do host atende aos termos de dados da aula 2 seção 07? Que precisão
   ele serve, e ela passa nos casos da ana?
2. **Trocas**: preço, latência medida, os limites de requisição da conta dela.

E uma propriedade que só pesos abertos têm: **se o host decepcionar, o mesmo modelo pode ir para o
próximo**, ou para dentro de casa, com a avaliação ainda valendo. É o controle que a aula 2 descreveu,
e é o motivo de a aula 3 ter dito à ana para manter na lista candidatos com pesos disponíveis.
