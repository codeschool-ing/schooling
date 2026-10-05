---
title: Duas formas de pagar
version: 1
---

Um modelo fechado é pago **por token**, ao provedor ou a uma nuvem que o revende. Um modelo aberto
pode ser pago do mesmo jeito, a qualquer das empresas que o hospedam, ou **por hora**, por uma
máquina em que você mesmo o roda. A aula 3 trata do segundo caso. Esta seção trata de como o
primeiro fica para cada tipo, lido na tabela.

O `sheet where` lista toda entrada cujo nome contém uma string. Aqui está um modelo aberto, a Llama
3.3 70B, e todos os hosts a que a tabela dá preço:

```
ana@desk:~/desk$ sheet where llama-3.3-70b
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
cerebras/llama-3.3-70b                               cerebras                       0.85      1.2
cloudflare/@cf/meta/llama-3.3-70b-instruct-fp8-fast  cloudflare                    0.293    2.253
novita/meta-llama/llama-3.3-70b-instruct             novita                        0.135      0.4
oci/meta.llama-3.3-70b-instruct                      oci                            0.72     0.72
oci/meta.llama-3.3-70b-instruct-fp8-dynamic          oci                            0.72     0.72
openrouter/meta-llama/llama-3.3-70b-instruct         openrouter                     0.22      0.5
scaleway/meta/llama-3.3-70b-instruct                 scaleway                        0.9      0.9
snowflake/snowflake-llama-3.3-70b                    snowflake                      0.72     0.72
vercel_ai_gateway/meta/llama-3.3-70b                 vercel_ai_gateway              0.72     0.72
vertex_ai/meta/llama-3.3-70b-instruct-maas           vertex_ai-llama_models         0.72     0.72
```

Dez entradas de nove provedores, e o preço de entrada mais barato é **US$ 0,135** por milhão de tokens
contra **US$ 0,90** no mais caro: quase sete vezes mais pelos mesmos pesos. Os preços de saída vão de
US$ 0,40 a US$ 2,253. Parte da diferença é real: `fp8` num nome quer dizer que o host roda os pesos
com precisão reduzida, o que a aula 3 explica, e os hosts diferem em velocidade e no que prometem de
disponibilidade. Mas boa parte é **concorrência**. Qualquer um com o hardware pode servir esses
pesos, então muitos servem, e o preço cai em direção ao custo da máquina.

Agora um modelo fechado, o Claude Sonnet 5.5:

```
ana@desk:~/desk$ sheet where claude-sonnet-5-5
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
claude-sonnet-5-5                                    anthropic                         2       10
azure_ai/claude-sonnet-5-5                           azure_ai                          2       10
bedrock/us-gov-east-1/anthropic.claude-sonnet-5-5    bedrock                         2.4       12
bedrock/us-gov-west-1/anthropic.claude-sonnet-5-5    bedrock                         2.4       12
anthropic.claude-sonnet-5-5                          bedrock_converse                  2       10
apac.anthropic.claude-sonnet-5-5                     bedrock_converse                2.2       11
au.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
eu.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
global.anthropic.claude-sonnet-5-5                   bedrock_converse                  2       10
jp.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
us-gov.anthropic.claude-sonnet-5-5                   bedrock_converse                2.4       12
us.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
bedrock_mantle/anthropic.claude-sonnet-5-5           bedrock_mantle                  2.2       11
bedrock_mantle/us-gov-west-1/anthropic.claude-sonnet bedrock_mantle                  2.4       12
perplexity/anthropic/claude-sonnet-5-5               perplexity                        2       10
vertex_ai/claude-sonnet-5-5                          vertex_ai-anthropic_models        2       10
vertex_ai/claude-sonnet-5-5@default                  vertex_ai-anthropic_models        2       10
```

Dezessete entradas, e todas são o modelo da Anthropic revendido, ou acessado pela API da própria
Anthropic. Os preços quase não se mexem: **US$ 2** na entrada e **US$ 10** na saída na própria
Anthropic, na Azure, no Vertex do Google e na rota `global` do Bedrock; dez por cento a mais nas
rotas regionais do Bedrock, vinte por cento a mais nas regiões do governo americano. Nenhum host
consegue cobrar menos que o autor, porque nenhum host tem nada a vender além do acesso ao modelo do
autor.

## O que isso significa para escolher

- **Um modelo aberto é uma mercadoria, e mercadoria se pesquisa.** O modelo é fixo; escolha o
  host por preço, velocidade e termos, e troque de host sem mudar uma linha do prompt. A aula 15
  mostra um roteador que faz essa pesquisa a cada requisição.
- **Um modelo fechado tem um preço**, definido por quem o fez, com pequenas diferenças regionais.
  O que se negocia é volume, não a taxa por token da página.
- **Por token nunca é a conta inteira.** É a parte que cresce com o uso. A aula 4 soma as outras
  partes, e a aula 21 as que só aparecem quando algo dá errado.

A tabela é uma cópia de terceiros tirada num commit, e as duas listas vão ter mudado quando você ler
isto. **O formato é o que dura**: muitos hosts e uma faixa larga para pesos abertos, um autor e uma
faixa estreita para os fechados.
