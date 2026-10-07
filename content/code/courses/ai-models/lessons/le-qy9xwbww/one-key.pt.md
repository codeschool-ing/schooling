---
title: Uma chave na frente de muitas
version: 1
---

As aulas 6 a 12 encontraram cada provedor separado: a chave dele, o SDK dele, a conta dele. O
**OpenRouter** põe um endereço e uma chave na frente da maioria deles. Uma requisição nomeia um
modelo como `autor/modelo`, no formato da OpenAI da seção 05 da aula 9, e o OpenRouter a encaminha a
um provedor que serve esse modelo. Na tabela de modelos ele é, com folga, a maior entrada sozinha:

```
ana@desk:~/desk$ python sheet.py count | head -4
# LiteLLM model sheet at 21881c57, 4472 entries
  490  openrouter
  335  fireworks_ai
  305  azure
```

O openrouter.ai foi recusado pela rede da máquina em que este curso foi gravado, e uma chave do
OpenRouter é uma conta a pagar. Então esta aula mostra duas coisas que são reais: o que a
documentação do OpenRouter diz, lida num commit fixado, e como é uma requisição para ele, mandada
pelo relay da seção 03 da aula 9 até o Ollama. **O que o OpenRouter responderia é citado da
documentação dele e nunca mostrado como se tivesse rodado.**

## Quanto custa

A tabela lista os mesmos modelos pelo OpenRouter e direto dos autores:

```
ana@desk:~/desk$ python sheet.py compare claude-sonnet-4-5 openrouter/anthropic/claude-sonnet-4.5 gemini-2.5-flash openrouter/google/gemini-2.5-flash
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
claude-sonnet-4-5                             1,000,000    64000        3       15  VFSCRP
openrouter/anthropic/claude-sonnet-4.5        1,000,000    64000        3       15  VFSCRP
gemini-2.5-flash                              1,048,576    65535      0.3      2.5  VFSCRP
openrouter/google/gemini-2.5-flash            1,048,576    65535      0.3      2.5  VFSCRP
```

Idênticos, e a documentação diz por quê:

```
# OpenRouterTeam/docs@3e840a21 faq.mdx
  72: We pass through the pricing of the underlying providers; there is no markup
  83: OpenRouter charges a {getTotalFeeString('stripe', null)} fee when you purchase credits.
      We pass through
```

A taxa é um modelo de texto nessa página, preenchido por um arquivo de constantes ao lado dela, que
diz quanto dá:

```
# OpenRouterTeam/docs@3e840a21 snippets/exports/constants.mdx
 141: export const getTotalFeeString = (type, value) => {
 142: if (type === 'stripe') return '5.5% ($0.80 minimum)';
```

Então o preço por token é o do provedor, e **a plataforma é paga quando você compra créditos**: 5,5%
no cartão, nunca menos de US$ 0,80. Comprar US$ 100 de créditos custa US$ 5,50 a mais; comprar US$
10 custa o mínimo de US$ 0,80, que é 8%. Para uma mesa do tamanho da da ana, esse é o número a
comparar com ter três contas em três provedores, cada uma com uma chave para guardar e uma conta
para ler.

## A resposta traz o próprio custo

O OpenRouter devolve o custo de cada requisição dentro da resposta, em `usage.cost`, e a
documentação dele separa o que a conta pagou do que o provedor cobrou:

```
# OpenRouterTeam/docs@3e840a21 cookbook/administration/usage-accounting.mdx
  73: - `cost`: The total amount charged to your account
  74: - `cost_details.upstream_inference_cost`: The actual cost charged by the upstream AI
      provider
```

Os preços na lista de modelos dele são **dólares por token, como strings**, onde a tabela e a aula 4
usaram dólares por milhão: US$ 3 por milhão é `0.000003`. Somar o `usage.cost` de um mês é a conta
que a aula 21 controla, sem uma segunda fonte para conciliar.
