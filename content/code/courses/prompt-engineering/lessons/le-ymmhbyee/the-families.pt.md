---
title: Os cinco provedores e as suas famílias
version: 1
---

É natural querer um ranking: o modelo de qual provedor é o melhor. **Nenhum ranking sobrevive a um
ano**, porque cada uma dessas empresas lança modelos novos várias vezes por ano, troca os nomes e
aposenta os antigos. O que dura mais é o formato da oferta de cada provedor: como se chamam as
famílias de modelos, e se você só as alcança pelo serviço dele ou se dá para baixá-las. Esta seção
é esse formato, no momento em que foi escrita (2026), sem números de versão, sem preços e sem
notas, porque é justamente isso que envelhece primeiro.

| provedor | as famílias de modelos | como você chega a elas |
|---|---|---|
| OpenAI | modelos GPT, incluindo alguns feitos para raciocinar longamente antes de responder | os apps do ChatGPT e a API da OpenAI; ela também publicou alguns modelos de pesos abertos |
| Google | Gemini; Gemma, uma família à parte de modelos menores de pesos abertos | os apps do Gemini, a API do Google e o Google Cloud; os pesos do Gemma podem ser baixados |
| Anthropic | Claude | os apps do Claude, a API da Anthropic e grandes plataformas de nuvem que também o oferecem |
| Meta | Llama | pesos que você baixa sob a licença própria da Meta, e o assistente da Meta nos apps dela |
| xAI | Grok | o app do Grok, a plataforma X e a API da xAI; ela publicou os pesos de um modelo Grok mais antigo |

Três coisas na tabela importam mais que os nomes.

**Cada família tem muitos modelos.** Um provedor costuma oferecer vários tamanhos de cada geração ao
mesmo tempo: um grande, mais capaz e mais lento, e menores, mais baratos e mais rápidos. "Usamos o
Claude" ou "usamos o GPT" diz qual empresa, não qual modelo, e dois modelos da mesma família podem
ser mais diferentes entre si que dois modelos de empresas diferentes.

**O mesmo modelo é muitas vezes vendido em mais de um lugar.** Um modelo pode ser alcançado pela API
de quem o fez e por uma ou mais plataformas de nuvem, com preços, limites, regiões e condições de
dados diferentes em cada uma. De onde você chama um modelo é uma decisão à parte.

**Cinco não é o campo inteiro.** Esses são os provedores que o título desta lição nomeia. Outros
publicam modelos muito usados, vários deles de pesos abertos, entre eles a Mistral AI, na França, e
a DeepSeek e a equipe Qwen da Alibaba, na China. Uma escolha feita só entre os cinco famosos é uma
escolha feita com parte do cardápio.

## Modelos de raciocínio

Vale nomear uma novidade, porque ela muda o jeito de usar um modelo. Vários provedores oferecem hoje
modelos treinados para escrever uma longa cadeia de passos intermediários antes da resposta final,
às vezes escondida de você e às vezes mostrada. Eles tendem a se sair melhor em problemas de muitos
passos, como matemática e código, e gastam mais tokens e mais tempo por resposta, que você paga. A
lição 26 é a cadeia de pensamento, a técnica de prompt que pede esses passos no próprio prompt.

## No que não confiar nesta seção

Tudo na tabela foi conferido no momento da escrita e **vai mudar**: uma família renomeada, um novo
lançamento de pesos abertos, um modelo disponível numa plataforma em que não estava antes. Leia a
tabela como um mapa de onde procurar, e leia a documentação do próprio provedor, com a data dela,
para qualquer coisa de que você vá depender. A última seção desta lição trata de como fazer isso.
