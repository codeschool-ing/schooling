---
title: Qwen
version: 1
---

A Qwen é a família da Alibaba. A aula 2 citou a licença antiga dela, o acordo Tongyi Qianwen, com um
limite de 100 milhões de usuários e a proibição de usar as saídas para melhorar outros modelos. O
repositório da geração atual diz outra coisa:

```
ana@desk:~/desk$ sources quote qwen3-readme "open-weight models are licensed|license files"
# QwenLM/Qwen3@7a2f61ff README.md
 397: All our open-weight models are licensed under Apache 2.0.
 398: You can find the license files in the respective Hugging Face repositories.
```

**Apache 2.0 para todos os modelos de pesos abertos**, com os arquivos de licença guardados ao lado de
cada modelo no Hugging Face. Isso é uma mudança de tipo, não de detalhe: de uma licença com condições
para uma sem nenhuma além da atribuição. E é o motivo de a aula 2 seção 03 ter dito à ana para ler a
licença da versão que ela roda: uma resposta lida no acordo antigo da Qwen está errada para a Qwen 3.

## Lendo os nomes da Qwen

Os nomes da Qwen trazem a arquitetura, e depois de lidos dizem muito:

```
ana@desk:~/desk$ sheet where qwen3-235b-a22b
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
qwen.qwen3-235b-a22b-2507-v1:0                       bedrock_converse               0.22     0.88
bedrock_mantle/qwen.qwen3-235b-a22b-2507             bedrock_mantle                 0.22     0.88
fireworks_ai/accounts/fireworks/models/qwen3-235b-a2 fireworks_ai                   0.22     0.88
fireworks_ai/accounts/fireworks/models/qwen3-235b-a2 fireworks_ai                   0.22     0.88
fireworks_ai/accounts/fireworks/models/qwen3-235b-a2 fireworks_ai                   0.22     0.88
novita/qwen/qwen3-235b-a22b-fp8                      novita                          0.2      0.8
novita/qwen/qwen3-235b-a22b-instruct-2507            novita                         0.09     0.58
novita/qwen/qwen3-235b-a22b-thinking-2507            novita                          0.3        3
openrouter/qwen/qwen3-235b-a22b                      openrouter                    0.455     1.82
openrouter/qwen/qwen3-235b-a22b-2507                 openrouter                   0.0875     0.35
openrouter/qwen/qwen3-235b-a22b-thinking-2507        openrouter                     0.23      2.3
replicate/qwen/qwen3-235b-a22b-instruct-2507         replicate                     0.264     1.06
scaleway/qwen/qwen3-235b-a22b-instruct-2507          scaleway                       0.75     2.25
vertex_ai/qwen/qwen3-235b-a22b-instruct-2507-maas    vertex_ai-qwen_models          0.22     0.88
```

`qwen3-235b-a22b` é uma mistura de especialistas (aula 10 seção 03) com **235 bilhões de parâmetros no
total e 22 bilhões ativos**: o `a` é de ativo. Então a memória para guardá-lo é definida pelos 235B e a
velocidade pelos 22B. `-2507` é um lançamento, julho de 2025. `instruct` e `thinking` são as variantes
ajustada e de raciocínio do mesmo lançamento. `fp8` é a escolha de precisão de um host.

Os preços cobrem um fator de mais de oito na entrada, de US$ 0,0875 a US$ 0,75, para pesos que dividem um nome.

## O modelo que não é aberto

```
ana@desk:~/desk$ sheet where qwen3-max | head -4
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
dashscope/qwen3-max                                  dashscope                         -        -
dashscope/qwen3-max-2026-01-23                       dashscope                         -        -
```

O maior modelo da Qwen, o Max, aparece sob `dashscope`, a API da própria Alibaba Cloud, e a tabela não
registra **preço nenhum** para ele. A frase sobre Apache no README fala de modelos de pesos abertos, o
que já é uma pista: uma família pode ser aberta na maioria dos tamanhos e fechada no maior. Antes de
escolher um modelo Qwen para a opção de pesos abertos que a aula 3 pediu para a ana manter, confira se
aquele que ela quer está entre os que têm pesos publicados.
